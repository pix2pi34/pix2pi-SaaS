CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.stock_movement_batches (
    stock_movement_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    batch_no text NOT NULL,
    batch_type text NOT NULL DEFAULT 'manual',
    movement_source text NOT NULL DEFAULT 'internal',
    source_ref text,
    source_event_id text,
    request_id text,
    idempotency_key text NOT NULL,
    status_code text NOT NULL DEFAULT 'draft',
    movement_count integer NOT NULL DEFAULT 0 CHECK (movement_count >= 0),
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    total_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    posted_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, batch_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movement_documents (
    stock_movement_document_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    document_no text NOT NULL,
    document_type text NOT NULL,
    document_date date NOT NULL,
    period_key text NOT NULL,
    source_document_id text,
    source_document_type text,
    party_id text,
    party_code text,
    location_code text,
    status_code text NOT NULL DEFAULT 'draft',
    currency_code text NOT NULL DEFAULT 'TRY',
    total_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_amount numeric(18,4) NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, document_type, document_no)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movements (
    stock_movement_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    stock_movement_document_id text,
    movement_no text NOT NULL,
    movement_type text NOT NULL,
    movement_direction text NOT NULL,
    movement_date date NOT NULL,
    period_key text NOT NULL,
    location_code text,
    source_ref text,
    source_event_id text,
    reversal_of_movement_id text,
    status_code text NOT NULL DEFAULT 'planned',
    idempotency_key text NOT NULL,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    total_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    posted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, movement_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movement_lines (
    stock_movement_line_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    stock_movement_document_id text,
    line_no integer NOT NULL CHECK (line_no > 0),
    movement_type text NOT NULL,
    movement_direction text NOT NULL,
    product_id text,
    product_code text NOT NULL,
    barcode text,
    unit_code text NOT NULL,
    from_location_id text,
    from_location_code text,
    to_location_id text,
    to_location_code text,
    location_code text,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK (total_cost_amount >= 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    lot_no text,
    serial_no text,
    expiry_date date,
    source_line_ref text,
    opening_stock_line_id text,
    status_code text NOT NULL DEFAULT 'planned',
    validation_status text NOT NULL DEFAULT 'pending',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, stock_movement_id, line_no)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movement_allocations (
    stock_movement_allocation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_line_id text NOT NULL,
    stock_movement_id text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    allocation_type text NOT NULL DEFAULT 'balance_delta',
    movement_direction text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    reserved_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_delta numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    balance_snapshot_id text,
    status_code text NOT NULL DEFAULT 'candidate',
    generated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, stock_movement_line_id, allocation_type, location_code)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movement_validation_errors (
    stock_movement_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    stock_movement_id text NOT NULL,
    stock_movement_line_id text NOT NULL,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, stock_movement_batch_id, error_code, field_name, stock_movement_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.stock_movement_posting_runs (
    stock_movement_posting_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_movement_batch_id text NOT NULL,
    run_no integer NOT NULL CHECK (run_no > 0),
    run_mode text NOT NULL DEFAULT 'dry_run',
    status_code text NOT NULL DEFAULT 'planned',
    movement_count integer NOT NULL DEFAULT 0 CHECK (movement_count >= 0),
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    posted_line_count integer NOT NULL DEFAULT 0 CHECK (posted_line_count >= 0),
    failed_line_count integer NOT NULL DEFAULT 0 CHECK (failed_line_count >= 0),
    idempotency_key text NOT NULL,
    request_id text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, stock_movement_batch_id, run_no)
);

CREATE INDEX IF NOT EXISTS idx_stock_movement_batches_tenant_status
    ON inventory.stock_movement_batches (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_movement_batches_tenant_source
    ON inventory.stock_movement_batches (tenant_id, movement_source, source_ref);

CREATE INDEX IF NOT EXISTS idx_stock_movement_documents_tenant_date
    ON inventory.stock_movement_documents (tenant_id, document_date);

CREATE INDEX IF NOT EXISTS idx_stock_movement_documents_tenant_type_no
    ON inventory.stock_movement_documents (tenant_id, document_type, document_no);

CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant_date
    ON inventory.stock_movements (tenant_id, movement_date);

CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant_type_status
    ON inventory.stock_movements (tenant_id, movement_type, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant_batch
    ON inventory.stock_movements (tenant_id, stock_movement_batch_id);

CREATE INDEX IF NOT EXISTS idx_stock_lines_tenant_movement
    ON inventory.stock_movement_lines (tenant_id, stock_movement_id);

CREATE INDEX IF NOT EXISTS idx_stock_lines_tenant_product
    ON inventory.stock_movement_lines (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_stock_lines_tenant_from_location
    ON inventory.stock_movement_lines (tenant_id, from_location_code);

CREATE INDEX IF NOT EXISTS idx_stock_lines_tenant_to_location
    ON inventory.stock_movement_lines (tenant_id, to_location_code);

CREATE INDEX IF NOT EXISTS idx_stock_allocations_tenant_line
    ON inventory.stock_movement_allocations (tenant_id, stock_movement_line_id);

CREATE INDEX IF NOT EXISTS idx_stock_allocations_tenant_product_location
    ON inventory.stock_movement_allocations (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_errors_tenant_batch
    ON inventory.stock_movement_validation_errors (tenant_id, stock_movement_batch_id);

CREATE INDEX IF NOT EXISTS idx_stock_errors_tenant_status
    ON inventory.stock_movement_validation_errors (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_posting_runs_tenant_batch
    ON inventory.stock_movement_posting_runs (tenant_id, stock_movement_batch_id);

CREATE INDEX IF NOT EXISTS idx_stock_posting_runs_tenant_status
    ON inventory.stock_movement_posting_runs (tenant_id, status_code);
