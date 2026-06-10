CREATE SCHEMA IF NOT EXISTS tenant_identity;

CREATE TABLE IF NOT EXISTS tenant_identity.tenant_users (
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NULL,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL,
  activated_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_users_tenant_email_lower
  ON tenant_identity.tenant_users(tenant_id, lower(email));

CREATE TABLE IF NOT EXISTS tenant_identity.tenant_user_invites (
  invite_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NULL,
  display_name TEXT NOT NULL,
  role_code TEXT NOT NULL,
  invited_by_user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_by_user_id TEXT NULL,
  accepted_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_user_invites_pending_email
  ON tenant_identity.tenant_user_invites(tenant_id, lower(email))
  WHERE status = 'pending';

CREATE TABLE IF NOT EXISTS tenant_identity.invite_mail_deliveries (
  delivery_id TEXT PRIMARY KEY,
  invite_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  email TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  smtp_status TEXT NOT NULL,
  smtp_response TEXT NULL,
  sent_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_identity.invite_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  invite_id TEXT NULL,
  user_id TEXT NULL,
  event_type TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
