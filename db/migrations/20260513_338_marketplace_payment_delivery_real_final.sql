CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_payment_intents (
  payment_intent_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'manual_placeholder',
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
  UNIQUE(tenant_id, marketplace_order_id),
  UNIQUE(tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_payment_status_events (
  payment_event_id TEXT PRIMARY KEY,
  payment_intent_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_deliveries (
  delivery_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  payment_intent_id TEXT NOT NULL,
  delivery_status TEXT NOT NULL DEFAULT 'preparing',
  carrier_placeholder TEXT NOT NULL DEFAULT 'manual_delivery_placeholder',
  tracking_placeholder_ref TEXT NOT NULL DEFAULT '',
  delivery_note TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  shipped_at TIMESTAMPTZ NULL,
  delivered_at TIMESTAMPTZ NULL,
  UNIQUE(tenant_id, marketplace_order_id)
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_delivery_status_events (
  delivery_event_id TEXT PRIMARY KEY,
  delivery_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  marketplace_order_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_payment_delivery_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NULL,
  marketplace_order_id TEXT NULL,
  payment_intent_id TEXT NULL,
  delivery_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_payment_intents_order
  ON marketplace_runtime.marketplace_payment_intents(tenant_id, seller_id, marketplace_order_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_marketplace_deliveries_order
  ON marketplace_runtime.marketplace_deliveries(tenant_id, seller_id, marketplace_order_id, delivery_status);

CREATE INDEX IF NOT EXISTS idx_marketplace_payment_delivery_audit_run
  ON marketplace_runtime.marketplace_payment_delivery_audit_events(run_id, event_type, decision);
