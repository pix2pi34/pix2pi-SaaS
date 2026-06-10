CREATE SCHEMA IF NOT EXISTS pos_pwa;

CREATE TABLE IF NOT EXISTS pos_pwa.pwa_runtime_checks (
  pwa_run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  manifest_status TEXT NOT NULL,
  service_worker_status TEXT NOT NULL,
  offline_shell_status TEXT NOT NULL,
  installability_status TEXT NOT NULL,
  mobile_responsive_status TEXT NOT NULL,
  icon_status TEXT NOT NULL,
  cache_version TEXT NOT NULL,
  cache_update_guard_status TEXT NOT NULL,
  route_smoke_status TEXT NOT NULL,
  db_written BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS pos_pwa.pwa_audit_events (
  event_id TEXT PRIMARY KEY,
  pwa_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  evidence_ref TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pwa_audit_run
  ON pos_pwa.pwa_audit_events(pwa_run_id, event_type, decision);
