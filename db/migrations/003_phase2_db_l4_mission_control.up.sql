BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'mission_control_severity_enum'
  ) THEN
    CREATE TYPE runtime.mission_control_severity_enum AS ENUM (
      'critical',
      'high',
      'medium',
      'low',
      'info'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'mission_control_incident_status_enum'
  ) THEN
    CREATE TYPE runtime.mission_control_incident_status_enum AS ENUM (
      'open',
      'acknowledged',
      'investigating',
      'mitigated',
      'resolved',
      'closed'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'mission_control_action_type_enum'
  ) THEN
    CREATE TYPE runtime.mission_control_action_type_enum AS ENUM (
      'note',
      'restart',
      'isolate',
      'quarantine',
      'maintenance_on',
      'maintenance_off',
      'acknowledge',
      'resolve',
      'reopen'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'mission_control_action_status_enum'
  ) THEN
    CREATE TYPE runtime.mission_control_action_status_enum AS ENUM (
      'requested',
      'approved',
      'running',
      'succeeded',
      'failed',
      'cancelled'
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

CREATE TABLE IF NOT EXISTS runtime.mission_control_incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  incident_key text NOT NULL,
  service_id uuid REFERENCES runtime.service_registry_services(id) ON DELETE SET NULL,
  instance_id uuid REFERENCES runtime.service_registry_instances(id) ON DELETE SET NULL,
  title text NOT NULL,
  summary text NOT NULL DEFAULT '',
  severity runtime.mission_control_severity_enum NOT NULL,
  status runtime.mission_control_incident_status_enum NOT NULL DEFAULT 'open',
  source text NOT NULL DEFAULT 'runtime',
  owner_team text,
  opened_by text,
  acknowledged_by text,
  resolved_by text,
  detected_at timestamptz NOT NULL DEFAULT now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  closed_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (incident_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (title <> ''),
  CHECK (source <> ''),
  CHECK (acknowledged_at IS NULL OR acknowledged_at >= detected_at),
  CHECK (resolved_at IS NULL OR resolved_at >= detected_at),
  CHECK (closed_at IS NULL OR closed_at >= detected_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_mission_control_incidents_tenant_incident_key
ON runtime.mission_control_incidents (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  incident_key
);

CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_tenant_id
ON runtime.mission_control_incidents (tenant_id);

CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_status
ON runtime.mission_control_incidents (status);

CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_severity
ON runtime.mission_control_incidents (severity);

CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_service_id
ON runtime.mission_control_incidents (service_id);

CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_instance_id
ON runtime.mission_control_incidents (instance_id);

CREATE TABLE IF NOT EXISTS runtime.mission_control_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  incident_id uuid NOT NULL REFERENCES runtime.mission_control_incidents(id) ON DELETE CASCADE,
  service_id uuid REFERENCES runtime.service_registry_services(id) ON DELETE SET NULL,
  instance_id uuid REFERENCES runtime.service_registry_instances(id) ON DELETE SET NULL,
  action_type runtime.mission_control_action_type_enum NOT NULL,
  action_status runtime.mission_control_action_status_enum NOT NULL DEFAULT 'requested',
  requested_by text NOT NULL,
  requested_reason text NOT NULL DEFAULT '',
  executed_by text,
  result_message text NOT NULL DEFAULT '',
  requested_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  finished_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (requested_by <> ''),
  CHECK (started_at IS NULL OR started_at >= requested_at),
  CHECK (finished_at IS NULL OR finished_at >= requested_at)
);

CREATE INDEX IF NOT EXISTS ix_mission_control_actions_tenant_id
ON runtime.mission_control_actions (tenant_id);

CREATE INDEX IF NOT EXISTS ix_mission_control_actions_incident_id
ON runtime.mission_control_actions (incident_id);

CREATE INDEX IF NOT EXISTS ix_mission_control_actions_status
ON runtime.mission_control_actions (action_status);

CREATE INDEX IF NOT EXISTS ix_mission_control_actions_type
ON runtime.mission_control_actions (action_type);

CREATE OR REPLACE FUNCTION runtime.validate_mission_control_incident_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_service_tenant_id uuid;
  v_instance_tenant_id uuid;
  v_instance_service_id uuid;
BEGIN
  IF NEW.service_id IS NOT NULL THEN
    SELECT s.tenant_id
      INTO v_service_tenant_id
    FROM runtime.service_registry_services s
    WHERE s.id = NEW.service_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'mission_control incident service not found: %', NEW.service_id;
    END IF;

    IF v_service_tenant_id IS NOT NULL AND NEW.tenant_id IS DISTINCT FROM v_service_tenant_id THEN
      RAISE EXCEPTION 'incident tenant_id must match service tenant_id for tenant-scoped service';
    END IF;
  END IF;

  IF NEW.instance_id IS NOT NULL THEN
    SELECT i.tenant_id, i.service_id
      INTO v_instance_tenant_id, v_instance_service_id
    FROM runtime.service_registry_instances i
    WHERE i.id = NEW.instance_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'mission_control incident instance not found: %', NEW.instance_id;
    END IF;

    IF NEW.service_id IS NOT NULL AND NEW.service_id <> v_instance_service_id THEN
      RAISE EXCEPTION 'incident instance.service_id must match incident.service_id';
    END IF;

    IF v_instance_tenant_id IS NOT NULL AND NEW.tenant_id IS DISTINCT FROM v_instance_tenant_id THEN
      RAISE EXCEPTION 'incident tenant_id must match instance tenant_id for tenant-scoped instance';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_mission_control_action_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_incident_tenant_id uuid;
  v_incident_service_id uuid;
  v_incident_instance_id uuid;
BEGIN
  SELECT i.tenant_id, i.service_id, i.instance_id
    INTO v_incident_tenant_id, v_incident_service_id, v_incident_instance_id
  FROM runtime.mission_control_incidents i
  WHERE i.id = NEW.incident_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'mission_control action incident not found: %', NEW.incident_id;
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_incident_tenant_id THEN
    RAISE EXCEPTION 'action tenant_id must match incident tenant_id';
  END IF;

  IF NEW.service_id IS NOT NULL AND v_incident_service_id IS NOT NULL AND NEW.service_id <> v_incident_service_id THEN
    RAISE EXCEPTION 'action service_id must match incident service_id';
  END IF;

  IF NEW.instance_id IS NOT NULL AND v_incident_instance_id IS NOT NULL AND NEW.instance_id <> v_incident_instance_id THEN
    RAISE EXCEPTION 'action instance_id must match incident instance_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mission_control_incidents_touch_updated_at
ON runtime.mission_control_incidents;

CREATE TRIGGER trg_mission_control_incidents_touch_updated_at
BEFORE UPDATE ON runtime.mission_control_incidents
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_mission_control_actions_touch_updated_at
ON runtime.mission_control_actions;

CREATE TRIGGER trg_mission_control_actions_touch_updated_at
BEFORE UPDATE ON runtime.mission_control_actions
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_mission_control_incidents_validate_scope
ON runtime.mission_control_incidents;

CREATE TRIGGER trg_mission_control_incidents_validate_scope
BEFORE INSERT OR UPDATE ON runtime.mission_control_incidents
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_mission_control_incident_scope();

DROP TRIGGER IF EXISTS trg_mission_control_actions_validate_scope
ON runtime.mission_control_actions;

CREATE TRIGGER trg_mission_control_actions_validate_scope
BEFORE INSERT OR UPDATE ON runtime.mission_control_actions
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_mission_control_action_scope();

ALTER TABLE runtime.mission_control_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.mission_control_incidents FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.mission_control_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.mission_control_actions FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_mission_control_incidents_select ON runtime.mission_control_incidents;
CREATE POLICY p_mission_control_incidents_select
ON runtime.mission_control_incidents
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_mission_control_incidents_insert ON runtime.mission_control_incidents;
CREATE POLICY p_mission_control_incidents_insert
ON runtime.mission_control_incidents
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_mission_control_incidents_update ON runtime.mission_control_incidents;
CREATE POLICY p_mission_control_incidents_update
ON runtime.mission_control_incidents
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_mission_control_incidents_delete ON runtime.mission_control_incidents;
CREATE POLICY p_mission_control_incidents_delete
ON runtime.mission_control_incidents
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_mission_control_actions_select ON runtime.mission_control_actions;
CREATE POLICY p_mission_control_actions_select
ON runtime.mission_control_actions
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_mission_control_actions_insert ON runtime.mission_control_actions;
CREATE POLICY p_mission_control_actions_insert
ON runtime.mission_control_actions
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_mission_control_actions_update ON runtime.mission_control_actions;
CREATE POLICY p_mission_control_actions_update
ON runtime.mission_control_actions
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_mission_control_actions_delete ON runtime.mission_control_actions;
CREATE POLICY p_mission_control_actions_delete
ON runtime.mission_control_actions
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
