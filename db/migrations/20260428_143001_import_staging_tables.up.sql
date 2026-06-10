CREATE SCHEMA IF NOT EXISTS import_pipeline;

CREATE TABLE IF NOT EXISTS import_pipeline.import_batches (
    import_batch_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_type text NOT NULL,
    source_system text NOT NULL DEFAULT 'manual',
    status text NOT NULL DEFAULT 'draft',
    dry_run boolean NOT NULL DEFAULT true,
    total_rows integer NOT NULL DEFAULT 0 CHECK (total_rows >= 0),
    valid_rows integer NOT NULL DEFAULT 0 CHECK (valid_rows >= 0),
    invalid_rows integer NOT NULL DEFAULT 0 CHECK (invalid_rows >= 0),
    applied_rows integer NOT NULL DEFAULT 0 CHECK (applied_rows >= 0),
    failed_rows integer NOT NULL DEFAULT 0 CHECK (failed_rows >= 0),
    created_by text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    CONSTRAINT import_batches_status_chk CHECK (
        status IN (
            'draft',
            'uploaded',
            'validating',
            'validated',
            'dry_run_pass',
            'dry_run_fail',
            'ready_to_apply',
            'applying',
            'applied',
            'failed',
            'cancelled'
        )
    )
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_files (
    import_file_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    original_file_name text NOT NULL,
    file_kind text NOT NULL,
    mime_type text,
    storage_uri text,
    checksum_sha256 text,
    file_size_bytes bigint NOT NULL DEFAULT 0 CHECK (file_size_bytes >= 0),
    uploaded_by text,
    uploaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_customers_staging (
    staging_customer_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    external_ref text,
    customer_code text,
    display_name text,
    tax_no text,
    tax_office text,
    email text,
    phone text,
    address_line text,
    city text,
    district text,
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    row_hash text,
    validation_status text NOT NULL DEFAULT 'pending',
    apply_status text NOT NULL DEFAULT 'not_applied',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_vendors_staging (
    staging_vendor_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    external_ref text,
    vendor_code text,
    display_name text,
    tax_no text,
    tax_office text,
    email text,
    phone text,
    address_line text,
    city text,
    district text,
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    row_hash text,
    validation_status text NOT NULL DEFAULT 'pending',
    apply_status text NOT NULL DEFAULT 'not_applied',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_products_staging (
    staging_product_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    external_ref text,
    product_code text,
    sku text,
    barcode text,
    product_name text,
    unit_code text,
    category_code text,
    tax_rate_code text,
    purchase_price numeric(18,4),
    sales_price numeric(18,4),
    currency_code text DEFAULT 'TRY',
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    row_hash text,
    validation_status text NOT NULL DEFAULT 'pending',
    apply_status text NOT NULL DEFAULT 'not_applied',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_opening_stocks_staging (
    staging_opening_stock_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    external_ref text,
    product_code text,
    location_code text,
    quantity numeric(18,4),
    unit_cost numeric(18,4),
    currency_code text DEFAULT 'TRY',
    stock_date date,
    valuation_method text DEFAULT 'weighted_average',
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    row_hash text,
    validation_status text NOT NULL DEFAULT 'pending',
    apply_status text NOT NULL DEFAULT 'not_applied',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_price_lists_staging (
    staging_price_list_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    external_ref text,
    price_list_code text,
    product_code text,
    price_type text NOT NULL DEFAULT 'sales',
    price_amount numeric(18,4),
    currency_code text DEFAULT 'TRY',
    valid_from date,
    valid_until date,
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    row_hash text,
    validation_status text NOT NULL DEFAULT 'pending',
    apply_status text NOT NULL DEFAULT 'not_applied',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_validation_errors (
    validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    staging_table text NOT NULL,
    staging_row_id text NOT NULL,
    row_number integer,
    field_name text,
    error_code text NOT NULL,
    error_message text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    is_blocking boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT import_validation_errors_severity_chk CHECK (
        severity IN ('info', 'warning', 'error', 'critical')
    )
);

CREATE TABLE IF NOT EXISTS import_pipeline.import_row_status_events (
    row_status_event_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    import_batch_id text NOT NULL REFERENCES import_pipeline.import_batches(import_batch_id) ON DELETE CASCADE,
    staging_table text NOT NULL,
    staging_row_id text NOT NULL,
    row_number integer,
    previous_status text,
    next_status text NOT NULL,
    reason_code text,
    reason_message text,
    actor text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_import_batches_tenant_status
    ON import_pipeline.import_batches (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_import_batches_tenant_type
    ON import_pipeline.import_batches (tenant_id, import_type);

CREATE INDEX IF NOT EXISTS idx_import_files_tenant_batch
    ON import_pipeline.import_files (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_customers_tenant_batch
    ON import_pipeline.import_customers_staging (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_customers_tenant_code
    ON import_pipeline.import_customers_staging (tenant_id, customer_code);

CREATE INDEX IF NOT EXISTS idx_import_vendors_tenant_batch
    ON import_pipeline.import_vendors_staging (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_vendors_tenant_code
    ON import_pipeline.import_vendors_staging (tenant_id, vendor_code);

CREATE INDEX IF NOT EXISTS idx_import_products_tenant_batch
    ON import_pipeline.import_products_staging (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_products_tenant_code
    ON import_pipeline.import_products_staging (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_import_opening_stocks_tenant_batch
    ON import_pipeline.import_opening_stocks_staging (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_opening_stocks_tenant_product
    ON import_pipeline.import_opening_stocks_staging (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_import_price_lists_tenant_batch
    ON import_pipeline.import_price_lists_staging (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_validation_errors_tenant_batch
    ON import_pipeline.import_validation_errors (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_validation_errors_staging_row
    ON import_pipeline.import_validation_errors (tenant_id, staging_table, staging_row_id);

CREATE INDEX IF NOT EXISTS idx_import_row_status_events_tenant_batch
    ON import_pipeline.import_row_status_events (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS idx_import_row_status_events_staging_row
    ON import_pipeline.import_row_status_events (tenant_id, staging_table, staging_row_id);
