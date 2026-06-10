CREATE SCHEMA IF NOT EXISTS pos_runtime;

CREATE TABLE IF NOT EXISTS pos_runtime.pos_access_sessions (
  session_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  store_id TEXT NOT NULL,
  register_id TEXT NOT NULL,
  status TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  last_validated_at TIMESTAMPTZ NULL,
  revoked_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_runtime.pos_access_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NULL,
  session_id TEXT NULL,
  store_id TEXT NULL,
  register_id TEXT NULL,
  event_type TEXT NOT NULL,
  route_path TEXT NULL,
  action_code TEXT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_access_sessions_tenant_user
  ON pos_runtime.pos_access_sessions(tenant_id, user_id, status);

CREATE INDEX IF NOT EXISTS idx_pos_access_sessions_register
  ON pos_runtime.pos_access_sessions(tenant_id, store_id, register_id, status);

CREATE INDEX IF NOT EXISTS idx_pos_access_audit_tenant
  ON pos_runtime.pos_access_audit_events(tenant_id, created_at DESC);

INSERT INTO tenant_identity.role_permissions(role_code, action_code, allowed) VALUES
  ('owner', '*', true),
  ('manager', 'pos.access', true),
  ('manager', 'pos.sale.read', true),
  ('manager', 'pos.sale.create', true),
  ('manager', 'pos.cart.write', true),
  ('manager', 'pos.payment.collect', true),
  ('manager', 'pos.refund.create', true),
  ('cashier', 'pos.access', true),
  ('cashier', 'pos.sale.read', true),
  ('cashier', 'pos.sale.create', true),
  ('cashier', 'pos.cart.write', true),
  ('cashier', 'pos.payment.collect', true),
  ('accountant', 'pos.sale.read', true),
  ('accountant', 'finance.report.view', true),
  ('accountant', 'document.invoice.read', true)
ON CONFLICT(role_code, action_code) DO UPDATE SET allowed = EXCLUDED.allowed;
