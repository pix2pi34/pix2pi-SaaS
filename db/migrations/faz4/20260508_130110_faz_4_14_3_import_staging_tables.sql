-- FAZ 4-14.3 — Import / Staging Tablolari
-- Purpose:
--   Tenant-safe import staging foundation for pilot/import/UAT closure.
-- Scope:
--   Import batch, source file, raw rows, customer/product/stock/finance staging,
--   validation errors and audit events.
-- Policy:
--   Live external provider/GIB/bank/POS gates are not activated here.
--   They remain CLOSED_POLICY_GATE_REFERENCE_ONLY.

CREATE TABLE IF NOT EXISTS public.import_batches (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    import_type            TEXT NOT NULL,
    source_name            TEXT NOT NULL,
    source_checksum        TEXT,
    dry_run                BOOLEAN NOT NULL DEFAULT TRUE,
    status                 TEXT NOT NULL DEFAULT 'CREATED',
    total_rows             INTEGER NOT NULL DEFAULT 0,
    valid_rows             INTEGER NOT NULL DEFAULT 0,
    invalid_rows           INTEGER NOT NULL DEFAULT 0,
    duplicate_rows         INTEGER NOT NULL DEFAULT 0,
    committed_rows         INTEGER NOT NULL DEFAULT 0,
    failed_rows            INTEGER NOT NULL DEFAULT 0,
    created_by             TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_batches_pk
        PRIMARY KEY (tenant_id, import_batch_id),

    CONSTRAINT import_batches_import_type_chk
        CHECK (import_type IN (
            'CUSTOMER',
            'PRODUCT',
            'STOCK',
            'FINANCE_DOCUMENT',
            'MIXED'
        )),

    CONSTRAINT import_batches_status_chk
        CHECK (status IN (
            'CREATED',
            'DRY_RUN_STARTED',
            'DRY_RUN_COMPLETED',
            'VALIDATION_FAILED',
            'VALIDATED',
            'COMMIT_STARTED',
            'COMMITTED',
            'ROLLBACK_REQUIRED',
            'ROLLED_BACK',
            'FAILED',
            'CANCELED'
        )),

    CONSTRAINT import_batches_row_counts_chk
        CHECK (
            total_rows >= 0
            AND valid_rows >= 0
            AND invalid_rows >= 0
            AND duplicate_rows >= 0
            AND committed_rows >= 0
            AND failed_rows >= 0
        )
);

CREATE INDEX IF NOT EXISTS import_batches_tenant_status_idx
    ON public.import_batches (tenant_id, status);

CREATE INDEX IF NOT EXISTS import_batches_tenant_type_idx
    ON public.import_batches (tenant_id, import_type);

CREATE INDEX IF NOT EXISTS import_batches_correlation_idx
    ON public.import_batches (tenant_id, correlation_id);

CREATE INDEX IF NOT EXISTS import_batches_created_at_idx
    ON public.import_batches (tenant_id, created_at DESC);


CREATE TABLE IF NOT EXISTS public.import_source_files (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    file_id                TEXT NOT NULL,
    file_name              TEXT NOT NULL,
    file_mime_type         TEXT,
    file_size_bytes        BIGINT NOT NULL DEFAULT 0,
    source_checksum        TEXT,
    storage_reference      TEXT,
    parse_status           TEXT NOT NULL DEFAULT 'UPLOADED',
    parse_error            TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_source_files_pk
        PRIMARY KEY (tenant_id, import_batch_id, file_id),

    CONSTRAINT import_source_files_batch_fk
        FOREIGN KEY (tenant_id, import_batch_id)
        REFERENCES public.import_batches (tenant_id, import_batch_id)
        ON DELETE CASCADE,

    CONSTRAINT import_source_files_size_chk
        CHECK (file_size_bytes >= 0),

    CONSTRAINT import_source_files_parse_status_chk
        CHECK (parse_status IN (
            'UPLOADED',
            'PARSE_STARTED',
            'PARSED',
            'PARSE_FAILED',
            'IGNORED'
        ))
);

