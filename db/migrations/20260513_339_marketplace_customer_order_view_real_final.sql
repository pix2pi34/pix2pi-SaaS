CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_customer_order_views (
  customer_view_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  buyer_session_id TEXT NOT NULL,
  view_type TEXT NOT NULL,
  order_status TEXT NOT NULL,
  payment_status TEXT NOT NULL DEFAULT '',
  delivery_status TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_customer_order_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NULL,
  marketplace_order_id TEXT NULL,
  buyer_session_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_customer_order_views_run
  ON marketplace_runtime.marketplace_customer_order_views(run_id, tenant_id, marketplace_order_id, buyer_session_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_customer_order_audit_run
  ON marketplace_runtime.marketplace_customer_order_audit_events(run_id, event_type, decision);
