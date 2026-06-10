CREATE SCHEMA IF NOT EXISTS product_support;

CREATE TABLE IF NOT EXISTS product_support.help_center_documents (
  doc_id TEXT PRIMARY KEY,
  doc_code TEXT NOT NULL UNIQUE,
  title_i18n_key TEXT NOT NULL,
  body_i18n_key TEXT NOT NULL,
  route_path TEXT NOT NULL UNIQUE,
  locale_scope TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_support.help_center_smoke_runs (
  smoke_run_id TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  document_count INTEGER NOT NULL,
  http_200_count INTEGER NOT NULL,
  i18n_key_count INTEGER NOT NULL,
  db_written BOOLEAN NOT NULL DEFAULT false,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS product_support.help_center_smoke_events (
  event_id TEXT PRIMARY KEY,
  smoke_run_id TEXT NOT NULL,
  doc_code TEXT NOT NULL,
  route_path TEXT NOT NULL,
  http_status INTEGER NOT NULL,
  i18n_status TEXT NOT NULL,
  event_status TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_help_center_smoke_events_run
  ON product_support.help_center_smoke_events(smoke_run_id, event_status, created_at DESC);
