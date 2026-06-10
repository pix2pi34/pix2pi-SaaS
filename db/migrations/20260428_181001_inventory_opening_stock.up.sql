CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.opening_stock_batches (
    opening_stock_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    batch_no text NOT NULL,
    opening_date date NOT NULL,
    source_type text NOT NULL DEFAULT 'manual',
    source_ref text,
    import_batch_id text,
    status_code text NOT NULL DEFAULT 'draft',
    currency_code text NOT NULL DEFAULT 'TRY',
    valuation_method text NOT NULL DEFAULT 'weighted_average',
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    total_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    approved_by text,
    approved_at timestamptz,
    posted_at timestamptz,
    notes text,
    request_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, batch_no)
);

CREATE TABLE IF NOT EXISTS inventory.opening_stock_lines (
    opening_stock_line_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    opening_stock_batch_id text NOT NULL,
    line_no integer NOT NULL CHECK (line_no > 0),
    product_id text,
    product_code text NOT NULL,
    barcode text,
    location_id text,
    location_code text NOT NULL,
    unit_code text NOT NULL,
    opening_date date NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK (total_cost_amount >= 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    lot_no text,
    serial_no text,
    expiry_date date,
    import_row_id text,
    source_line_ref text,
    status_code text NOT NULL DEFAULT 'draft',
    validation_status text NOT NULL DEFAULT 'pending',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, opening_stock_batch_id, line_no)
);

CREATE TABLE IF NOT EXISTS inventory.opening_stock_validation_errors (
    opening_stock_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    opening_stock_batch_id text NOT NULL,
    opening_stock_line_id text,
    import_row_id text,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, opening_stock_batch_id, error_code, field_name, opening_stock_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.opening_stock_posting_runs (
    opening_stock_posting_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    opening_stock_batch_id text NOT NULL,
    run_no integer NOT NULL CHECK (run_no > 0),
    run_mode text NOT NULL DEFAULT 'dry_run',
    status_code text NOT NULL DEFAULT 'planned',
    movement_batch_id text,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    posted_line_count integer NOT NULL DEFAULT 0 CHECK (posted_line_count >= 0),
    failed_line_count integer NOT NULL DEFAULT 0 CHECK (failed_line_count >= 0),
    idempotency_key text NOT NULL,
    request_id text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, opening_stock_batch_id, run_no)
);

CREATE TABLE IF NOT EXISTS inventory.opening_stock_balance_snapshots (
    opening_stock_balance_snapshot_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    opening_date date NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit_cost numeric(18,4) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK (total_cost_amount >= 0),
    currency_code text NOT NULL DEFAULT 'TRY',
    source_batch_id text NOT NULL,
    source_line_id text NOT NULL,
    snapshot_status text NOT NULL DEFAULT 'candidate',
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, product_code, location_code, opening_date, source_line_id)
);

CREATE INDEX IF NOT EXISTS idx_opening_stock_batches_tenant_date
    ON inventory.opening_stock_batches (tenant_id, opening_date);

CREATE INDEX IF NOT EXISTS idx_opening_stock_batches_tenant_status
    ON inventory.opening_stock_batches (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_batches_tenant_import
    ON inventory.opening_stock_batches (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_opening_stock_lines_tenant_batch
    ON inventory.opening_stock_lines (tenant_id, opening_stock_batch_id);

CREATE INDEX IF NOT EXISTS idx_opening_stock_lines_tenant_product
    ON inventory.opening_stock_lines (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_lines_tenant_location
    ON inventory.opening_stock_lines (tenant_id, location_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_lines_tenant_import_row
    ON inventory.opening_stock_lines (tenant_id, import_row_id);

CREATE INDEX IF NOT EXISTS idx_opening_stock_errors_tenant_batch
    ON inventory.opening_stock_validation_errors (tenant_id, opening_stock_batch_id);

CREATE INDEX IF NOT EXISTS idx_opening_stock_errors_tenant_status
    ON inventory.opening_stock_validation_errors (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_posting_runs_tenant_batch
    ON inventory.opening_stock_posting_runs (tenant_id, opening_stock_batch_id);

CREATE INDEX IF NOT EXISTS idx_opening_stock_posting_runs_tenant_status
    ON inventory.opening_stock_posting_runs (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_snapshots_tenant_product_location
    ON inventory.opening_stock_balance_snapshots (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_opening_stock_snapshots_tenant_date
    ON inventory.opening_stock_balance_snapshots (tenant_id, opening_date);
