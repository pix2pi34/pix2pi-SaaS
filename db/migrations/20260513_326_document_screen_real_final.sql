CREATE SCHEMA IF NOT EXISTS erp_document;

CREATE TABLE IF NOT EXISTS erp_document.sales_documents (
  document_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  source_sale_id TEXT NOT NULL,
  document_no TEXT NOT NULL,
  document_type TEXT NOT NULL DEFAULT 'sales_receipt',
  document_status TEXT NOT NULL DEFAULT 'draft',
  customer_party_id TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL DEFAULT 'TRY',
  subtotal_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_by_user_id TEXT NOT NULL,
  issued_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, document_no),
  UNIQUE(tenant_id, source_sale_id)
);

CREATE TABLE IF NOT EXISTS erp_document.sales_document_lines (
  document_line_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  source_sale_line_id TEXT NOT NULL DEFAULT '',
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  barcode TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  quantity NUMERIC(18,3) NOT NULL DEFAULT 0,
  unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  vat_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  vat_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS erp_document.document_artifacts (
  artifact_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  artifact_type TEXT NOT NULL CHECK (artifact_type IN ('pdf','ubl')),
  artifact_status TEXT NOT NULL DEFAULT 'placeholder',
  artifact_path TEXT NOT NULL DEFAULT '',
  checksum TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS erp_document.document_status_events (
  status_event_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  old_status TEXT NOT NULL DEFAULT '',
  new_status TEXT NOT NULL,
  event_reason TEXT NOT NULL DEFAULT '',
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS erp_document.document_retry_cancel_previews (
  preview_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  requested_by_user_id TEXT NOT NULL,
  retry_allowed BOOLEAN NOT NULL DEFAULT false,
  cancel_allowed BOOLEAN NOT NULL DEFAULT false,
  document_status TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS erp_document.document_audit_events (
  event_id TEXT PRIMARY KEY,
  document_run_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  document_id TEXT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sales_documents_tenant_status
  ON erp_document.sales_documents(tenant_id, document_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sales_document_lines_doc
  ON erp_document.sales_document_lines(tenant_id, document_id);

CREATE INDEX IF NOT EXISTS idx_document_artifacts_doc
  ON erp_document.document_artifacts(tenant_id, document_id, artifact_type);

CREATE INDEX IF NOT EXISTS idx_document_status_events_doc
  ON erp_document.document_status_events(tenant_id, document_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_document_audit_tenant
  ON erp_document.document_audit_events(tenant_id, event_type, decision, created_at DESC);
