CREATE SCHEMA IF NOT EXISTS pos_sales;

CREATE TABLE IF NOT EXISTS pos_sales.sales (
  sale_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  store_id TEXT NOT NULL,
  register_id TEXT NOT NULL,
  cashier_user_id TEXT NOT NULL,
  sale_no TEXT NOT NULL,
  sale_status TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  payment_status TEXT NOT NULL DEFAULT 'unpaid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ NULL,
  correlation_id TEXT NOT NULL,
  UNIQUE(tenant_id, sale_no)
);

CREATE TABLE IF NOT EXISTS pos_sales.sale_lines (
  sale_line_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sale_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  barcode TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  product_name TEXT NOT NULL,
  quantity NUMERIC(18,3) NOT NULL,
  unit_price NUMERIC(18,2) NOT NULL,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL,
  stock_after NUMERIC(18,3) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_sales.sale_payments (
  payment_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sale_id TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  payment_status TEXT NOT NULL,
  provider_ref TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_sales.sale_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sale_id TEXT NULL,
  cashier_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_sales_tenant_register
  ON pos_sales.sales(tenant_id, register_id, completed_at DESC);

CREATE INDEX IF NOT EXISTS idx_pos_sale_lines_sale
  ON pos_sales.sale_lines(tenant_id, sale_id);

CREATE INDEX IF NOT EXISTS idx_pos_sale_payments_sale
  ON pos_sales.sale_payments(tenant_id, sale_id);

CREATE INDEX IF NOT EXISTS idx_pos_sale_audit_tenant
  ON pos_sales.sale_audit_events(tenant_id, event_type, decision, created_at DESC);
