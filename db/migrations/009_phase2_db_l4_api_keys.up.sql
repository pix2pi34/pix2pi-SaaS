BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'api_key_status_enum'
  ) THEN
    CREATE TYPE runtime.api_key_status_enum AS ENUM (
      'active',
      'revoked',
      'expired',
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
    WHERE n.nspname = 'runtime' AND t.typname = 'quota_period_enum'
  ) THEN
    CREATE TYPE runtime.quota_period_enum AS ENUM (
      'minute',
      'hour',
      'day',
      'month'
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

CREATE TABLE IF NOT EXISTS runtime.api_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  key_ref text NOT NULL,
  display_name text NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  key_prefix text NOT NULL,
  key_hash text NOT NULL,
  status runtime.api_key_status_enum NOT NULL DEFAULT 'active',
  scope_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_used_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (key_ref ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (display_name <> ''),
  CHECK (key_prefix <> ''),
  CHECK (key_hash <> ''),
  CHECK (expires_at IS NULL OR expires_at >= created_at),
  CHECK (revoked_at IS NULL OR revoked_at >= created_at),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_api_keys_tenant_key_ref
ON runtime.api_keys (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  key_ref
);

CREATE INDEX IF NOT EXISTS ix_api_keys_tenant_id
ON runtime.api_keys (tenant_id);

CREATE INDEX IF NOT EXISTS ix_api_keys_status
ON runtime.api_keys (status);

CREATE INDEX IF NOT EXISTS ix_api_keys_expires_at
ON runtime.api_keys (expires_at);

CREATE TABLE IF NOT EXISTS runtime.api_quota_policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  api_key_id uuid NOT NULL REFERENCES runtime.api_keys(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  policy_key text NOT NULL,
  endpoint_scope text NOT NULL DEFAULT '*',
  quota_period runtime.quota_period_enum NOT NULL,
  request_limit integer NOT NULL,
  burst_limit integer,
  is_enabled boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (policy_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (endpoint_scope <> ''),
  CHECK (request_limit BETWEEN 1 AND 100000000),
  CHECK (burst_limit IS NULL OR burst_limit BETWEEN 1 AND 100000000)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_api_quota_policies_api_key_policy_key
ON runtime.api_quota_policies (api_key_id, policy_key);

CREATE INDEX IF NOT EXISTS ix_api_quota_policies_tenant_id
ON runtime.api_quota_policies (tenant_id);

CREATE INDEX IF NOT EXISTS ix_api_quota_policies_api_key_id
ON runtime.api_quota_policies (api_key_id);

CREATE INDEX IF NOT EXISTS ix_api_quota_policies_enabled
ON runtime.api_quota_policies (is_enabled);

CREATE TABLE IF NOT EXISTS runtime.api_key_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  api_key_id uuid NOT NULL REFERENCES runtime.api_keys(id) ON DELETE CASCADE,
  policy_id uuid REFERENCES runtime.api_quota_policies(id) ON DELETE SET NULL,
  business_code text NOT NULL,
  usage_window_start timestamptz NOT NULL,
  usage_window_end timestamptz NOT NULL,
  request_count bigint NOT NULL DEFAULT 0,
  rejected_count bigint NOT NULL DEFAULT 0,
  last_request_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (usage_window_end > usage_window_start),
  CHECK (request_count >= 0),
  CHECK (rejected_count >= 0),
  CHECK (last_request_at IS NULL OR last_request_at >= usage_window_start)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_api_key_usage_api_key_window
ON runtime.api_key_usage (api_key_id, usage_window_start, usage_window_end);

CREATE INDEX IF NOT EXISTS ix_api_key_usage_tenant_id
ON runtime.api_key_usage (tenant_id);

CREATE INDEX IF NOT EXISTS ix_api_key_usage_api_key_id
ON runtime.api_key_usage (api_key_id);

CREATE INDEX IF NOT EXISTS ix_api_key_usage_policy_id
ON runtime.api_key_usage (policy_id);

CREATE INDEX IF NOT EXISTS ix_api_key_usage_window
ON runtime.api_key_usage (usage_window_start, usage_window_end);

CREATE OR REPLACE FUNCTION runtime.validate_api_quota_policy_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_key_tenant_id uuid;
  v_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT k.tenant_id, k.visibility_scope
    INTO v_key_tenant_id, v_visibility_scope
  FROM runtime.api_keys k
  WHERE k.id = NEW.api_key_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'api key not found: %', NEW.api_key_id;
  END IF;

  IF v_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global api quota policy must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant api quota policy must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_key_tenant_id THEN
      RAISE EXCEPTION 'api quota policy tenant_id must match api_key tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_api_key_usage_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_key_tenant_id uuid;
  v_policy_tenant_id uuid;
  v_policy_api_key_id uuid;
BEGIN
  SELECT k.tenant_id
    INTO v_key_tenant_id
  FROM runtime.api_keys k
  WHERE k.id = NEW.api_key_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'api key not found: %', NEW.api_key_id;
  END IF;

  IF NEW.policy_id IS NOT NULL THEN
    SELECT p.tenant_id, p.api_key_id
      INTO v_policy_tenant_id, v_policy_api_key_id
    FROM runtime.api_quota_policies p
    WHERE p.id = NEW.policy_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'api quota policy not found: %', NEW.policy_id;
    END IF;

    IF v_policy_api_key_id <> NEW.api_key_id THEN
      RAISE EXCEPTION 'api key usage policy_id must belong to api_key_id';
    END IF;
  ELSE
    v_policy_tenant_id := v_key_tenant_id;
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_key_tenant_id THEN
    RAISE EXCEPTION 'api key usage tenant_id must match api_key tenant_id';
  END IF;

  IF NEW.policy_id IS NOT NULL AND NEW.tenant_id IS DISTINCT FROM v_policy_tenant_id THEN
    RAISE EXCEPTION 'api key usage tenant_id must match policy tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_api_keys_touch_updated_at
ON runtime.api_keys;

CREATE TRIGGER trg_api_keys_touch_updated_at
BEFORE UPDATE ON runtime.api_keys
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_api_quota_policies_touch_updated_at
ON runtime.api_quota_policies;

CREATE TRIGGER trg_api_quota_policies_touch_updated_at
BEFORE UPDATE ON runtime.api_quota_policies
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_api_key_usage_touch_updated_at
ON runtime.api_key_usage;

CREATE TRIGGER trg_api_key_usage_touch_updated_at
BEFORE UPDATE ON runtime.api_key_usage
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_api_quota_policies_validate_scope
ON runtime.api_quota_policies;

CREATE TRIGGER trg_api_quota_policies_validate_scope
BEFORE INSERT OR UPDATE ON runtime.api_quota_policies
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_api_quota_policy_scope();

DROP TRIGGER IF EXISTS trg_api_key_usage_validate_scope
ON runtime.api_key_usage;

CREATE TRIGGER trg_api_key_usage_validate_scope
BEFORE INSERT OR UPDATE ON runtime.api_key_usage
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_api_key_usage_scope();

ALTER TABLE runtime.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.api_keys FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.api_quota_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.api_quota_policies FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.api_key_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.api_key_usage FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_api_keys_select ON runtime.api_keys;
CREATE POLICY p_api_keys_select
ON runtime.api_keys
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_api_keys_insert ON runtime.api_keys;
CREATE POLICY p_api_keys_insert
ON runtime.api_keys
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_keys_update ON runtime.api_keys;
CREATE POLICY p_api_keys_update
ON runtime.api_keys
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_keys_delete ON runtime.api_keys;
CREATE POLICY p_api_keys_delete
ON runtime.api_keys
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_quota_policies_select ON runtime.api_quota_policies;
CREATE POLICY p_api_quota_policies_select
ON runtime.api_quota_policies
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_api_quota_policies_insert ON runtime.api_quota_policies;
CREATE POLICY p_api_quota_policies_insert
ON runtime.api_quota_policies
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_quota_policies_update ON runtime.api_quota_policies;
CREATE POLICY p_api_quota_policies_update
ON runtime.api_quota_policies
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_quota_policies_delete ON runtime.api_quota_policies;
CREATE POLICY p_api_quota_policies_delete
ON runtime.api_quota_policies
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_key_usage_select ON runtime.api_key_usage;
CREATE POLICY p_api_key_usage_select
ON runtime.api_key_usage
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_api_key_usage_insert ON runtime.api_key_usage;
CREATE POLICY p_api_key_usage_insert
ON runtime.api_key_usage
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_key_usage_update ON runtime.api_key_usage;
CREATE POLICY p_api_key_usage_update
ON runtime.api_key_usage
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_api_key_usage_delete ON runtime.api_key_usage;
CREATE POLICY p_api_key_usage_delete
ON runtime.api_key_usage
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