CREATE INDEX IF NOT EXISTS import_source_files_batch_idx
    ON public.import_source_files (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS import_source_files_checksum_idx
    ON public.import_source_files (tenant_id, source_checksum);


CREATE TABLE IF NOT EXISTS public.import_staging_rows (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    entity_type            TEXT NOT NULL,
    source_file_id         TEXT,
    source_row             JSONB NOT NULL DEFAULT '{}'::jsonb,
    normalized_row         JSONB NOT NULL DEFAULT '{}'::jsonb,
    row_hash               TEXT,
    validation_status      TEXT NOT NULL DEFAULT 'PENDING',
    validation_errors      JSONB NOT NULL DEFAULT '[]'::jsonb,
    transform_status       TEXT NOT NULL DEFAULT 'PENDING',
    commit_status          TEXT NOT NULL DEFAULT 'NOT_COMMITTED',
    target_record_ref      TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_staging_rows_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number),

    CONSTRAINT import_staging_rows_batch_fk
        FOREIGN KEY (tenant_id, import_batch_id)
        REFERENCES public.import_batches (tenant_id, import_batch_id)
        ON DELETE CASCADE,

    CONSTRAINT import_staging_rows_row_number_chk
        CHECK (row_number > 0),

    CONSTRAINT import_staging_rows_entity_type_chk
        CHECK (entity_type IN (
            'CUSTOMER',
            'PRODUCT',
            'STOCK',
            'FINANCE_DOCUMENT',
            'UNKNOWN'
        )),

    CONSTRAINT import_staging_rows_validation_status_chk
        CHECK (validation_status IN (
            'PENDING',
            'VALID',
            'INVALID',
            'DUPLICATE',
            'SKIPPED'
        )),

    CONSTRAINT import_staging_rows_transform_status_chk
        CHECK (transform_status IN (
            'PENDING',
            'TRANSFORMED',
            'TRANSFORM_FAILED',
            'SKIPPED'
        )),

    CONSTRAINT import_staging_rows_commit_status_chk
        CHECK (commit_status IN (
            'NOT_COMMITTED',
            'COMMIT_READY',
            'COMMITTED',
            'COMMIT_FAILED',
            'ROLLED_BACK',
            'SKIPPED'
        ))
);

CREATE INDEX IF NOT EXISTS import_staging_rows_batch_status_idx
    ON public.import_staging_rows (tenant_id, import_batch_id, validation_status);

CREATE INDEX IF NOT EXISTS import_staging_rows_entity_idx
    ON public.import_staging_rows (tenant_id, import_batch_id, entity_type);

CREATE INDEX IF NOT EXISTS import_staging_rows_hash_idx
    ON public.import_staging_rows (tenant_id, import_batch_id, row_hash);

CREATE INDEX IF NOT EXISTS import_staging_rows_commit_idx
    ON public.import_staging_rows (tenant_id, import_batch_id, commit_status);

CREATE INDEX IF NOT EXISTS import_staging_rows_source_gin_idx
    ON public.import_staging_rows USING GIN (source_row);

CREATE INDEX IF NOT EXISTS import_staging_rows_normalized_gin_idx
    ON public.import_staging_rows USING GIN (normalized_row);


CREATE TABLE IF NOT EXISTS public.import_staging_customers (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    customer_code          TEXT,
    customer_name          TEXT NOT NULL,
    customer_type          TEXT NOT NULL DEFAULT 'COMMERCIAL',
    tax_no                 TEXT,
    tax_office             TEXT,
    mersis_no              TEXT,
    phone                  TEXT,
    email                  TEXT,
    address_line           TEXT,
    city                   TEXT,
    district               TEXT,
    country_code           TEXT NOT NULL DEFAULT 'TR',
    raw_data               JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_status      TEXT NOT NULL DEFAULT 'PENDING',
    validation_errors      JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_staging_customers_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number),

    CONSTRAINT import_staging_customers_row_fk
        FOREIGN KEY (tenant_id, import_batch_id, row_number)
        REFERENCES public.import_staging_rows (tenant_id, import_batch_id, row_number)
        ON DELETE CASCADE,

    CONSTRAINT import_staging_customers_customer_type_chk
        CHECK (customer_type IN (
            'COMMERCIAL',
            'INDIVIDUAL',
            'SUPPLIER',
            'BOTH'
        )),

    CONSTRAINT import_staging_customers_validation_status_chk
        CHECK (validation_status IN (
            'PENDING',
            'VALID',
            'INVALID',
            'DUPLICATE',
            'SKIPPED'
        ))
);

CREATE INDEX IF NOT EXISTS import_staging_customers_code_idx
    ON public.import_staging_customers (tenant_id, import_batch_id, customer_code);

CREATE INDEX IF NOT EXISTS import_staging_customers_tax_no_idx
    ON public.import_staging_customers (tenant_id, import_batch_id, tax_no);

CREATE INDEX IF NOT EXISTS import_staging_customers_name_idx
    ON public.import_staging_customers (tenant_id, import_batch_id, customer_name);


