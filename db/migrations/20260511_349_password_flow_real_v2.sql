-- FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı gerçek V2
-- Non-destructive migration.

CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.user_password_credentials (
  user_id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  password_version INT NOT NULL DEFAULT 1,
  password_changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  must_change_password BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.password_reset_tokens (
  token_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ NULL,
  requested_ip TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.login_sessions_349 (
  session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,
  access_token_hash TEXT NOT NULL UNIQUE,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS auth.password_flow_audit_events (
  event_id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  user_id UUID NULL,
  event_type TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user ON auth.password_reset_tokens(user_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_login_sessions_349_user ON auth.login_sessions_349(user_id, tenant_id);
CREATE INDEX IF NOT EXISTS idx_password_flow_audit_events_tenant ON auth.password_flow_audit_events(tenant_id, created_at DESC);
