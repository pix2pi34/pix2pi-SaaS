CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_batches (
    stock_reservation_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    batch_no text NOT NULL,
    reservation_source text NOT NULL DEFAULT 'sales',
    source_ref text,
    sales_document_id text,
    sales_document_no text,
    sales_document_type text NOT NULL DEFAULT 'sale',
    reservation_date date NOT NULL,
    period_key text NOT NULL,
    party_id text,
    party_code text,
    status_code text NOT NULL DEFAULT 'planned',
    idempotency_key text NOT NULL,
    request_id text,
    source_event_id text,
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    total_requested_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_reserved_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_available_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_released_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_expired_quantity numeric(18,4) NOT NULL DEFAULT 0,
    expires_at timestamptz,
    created_by text,
    approved_by text,
    approved_at timestamptz,
    posted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, batch_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservations (
    stock_reservation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_reservation_batch_id text NOT NULL,
    reservation_no text NOT NULL,
    reservation_type text NOT NULL DEFAULT 'sales_hold',
    reservation_status text NOT NULL DEFAULT 'planned',
    sales_document_id text,
    sales_document_line_id text,
    party_id text,
    party_code text,
    product_code text,
    location_code text,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    requested_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (requested_quantity >= 0),
    reserved_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    available_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (available_quantity >= 0),
    released_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (released_quantity >= 0),
    expired_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (expired_quantity >= 0),
    consumed_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (consumed_quantity >= 0),
    priority_code text NOT NULL DEFAULT 'normal',
    expires_at timestamptz,
    idempotency_key text NOT NULL,
    request_id text,
    source_event_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, reservation_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_lines (
    stock_reservation_line_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_reservation_id text NOT NULL,
    stock_reservation_batch_id text NOT NULL,
    line_no integer NOT NULL CHECK (line_no > 0),
    sales_document_id text,
    sales_document_line_id text,
    product_id text,
    product_code text NOT NULL,
    barcode text,
    unit_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    requested_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (requested_quantity >= 0),
    reserved_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    available_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (available_quantity >= 0),
    released_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (released_quantity >= 0),
    expired_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (expired_quantity >= 0),
    consumed_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (consumed_quantity >= 0),
    reservation_status text NOT NULL DEFAULT 'planned',
    stock_policy text NOT NULL DEFAULT 'reserve_if_available',
    expires_at timestamptz,
    validation_status text NOT NULL DEFAULT 'pending',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, stock_reservation_id, line_no)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_allocations (
    stock_reservation_allocation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_reservation_id text NOT NULL,
    stock_reservation_line_id text NOT NULL,
    stock_reservation_batch_id text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    allocation_type text NOT NULL DEFAULT 'reservation_delta',
    reservation_status text NOT NULL DEFAULT 'candidate',
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reserved_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    reserved_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (available_quantity >= 0),
    available_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    balance_before numeric(18,4) NOT NULL DEFAULT 0,
    balance_after numeric(18,4) NOT NULL DEFAULT 0,
    expires_at timestamptz,
    balance_snapshot_id text,
    status_code text NOT NULL DEFAULT 'candidate',
    generated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, stock_reservation_line_id, allocation_type, location_code)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_releases (
    stock_reservation_release_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_reservation_id text NOT NULL,
    stock_reservation_line_id text,
    stock_reservation_batch_id text NOT NULL,
    release_no text NOT NULL,
    release_reason text NOT NULL DEFAULT 'manual',
    release_source text NOT NULL DEFAULT 'internal',
    reservation_status text NOT NULL DEFAULT 'release_planned',
    sales_document_id text,
    sales_document_line_id text,
    product_code text,
    location_code text,
    quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    released_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (released_quantity >= 0),
    reserved_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    reservation_status_before text NOT NULL DEFAULT 'reserved',
    reservation_status_after text NOT NULL DEFAULT 'released',
    idempotency_key text NOT NULL,
    request_id text,
    status_code text NOT NULL DEFAULT 'planned',
    created_at timestamptz NOT NULL DEFAULT now(),
    posted_at timestamptz,
    UNIQUE (tenant_id, release_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_validation_errors (
    stock_reservation_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_reservation_batch_id text NOT NULL,
    stock_reservation_id text,
    stock_reservation_line_id text,
    sales_document_id text,
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
    UNIQUE (tenant_id, stock_reservation_batch_id, error_code, field_name, stock_reservation_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.stock_reservation_expiry_runs (
    stock_reservation_expiry_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    run_no text NOT NULL,
    run_mode text NOT NULL DEFAULT 'dry_run',
    status_code text NOT NULL DEFAULT 'planned',
    expires_before timestamptz NOT NULL,
    scanned_reservation_count integer NOT NULL DEFAULT 0 CHECK (scanned_reservation_count >= 0),
    expired_reservation_count integer NOT NULL DEFAULT 0 CHECK (expired_reservation_count >= 0),
    released_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (released_quantity >= 0),
    reserved_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity_delta numeric(18,4) NOT NULL DEFAULT 0,
    idempotency_key text NOT NULL,
    request_id text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, run_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_batches_tenant_date
    ON inventory.stock_reservation_batches (tenant_id, reservation_date);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_batches_tenant_status
    ON inventory.stock_reservation_batches (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_batches_tenant_sales_document
    ON inventory.stock_reservation_batches (tenant_id, sales_document_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservations_tenant_batch
    ON inventory.stock_reservations (tenant_id, stock_reservation_batch_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservations_tenant_status
    ON inventory.stock_reservations (tenant_id, reservation_status);

CREATE INDEX IF NOT EXISTS idx_stock_reservations_tenant_expiry
    ON inventory.stock_reservations (tenant_id, expires_at);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_lines_tenant_reservation
    ON inventory.stock_reservation_lines (tenant_id, stock_reservation_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_lines_tenant_product
    ON inventory.stock_reservation_lines (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_lines_tenant_location
    ON inventory.stock_reservation_lines (tenant_id, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_allocations_tenant_line
    ON inventory.stock_reservation_allocations (tenant_id, stock_reservation_line_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_allocations_tenant_product_location
    ON inventory.stock_reservation_allocations (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_releases_tenant_reservation
    ON inventory.stock_reservation_releases (tenant_id, stock_reservation_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_releases_tenant_status
    ON inventory.stock_reservation_releases (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_errors_tenant_batch
    ON inventory.stock_reservation_validation_errors (tenant_id, stock_reservation_batch_id);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_errors_tenant_status
    ON inventory.stock_reservation_validation_errors (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_expiry_runs_tenant_status
    ON inventory.stock_reservation_expiry_runs (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_reservation_expiry_runs_tenant_expires_before
    ON inventory.stock_reservation_expiry_runs (tenant_id, expires_before);
