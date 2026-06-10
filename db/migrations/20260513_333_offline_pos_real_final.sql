CREATE SCHEMA IF NOT EXISTS offline_pos;

CREATE TABLE IF NOT EXISTS offline_pos.offline_sales_queue (
  offline_queue_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  store_id TEXT NOT NULL,
  register_id TEXT NOT NULL,
  cashier_user_id TEXT NOT NULL,
  offline_sale_key TEXT NOT NULL,
  offline_sale_id TEXT NOT NULL,
  queue_status TEXT NOT NULL DEFAULT 'queued',
  payment_method TEXT NOT NULL DEFAULT 'cash',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  queued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  synced_at TIMESTAMPTZ NULL,
  sync_sale_id TEXT NULL,
  idempotency_key TEXT NOT NULL,
  raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(tenant_id, offline_sale_key),
  UNIQUE(tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS offline_pos.offline_sale_lines (
  offline_line_id TEXT PRIMARY KEY,
  offline_queue_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  quantity NUMERIC(18,3) NOT NULL,
  unit_price NUMERIC(18,2) NOT NULL,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offline_pos.offline_payment_placeholders (
  payment_placeholder_id TEXT PRIMARY KEY,
  offline_queue_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  payment_status TEXT NOT NULL DEFAULT 'offline_pending',
  provider_ref TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offline_pos.offline_sync_attempts (
  sync_attempt_id TEXT PRIMARY KEY,
  offline_queue_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  attempt_status TEXT NOT NULL,
  attempt_no INTEGER NOT NULL DEFAULT 1,
  conflict_reason TEXT NOT NULL DEFAULT '',
  synced_sale_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offline_pos.offline_pos_audit_events (
  event_id TEXT PRIMARY KEY,
  offline_queue_id TEXT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_offline_sales_queue_tenant_status
  ON offline_pos.offline_sales_queue(tenant_id, queue_status, queued_at DESC);

CREATE INDEX IF NOT EXISTS idx_offline_sale_lines_queue
  ON offline_pos.offline_sale_lines(tenant_id, offline_queue_id);

CREATE INDEX IF NOT EXISTS idx_offline_sync_attempts_queue
  ON offline_pos.offline_sync_attempts(tenant_id, offline_queue_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_offline_audit_tenant
  ON offline_pos.offline_pos_audit_events(tenant_id, event_type, decision, created_at DESC);
