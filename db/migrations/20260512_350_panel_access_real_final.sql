CREATE SCHEMA IF NOT EXISTS tenant_identity;

CREATE TABLE IF NOT EXISTS tenant_identity.panel_access_sessions (
  session_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  status TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  last_validated_at TIMESTAMPTZ NULL,
  revoked_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_identity.panel_access_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NULL,
  session_id TEXT NULL,
  event_type TEXT NOT NULL,
  route_path TEXT NULL,
  action_code TEXT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_panel_access_sessions_tenant_user
  ON tenant_identity.panel_access_sessions(tenant_id, user_id, status);

CREATE INDEX IF NOT EXISTS idx_panel_access_audit_tenant
  ON tenant_identity.panel_access_audit_events(tenant_id, created_at DESC);

INSERT INTO tenant_identity.role_permissions(role_code, action_code, allowed) VALUES
  ('owner', '*', true),
  ('manager', 'panel.dashboard.view', true),
  ('manager', 'panel.users.invite', true),
  ('manager', 'panel.users.role_assign', true),
  ('manager', 'panel.products.read', true),
  ('manager', 'panel.products.write', true),
  ('manager', 'panel.reports.view', true),
  ('cashier', 'panel.dashboard.view', true),
  ('cashier', 'panel.products.read', true),
  ('cashier', 'pos.sale.create', true),
  ('cashier', 'pos.sale.read', true),
  ('accountant', 'panel.dashboard.view', true),
  ('accountant', 'finance.report.view', true),
  ('accountant', 'document.invoice.read', true),
  ('accountant', 'ledger.view', true)
ON CONFLICT(role_code, action_code) DO UPDATE SET allowed = EXCLUDED.allowed;
