CREATE SCHEMA IF NOT EXISTS pos_checkout;

CREATE TABLE IF NOT EXISTS pos_checkout.checkout_product_snapshots (
  product_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  product_name TEXT NOT NULL,
  unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 20,
  stock_available NUMERIC(18,3) NOT NULL DEFAULT 0,
  product_status TEXT NOT NULL DEFAULT 'active',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_checkout.pos_carts (
  cart_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  store_id TEXT NOT NULL,
  register_id TEXT NOT NULL,
  cashier_user_id TEXT NOT NULL,
  cart_status TEXT NOT NULL DEFAULT 'open',
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_checkout.pos_cart_items (
  cart_item_id TEXT PRIMARY KEY,
  cart_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  product_name TEXT NOT NULL,
  quantity NUMERIC(18,3) NOT NULL,
  unit_price NUMERIC(18,2) NOT NULL,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 20,
  line_subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_vat NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_checkout.pos_checkout_payments (
  payment_id TEXT PRIMARY KEY,
  cart_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  payment_status TEXT NOT NULL DEFAULT 'pending',
  currency TEXT NOT NULL DEFAULT 'TRY',
  amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  provider_placeholder_ref TEXT NOT NULL DEFAULT '',
  idempotency_key TEXT NOT NULL,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ NULL,
  failed_at TIMESTAMPTZ NULL,
  failure_reason TEXT NOT NULL DEFAULT '',
  UNIQUE(tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS pos_checkout.pos_checkout_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  cart_id TEXT NULL,
  payment_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_carts_tenant_status
  ON pos_checkout.pos_carts(tenant_id, cart_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_pos_cart_items_cart
  ON pos_checkout.pos_cart_items(tenant_id, cart_id);

CREATE INDEX IF NOT EXISTS idx_pos_checkout_payments_cart
  ON pos_checkout.pos_checkout_payments(tenant_id, cart_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_pos_checkout_audit_run
  ON pos_checkout.pos_checkout_audit_events(run_id, event_type, decision);
