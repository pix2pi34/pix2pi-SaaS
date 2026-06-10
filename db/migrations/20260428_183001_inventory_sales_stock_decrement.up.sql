CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_batches (
    sales_stock_decrement_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    batch_no text NOT NULL,
    sales_channel text NOT NULL DEFAULT 'pos',
    sales_source text NOT NULL DEFAULT 'internal',
    sales_document_id text NOT NULL,
    sales_document_no text NOT NULL,
    sales_document_type text NOT NULL DEFAULT 'sale',
    sales_document_date date NOT NULL,
    period_key text NOT NULL,
    status_code text NOT NULL DEFAULT 'planned',
    idempotency_key text NOT NULL,
    request_id text,
    source_event_id text,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    total_requested_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_decremented_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_short_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    negative_stock_policy text NOT NULL DEFAULT 'block',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    posted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, batch_no),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, sales_document_type, sales_document_id)
);

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_lines (
    sales_stock_decrement_line_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    sales_stock_decrement_batch_id text NOT NULL,
    line_no integer NOT NULL CHECK (line_no > 0),
    sales_document_id text NOT NULL,
    sales_document_line_id text NOT NULL,
    product_id text,
    product_code text NOT NULL,
    barcode text,
    unit_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    requested_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (requested_quantity >= 0),
    decremented_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (decremented_quantity >= 0),
    short_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (short_quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK (total_cost_amount >= 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    reservation_id text,
    negative_stock_allowed boolean NOT NULL DEFAULT false,
    stock_policy text NOT NULL DEFAULT 'block_if_insufficient',
    status_code text NOT NULL DEFAULT 'planned',
    validation_status text NOT NULL DEFAULT 'pending',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, sales_stock_decrement_batch_id, line_no),
    UNIQUE (tenant_id, sales_document_id, sales_document_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_allocations (
    sales_stock_decrement_allocation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    sales_stock_decrement_batch_id text NOT NULL,
    sales_stock_decrement_line_id text NOT NULL,
    sales_document_id text NOT NULL,
    sales_document_line_id text NOT NULL,
    stock_movement_id text,
    stock_movement_line_id text,
    product_code text NOT NULL,
    location_code text NOT NULL,
    movement_type text NOT NULL DEFAULT 'SALE',
    movement_direction text NOT NULL DEFAULT 'OUT',
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
    UNIQUE (tenant_id, sales_stock_decrement_line_id, location_code)
);

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_movement_links (
    sales_stock_decrement_movement_link_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    sales_stock_decrement_batch_id text NOT NULL,
    sales_stock_decrement_line_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    stock_movement_id text NOT NULL,
    stock_movement_line_id text NOT NULL,
    movement_type text NOT NULL DEFAULT 'SALE',
    movement_direction text NOT NULL DEFAULT 'OUT',
    sales_document_id text NOT NULL,
    sales_document_line_id text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    idempotency_key text NOT NULL,
    status_code text NOT NULL DEFAULT 'linked',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, sales_stock_decrement_line_id, stock_movement_line_id),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_validation_errors (
    sales_stock_decrement_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    sales_stock_decrement_batch_id text NOT NULL,
    sales_stock_decrement_line_id text,
    sales_document_id text NOT NULL,
    sales_document_line_id text,
    product_code text,
    location_code text,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, sales_stock_decrement_batch_id, error_code, field_name, sales_stock_decrement_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.sales_stock_decrement_posting_runs (
    sales_stock_decrement_posting_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    sales_stock_decrement_batch_id text NOT NULL,
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
    UNIQUE (tenant_id, sales_stock_decrement_batch_id, run_no)
);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_batches_tenant_document
    ON inventory.sales_stock_decrement_batches (tenant_id, sales_document_type, sales_document_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_batches_tenant_date
    ON inventory.sales_stock_decrement_batches (tenant_id, sales_document_date);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_batches_tenant_status
    ON inventory.sales_stock_decrement_batches (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_lines_tenant_batch
    ON inventory.sales_stock_decrement_lines (tenant_id, sales_stock_decrement_batch_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_lines_tenant_document_line
    ON inventory.sales_stock_decrement_lines (tenant_id, sales_document_id, sales_document_line_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_lines_tenant_product
    ON inventory.sales_stock_decrement_lines (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_lines_tenant_location
    ON inventory.sales_stock_decrement_lines (tenant_id, location_code);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_allocations_tenant_line
    ON inventory.sales_stock_decrement_allocations (tenant_id, sales_stock_decrement_line_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_allocations_tenant_product_location
    ON inventory.sales_stock_decrement_allocations (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_movement_links_tenant_line
    ON inventory.sales_stock_decrement_movement_links (tenant_id, sales_stock_decrement_line_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_movement_links_tenant_movement
    ON inventory.sales_stock_decrement_movement_links (tenant_id, stock_movement_id, stock_movement_line_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_errors_tenant_batch
    ON inventory.sales_stock_decrement_validation_errors (tenant_id, sales_stock_decrement_batch_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_errors_tenant_status
    ON inventory.sales_stock_decrement_validation_errors (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_posting_runs_tenant_batch
    ON inventory.sales_stock_decrement_posting_runs (tenant_id, sales_stock_decrement_batch_id);

CREATE INDEX IF NOT EXISTS idx_sales_decrement_posting_runs_tenant_status
    ON inventory.sales_stock_decrement_posting_runs (tenant_id, status_code);
