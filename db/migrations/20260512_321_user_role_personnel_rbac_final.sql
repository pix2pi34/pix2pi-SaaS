CREATE SCHEMA IF NOT EXISTS tenant_identity;

CREATE TABLE IF NOT EXISTS tenant_identity.role_permissions (
  role_code TEXT NOT NULL,
  action_code TEXT NOT NULL,
  allowed BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (role_code, action_code)
);

CREATE TABLE IF NOT EXISTS tenant_identity.personnel_profiles (
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  personnel_type TEXT NOT NULL,
  status TEXT NOT NULL,
  display_name TEXT NOT NULL,
  updated_by_user_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE IF NOT EXISTS tenant_identity.rbac_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NULL,
  actor_user_id TEXT NULL,
  event_type TEXT NOT NULL,
  action_code TEXT NULL,
  role_code TEXT NULL,
  decision TEXT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO tenant_identity.role_permissions(role_code, action_code, allowed) VALUES
  ('owner', '*', true),
  ('manager', 'panel.users.invite', true),
  ('manager', 'panel.users.role_assign', true),
  ('manager', 'panel.products.write', true),
  ('manager', 'panel.reports.view', true),
  ('manager', 'pos.sale.read', true),
  ('manager', 'pos.sale.create', true),
  ('cashier', 'pos.sale.read', true),
  ('cashier', 'pos.sale.create', true),
  ('cashier', 'pos.cart.write', true),
  ('cashier', 'panel.products.read', true),
  ('accountant', 'finance.report.view', true),
  ('accountant', 'document.invoice.read', true),
  ('accountant', 'ledger.view', true),
  ('accountant', 'tax.report.view', true)
ON CONFLICT(role_code, action_code) DO UPDATE SET
  allowed = EXCLUDED.allowed;
