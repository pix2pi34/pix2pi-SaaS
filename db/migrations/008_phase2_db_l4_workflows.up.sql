BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'workflow_definition_status_enum'
  ) THEN
    CREATE TYPE runtime.workflow_definition_status_enum AS ENUM (
      'draft',
      'active',
      'deprecated',
      'disabled'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'workflow_instance_status_enum'
  ) THEN
    CREATE TYPE runtime.workflow_instance_status_enum AS ENUM (
      'pending',
      'running',
      'waiting_approval',
      'completed',
      'failed',
      'cancelled'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'workflow_step_status_enum'
  ) THEN
    CREATE TYPE runtime.workflow_step_status_enum AS ENUM (
      'pending',
      'ready',
      'running',
      'waiting_approval',
      'completed',
      'failed',
      'cancelled',
      'skipped'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'workflow_approval_status_enum'
  ) THEN
    CREATE TYPE runtime.workflow_approval_status_enum AS ENUM (
      'pending',
      'approved',
      'rejected',
      'cancelled',
      'expired'
    );
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION runtime.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS runtime.workflow_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  workflow_key text NOT NULL,
  display_name text NOT NULL,
  version_no integer NOT NULL DEFAULT 1,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  definition_status runtime.workflow_definition_status_enum NOT NULL DEFAULT 'draft',
  trigger_event text,
  definition_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (workflow_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (display_name <> ''),
  CHECK (version_no BETWEEN 1 AND 10000),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_definitions_tenant_key_version
ON runtime.workflow_definitions (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  workflow_key,
  version_no
);

CREATE INDEX IF NOT EXISTS ix_workflow_definitions_tenant_id
ON runtime.workflow_definitions (tenant_id);

CREATE INDEX IF NOT EXISTS ix_workflow_definitions_status
ON runtime.workflow_definitions (definition_status);

CREATE TABLE IF NOT EXISTS runtime.workflow_instances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  definition_id uuid NOT NULL REFERENCES runtime.workflow_definitions(id) ON DELETE RESTRICT,
  business_code text NOT NULL,
  instance_key text NOT NULL,
  workflow_status runtime.workflow_instance_status_enum NOT NULL DEFAULT 'pending',
  subject_ref_type text,
  subject_ref_id text,
  current_step_key text,
  context_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (instance_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_instances_tenant_instance_key
ON runtime.workflow_instances (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  instance_key
);

CREATE INDEX IF NOT EXISTS ix_workflow_instances_tenant_id
ON runtime.workflow_instances (tenant_id);

CREATE INDEX IF NOT EXISTS ix_workflow_instances_definition_id
ON runtime.workflow_instances (definition_id);

CREATE INDEX IF NOT EXISTS ix_workflow_instances_status
ON runtime.workflow_instances (workflow_status);

CREATE TABLE IF NOT EXISTS runtime.workflow_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  instance_id uuid NOT NULL REFERENCES runtime.workflow_instances(id) ON DELETE CASCADE,
  definition_id uuid NOT NULL REFERENCES runtime.workflow_definitions(id) ON DELETE RESTRICT,
  business_code text NOT NULL,
  step_key text NOT NULL,
  step_order integer NOT NULL,
  step_type text NOT NULL,
  step_status runtime.workflow_step_status_enum NOT NULL DEFAULT 'pending',
  assigned_to text,
  started_at timestamptz,
  finished_at timestamptz,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (step_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (step_order BETWEEN 1 AND 10000),
  CHECK (step_type <> ''),
  CHECK (finished_at IS NULL OR started_at IS NOT NULL),
  CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_steps_instance_step_key
ON runtime.workflow_steps (instance_id, step_key);

CREATE INDEX IF NOT EXISTS ix_workflow_steps_tenant_id
ON runtime.workflow_steps (tenant_id);

CREATE INDEX IF NOT EXISTS ix_workflow_steps_instance_id
ON runtime.workflow_steps (instance_id);

CREATE INDEX IF NOT EXISTS ix_workflow_steps_status
ON runtime.workflow_steps (step_status);

CREATE TABLE IF NOT EXISTS runtime.workflow_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  instance_id uuid NOT NULL REFERENCES runtime.workflow_instances(id) ON DELETE CASCADE,
  step_id uuid NOT NULL REFERENCES runtime.workflow_steps(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  approval_key text NOT NULL,
  approver_ref text NOT NULL,
  approval_status runtime.workflow_approval_status_enum NOT NULL DEFAULT 'pending',
  requested_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  response_note text NOT NULL DEFAULT '',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (approval_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (approver_ref <> ''),
  CHECK (responded_at IS NULL OR responded_at >= requested_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_approvals_step_approval_key
ON runtime.workflow_approvals (step_id, approval_key);

CREATE INDEX IF NOT EXISTS ix_workflow_approvals_tenant_id
ON runtime.workflow_approvals (tenant_id);

CREATE INDEX IF NOT EXISTS ix_workflow_approvals_instance_id
ON runtime.workflow_approvals (instance_id);

CREATE INDEX IF NOT EXISTS ix_workflow_approvals_step_id
ON runtime.workflow_approvals (step_id);

CREATE INDEX IF NOT EXISTS ix_workflow_approvals_status
ON runtime.workflow_approvals (approval_status);

CREATE OR REPLACE FUNCTION runtime.validate_workflow_instance_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_definition_tenant_id uuid;
  v_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT d.tenant_id, d.visibility_scope
    INTO v_definition_tenant_id, v_visibility_scope
  FROM runtime.workflow_definitions d
  WHERE d.id = NEW.definition_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'workflow definition not found: %', NEW.definition_id;
  END IF;

  IF v_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global workflow instance must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant workflow instance must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_definition_tenant_id THEN
      RAISE EXCEPTION 'workflow instance tenant_id must match definition tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_workflow_step_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_instance_tenant_id uuid;
  v_instance_definition_id uuid;
BEGIN
  SELECT i.tenant_id, i.definition_id
    INTO v_instance_tenant_id, v_instance_definition_id
  FROM runtime.workflow_instances i
  WHERE i.id = NEW.instance_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'workflow instance not found: %', NEW.instance_id;
  END IF;

  IF NEW.definition_id <> v_instance_definition_id THEN
    RAISE EXCEPTION 'workflow step definition_id must match instance definition_id';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_instance_tenant_id THEN
    RAISE EXCEPTION 'workflow step tenant_id must match instance tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_workflow_approval_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_step_tenant_id uuid;
  v_step_instance_id uuid;
BEGIN
  SELECT s.tenant_id, s.instance_id
    INTO v_step_tenant_id, v_step_instance_id
  FROM runtime.workflow_steps s
  WHERE s.id = NEW.step_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'workflow step not found: %', NEW.step_id;
  END IF;

  IF NEW.instance_id <> v_step_instance_id THEN
    RAISE EXCEPTION 'workflow approval instance_id must match step instance_id';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_step_tenant_id THEN
    RAISE EXCEPTION 'workflow approval tenant_id must match step tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_workflow_definitions_touch_updated_at
ON runtime.workflow_definitions;

CREATE TRIGGER trg_workflow_definitions_touch_updated_at
BEFORE UPDATE ON runtime.workflow_definitions
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_instances_touch_updated_at
ON runtime.workflow_instances;

CREATE TRIGGER trg_workflow_instances_touch_updated_at
BEFORE UPDATE ON runtime.workflow_instances
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_steps_touch_updated_at
ON runtime.workflow_steps;

CREATE TRIGGER trg_workflow_steps_touch_updated_at
BEFORE UPDATE ON runtime.workflow_steps
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_approvals_touch_updated_at
ON runtime.workflow_approvals;

CREATE TRIGGER trg_workflow_approvals_touch_updated_at
BEFORE UPDATE ON runtime.workflow_approvals
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_instances_validate_scope
ON runtime.workflow_instances;

CREATE TRIGGER trg_workflow_instances_validate_scope
BEFORE INSERT OR UPDATE ON runtime.workflow_instances
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_workflow_instance_scope();

DROP TRIGGER IF EXISTS trg_workflow_steps_validate_scope
ON runtime.workflow_steps;

CREATE TRIGGER trg_workflow_steps_validate_scope
BEFORE INSERT OR UPDATE ON runtime.workflow_steps
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_workflow_step_scope();

DROP TRIGGER IF EXISTS trg_workflow_approvals_validate_scope
ON runtime.workflow_approvals;

CREATE TRIGGER trg_workflow_approvals_validate_scope
BEFORE INSERT OR UPDATE ON runtime.workflow_approvals
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_workflow_approval_scope();

ALTER TABLE runtime.workflow_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.workflow_definitions FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.workflow_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.workflow_instances FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.workflow_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.workflow_steps FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.workflow_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.workflow_approvals FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_workflow_definitions_select ON runtime.workflow_definitions;
CREATE POLICY p_workflow_definitions_select
ON runtime.workflow_definitions
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_workflow_definitions_insert ON runtime.workflow_definitions;
CREATE POLICY p_workflow_definitions_insert
ON runtime.workflow_definitions
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_definitions_update ON runtime.workflow_definitions;
CREATE POLICY p_workflow_definitions_update
ON runtime.workflow_definitions
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_definitions_delete ON runtime.workflow_definitions;
CREATE POLICY p_workflow_definitions_delete
ON runtime.workflow_definitions
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_instances_select ON runtime.workflow_instances;
CREATE POLICY p_workflow_instances_select
ON runtime.workflow_instances
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_workflow_instances_insert ON runtime.workflow_instances;
CREATE POLICY p_workflow_instances_insert
ON runtime.workflow_instances
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_instances_update ON runtime.workflow_instances;
CREATE POLICY p_workflow_instances_update
ON runtime.workflow_instances
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_instances_delete ON runtime.workflow_instances;
CREATE POLICY p_workflow_instances_delete
ON runtime.workflow_instances
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_steps_select ON runtime.workflow_steps;
CREATE POLICY p_workflow_steps_select
ON runtime.workflow_steps
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_workflow_steps_insert ON runtime.workflow_steps;
CREATE POLICY p_workflow_steps_insert
ON runtime.workflow_steps
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_steps_update ON runtime.workflow_steps;
CREATE POLICY p_workflow_steps_update
ON runtime.workflow_steps
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_steps_delete ON runtime.workflow_steps;
CREATE POLICY p_workflow_steps_delete
ON runtime.workflow_steps
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_approvals_select ON runtime.workflow_approvals;
CREATE POLICY p_workflow_approvals_select
ON runtime.workflow_approvals
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_workflow_approvals_insert ON runtime.workflow_approvals;
CREATE POLICY p_workflow_approvals_insert
ON runtime.workflow_approvals
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_approvals_update ON runtime.workflow_approvals;
CREATE POLICY p_workflow_approvals_update
ON runtime.workflow_approvals
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_workflow_approvals_delete ON runtime.workflow_approvals;
CREATE POLICY p_workflow_approvals_delete
ON runtime.workflow_approvals
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_app') THEN
    GRANT USAGE ON SCHEMA runtime TO pix2pi_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA runtime TO pix2pi_app;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA runtime TO pix2pi_app;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA runtime TO pix2pi_app;
  END IF;
END
$$;

COMMIT;
