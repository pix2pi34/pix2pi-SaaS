CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_sellers (
  seller_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  seller_name TEXT NOT NULL,
  seller_status TEXT NOT NULL DEFAULT 'active',
  marketplace_enabled BOOLEAN NOT NULL DEFAULT false,
  controlled_access_enabled BOOLEAN NOT NULL DEFAULT false,
  default_currency TEXT NOT NULL DEFAULT 'TRY',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id)
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_catalog_products (
  catalog_product_id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  source_product_id TEXT NOT NULL,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  category_code TEXT NOT NULL,
  category_name TEXT NOT NULL,
  barcode TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL DEFAULT 'TRY',
  sale_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  stock_quantity_snapshot NUMERIC(18,3) NOT NULL DEFAULT 0,
  catalog_status TEXT NOT NULL DEFAULT 'draft',
  market_visibility TEXT NOT NULL DEFAULT 'public',
  published_at TIMESTAMPTZ NULL,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(tenant_id, source_product_id),
  UNIQUE(tenant_id, slug)
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_checkout_intents (
  checkout_intent_id TEXT PRIMARY KEY,
  seller_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  buyer_session_id TEXT NOT NULL,
  intent_status TEXT NOT NULL DEFAULT 'created',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_catalog_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NULL,
  catalog_product_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_catalog_products_tenant_status
  ON marketplace_runtime.marketplace_catalog_products(tenant_id, catalog_status, market_visibility, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_marketplace_catalog_products_category
  ON marketplace_runtime.marketplace_catalog_products(category_code, catalog_status, market_visibility);

CREATE INDEX IF NOT EXISTS idx_marketplace_audit_run
  ON marketplace_runtime.marketplace_catalog_audit_events(run_id, event_type, decision);
