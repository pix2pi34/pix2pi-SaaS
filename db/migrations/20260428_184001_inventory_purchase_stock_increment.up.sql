CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_batches (
    purchase_stock_increment_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    batch_no text NOT NULL,
    purchase_channel text NOT NULL DEFAULT 'manual',
    purchase_source text NOT NULL DEFAULT 'internal',
    purchase_document_id text NOT NULL,
    purchase_document_no text NOT NULL,
    purchase_document_type text NOT NULL DEFAULT 'purchase',
    purchase_document_date date NOT NULL,
    period_key text NOT NULL,
    supplier_id text,
    supplier_code text,
    status_code text NOT NULL DEFAULT 'planned',
    idempotency_key text NOT NULL,
    request_id text,
    source_event_id text,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    total_ordered_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_received_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_rejected_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    valuation_method text NOT NULL DEFAULT 'weighted_average',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    posted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, batch_no),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, purchase_document_type, purchase_document_id)
);

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_lines (
    purchase_stock_increment_line_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    purchase_stock_increment_batch_id text NOT NULL,
    line_no integer NOT NULL CHECK (line_no > 0),
    purchase_document_id text NOT NULL,
    purchase_document_line_id text NOT NULL,
    supplier_id text,
    supplier_code text,
    product_id text,
    product_code text NOT NULL,
    barcode text,
    unit_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    ordered_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (ordered_quantity >= 0),
    received_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (received_quantity >= 0),
    rejected_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (rejected_quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK (total_cost_amount >= 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    lot_no text,
    serial_no text,
    expiry_date date,
    stock_policy text NOT NULL DEFAULT 'allow_increment',
    status_code text NOT NULL DEFAULT 'planned',
    validation_status text NOT NULL DEFAULT 'pending',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, purchase_stock_increment_batch_id, line_no),
    UNIQUE (tenant_id, purchase_document_id, purchase_document_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_allocations (
    purchase_stock_increment_allocation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    purchase_stock_increment_batch_id text NOT NULL,
    purchase_stock_increment_line_id text NOT NULL,
    purchase_document_id text NOT NULL,
    purchase_document_line_id text NOT NULL,
    stock_movement_id text,
    stock_movement_line_id text,
    product_code text NOT NULL,
    location_code text NOT NULL,
    movement_type text NOT NULL DEFAULT 'PURCHASE',
    movement_direction text NOT NULL DEFAULT 'IN',
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    balance_before numeric(18,4) NOT NULL DEFAULT 0,
    balance_after numeric(18,4) NOT NULL DEFAULT 0,
    reserved_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_delta numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    status_code text NOT NULL DEFAULT 'candidate',
    generated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, purchase_stock_increment_line_id, location_code)
);

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_movement_links (
    purchase_stock_increment_movement_link_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    purchase_stock_increment_batch_id text NOT NULL,
    purchase_stock_increment_line_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    stock_movement_id text NOT NULL,
    stock_movement_line_id text NOT NULL,
    movement_type text NOT NULL DEFAULT 'PURCHASE',
    movement_direction text NOT NULL DEFAULT 'IN',
    purchase_document_id text NOT NULL,
    purchase_document_line_id text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    idempotency_key text NOT NULL,
    status_code text NOT NULL DEFAULT 'linked',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, purchase_stock_increment_line_id, stock_movement_line_id),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_validation_errors (
    purchase_stock_increment_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    purchase_stock_increment_batch_id text NOT NULL,
    purchase_stock_increment_line_id text,
    purchase_document_id text NOT NULL,
    purchase_document_line_id text,
    supplier_code text,
    product_code text,
    location_code text,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, purchase_stock_increment_batch_id, error_code, field_name, purchase_stock_increment_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.purchase_stock_increment_posting_runs (
    purchase_stock_increment_posting_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    purchase_stock_increment_batch_id text NOT NULL,
    run_no integer NOT NULL CHECK (run_no > 0),
    run_mode text NOT NULL DEFAULT 'dry_run',
    status_code text NOT NULL DEFAULT 'planned',
    stock_movement_batch_id text,
    stock_movement_id text,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    posted_line_count integer NOT NULL DEFAULT 0 CHECK (posted_line_count >= 0),
    failed_line_count integer NOT NULL DEFAULT 0 CHECK (failed_line_count >= 0),
    idempotency_key text NOT NULL,
    request_id text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, purchase_stock_increment_batch_id, run_no)
);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_batches_tenant_document
    ON inventory.purchase_stock_increment_batches (tenant_id, purchase_document_type, purchase_document_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_batches_tenant_date
    ON inventory.purchase_stock_increment_batches (tenant_id, purchase_document_date);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_batches_tenant_status
    ON inventory.purchase_stock_increment_batches (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_batches_tenant_supplier
    ON inventory.purchase_stock_increment_batches (tenant_id, supplier_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_lines_tenant_batch
    ON inventory.purchase_stock_increment_lines (tenant_id, purchase_stock_increment_batch_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_lines_tenant_document_line
    ON inventory.purchase_stock_increment_lines (tenant_id, purchase_document_id, purchase_document_line_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_lines_tenant_product
    ON inventory.purchase_stock_increment_lines (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_lines_tenant_location
    ON inventory.purchase_stock_increment_lines (tenant_id, location_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_allocations_tenant_line
    ON inventory.purchase_stock_increment_allocations (tenant_id, purchase_stock_increment_line_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_allocations_tenant_product_location
    ON inventory.purchase_stock_increment_allocations (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_movement_links_tenant_line
    ON inventory.purchase_stock_increment_movement_links (tenant_id, purchase_stock_increment_line_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_movement_links_tenant_movement
    ON inventory.purchase_stock_increment_movement_links (tenant_id, stock_movement_id, stock_movement_line_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_errors_tenant_batch
    ON inventory.purchase_stock_increment_validation_errors (tenant_id, purchase_stock_increment_batch_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_errors_tenant_status
    ON inventory.purchase_stock_increment_validation_errors (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_posting_runs_tenant_batch
    ON inventory.purchase_stock_increment_posting_runs (tenant_id, purchase_stock_increment_batch_id);

CREATE INDEX IF NOT EXISTS idx_purchase_increment_posting_runs_tenant_status
    ON inventory.purchase_stock_increment_posting_runs (tenant_id, status_code);
