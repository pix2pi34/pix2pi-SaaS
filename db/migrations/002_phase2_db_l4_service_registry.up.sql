BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'registry_service_kind_enum'
  ) THEN
    CREATE TYPE runtime.registry_service_kind_enum AS ENUM (
      'api',
      'worker',
      'gateway',
      'cron',
      'realtime',
      'plugin',
      'external'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'registry_visibility_scope_enum'
  ) THEN
    CREATE TYPE runtime.registry_visibility_scope_enum AS ENUM (
      'global',
      'tenant',
      'internal'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'registry_protocol_enum'
  ) THEN
    CREATE TYPE runtime.registry_protocol_enum AS ENUM (
      'http',
      'https',
      'grpc',
      'ws',
      'sse',
      'nats',
      'tcp',
      'internal'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'registry_instance_status_enum'
  ) THEN
    CREATE TYPE runtime.registry_instance_status_enum AS ENUM (
      'starting',
      'healthy',
      'degraded',
      'unhealthy',
      'draining',
      'stopped'
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

CREATE OR REPLACE FUNCTION security.tenant_or_global_row_visible(row_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT security.is_super_admin()
         OR row_tenant_id IS NULL
         OR row_tenant_id = security.current_tenant_id()
$$;

CREATE OR REPLACE FUNCTION security.tenant_only_row_mutable(row_tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT security.is_super_admin()
         OR row_tenant_id = security.current_tenant_id()
$$;

CREATE TABLE IF NOT EXISTS runtime.service_registry_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  service_key text NOT NULL,
  display_name text NOT NULL,
  service_kind runtime.registry_service_kind_enum NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  protocol runtime.registry_protocol_enum NOT NULL DEFAULT 'http',
  base_path text NOT NULL DEFAULT '/',
  health_path text NOT NULL DEFAULT '/health',
  default_port integer,
  owner_team text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (service_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (base_path LIKE '/%'),
  CHECK (health_path LIKE '/%'),
  CHECK (default_port IS NULL OR default_port BETWEEN 1 AND 65535),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_service_registry_services_tenant_service_key
ON runtime.service_registry_services (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  service_key
);

CREATE INDEX IF NOT EXISTS ix_service_registry_services_tenant_id
ON runtime.service_registry_services (tenant_id);

CREATE INDEX IF NOT EXISTS ix_service_registry_services_kind
ON runtime.service_registry_services (service_kind);

CREATE TABLE IF NOT EXISTS runtime.service_registry_instances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES runtime.service_registry_services(id) ON DELETE CASCADE,
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  instance_key text NOT NULL,
  node_name text NOT NULL,
  host text NOT NULL,
  port integer NOT NULL,
  status runtime.registry_instance_status_enum NOT NULL DEFAULT 'starting',
  version text,
  heartbeat_interval_seconds integer NOT NULL DEFAULT 30,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz,
  last_health_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_maintenance_mode boolean NOT NULL DEFAULT false,
  is_quarantined boolean NOT NULL DEFAULT false,
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (instance_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (host <> ''),
  CHECK (port BETWEEN 1 AND 65535),
  CHECK (heartbeat_interval_seconds BETWEEN 5 AND 3600)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_service_registry_instances_service_instance_key
ON runtime.service_registry_instances (service_id, instance_key);

CREATE INDEX IF NOT EXISTS ix_service_registry_instances_tenant_id
ON runtime.service_registry_instances (tenant_id);

CREATE INDEX IF NOT EXISTS ix_service_registry_instances_status
ON runtime.service_registry_instances (status);

CREATE INDEX IF NOT EXISTS ix_service_registry_instances_last_heartbeat_at
ON runtime.service_registry_instances (last_heartbeat_at);

CREATE TABLE IF NOT EXISTS runtime.service_registry_heartbeats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES runtime.service_registry_services(id) ON DELETE CASCADE,
  instance_id uuid NOT NULL REFERENCES runtime.service_registry_instances(id) ON DELETE CASCADE,
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  status runtime.registry_instance_status_enum NOT NULL,
  response_time_ms integer,
  heartbeat_at timestamptz NOT NULL DEFAULT now(),
  detail jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (response_time_ms IS NULL OR response_time_ms >= 0)
);

CREATE INDEX IF NOT EXISTS ix_service_registry_heartbeats_instance_id
ON runtime.service_registry_heartbeats (instance_id, heartbeat_at DESC);

CREATE INDEX IF NOT EXISTS ix_service_registry_heartbeats_tenant_id
ON runtime.service_registry_heartbeats (tenant_id);

CREATE OR REPLACE FUNCTION runtime.validate_service_registry_instance_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_service_tenant_id uuid;
  v_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT s.tenant_id, s.visibility_scope
    INTO v_service_tenant_id, v_visibility_scope
  FROM runtime.service_registry_services s
  WHERE s.id = NEW.service_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'service_registry service not found: %', NEW.service_id;
  END IF;

  IF v_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global service instance must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant scoped service instance must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_service_tenant_id THEN
      RAISE EXCEPTION 'instance tenant_id must match service tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_service_registry_heartbeat_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_instance_tenant_id uuid;
  v_instance_service_id uuid;
BEGIN
  SELECT i.tenant_id, i.service_id
    INTO v_instance_tenant_id, v_instance_service_id
  FROM runtime.service_registry_instances i
  WHERE i.id = NEW.instance_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'service_registry instance not found: %', NEW.instance_id;
  END IF;

  IF NEW.service_id <> v_instance_service_id THEN
    RAISE EXCEPTION 'heartbeat service_id must match instance.service_id';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_instance_tenant_id THEN
    RAISE EXCEPTION 'heartbeat tenant_id must match instance.tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_service_registry_services_touch_updated_at
ON runtime.service_registry_services;

CREATE TRIGGER trg_service_registry_services_touch_updated_at
BEFORE UPDATE ON runtime.service_registry_services
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_service_registry_instances_touch_updated_at
ON runtime.service_registry_instances;

CREATE TRIGGER trg_service_registry_instances_touch_updated_at
BEFORE UPDATE ON runtime.service_registry_instances
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_service_registry_instances_validate_scope
ON runtime.service_registry_instances;

CREATE TRIGGER trg_service_registry_instances_validate_scope
BEFORE INSERT OR UPDATE ON runtime.service_registry_instances
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_service_registry_instance_scope();

DROP TRIGGER IF EXISTS trg_service_registry_heartbeats_validate_scope
ON runtime.service_registry_heartbeats;

CREATE TRIGGER trg_service_registry_heartbeats_validate_scope
BEFORE INSERT OR UPDATE ON runtime.service_registry_heartbeats
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_service_registry_heartbeat_scope();

ALTER TABLE runtime.service_registry_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.service_registry_services FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.service_registry_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.service_registry_instances FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.service_registry_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.service_registry_heartbeats FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_service_registry_services_select ON runtime.service_registry_services;
CREATE POLICY p_service_registry_services_select
ON runtime.service_registry_services
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_service_registry_services_insert ON runtime.service_registry_services;
CREATE POLICY p_service_registry_services_insert
ON runtime.service_registry_services
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_services_update ON runtime.service_registry_services;
CREATE POLICY p_service_registry_services_update
ON runtime.service_registry_services
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_services_delete ON runtime.service_registry_services;
CREATE POLICY p_service_registry_services_delete
ON runtime.service_registry_services
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_instances_select ON runtime.service_registry_instances;
CREATE POLICY p_service_registry_instances_select
ON runtime.service_registry_instances
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_service_registry_instances_insert ON runtime.service_registry_instances;
CREATE POLICY p_service_registry_instances_insert
ON runtime.service_registry_instances
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_instances_update ON runtime.service_registry_instances;
CREATE POLICY p_service_registry_instances_update
ON runtime.service_registry_instances
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_instances_delete ON runtime.service_registry_instances;
CREATE POLICY p_service_registry_instances_delete
ON runtime.service_registry_instances
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_heartbeats_select ON runtime.service_registry_heartbeats;
CREATE POLICY p_service_registry_heartbeats_select
ON runtime.service_registry_heartbeats
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_service_registry_heartbeats_insert ON runtime.service_registry_heartbeats;
CREATE POLICY p_service_registry_heartbeats_insert
ON runtime.service_registry_heartbeats
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_service_registry_heartbeats_delete ON runtime.service_registry_heartbeats;
CREATE POLICY p_service_registry_heartbeats_delete
ON runtime.service_registry_heartbeats
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