CREATE TABLE IF NOT EXISTS public.import_staging_products (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    product_code           TEXT,
    barcode                TEXT,
    product_name           TEXT NOT NULL,
    product_type           TEXT NOT NULL DEFAULT 'STOCK_ITEM',
    unit_code              TEXT NOT NULL DEFAULT 'ADET',
    vat_rate               NUMERIC(5,2),
    category_code          TEXT,
    brand                  TEXT,
    oem_code               TEXT,
    equivalent_code        TEXT,
    raw_data               JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_status      TEXT NOT NULL DEFAULT 'PENDING',
    validation_errors      JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_staging_products_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number),

    CONSTRAINT import_staging_products_row_fk
        FOREIGN KEY (tenant_id, import_batch_id, row_number)
        REFERENCES public.import_staging_rows (tenant_id, import_batch_id, row_number)
        ON DELETE CASCADE,

    CONSTRAINT import_staging_products_type_chk
        CHECK (product_type IN (
            'STOCK_ITEM',
            'SERVICE',
            'BUNDLE',
            'RAW_MATERIAL'
        )),

    CONSTRAINT import_staging_products_vat_rate_chk
        CHECK (vat_rate IS NULL OR vat_rate >= 0),

    CONSTRAINT import_staging_products_validation_status_chk
        CHECK (validation_status IN (
            'PENDING',
            'VALID',
            'INVALID',
            'DUPLICATE',
            'SKIPPED'
        ))
);

CREATE INDEX IF NOT EXISTS import_staging_products_code_idx
    ON public.import_staging_products (tenant_id, import_batch_id, product_code);

CREATE INDEX IF NOT EXISTS import_staging_products_barcode_idx
    ON public.import_staging_products (tenant_id, import_batch_id, barcode);

CREATE INDEX IF NOT EXISTS import_staging_products_name_idx
    ON public.import_staging_products (tenant_id, import_batch_id, product_name);

CREATE INDEX IF NOT EXISTS import_staging_products_oem_idx
    ON public.import_staging_products (tenant_id, import_batch_id, oem_code);


CREATE TABLE IF NOT EXISTS public.import_staging_stock_entries (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    product_code           TEXT NOT NULL,
    warehouse_code         TEXT,
    movement_type          TEXT NOT NULL,
    quantity               NUMERIC(18,4) NOT NULL,
    unit_code              TEXT NOT NULL DEFAULT 'ADET',
    document_no            TEXT,
    document_date          DATE,
    source_reference       TEXT,
    raw_data               JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_status      TEXT NOT NULL DEFAULT 'PENDING',
    validation_errors      JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_staging_stock_entries_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number),

    CONSTRAINT import_staging_stock_entries_row_fk
        FOREIGN KEY (tenant_id, import_batch_id, row_number)
        REFERENCES public.import_staging_rows (tenant_id, import_batch_id, row_number)
        ON DELETE CASCADE,

    CONSTRAINT import_staging_stock_entries_movement_type_chk
        CHECK (movement_type IN (
            'OPENING',
            'IN',
            'OUT',
            'ADJUSTMENT',
            'TRANSFER'
        )),

    CONSTRAINT import_staging_stock_entries_quantity_chk
        CHECK (quantity <> 0),

    CONSTRAINT import_staging_stock_entries_validation_status_chk
        CHECK (validation_status IN (
            'PENDING',
            'VALID',
            'INVALID',
            'DUPLICATE',
            'SKIPPED'
        ))
);

CREATE INDEX IF NOT EXISTS import_staging_stock_product_idx
    ON public.import_staging_stock_entries (tenant_id, import_batch_id, product_code);

CREATE INDEX IF NOT EXISTS import_staging_stock_warehouse_idx
    ON public.import_staging_stock_entries (tenant_id, import_batch_id, warehouse_code);

CREATE INDEX IF NOT EXISTS import_staging_stock_document_idx
    ON public.import_staging_stock_entries (tenant_id, import_batch_id, document_no);


