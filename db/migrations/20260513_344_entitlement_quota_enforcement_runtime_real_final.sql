CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.entitlement_runtime_decisions (
  decision_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  plan_code TEXT NOT NULL DEFAULT '',
  subscription_id TEXT NOT NULL DEFAULT '',
  invoice_id TEXT NOT NULL DEFAULT '',
  feature_code TEXT NOT NULL,
  decision TEXT NOT NULL,
  reason_code TEXT NOT NULL,
  period_key TEXT NOT NULL DEFAULT '',
  used_amount NUMERIC(18,3) NOT NULL DEFAULT 0,
  requested_amount NUMERIC(18,3) NOT NULL DEFAULT 0,
  limit_value NUMERIC(18,3) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.entitlement_usage_ledger (
  ledger_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  feature_code TEXT NOT NULL,
  period_key TEXT NOT NULL,
  amount NUMERIC(18,3) NOT NULL,
  usage_status TEXT NOT NULL DEFAULT 'reserved',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.entitlement_runtime_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  feature_code TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_entitlement_runtime_decisions_run
  ON commercial_runtime.entitlement_runtime_decisions(run_id, tenant_id, feature_code, decision);

CREATE INDEX IF NOT EXISTS idx_entitlement_usage_ledger_run
  ON commercial_runtime.entitlement_usage_ledger(run_id, tenant_id, feature_code, period_key);

CREATE INDEX IF NOT EXISTS idx_entitlement_runtime_audit_run
  ON commercial_runtime.entitlement_runtime_audit_events(run_id, event_type, decision);
