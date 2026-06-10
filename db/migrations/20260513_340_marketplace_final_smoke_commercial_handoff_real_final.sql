CREATE SCHEMA IF NOT EXISTS marketplace_runtime;

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_final_smoke_runs (
  run_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NOT NULL,
  catalog_product_id TEXT NOT NULL,
  checkout_intent_id TEXT NOT NULL DEFAULT '',
  marketplace_order_id TEXT NOT NULL DEFAULT '',
  payment_intent_id TEXT NOT NULL DEFAULT '',
  delivery_id TEXT NOT NULL DEFAULT '',
  catalog_smoke_status TEXT NOT NULL,
  seller_management_status TEXT NOT NULL,
  checkout_order_status TEXT NOT NULL,
  payment_delivery_status TEXT NOT NULL,
  customer_tracking_status TEXT NOT NULL,
  tenant_safe_status TEXT NOT NULL,
  controlled_guard_status TEXT NOT NULL,
  commercial_handoff_status TEXT NOT NULL,
  route_smoke_status TEXT NOT NULL,
  final_status TEXT NOT NULL,
  db_written BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_final_smoke_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  seller_id TEXT NULL,
  marketplace_order_id TEXT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  evidence_ref TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS marketplace_runtime.marketplace_commercial_handoff_checks (
  handoff_check_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  check_code TEXT NOT NULL,
  check_status TEXT NOT NULL,
  check_detail TEXT NOT NULL DEFAULT '',
  evidence_ref TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(run_id, check_code)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_final_smoke_audit_run
  ON marketplace_runtime.marketplace_final_smoke_audit_events(run_id, event_type, decision);

CREATE INDEX IF NOT EXISTS idx_marketplace_commercial_handoff_run
  ON marketplace_runtime.marketplace_commercial_handoff_checks(run_id, check_code, check_status);
