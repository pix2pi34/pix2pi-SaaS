CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE IF NOT EXISTS commercial_runtime.billing_invoices (
  invoice_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  billing_period_id TEXT NOT NULL,
  invoice_draft_id TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  invoice_no TEXT NOT NULL,
  invoice_status TEXT NOT NULL DEFAULT 'issued',
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  issued_by_user_id TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ NULL,
  voided_at TIMESTAMPTZ NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(tenant_id, invoice_draft_id),
  UNIQUE(tenant_id, invoice_no)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.billing_invoice_lines (
  invoice_line_id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  line_type TEXT NOT NULL DEFAULT 'subscription',
  description TEXT NOT NULL,
  quantity NUMERIC(18,3) NOT NULL DEFAULT 1,
  unit_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  tax_rate NUMERIC(5,2) NOT NULL DEFAULT 20,
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commercial_runtime.billing_payment_collections (
  collection_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  invoice_id TEXT NOT NULL,
  subscription_id TEXT NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'manual_placeholder',
  collection_status TEXT NOT NULL DEFAULT 'pending',
  currency TEXT NOT NULL DEFAULT 'TRY',
  amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  provider_placeholder_ref TEXT NOT NULL DEFAULT '',
  idempotency_key TEXT NOT NULL,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  collected_at TIMESTAMPTZ NULL,
  failed_at TIMESTAMPTZ NULL,
  failure_reason TEXT NOT NULL DEFAULT '',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE(tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS commercial_runtime.billing_invoice_payment_audit_events (
  event_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  invoice_id TEXT NULL,
  collection_id TEXT NULL,
  subscription_id TEXT NULL,
  actor_user_id TEXT NOT NULL DEFAULT '',
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_billing_invoices_tenant_status
  ON commercial_runtime.billing_invoices(tenant_id, invoice_status, issued_at DESC);

CREATE INDEX IF NOT EXISTS idx_billing_payment_collections_invoice
  ON commercial_runtime.billing_payment_collections(tenant_id, invoice_id, collection_status);

CREATE INDEX IF NOT EXISTS idx_billing_invoice_payment_audit_run
  ON commercial_runtime.billing_invoice_payment_audit_events(run_id, event_type, decision);
