CREATE SCHEMA IF NOT EXISTS customer_smoke;

CREATE TABLE IF NOT EXISTS customer_smoke.first_usage_smoke_runs (
  smoke_run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  status TEXT NOT NULL,
  party_id TEXT NULL,
  product_id TEXT NULL,
  sale_id TEXT NULL,
  dashboard_visible BOOLEAN NOT NULL DEFAULT false,
  report_generated BOOLEAN NOT NULL DEFAULT false,
  db_written BOOLEAN NOT NULL DEFAULT false,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS customer_smoke.first_usage_smoke_events (
  event_id TEXT PRIMARY KEY,
  smoke_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_code TEXT NOT NULL,
  event_status TEXT NOT NULL,
  evidence_ref TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_smoke.first_usage_dashboard_snapshots (
  snapshot_id TEXT PRIMARY KEY,
  smoke_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  metric_code TEXT NOT NULL,
  metric_value NUMERIC(18,2) NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_smoke.first_usage_report_snapshots (
  report_id TEXT PRIMARY KEY,
  smoke_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  report_code TEXT NOT NULL,
  report_status TEXT NOT NULL,
  row_count INTEGER NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_first_usage_smoke_events_run
  ON customer_smoke.first_usage_smoke_events(smoke_run_id, event_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_first_usage_dashboard_run
  ON customer_smoke.first_usage_dashboard_snapshots(smoke_run_id, metric_code);

CREATE INDEX IF NOT EXISTS idx_first_usage_report_run
  ON customer_smoke.first_usage_report_snapshots(smoke_run_id, report_code);
