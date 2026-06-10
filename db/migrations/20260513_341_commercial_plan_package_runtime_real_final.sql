CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.plan_packages (
  plan_code TEXT PRIMARY KEY,
  plan_name TEXT NOT NULL,
  plan_status TEXT NOT NULL DEFAULT 'active',
  billing_cycle TEXT NOT NULL DEFAULT 'monthly',
  currency TEXT NOT NULL DEFAULT 'TRY',
  base_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.plan_feature_matrix (
  plan_code TEXT NOT NULL,
  feature_code TEXT NOT NULL,
  feature_name TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT false,
  limit_kind TEXT NOT NULL DEFAULT 'none',
  limit_value NUMERIC(18,3) NOT NULL DEFAULT 0,
  enforcement_mode TEXT NOT NULL DEFAULT 'enforce',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(plan_code, feature_code)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.tenant_plan_assignments (
  assignment_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  plan_status TEXT NOT NULL DEFAULT 'active',
  assigned_by_user_id TEXT NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NULL,
  reason TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.tenant_quota_usage (
  usage_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  feature_code TEXT NOT NULL,
  period_key TEXT NOT NULL,
  used_amount NUMERIC(18,3) NOT NULL DEFAULT 0,
  limit_value NUMERIC(18,3) NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, feature_code, period_key)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.commercial_plan_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  plan_code TEXT NULL,
  assignment_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  feature_code TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_plan_assignments_tenant_status
  ON commercial_runtime.tenant_plan_assignments(tenant_id, plan_status, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_tenant_quota_usage_tenant_feature
  ON commercial_runtime.tenant_quota_usage(tenant_id, feature_code, period_key);

CREATE INDEX IF NOT EXISTS idx_commercial_plan_audit_run
  ON commercial_runtime.commercial_plan_audit_events(run_id, event_type, decision);
