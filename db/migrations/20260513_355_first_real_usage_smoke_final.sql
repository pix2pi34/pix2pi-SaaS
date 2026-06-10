CREATE SCHEMA IF NOT EXISTS customer_smoke;

CREATE TABLE IF NOT EXISTS customer_smoke.smoke_runs (
  smoke_run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  smoke_name TEXT NOT NULL,
  status TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS customer_smoke.smoke_events (
  event_id TEXT PRIMARY KEY,
  smoke_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  status TEXT NOT NULL,
  http_status INTEGER NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_smoke_events_run
  ON customer_smoke.smoke_events(smoke_run_id, created_at DESC);
