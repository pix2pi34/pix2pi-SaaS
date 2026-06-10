CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_management_audit_events (
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

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_product_status_history (
  history_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  old_visibility TEXT NOT NULL,
  new_visibility TEXT NOT NULL,
  changed_by_user_id TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_snapshot_updates (
  snapshot_update_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  old_sale_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  new_sale_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  old_stock_snapshot NUMERIC(18,3) NOT NULL DEFAULT 0,
  new_stock_snapshot NUMERIC(18,3) NOT NULL DEFAULT 0,
  changed_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_management_audit_run
  ON marketplace_runtime.marketplace_management_audit_events(run_id, event_type, decision);

CREATE INDEX IF NOT EXISTS idx_marketplace_product_status_history_run
  ON marketplace_runtime.marketplace_product_status_history(run_id, tenant_id, catalog_product_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_snapshot_updates_run
  ON marketplace_runtime.marketplace_snapshot_updates(run_id, tenant_id, catalog_product_id);
