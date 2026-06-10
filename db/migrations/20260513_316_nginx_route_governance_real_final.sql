CREATE SCHEMA IF NOT EXISTS edge_governance;

CREATE TABLE IF NOT EXISTS edge_governance.nginx_route_audit_runs (
  run_id TEXT PRIMARY KEY,
  nginx_test_status TEXT NOT NULL,
  duplicate_server_name_status TEXT NOT NULL,
  snippet_include_status TEXT NOT NULL,
  exact_location_status TEXT NOT NULL,
  panel_route_status TEXT NOT NULL,
  pos_route_status TEXT NOT NULL,
  static_route_status TEXT NOT NULL,
  api_route_status TEXT NOT NULL,
  reload_status TEXT NOT NULL,
  db_written BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS edge_governance.nginx_route_map_entries (
  entry_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  domain_name TEXT NOT NULL,
  route_path TEXT NOT NULL,
  route_type TEXT NOT NULL,
  expected_status TEXT NOT NULL,
  actual_status TEXT NOT NULL,
  decision TEXT NOT NULL,
  evidence_ref TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS edge_governance.nginx_route_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  evidence_ref TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_nginx_route_map_run
  ON edge_governance.nginx_route_map_entries(run_id, domain_name, route_path);

CREATE INDEX IF NOT EXISTS idx_nginx_route_audit_events_run
  ON edge_governance.nginx_route_audit_events(run_id, event_type, decision);
