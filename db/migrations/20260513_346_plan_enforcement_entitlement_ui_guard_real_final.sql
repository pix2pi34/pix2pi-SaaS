CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.plan_enforcement_ui_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  plan_code TEXT NOT NULL DEFAULT '',
  subscription_id TEXT NOT NULL DEFAULT '',
  invoice_id TEXT NOT NULL DEFAULT '',
  account_status TEXT NOT NULL,
  ui_guard_status TEXT NOT NULL,
  allowed_feature_count INTEGER NOT NULL DEFAULT 0,
  disabled_feature_count INTEGER NOT NULL DEFAULT 0,
  quota_exceeded_feature_count INTEGER NOT NULL DEFAULT 0,
  upgrade_required_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  context JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.plan_enforcement_ui_action_decisions (
  decision_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  plan_code TEXT NOT NULL DEFAULT '',
  subscription_id TEXT NOT NULL DEFAULT '',
  invoice_id TEXT NOT NULL DEFAULT '',
  feature_code TEXT NOT NULL,
  action_code TEXT NOT NULL,
  route_path TEXT NOT NULL DEFAULT '',
  ui_decision TEXT NOT NULL,
  reason_code TEXT NOT NULL,
  requested_amount NUMERIC(18,3) NOT NULL DEFAULT 0,
  used_amount NUMERIC(18,3) NOT NULL DEFAULT 0,
  limit_value NUMERIC(18,3) NOT NULL DEFAULT 0,
  upgrade_required BOOLEAN NOT NULL DEFAULT false,
  disabled_action BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS commercial_runtime.plan_enforcement_ui_audit_events (
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

CREATE INDEX IF NOT EXISTS idx_plan_enforcement_ui_snapshots_run
  ON commercial_runtime.plan_enforcement_ui_snapshots(run_id, tenant_id, ui_guard_status);

CREATE INDEX IF NOT EXISTS idx_plan_enforcement_ui_decisions_run
  ON commercial_runtime.plan_enforcement_ui_action_decisions(run_id, tenant_id, feature_code, ui_decision);

CREATE INDEX IF NOT EXISTS idx_plan_enforcement_ui_audit_run
  ON commercial_runtime.plan_enforcement_ui_audit_events(run_id, event_type, decision);
