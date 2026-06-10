BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

CREATE OR REPLACE FUNCTION platform.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS platform.api_keys (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  api_key_id TEXT NOT NULL,
  app_id TEXT,
  key_name TEXT NOT NULL,
  key_prefix TEXT NOT NULL,
  key_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  scopes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  allowed_ips CIDR[] NOT NULL DEFAULT ARRAY[]::CIDR[],
  rate_limit_policy_id TEXT,
  quota_policy_id TEXT,
  environment TEXT NOT NULL DEFAULT 'PRODUCTION',
  created_by TEXT NOT NULL,
  revoked_by TEXT,
  rotation_parent_api_key_id TEXT,
  correlation_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  activated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  CONSTRAINT api_keys_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT api_keys_api_key_id_chk CHECK (length(trim(api_key_id)) > 0),
  CONSTRAINT api_keys_key_name_chk CHECK (length(trim(key_name)) > 0),
  CONSTRAINT api_keys_key_prefix_chk CHECK (length(trim(key_prefix)) > 0),
  CONSTRAINT api_keys_key_hash_chk CHECK (length(trim(key_hash)) > 0),
  CONSTRAINT api_keys_status_chk CHECK (
    status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED', 'ROTATED')
  ),
  CONSTRAINT api_keys_environment_chk CHECK (
    environment IN ('DEVELOPMENT', 'STAGING', 'SANDBOX', 'PRODUCTION')
  ),
  CONSTRAINT api_keys_tenant_key_uq UNIQUE (tenant_id, api_key_id)
);

CREATE TABLE IF NOT EXISTS platform.api_quota_policies (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  quota_policy_id TEXT NOT NULL,
  policy_name TEXT NOT NULL,
  subject_type TEXT NOT NULL,
  subject_ref TEXT NOT NULL,
  quota_scope TEXT NOT NULL DEFAULT 'API',
  window_type TEXT NOT NULL DEFAULT 'MONTH',
  max_requests BIGINT NOT NULL DEFAULT 0,
  max_units BIGINT NOT NULL DEFAULT 0,
  burst_limit BIGINT NOT NULL DEFAULT 0,
  reset_policy TEXT NOT NULL DEFAULT 'FIXED_WINDOW',
  overage_policy TEXT NOT NULL DEFAULT 'DENY',
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT api_quota_policies_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT api_quota_policies_id_chk CHECK (length(trim(quota_policy_id)) > 0),
  CONSTRAINT api_quota_policies_name_chk CHECK (length(trim(policy_name)) > 0),
  CONSTRAINT api_quota_policies_subject_type_chk CHECK (
    subject_type IN ('TENANT', 'APP', 'API_KEY', 'USER', 'INTEGRATION')
  ),
  CONSTRAINT api_quota_policies_window_type_chk CHECK (
    window_type IN ('MINUTE', 'HOUR', 'DAY', 'MONTH')
  ),
  CONSTRAINT api_quota_policies_reset_policy_chk CHECK (
    reset_policy IN ('FIXED_WINDOW', 'ROLLING_WINDOW', 'CALENDAR_MONTH')
  ),
  CONSTRAINT api_quota_policies_overage_policy_chk CHECK (
    overage_policy IN ('DENY', 'ALLOW_WITH_AUDIT', 'THROTTLE')
  ),
  CONSTRAINT api_quota_policies_status_chk CHECK (
    status IN ('ACTIVE', 'SUSPENDED', 'ARCHIVED')
  ),
  CONSTRAINT api_quota_policies_request_chk CHECK (max_requests >= 0),
  CONSTRAINT api_quota_policies_units_chk CHECK (max_units >= 0),
  CONSTRAINT api_quota_policies_burst_chk CHECK (burst_limit >= 0),
  CONSTRAINT api_quota_policies_tenant_policy_uq UNIQUE (tenant_id, quota_policy_id)
);

