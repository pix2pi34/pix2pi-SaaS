CREATE SCHEMA IF NOT EXISTS merchant_dashboard;

CREATE TABLE IF NOT EXISTS merchant_dashboard.dashboard_runs (
  dashboard_run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  status TEXT NOT NULL,
  source_scope TEXT NOT NULL,
  daily_sales_visible BOOLEAN NOT NULL DEFAULT false,
  stock_alert_visible BOOLEAN NOT NULL DEFAULT false,
  order_summary_visible BOOLEAN NOT NULL DEFAULT false,
  party_balance_visible BOOLEAN NOT NULL DEFAULT false,
  collection_visible BOOLEAN NOT NULL DEFAULT false,
  marketplace_status_visible BOOLEAN NOT NULL DEFAULT false,
  subscription_status_visible BOOLEAN NOT NULL DEFAULT false,
  quick_actions_visible BOOLEAN NOT NULL DEFAULT false,
  db_written BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS merchant_dashboard.dashboard_metric_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  dashboard_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  metric_code TEXT NOT NULL,
  metric_value NUMERIC(18,2) NOT NULL DEFAULT 0,
  metric_text TEXT NOT NULL DEFAULT '',
  source_table TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_dashboard.dashboard_quick_actions (
  action_id TEXT PRIMARY KEY,
  dashboard_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  action_code TEXT NOT NULL,
  route_path TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_dashboard.dashboard_audit_events (
  event_id TEXT PRIMARY KEY,
  dashboard_run_id TEXT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_merchant_dashboard_metrics_run
  ON merchant_dashboard.dashboard_metric_snapshots(dashboard_run_id, metric_code);

CREATE INDEX IF NOT EXISTS idx_merchant_dashboard_actions_run
  ON merchant_dashboard.dashboard_quick_actions(dashboard_run_id, action_code);

CREATE INDEX IF NOT EXISTS idx_merchant_dashboard_audit_tenant
  ON merchant_dashboard.dashboard_audit_events(tenant_id, event_type, decision, created_at DESC);
