CREATE SCHEMA IF NOT EXISTS erp_inventory;

CREATE TABLE IF NOT EXISTS erp_inventory.product_categories (
  category_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  category_code TEXT NOT NULL,
  category_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, category_code)
);

CREATE TABLE IF NOT EXISTS erp_inventory.products (
  product_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  product_code TEXT NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  category_id TEXT NOT NULL,
  unit_code TEXT NOT NULL,
  purchase_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  sale_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  stock_quantity NUMERIC(18,3) NOT NULL DEFAULT 0,
  critical_stock_level NUMERIC(18,3) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active',
  created_by_user_id TEXT NOT NULL,
  updated_by_user_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, product_code)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_inventory_product_tenant_barcode
  ON erp_inventory.products(tenant_id, lower(barcode))
  WHERE barcode <> '';

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_inventory_product_tenant_sku
  ON erp_inventory.products(tenant_id, lower(sku))
  WHERE sku <> '';

CREATE TABLE IF NOT EXISTS erp_inventory.stock_movements (
  movement_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  movement_type TEXT NOT NULL,
  movement_direction TEXT NOT NULL CHECK (movement_direction IN ('in','out','adjustment')),
  quantity NUMERIC(18,3) NOT NULL CHECK (quantity >= 0),
  stock_after NUMERIC(18,3) NOT NULL,
  unit_cost NUMERIC(18,2) NOT NULL DEFAULT 0,
  description TEXT NOT NULL DEFAULT '',
  source_ref TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_erp_inventory_stock_movements_tenant_product
  ON erp_inventory.stock_movements(tenant_id, product_id, created_at DESC);

CREATE TABLE IF NOT EXISTS erp_inventory.product_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  product_id TEXT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_erp_inventory_product_audit_tenant
  ON erp_inventory.product_audit_events(tenant_id, event_type, decision, created_at DESC);