CREATE TABLE IF NOT EXISTS platform.app_auth_relations (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  app_auth_relation_id TEXT NOT NULL,
  app_id TEXT NOT NULL,
  app_name TEXT NOT NULL,
  api_key_id BIGINT REFERENCES platform.api_keys(id) ON DELETE SET NULL,
  auth_type TEXT NOT NULL DEFAULT 'API_KEY',
  auth_subject_type TEXT NOT NULL DEFAULT 'APP',
  auth_subject_ref TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  allowed_scopes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  allowed_routes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  environment TEXT NOT NULL DEFAULT 'PRODUCTION',
  created_by TEXT NOT NULL DEFAULT 'system',
  revoked_by TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  activated_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  last_auth_at TIMESTAMPTZ,
  CONSTRAINT app_auth_relations_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT app_auth_relations_id_chk CHECK (length(trim(app_auth_relation_id)) > 0),
  CONSTRAINT app_auth_relations_app_id_chk CHECK (length(trim(app_id)) > 0),
  CONSTRAINT app_auth_relations_app_name_chk CHECK (length(trim(app_name)) > 0),
  CONSTRAINT app_auth_relations_auth_type_chk CHECK (
    auth_type IN ('API_KEY', 'OAUTH_CLIENT', 'SERVICE_ACCOUNT', 'WEBHOOK_SECRET')
  ),
  CONSTRAINT app_auth_relations_subject_type_chk CHECK (
    auth_subject_type IN ('APP', 'INTEGRATION', 'SERVICE', 'USER')
  ),
  CONSTRAINT app_auth_relations_status_chk CHECK (
    status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED')
  ),
  CONSTRAINT app_auth_relations_environment_chk CHECK (
    environment IN ('DEVELOPMENT', 'STAGING', 'SANDBOX', 'PRODUCTION')
  ),
  CONSTRAINT app_auth_relations_tenant_relation_uq UNIQUE (tenant_id, app_auth_relation_id),
  CONSTRAINT app_auth_relations_tenant_app_subject_uq UNIQUE (tenant_id, app_id, auth_subject_type, auth_subject_ref)
);

CREATE TABLE IF NOT EXISTS platform.api_usage_meters (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  usage_meter_id TEXT NOT NULL,
  api_key_id BIGINT REFERENCES platform.api_keys(id) ON DELETE SET NULL,
  quota_policy_id BIGINT REFERENCES platform.api_quota_policies(id) ON DELETE SET NULL,
  app_auth_relation_id BIGINT REFERENCES platform.app_auth_relations(id) ON DELETE SET NULL,
  subject_type TEXT NOT NULL,
  subject_ref TEXT NOT NULL,
  usage_scope TEXT NOT NULL DEFAULT 'API',
  route_key TEXT NOT NULL,
  method TEXT NOT NULL,
  window_type TEXT NOT NULL DEFAULT 'DAY',
  window_start_at TIMESTAMPTZ NOT NULL,
  window_end_at TIMESTAMPTZ NOT NULL,
  request_count BIGINT NOT NULL DEFAULT 0,
  success_count BIGINT NOT NULL DEFAULT 0,
  failure_count BIGINT NOT NULL DEFAULT 0,
  unit_count BIGINT NOT NULL DEFAULT 0,
  last_request_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT api_usage_meters_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT api_usage_meters_id_chk CHECK (length(trim(usage_meter_id)) > 0),
  CONSTRAINT api_usage_meters_subject_type_chk CHECK (
    subject_type IN ('TENANT', 'APP', 'API_KEY', 'USER', 'INTEGRATION')
  ),
  CONSTRAINT api_usage_meters_method_chk CHECK (
    method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS')
  ),
  CONSTRAINT api_usage_meters_window_type_chk CHECK (
    window_type IN ('MINUTE', 'HOUR', 'DAY', 'MONTH')
  ),
  CONSTRAINT api_usage_meters_request_count_chk CHECK (request_count >= 0),
  CONSTRAINT api_usage_meters_success_count_chk CHECK (success_count >= 0),
  CONSTRAINT api_usage_meters_failure_count_chk CHECK (failure_count >= 0),
  CONSTRAINT api_usage_meters_unit_count_chk CHECK (unit_count >= 0),
  CONSTRAINT api_usage_meters_window_chk CHECK (window_end_at > window_start_at),
  CONSTRAINT api_usage_meters_tenant_meter_uq UNIQUE (tenant_id, usage_meter_id),
  CONSTRAINT api_usage_meters_window_uq UNIQUE (
    tenant_id,
    subject_type,
    subject_ref,
    usage_scope,
    route_key,
    method,
    window_type,
    window_start_at
  )
);

