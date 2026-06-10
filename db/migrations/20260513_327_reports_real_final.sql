CREATE SCHEMA IF NOT EXISTS merchant_reports;

CREATE TABLE IF NOT EXISTS merchant_reports.report_runs (
  report_run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  status TEXT NOT NULL,
  source_scope TEXT NOT NULL,
  daily_sales_generated BOOLEAN NOT NULL DEFAULT false,
  product_sales_generated BOOLEAN NOT NULL DEFAULT false,
  stock_generated BOOLEAN NOT NULL DEFAULT false,
  party_balance_generated BOOLEAN NOT NULL DEFAULT false,
  vat_generated BOOLEAN NOT NULL DEFAULT false,
  marketplace_generated BOOLEAN NOT NULL DEFAULT false,
  subscription_usage_generated BOOLEAN NOT NULL DEFAULT false,
  db_written BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS merchant_reports.report_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  report_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  report_code TEXT NOT NULL,
  report_status TEXT NOT NULL,
  row_count INTEGER NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  metric_text TEXT NOT NULL DEFAULT '',
  source_table TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_reports.report_rows (
  row_id TEXT PRIMARY KEY,
  report_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  report_code TEXT NOT NULL,
  item_key TEXT NOT NULL,
  item_label TEXT NOT NULL DEFAULT '',
  quantity NUMERIC(18,3) NOT NULL DEFAULT 0,
  amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_reports.report_audit_events (
  event_id TEXT PRIMARY KEY,
  report_run_id TEXT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_merchant_reports_snapshots_run
  ON merchant_reports.report_snapshots(report_run_id, report_code);

CREATE INDEX IF NOT EXISTS idx_merchant_reports_rows_run
  ON merchant_reports.report_rows(report_run_id, report_code, item_key);

CREATE INDEX IF NOT EXISTS idx_merchant_reports_audit_tenant
  ON merchant_reports.report_audit_events(tenant_id, event_type, decision, created_at DESC);
