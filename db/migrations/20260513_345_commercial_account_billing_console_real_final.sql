CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.commercial_account_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  plan_code TEXT NOT NULL DEFAULT '',
  subscription_id TEXT NOT NULL DEFAULT '',
  invoice_id TEXT NOT NULL DEFAULT '',
  account_status TEXT NOT NULL,
  plan_status TEXT NOT NULL DEFAULT '',
  subscription_status TEXT NOT NULL DEFAULT '',
  invoice_status TEXT NOT NULL DEFAULT '',
  entitlement_status TEXT NOT NULL DEFAULT '',
  billing_total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  feature_count INTEGER NOT NULL DEFAULT 0,
  quota_used_count INTEGER NOT NULL DEFAULT 0,
  deny_decision_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.commercial_account_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_commercial_account_snapshots_run
  ON commercial_runtime.commercial_account_snapshots(run_id, tenant_id, account_status);

CREATE INDEX IF NOT EXISTS idx_commercial_account_audit_run
  ON commercial_runtime.commercial_account_audit_events(run_id, event_type, decision);
