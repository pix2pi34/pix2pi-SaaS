CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_orders (
  marketplace_order_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  checkout_intent_id TEXT NOT NULL,
  buyer_session_id TEXT NOT NULL,
  order_no TEXT NOT NULL,
  order_status TEXT NOT NULL DEFAULT 'requested',
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  buyer_note TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ NULL,
  rejected_at TIMESTAMPTZ NULL,
  preparing_at TIMESTAMPTZ NULL,
  UNIQUE(tenant_id, checkout_intent_id),
  UNIQUE(tenant_id, order_no)
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_order_items (
  marketplace_order_item_id TEXT PRIMARY KEY,
  marketplace_order_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  title TEXT NOT NULL,
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  quantity NUMERIC(18,3) NOT NULL,
  unit_price NUMERIC(18,2) NOT NULL,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_order_status_history (
  history_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  changed_by_user_id TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_order_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NULL,
  marketplace_order_id TEXT NULL,
  catalog_product_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_tenant_status
  ON marketplace_runtime.marketplace_orders(tenant_id, seller_id, order_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_marketplace_order_items_order
  ON marketplace_runtime.marketplace_order_items(tenant_id, marketplace_order_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_order_history_run
  ON marketplace_runtime.marketplace_order_status_history(run_id, tenant_id, marketplace_order_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_order_audit_run
  ON marketplace_runtime.marketplace_order_audit_events(run_id, event_type, decision);
