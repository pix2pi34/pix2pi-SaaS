CREATE SCHEMA IF NOT EXISTS tenant_identity;

CREATE TABLE IF NOT EXISTS tenant_identity.permission_check_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  actor_user_id TEXT NULL,
  action_code TEXT NOT NULL,
  decision TEXT NOT NULL,
  reason TEXT NOT NULL,
  roles JSONB NOT NULL DEFAULT '[]'::jsonb,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_identity.protected_action_events (
  action_event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  actor_user_id TEXT NULL,
  action_code TEXT NOT NULL,
  status TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_permission_check_audit_tenant
  ON tenant_identity.permission_check_audit_events(tenant_id, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_protected_action_events_tenant
  ON tenant_identity.protected_action_events(tenant_id, action_code, created_at DESC);

INSERT INTO tenant_identity.role_permissions(role_code, action_code, allowed) VALUES
  ('owner', '*', true),

  ('manager', 'panel.dashboard.view', true),
  ('manager', 'panel.users.invite', true),
  ('manager', 'panel.users.role_assign', true),
  ('manager', 'panel.products.read', true),
  ('manager', 'panel.products.write', true),
  ('manager', 'panel.reports.view', true),
  ('manager', 'pos.access', true),
  ('manager', 'pos.sale.read', true),
  ('manager', 'pos.sale.create', true),
  ('manager', 'pos.cart.write', true),
  ('manager', 'pos.payment.collect', true),

  ('cashier', 'panel.dashboard.view', true),
  ('cashier', 'panel.products.read', true),
  ('cashier', 'pos.access', true),
  ('cashier', 'pos.sale.read', true),
  ('cashier', 'pos.sale.create', true),
  ('cashier', 'pos.cart.write', true),
  ('cashier', 'pos.payment.collect', true),

  ('accountant', 'panel.dashboard.view', true),
  ('accountant', 'finance.report.view', true),
  ('accountant', 'ledger.view', true),
  ('accountant', 'tax.report.view', true),
  ('accountant', 'document.invoice.read', true)
ON CONFLICT(role_code, action_code) DO UPDATE SET allowed = EXCLUDED.allowed;