CREATE TABLE IF NOT EXISTS public.import_staging_finance_documents (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    document_type          TEXT NOT NULL,
    document_no            TEXT,
    document_date          DATE,
    customer_code          TEXT,
    tax_no                 TEXT,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    net_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    vat_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_amount           NUMERIC(18,2) NOT NULL DEFAULT 0,
    source_reference       TEXT,
    raw_data               JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_status      TEXT NOT NULL DEFAULT 'PENDING',
    validation_errors      JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_staging_finance_documents_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number),

    CONSTRAINT import_staging_finance_documents_row_fk
        FOREIGN KEY (tenant_id, import_batch_id, row_number)
        REFERENCES public.import_staging_rows (tenant_id, import_batch_id, row_number)
        ON DELETE CASCADE,

    CONSTRAINT import_staging_finance_documents_type_chk
        CHECK (document_type IN (
            'SALES_INVOICE',
            'PURCHASE_INVOICE',
            'RECEIPT',
            'PAYMENT',
            'COLLECTION',
            'OPENING_BALANCE',
            'OTHER'
        )),

    CONSTRAINT import_staging_finance_documents_amount_chk
        CHECK (
            net_amount >= 0
            AND vat_amount >= 0
            AND total_amount >= 0
        ),

    CONSTRAINT import_staging_finance_documents_validation_status_chk
        CHECK (validation_status IN (
            'PENDING',
            'VALID',
            'INVALID',
            'DUPLICATE',
            'SKIPPED'
        ))
);

CREATE INDEX IF NOT EXISTS import_staging_finance_document_idx
    ON public.import_staging_finance_documents (tenant_id, import_batch_id, document_type, document_no);

CREATE INDEX IF NOT EXISTS import_staging_finance_customer_idx
    ON public.import_staging_finance_documents (tenant_id, import_batch_id, customer_code);

CREATE INDEX IF NOT EXISTS import_staging_finance_tax_no_idx
    ON public.import_staging_finance_documents (tenant_id, import_batch_id, tax_no);


CREATE TABLE IF NOT EXISTS public.import_validation_errors (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    row_number             INTEGER NOT NULL,
    error_id               TEXT NOT NULL,
    entity_type            TEXT NOT NULL,
    field_name             TEXT,
    error_code             TEXT NOT NULL,
    error_message          TEXT NOT NULL,
    severity               TEXT NOT NULL DEFAULT 'ERROR',
    raw_value              TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_validation_errors_pk
        PRIMARY KEY (tenant_id, import_batch_id, row_number, error_id),

    CONSTRAINT import_validation_errors_row_fk
        FOREIGN KEY (tenant_id, import_batch_id, row_number)
        REFERENCES public.import_staging_rows (tenant_id, import_batch_id, row_number)
        ON DELETE CASCADE,

    CONSTRAINT import_validation_errors_severity_chk
        CHECK (severity IN (
            'INFO',
            'WARN',
            'ERROR',
            'BLOCKER'
        ))
);

CREATE INDEX IF NOT EXISTS import_validation_errors_batch_idx
    ON public.import_validation_errors (tenant_id, import_batch_id);

CREATE INDEX IF NOT EXISTS import_validation_errors_code_idx
    ON public.import_validation_errors (tenant_id, import_batch_id, error_code);

CREATE INDEX IF NOT EXISTS import_validation_errors_severity_idx
    ON public.import_validation_errors (tenant_id, import_batch_id, severity);


CREATE TABLE IF NOT EXISTS public.import_audit_events (
    tenant_id              TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT import_audit_events_pk
        PRIMARY KEY (tenant_id, import_batch_id, audit_event_id),

    CONSTRAINT import_audit_events_batch_fk
        FOREIGN KEY (tenant_id, import_batch_id)
        REFERENCES public.import_batches (tenant_id, import_batch_id)
        ON DELETE CASCADE,

    CONSTRAINT import_audit_events_type_chk
        CHECK (event_type IN (
            'IMPORT_BATCH_CREATED',
            'IMPORT_FILE_UPLOADED',
            'IMPORT_PARSE_STARTED',
            'IMPORT_PARSE_COMPLETED',
            'IMPORT_PARSE_FAILED',
            'IMPORT_VALIDATION_STARTED',
            'IMPORT_VALIDATION_COMPLETED',
            'IMPORT_COMMIT_STARTED',
            'IMPORT_COMMIT_COMPLETED',
            'IMPORT_COMMIT_FAILED',
            'IMPORT_ROLLBACK_REQUIRED',
            'IMPORT_ROLLED_BACK',
            'IMPORT_CANCELED'
        ))
);

CREATE INDEX IF NOT EXISTS import_audit_events_batch_idx
    ON public.import_audit_events (tenant_id, import_batch_id, created_at DESC);

CREATE INDEX IF NOT EXISTS import_audit_events_type_idx
    ON public.import_audit_events (tenant_id, import_batch_id, event_type);

-- 180 / FAZ 4-14.3 completion marker:
-- IMPORT_STAGING_TABLES_IMPLEMENTED
