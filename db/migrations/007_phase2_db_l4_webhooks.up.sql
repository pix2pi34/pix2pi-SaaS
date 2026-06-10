BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'webhook_auth_type_enum'
  ) THEN
    CREATE TYPE runtime.webhook_auth_type_enum AS ENUM (
      'none',
      'bearer',
      'hmac'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'webhook_delivery_status_enum'
  ) THEN
    CREATE TYPE runtime.webhook_delivery_status_enum AS ENUM (
      'queued',
      'processing',
      'delivered',
      'failed',
      'dead_letter',
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
    WHERE n.nspname = 'runtime' AND t.typname = 'webhook_attempt_status_enum'
  ) THEN
    CREATE TYPE runtime.webhook_attempt_status_enum AS ENUM (
      'started',
      'succeeded',
      'failed',
      'timeout',
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

CREATE TABLE IF NOT EXISTS runtime.webhook_endpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  endpoint_key text NOT NULL,
  display_name text NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  target_url text NOT NULL,
  http_method text NOT NULL DEFAULT 'POST',
  auth_type runtime.webhook_auth_type_enum NOT NULL DEFAULT 'none',
  auth_secret_ref text,
  signature_header text,
  timeout_seconds integer NOT NULL DEFAULT 15,
  retry_limit integer NOT NULL DEFAULT 5,
  retry_backoff_seconds integer NOT NULL DEFAULT 30,
  is_enabled boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (endpoint_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (display_name <> ''),
  CHECK (target_url ~ '^https?://'),
  CHECK (http_method IN ('POST', 'PUT', 'PATCH')),
  CHECK (timeout_seconds BETWEEN 1 AND 300),
  CHECK (retry_limit BETWEEN 0 AND 100),
  CHECK (retry_backoff_seconds BETWEEN 0 AND 86400),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_endpoints_tenant_endpoint_key
ON runtime.webhook_endpoints (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  endpoint_key
);

CREATE INDEX IF NOT EXISTS ix_webhook_endpoints_tenant_id
ON runtime.webhook_endpoints (tenant_id);

CREATE INDEX IF NOT EXISTS ix_webhook_endpoints_enabled
ON runtime.webhook_endpoints (is_enabled);

CREATE TABLE IF NOT EXISTS runtime.webhook_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  endpoint_id uuid NOT NULL REFERENCES runtime.webhook_endpoints(id) ON DELETE RESTRICT,
  business_code text NOT NULL,
  delivery_key text NOT NULL,
  event_type text NOT NULL,
  priority runtime.job_priority_enum NOT NULL DEFAULT 'normal',
  status runtime.webhook_delivery_status_enum NOT NULL DEFAULT 'queued',
  request_headers jsonb NOT NULL DEFAULT '{}'::jsonb,
  request_body jsonb NOT NULL DEFAULT '{}'::jsonb,
  response_code integer,
  response_body text NOT NULL DEFAULT '',
  scheduled_at timestamptz NOT NULL DEFAULT now(),
  delivered_at timestamptz,
  next_retry_at timestamptz,
  retry_count integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 5,
  dead_lettered_at timestamptz,
  source_ref_type text,
  source_ref_id text,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (delivery_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (event_type <> ''),
  CHECK (response_code IS NULL OR response_code BETWEEN 100 AND 599),
  CHECK (retry_count BETWEEN 0 AND 1000),
  CHECK (max_attempts BETWEEN 1 AND 1000),
  CHECK (delivered_at IS NULL OR delivered_at >= created_at),
  CHECK (dead_lettered_at IS NULL OR dead_lettered_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_deliveries_tenant_delivery_key
ON runtime.webhook_deliveries (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  delivery_key
);

CREATE INDEX IF NOT EXISTS ix_webhook_deliveries_tenant_id
ON runtime.webhook_deliveries (tenant_id);

CREATE INDEX IF NOT EXISTS ix_webhook_deliveries_endpoint_id
ON runtime.webhook_deliveries (endpoint_id);

CREATE INDEX IF NOT EXISTS ix_webhook_deliveries_status_scheduled_at
ON runtime.webhook_deliveries (status, scheduled_at);

CREATE INDEX IF NOT EXISTS ix_webhook_deliveries_next_retry_at
ON runtime.webhook_deliveries (next_retry_at);

CREATE TABLE IF NOT EXISTS runtime.webhook_delivery_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  delivery_id uuid NOT NULL REFERENCES runtime.webhook_deliveries(id) ON DELETE CASCADE,
  endpoint_id uuid NOT NULL REFERENCES runtime.webhook_endpoints(id) ON DELETE RESTRICT,
  attempt_no integer NOT NULL,
  status runtime.webhook_attempt_status_enum NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  duration_ms integer,
  response_code integer,
  error_message text,
  response_body text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (attempt_no BETWEEN 1 AND 1000),
  CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CHECK (response_code IS NULL OR response_code BETWEEN 100 AND 599),
  CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_delivery_attempts_delivery_attempt_no
ON runtime.webhook_delivery_attempts (delivery_id, attempt_no);

CREATE INDEX IF NOT EXISTS ix_webhook_delivery_attempts_tenant_id
ON runtime.webhook_delivery_attempts (tenant_id);

CREATE INDEX IF NOT EXISTS ix_webhook_delivery_attempts_delivery_id
ON runtime.webhook_delivery_attempts (delivery_id);

CREATE INDEX IF NOT EXISTS ix_webhook_delivery_attempts_status
ON runtime.webhook_delivery_attempts (status);

CREATE OR REPLACE FUNCTION runtime.validate_webhook_delivery_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_endpoint_tenant_id uuid;
  v_endpoint_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT e.tenant_id, e.visibility_scope
    INTO v_endpoint_tenant_id, v_endpoint_visibility_scope
  FROM runtime.webhook_endpoints e
  WHERE e.id = NEW.endpoint_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'webhook endpoint not found: %', NEW.endpoint_id;
  END IF;

  IF v_endpoint_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global webhook delivery must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant webhook delivery must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_endpoint_tenant_id THEN
      RAISE EXCEPTION 'webhook delivery tenant_id must match endpoint tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_webhook_attempt_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_delivery_tenant_id uuid;
  v_delivery_endpoint_id uuid;
BEGIN
  SELECT d.tenant_id, d.endpoint_id
    INTO v_delivery_tenant_id, v_delivery_endpoint_id
  FROM runtime.webhook_deliveries d
  WHERE d.id = NEW.delivery_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'webhook delivery not found: %', NEW.delivery_id;
  END IF;

  IF NEW.endpoint_id <> v_delivery_endpoint_id THEN
    RAISE EXCEPTION 'webhook attempt endpoint_id must match delivery endpoint_id';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_delivery_tenant_id THEN
    RAISE EXCEPTION 'webhook attempt tenant_id must match delivery tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_webhook_endpoints_touch_updated_at
ON runtime.webhook_endpoints;

CREATE TRIGGER trg_webhook_endpoints_touch_updated_at
BEFORE UPDATE ON runtime.webhook_endpoints
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_webhook_deliveries_touch_updated_at
ON runtime.webhook_deliveries;

CREATE TRIGGER trg_webhook_deliveries_touch_updated_at
BEFORE UPDATE ON runtime.webhook_deliveries
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_webhook_deliveries_validate_scope
ON runtime.webhook_deliveries;

CREATE TRIGGER trg_webhook_deliveries_validate_scope
BEFORE INSERT OR UPDATE ON runtime.webhook_deliveries
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_webhook_delivery_scope();

DROP TRIGGER IF EXISTS trg_webhook_delivery_attempts_validate_scope
ON runtime.webhook_delivery_attempts;

CREATE TRIGGER trg_webhook_delivery_attempts_validate_scope
BEFORE INSERT OR UPDATE ON runtime.webhook_delivery_attempts
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_webhook_attempt_scope();

ALTER TABLE runtime.webhook_endpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.webhook_endpoints FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.webhook_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.webhook_deliveries FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.webhook_delivery_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.webhook_delivery_attempts FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_webhook_endpoints_select ON runtime.webhook_endpoints;
CREATE POLICY p_webhook_endpoints_select
ON runtime.webhook_endpoints
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_webhook_endpoints_insert ON runtime.webhook_endpoints;
CREATE POLICY p_webhook_endpoints_insert
ON runtime.webhook_endpoints
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_endpoints_update ON runtime.webhook_endpoints;
CREATE POLICY p_webhook_endpoints_update
ON runtime.webhook_endpoints
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_endpoints_delete ON runtime.webhook_endpoints;
CREATE POLICY p_webhook_endpoints_delete
ON runtime.webhook_endpoints
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_deliveries_select ON runtime.webhook_deliveries;
CREATE POLICY p_webhook_deliveries_select
ON runtime.webhook_deliveries
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_webhook_deliveries_insert ON runtime.webhook_deliveries;
CREATE POLICY p_webhook_deliveries_insert
ON runtime.webhook_deliveries
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_deliveries_update ON runtime.webhook_deliveries;
CREATE POLICY p_webhook_deliveries_update
ON runtime.webhook_deliveries
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_deliveries_delete ON runtime.webhook_deliveries;
CREATE POLICY p_webhook_deliveries_delete
ON runtime.webhook_deliveries
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_delivery_attempts_select ON runtime.webhook_delivery_attempts;
CREATE POLICY p_webhook_delivery_attempts_select
ON runtime.webhook_delivery_attempts
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_webhook_delivery_attempts_insert ON runtime.webhook_delivery_attempts;
CREATE POLICY p_webhook_delivery_attempts_insert
ON runtime.webhook_delivery_attempts
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_webhook_delivery_attempts_delete ON runtime.webhook_delivery_attempts;
CREATE POLICY p_webhook_delivery_attempts_delete
ON runtime.webhook_delivery_attempts
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
