-- FAZ 4 / 15.1 - Operational readmodel tables
-- This migration defines readmodel tables only.
-- Apply is NOT executed by the package that creates this file.

CREATE SCHEMA IF NOT EXISTS readmodel;

CREATE TABLE IF NOT EXISTS readmodel.projection_state (
    tenant_id text NOT NULL,
    projection_name text NOT NULL,
    projection_version integer NOT NULL DEFAULT 1,
    source_stream text NOT NULL DEFAULT '',
    last_event_id text,
    last_event_time timestamptz,
    last_sequence bigint NOT NULL DEFAULT 0,
    status text NOT NULL DEFAULT 'idle',
    error_count integer NOT NULL DEFAULT 0,
    last_error text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, projection_name)
);

CREATE TABLE IF NOT EXISTS readmodel.tenant_operational_snapshot (
    tenant_id text PRIMARY KEY,
    legal_entity_count integer NOT NULL DEFAULT 0,
    branch_count integer NOT NULL DEFAULT 0,
    active_user_count integer NOT NULL DEFAULT 0,
    customer_count integer NOT NULL DEFAULT 0,
    vendor_count integer NOT NULL DEFAULT 0,
    product_count integer NOT NULL DEFAULT 0,
    open_sales_document_count integer NOT NULL DEFAULT 0,
    open_purchase_document_count integer NOT NULL DEFAULT 0,
    stock_alert_count integer NOT NULL DEFAULT 0,
    pending_document_count integer NOT NULL DEFAULT 0,
    pending_payment_count integer NOT NULL DEFAULT 0,
    last_event_time timestamptz,
    refreshed_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS readmodel.daily_operational_metrics (
    tenant_id text NOT NULL,
    metric_date date NOT NULL,
    sales_document_count integer NOT NULL DEFAULT 0,
    sales_total numeric(18, 2) NOT NULL DEFAULT 0,
    purchase_document_count integer NOT NULL DEFAULT 0,
    purchase_total numeric(18, 2) NOT NULL DEFAULT 0,
    payment_in_total numeric(18, 2) NOT NULL DEFAULT 0,
    payment_out_total numeric(18, 2) NOT NULL DEFAULT 0,
    stock_movement_count integer NOT NULL DEFAULT 0,
    journal_count integer NOT NULL DEFAULT 0,
    error_count integer NOT NULL DEFAULT 0,
    refreshed_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, metric_date)
);

CREATE TABLE IF NOT EXISTS readmodel.inventory_status_snapshot (
    tenant_id text NOT NULL,
    item_id text NOT NULL,
    warehouse_id text NOT NULL DEFAULT 'default',
    sku text,
    item_name text,
    on_hand_qty numeric(18, 4) NOT NULL DEFAULT 0,
    reserved_qty numeric(18, 4) NOT NULL DEFAULT 0,
    available_qty numeric(18, 4) NOT NULL DEFAULT 0,
    min_stock_qty numeric(18, 4) NOT NULL DEFAULT 0,
    negative_stock_flag boolean NOT NULL DEFAULT false,
    below_min_stock_flag boolean NOT NULL DEFAULT false,
    last_movement_at timestamptz,
    refreshed_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, item_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS readmodel.document_work_queue (
    tenant_id text NOT NULL,
    document_type text NOT NULL,
    document_id text NOT NULL,
    source_module text NOT NULL DEFAULT 'unknown',
    status text NOT NULL DEFAULT 'pending',
    priority integer NOT NULL DEFAULT 100,
    due_at timestamptz,
    last_error text,
    retry_count integer NOT NULL DEFAULT 0,
    last_event_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, document_type, document_id)
);

CREATE TABLE IF NOT EXISTS readmodel.reconciliation_status_snapshot (
    tenant_id text NOT NULL,
    scope_type text NOT NULL,
    scope_id text NOT NULL,
    status text NOT NULL DEFAULT 'open',
    unreconciled_count integer NOT NULL DEFAULT 0,
    difference_amount numeric(18, 2) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    last_reconciled_at timestamptz,
    refreshed_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, scope_type, scope_id)
);

CREATE INDEX IF NOT EXISTS idx_projection_state_status
    ON readmodel.projection_state (tenant_id, status, updated_at);

CREATE INDEX IF NOT EXISTS idx_tenant_operational_snapshot_refreshed
    ON readmodel.tenant_operational_snapshot (refreshed_at);

CREATE INDEX IF NOT EXISTS idx_daily_operational_metrics_date
    ON readmodel.daily_operational_metrics (metric_date, tenant_id);

CREATE INDEX IF NOT EXISTS idx_inventory_status_alerts
    ON readmodel.inventory_status_snapshot (tenant_id, negative_stock_flag, below_min_stock_flag, updated_at);

CREATE INDEX IF NOT EXISTS idx_document_work_queue_status_priority
    ON readmodel.document_work_queue (tenant_id, status, priority, due_at);

CREATE INDEX IF NOT EXISTS idx_document_work_queue_source_module
    ON readmodel.document_work_queue (tenant_id, source_module, status, updated_at);

CREATE INDEX IF NOT EXISTS idx_reconciliation_status_snapshot_status
    ON readmodel.reconciliation_status_snapshot (tenant_id, status, updated_at);
