CREATE SCHEMA IF NOT EXISTS pos_sales;

CREATE TABLE IF NOT EXISTS pos_sales.sale_refund_previews (
  preview_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sale_id TEXT NOT NULL,
  requested_by_user_id TEXT NOT NULL,
  refund_allowed BOOLEAN NOT NULL DEFAULT false,
  cancel_allowed BOOLEAN NOT NULL DEFAULT false,
  refund_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  payment_status TEXT NOT NULL,
  sale_status TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos_sales.sale_management_audit_events (
  event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  sale_id TEXT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pos_sale_refund_previews_sale
  ON pos_sales.sale_refund_previews(tenant_id, sale_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_pos_sale_management_audit_tenant
  ON pos_sales.sale_management_audit_events(tenant_id, event_type, decision, created_at DESC);