CREATE TABLE IF NOT EXISTS platform.api_usage_audit_events (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  usage_audit_event_id TEXT NOT NULL,
  api_key_id BIGINT REFERENCES platform.api_keys(id) ON DELETE SET NULL,
  quota_policy_id BIGINT REFERENCES platform.api_quota_policies(id) ON DELETE SET NULL,
  usage_meter_id BIGINT REFERENCES platform.api_usage_meters(id) ON DELETE SET NULL,
  app_auth_relation_id BIGINT REFERENCES platform.app_auth_relations(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  subject_type TEXT NOT NULL,
  subject_ref TEXT NOT NULL,
  route_key TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER,
  request_id TEXT,
  correlation_id TEXT,
  idempotency_key TEXT,
  remote_ip INET,
  user_agent TEXT,
  request_units BIGINT NOT NULL DEFAULT 1,
  audit_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT api_usage_audit_events_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT api_usage_audit_events_id_chk CHECK (length(trim(usage_audit_event_id)) > 0),
  CONSTRAINT api_usage_audit_events_event_type_chk CHECK (
    event_type IN (
      'API_KEY_CREATED',
      'API_KEY_USED',
      'API_KEY_REVOKED',
      'QUOTA_CHECKED',
      'QUOTA_ALLOWED',
      'QUOTA_DENIED',
      'USAGE_RECORDED',
      'APP_AUTH_GRANTED',
      'APP_AUTH_REVOKED'
    )
  ),
  CONSTRAINT api_usage_audit_events_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'THROTTLE', 'AUDIT_ONLY')
  ),
  CONSTRAINT api_usage_audit_events_subject_type_chk CHECK (
    subject_type IN ('TENANT', 'APP', 'API_KEY', 'USER', 'INTEGRATION')
  ),
  CONSTRAINT api_usage_audit_events_method_chk CHECK (
    method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS')
  ),
  CONSTRAINT api_usage_audit_events_status_code_chk CHECK (
    status_code IS NULL OR (status_code >= 100 AND status_code <= 599)
  ),
  CONSTRAINT api_usage_audit_events_units_chk CHECK (request_units > 0),
  CONSTRAINT api_usage_audit_events_tenant_event_uq UNIQUE (tenant_id, usage_audit_event_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_api_keys_tenant_key_prefix_active
  ON platform.api_keys (tenant_id, key_prefix)
  WHERE status IN ('ACTIVE', 'SUSPENDED');

CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_status
  ON platform.api_keys (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_app
  ON platform.api_keys (tenant_id, app_id);

CREATE INDEX IF NOT EXISTS idx_api_keys_prefix
  ON platform.api_keys (key_prefix);

CREATE INDEX IF NOT EXISTS idx_api_keys_expires_at
  ON platform.api_keys (expires_at)
  WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_keys_last_used_at
  ON platform.api_keys (last_used_at DESC)
  WHERE last_used_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_quota_policies_tenant_subject
  ON platform.api_quota_policies (tenant_id, subject_type, subject_ref, status);

CREATE INDEX IF NOT EXISTS idx_api_quota_policies_scope_window
  ON platform.api_quota_policies (tenant_id, quota_scope, window_type);

CREATE INDEX IF NOT EXISTS idx_api_quota_policies_status
  ON platform.api_quota_policies (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_api_quota_policies_ends_at
  ON platform.api_quota_policies (ends_at)
  WHERE ends_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_auth_relations_tenant_app
  ON platform.app_auth_relations (tenant_id, app_id, status);

CREATE INDEX IF NOT EXISTS idx_app_auth_relations_auth_subject
  ON platform.app_auth_relations (tenant_id, auth_subject_type, auth_subject_ref);

CREATE INDEX IF NOT EXISTS idx_app_auth_relations_api_key
  ON platform.app_auth_relations (tenant_id, api_key_id)
  WHERE api_key_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_auth_relations_last_auth_at
  ON platform.app_auth_relations (last_auth_at DESC)
  WHERE last_auth_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_meters_tenant_subject_window
  ON platform.api_usage_meters (tenant_id, subject_type, subject_ref, window_type, window_start_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_usage_meters_route_window
  ON platform.api_usage_meters (tenant_id, route_key, method, window_start_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_usage_meters_api_key_window
  ON platform.api_usage_meters (tenant_id, api_key_id, window_start_at DESC)
  WHERE api_key_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_meters_quota_policy_window
  ON platform.api_usage_meters (tenant_id, quota_policy_id, window_start_at DESC)
  WHERE quota_policy_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_meters_last_request
  ON platform.api_usage_meters (last_request_at DESC)
  WHERE last_request_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_tenant_created
  ON platform.api_usage_audit_events (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_route
  ON platform.api_usage_audit_events (tenant_id, route_key, method, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_decision
  ON platform.api_usage_audit_events (tenant_id, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_api_key
  ON platform.api_usage_audit_events (tenant_id, api_key_id, created_at DESC)
  WHERE api_key_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_correlation
  ON platform.api_usage_audit_events (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_api_usage_audit_events_request_id
  ON platform.api_usage_audit_events (tenant_id, request_id)
  WHERE request_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_api_keys_updated_at ON platform.api_keys;
CREATE TRIGGER trg_api_keys_updated_at
BEFORE UPDATE ON platform.api_keys
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_api_quota_policies_updated_at ON platform.api_quota_policies;
CREATE TRIGGER trg_api_quota_policies_updated_at
BEFORE UPDATE ON platform.api_quota_policies
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_app_auth_relations_updated_at ON platform.app_auth_relations;
CREATE TRIGGER trg_app_auth_relations_updated_at
BEFORE UPDATE ON platform.app_auth_relations
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_api_usage_meters_updated_at ON platform.api_usage_meters;
CREATE TRIGGER trg_api_usage_meters_updated_at
BEFORE UPDATE ON platform.api_usage_meters
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.api_quota_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.app_auth_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.api_usage_meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.api_usage_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.api_keys FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.api_quota_policies FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.app_auth_relations FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.api_usage_meters FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.api_usage_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS api_keys_tenant_isolation ON platform.api_keys;
CREATE POLICY api_keys_tenant_isolation
ON platform.api_keys
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS api_quota_policies_tenant_isolation ON platform.api_quota_policies;
CREATE POLICY api_quota_policies_tenant_isolation
ON platform.api_quota_policies
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS app_auth_relations_tenant_isolation ON platform.app_auth_relations;
CREATE POLICY app_auth_relations_tenant_isolation
ON platform.app_auth_relations
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS api_usage_meters_tenant_isolation ON platform.api_usage_meters;
CREATE POLICY api_usage_meters_tenant_isolation
ON platform.api_usage_meters
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS api_usage_audit_events_tenant_isolation ON platform.api_usage_audit_events;
CREATE POLICY api_usage_audit_events_tenant_isolation
ON platform.api_usage_audit_events
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

COMMENT ON TABLE platform.api_keys IS 'FAZ 2-6.8 API key persistence table. Raw secret is never stored; only key_hash and key_prefix are stored.';
COMMENT ON TABLE platform.api_quota_policies IS 'FAZ 2-6.8 quota policy persistence table for tenant/app/api-key/user/integration usage limits.';
COMMENT ON TABLE platform.app_auth_relations IS 'FAZ 2-6.8 app authorization relation persistence table.';
COMMENT ON TABLE platform.api_usage_meters IS 'FAZ 2-6.8 aggregated usage meter persistence table.';
COMMENT ON TABLE platform.api_usage_audit_events IS 'FAZ 2-6.8 immutable API usage/quota/auth audit event table.';

COMMIT;
