CREATE SCHEMA IF NOT EXISTS tenant_security;

CREATE TABLE IF NOT EXISTS tenant_security.tenant_isolation_records (
  record_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  record_key TEXT NOT NULL,
  record_value TEXT NOT NULL,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, record_key)
);

CREATE TABLE IF NOT EXISTS tenant_security.tenant_isolation_audit_events (
  event_id TEXT PRIMARY KEY,
  actor_tenant_id TEXT NOT NULL,
  target_tenant_id TEXT NOT NULL,
  actor_user_id TEXT NULL,
  event_type TEXT NOT NULL,
  action_code TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_isolation_records_tenant
  ON tenant_security.tenant_isolation_records(tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tenant_isolation_audit_actor_target
  ON tenant_security.tenant_isolation_audit_events(actor_tenant_id, target_tenant_id, decision, created_at DESC);
