BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'plugin_source_type_enum'
  ) THEN
    CREATE TYPE runtime.plugin_source_type_enum AS ENUM (
      'builtin',
      'local',
      'remote',
      'marketplace'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'plugin_lifecycle_status_enum'
  ) THEN
    CREATE TYPE runtime.plugin_lifecycle_status_enum AS ENUM (
      'draft',
      'published',
      'deprecated',
      'disabled',
      'archived'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'plugin_runtime_state_enum'
  ) THEN
    CREATE TYPE runtime.plugin_runtime_state_enum AS ENUM (
      'installed',
      'activating',
      'active',
      'degraded',
      'inactive',
      'failed',
      'uninstalled'
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

CREATE TABLE IF NOT EXISTS runtime.plugins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  plugin_key text NOT NULL,
  display_name text NOT NULL,
  version_no text NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  source_type runtime.plugin_source_type_enum NOT NULL DEFAULT 'local',
  lifecycle_status runtime.plugin_lifecycle_status_enum NOT NULL DEFAULT 'draft',
  entrypoint_ref text NOT NULL,
  checksum text,
  required_platform_version text,
  manifest jsonb NOT NULL DEFAULT '{}'::jsonb,
  permissions jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_enabled boolean NOT NULL DEFAULT true,
  published_at timestamptz,
  deprecated_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (plugin_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (display_name <> ''),
  CHECK (version_no <> ''),
  CHECK (entrypoint_ref <> ''),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  ),
  CHECK (published_at IS NULL OR published_at >= created_at),
  CHECK (deprecated_at IS NULL OR deprecated_at >= created_at),
  CHECK (archived_at IS NULL OR archived_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_plugins_tenant_plugin_key_version
ON runtime.plugins (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  plugin_key,
  version_no
);

CREATE INDEX IF NOT EXISTS ix_plugins_tenant_id
ON runtime.plugins (tenant_id);

CREATE INDEX IF NOT EXISTS ix_plugins_status
ON runtime.plugins (lifecycle_status);

CREATE INDEX IF NOT EXISTS ix_plugins_source_type
ON runtime.plugins (source_type);

CREATE TABLE IF NOT EXISTS runtime.plugin_states (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  plugin_id uuid NOT NULL REFERENCES runtime.plugins(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  state_key text NOT NULL,
  desired_state runtime.plugin_runtime_state_enum NOT NULL DEFAULT 'active',
  current_state runtime.plugin_runtime_state_enum NOT NULL DEFAULT 'installed',
  install_ref text,
  installed_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  deactivated_at timestamptz,
  last_health_at timestamptz,
  last_error text,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  runtime_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (state_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (installed_at >= created_at),
  CHECK (activated_at IS NULL OR activated_at >= installed_at),
  CHECK (deactivated_at IS NULL OR deactivated_at >= installed_at),
  CHECK (last_health_at IS NULL OR last_health_at >= installed_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_plugin_states_plugin_state_key
ON runtime.plugin_states (plugin_id, state_key);

CREATE INDEX IF NOT EXISTS ix_plugin_states_tenant_id
ON runtime.plugin_states (tenant_id);

CREATE INDEX IF NOT EXISTS ix_plugin_states_plugin_id
ON runtime.plugin_states (plugin_id);

CREATE INDEX IF NOT EXISTS ix_plugin_states_current_state
ON runtime.plugin_states (current_state);

CREATE OR REPLACE FUNCTION runtime.validate_plugin_state_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_plugin_tenant_id uuid;
  v_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT p.tenant_id, p.visibility_scope
    INTO v_plugin_tenant_id, v_visibility_scope
  FROM runtime.plugins p
  WHERE p.id = NEW.plugin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'plugin not found: %', NEW.plugin_id;
  END IF;

  IF v_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global plugin state must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant plugin state must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_plugin_tenant_id THEN
      RAISE EXCEPTION 'plugin state tenant_id must match plugin tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_plugins_touch_updated_at
ON runtime.plugins;

CREATE TRIGGER trg_plugins_touch_updated_at
BEFORE UPDATE ON runtime.plugins
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_plugin_states_touch_updated_at
ON runtime.plugin_states;

CREATE TRIGGER trg_plugin_states_touch_updated_at
BEFORE UPDATE ON runtime.plugin_states
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_plugin_states_validate_scope
ON runtime.plugin_states;

CREATE TRIGGER trg_plugin_states_validate_scope
BEFORE INSERT OR UPDATE ON runtime.plugin_states
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_plugin_state_scope();

ALTER TABLE runtime.plugins ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.plugins FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.plugin_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.plugin_states FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_plugins_select ON runtime.plugins;
CREATE POLICY p_plugins_select
ON runtime.plugins
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_plugins_insert ON runtime.plugins;
CREATE POLICY p_plugins_insert
ON runtime.plugins
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_plugins_update ON runtime.plugins;
CREATE POLICY p_plugins_update
ON runtime.plugins
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_plugins_delete ON runtime.plugins;
CREATE POLICY p_plugins_delete
ON runtime.plugins
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_plugin_states_select ON runtime.plugin_states;
CREATE POLICY p_plugin_states_select
ON runtime.plugin_states
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_plugin_states_insert ON runtime.plugin_states;
CREATE POLICY p_plugin_states_insert
ON runtime.plugin_states
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_plugin_states_update ON runtime.plugin_states;
CREATE POLICY p_plugin_states_update
ON runtime.plugin_states
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_plugin_states_delete ON runtime.plugin_states;
CREATE POLICY p_plugin_states_delete
ON runtime.plugin_states
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
