-- 188 — FAZ 4-15.3 e-Belge / Export Reporting Mart
-- Purpose:
--   Tenant-safe e-document and export reporting mart foundation for FAZ 4-R DB-L6 Reporting / Readmodel.
-- Policy:
--   Reporting mart is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.e_document_report_periods (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    fiscal_year            INTEGER NOT NULL,
    fiscal_month           INTEGER NOT NULL,
    period_start           DATE NOT NULL,
    period_end             DATE NOT NULL,
    status                 TEXT NOT NULL DEFAULT 'OPEN',
    locked_at              TIMESTAMPTZ,
    locked_by              TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_report_periods_pk
        PRIMARY KEY (tenant_id, period_id),

    CONSTRAINT e_document_report_periods_unique_month
        UNIQUE (tenant_id, fiscal_year, fiscal_month),

    CONSTRAINT e_document_report_periods_month_chk
        CHECK (fiscal_month BETWEEN 1 AND 12),

    CONSTRAINT e_document_report_periods_dates_chk
        CHECK (period_end >= period_start),

    CONSTRAINT e_document_report_periods_status_chk
        CHECK (status IN (
            'OPEN',
            'LOCKED',
            'CLOSED',
            'REBUILD_REQUIRED'
        ))
);

CREATE INDEX IF NOT EXISTS e_document_report_periods_year_month_idx
    ON public.e_document_report_periods (tenant_id, fiscal_year, fiscal_month);

CREATE INDEX IF NOT EXISTS e_document_report_periods_status_idx
    ON public.e_document_report_periods (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.e_document_documents_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    e_document_id          TEXT NOT NULL,
    document_type          TEXT NOT NULL,
    document_no            TEXT NOT NULL,
    document_uuid          TEXT,
    scenario_type          TEXT NOT NULL DEFAULT 'BASIC',
    direction              TEXT NOT NULL,
    document_status        TEXT NOT NULL DEFAULT 'DRAFT',
    issue_date             DATE NOT NULL,
    party_id               TEXT,
    party_name             TEXT,
    tax_no                 TEXT,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    net_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    gross_amount           NUMERIC(18,2) NOT NULL DEFAULT 0,
    source_event_id        TEXT,
    source_document_ref    TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_documents_mart_pk
        PRIMARY KEY (tenant_id, period_id, e_document_id),

    CONSTRAINT e_document_documents_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.e_document_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT e_document_documents_unique_document
        UNIQUE (tenant_id, document_type, document_no),

    CONSTRAINT e_document_documents_type_chk
        CHECK (document_type IN (
            'E_FATURA',
            'E_ARSIV',
            'E_IRSALIYE',
            'E_ADISYON',
            'EXPORT_LEDGER',
            'EXPORT_ACCOUNTING',
            'OTHER'
        )),

    CONSTRAINT e_document_documents_scenario_chk
        CHECK (scenario_type IN (
            'BASIC',
            'COMMERCIAL',
            'EXPORT',
            'PUBLIC',
            'OTHER'
        )),

    CONSTRAINT e_document_documents_direction_chk
        CHECK (direction IN (
            'OUTBOUND',
            'INBOUND',
            'EXPORT'
        )),

    CONSTRAINT e_document_documents_status_chk
        CHECK (document_status IN (
            'DRAFT',
            'READY',
            'SENT',
            'ACCEPTED',
            'REJECTED',
            'CANCELED',
            'FAILED',
            'EXPORTED'
        )),

    CONSTRAINT e_document_documents_amount_chk
        CHECK (
            net_amount >= 0
            AND tax_amount >= 0
            AND gross_amount >= 0
        )
);

CREATE INDEX IF NOT EXISTS e_document_documents_type_status_idx
    ON public.e_document_documents_mart (tenant_id, period_id, document_type, document_status);

CREATE INDEX IF NOT EXISTS e_document_documents_no_idx
    ON public.e_document_documents_mart (tenant_id, document_no);

CREATE INDEX IF NOT EXISTS e_document_documents_uuid_idx
    ON public.e_document_documents_mart (tenant_id, document_uuid);

CREATE INDEX IF NOT EXISTS e_document_documents_party_idx
    ON public.e_document_documents_mart (tenant_id, period_id, party_id);

CREATE INDEX IF NOT EXISTS e_document_documents_issue_date_idx
    ON public.e_document_documents_mart (tenant_id, issue_date);

CREATE INDEX IF NOT EXISTS e_document_documents_metadata_gin_idx
    ON public.e_document_documents_mart USING GIN (metadata);


CREATE TABLE IF NOT EXISTS public.e_document_export_batches_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    export_batch_id        TEXT NOT NULL,
    export_type            TEXT NOT NULL,
    target_system          TEXT NOT NULL,
    export_status          TEXT NOT NULL DEFAULT 'CREATED',
    file_count             INTEGER NOT NULL DEFAULT 0,
    document_count         INTEGER NOT NULL DEFAULT 0,
    total_net_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_tax_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_gross_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
    requested_by           TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    error_message          TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_export_batches_mart_pk
        PRIMARY KEY (tenant_id, period_id, export_batch_id),

    CONSTRAINT e_document_export_batches_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.e_document_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT e_document_export_batches_type_chk
        CHECK (export_type IN (
            'PDF',
            'XML',
            'EXCEL',
            'CSV',
            'LOGO',
            'MIKRO',
            'ZIRVE',
            'ETA',
            'TDHP',
            'ARCHIVE'
        )),

    CONSTRAINT e_document_export_batches_status_chk
        CHECK (export_status IN (
            'CREATED',
            'RUNNING',
            'COMPLETED',
            'FAILED',
            'CANCELED'
        )),

    CONSTRAINT e_document_export_batches_count_chk
        CHECK (
            file_count >= 0
            AND document_count >= 0
            AND total_net_amount >= 0
            AND total_tax_amount >= 0
            AND total_gross_amount >= 0
        )
);

CREATE INDEX IF NOT EXISTS e_document_export_batches_type_idx
    ON public.e_document_export_batches_mart (tenant_id, period_id, export_type);

CREATE INDEX IF NOT EXISTS e_document_export_batches_status_idx
    ON public.e_document_export_batches_mart (tenant_id, period_id, export_status);

CREATE INDEX IF NOT EXISTS e_document_export_batches_target_idx
    ON public.e_document_export_batches_mart (tenant_id, target_system);


CREATE TABLE IF NOT EXISTS public.e_document_export_files_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    export_batch_id        TEXT NOT NULL,
    export_file_id         TEXT NOT NULL,
    file_name              TEXT NOT NULL,
    file_type              TEXT NOT NULL,
    file_size_bytes        BIGINT NOT NULL DEFAULT 0,
    file_checksum          TEXT,
    storage_reference      TEXT,
    document_count         INTEGER NOT NULL DEFAULT 0,
    export_status          TEXT NOT NULL DEFAULT 'CREATED',
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_export_files_mart_pk
        PRIMARY KEY (tenant_id, period_id, export_batch_id, export_file_id),

    CONSTRAINT e_document_export_files_batch_fk
        FOREIGN KEY (tenant_id, period_id, export_batch_id)
        REFERENCES public.e_document_export_batches_mart (tenant_id, period_id, export_batch_id)
        ON DELETE CASCADE,

    CONSTRAINT e_document_export_files_type_chk
        CHECK (file_type IN (
            'PDF',
            'XML',
            'XLSX',
            'CSV',
            'TXT',
            'ZIP',
            'JSON'
        )),

    CONSTRAINT e_document_export_files_status_chk
        CHECK (export_status IN (
            'CREATED',
            'WRITTEN',
            'VERIFIED',
            'FAILED',
            'DELETED'
        )),

    CONSTRAINT e_document_export_files_count_chk
        CHECK (file_size_bytes >= 0 AND document_count >= 0)
);

CREATE INDEX IF NOT EXISTS e_document_export_files_batch_idx
    ON public.e_document_export_files_mart (tenant_id, period_id, export_batch_id);

CREATE INDEX IF NOT EXISTS e_document_export_files_type_idx
    ON public.e_document_export_files_mart (tenant_id, file_type);

CREATE INDEX IF NOT EXISTS e_document_export_files_checksum_idx
    ON public.e_document_export_files_mart (tenant_id, file_checksum);


CREATE TABLE IF NOT EXISTS public.e_document_status_summary_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    summary_id             TEXT NOT NULL,
    document_type          TEXT NOT NULL,
    document_status        TEXT NOT NULL,
    direction              TEXT NOT NULL,
    document_count         INTEGER NOT NULL DEFAULT 0,
    total_net_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_tax_amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_gross_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_status_summary_mart_pk
        PRIMARY KEY (tenant_id, period_id, summary_id),

    CONSTRAINT e_document_status_summary_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.e_document_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT e_document_status_summary_count_chk
        CHECK (
            document_count >= 0
            AND total_net_amount >= 0
            AND total_tax_amount >= 0
            AND total_gross_amount >= 0
        )
);

CREATE INDEX IF NOT EXISTS e_document_status_summary_type_idx
    ON public.e_document_status_summary_mart (tenant_id, period_id, document_type);

CREATE INDEX IF NOT EXISTS e_document_status_summary_status_idx
    ON public.e_document_status_summary_mart (tenant_id, period_id, document_status);

CREATE INDEX IF NOT EXISTS e_document_status_summary_direction_idx
    ON public.e_document_status_summary_mart (tenant_id, period_id, direction);


CREATE TABLE IF NOT EXISTS public.e_document_reporting_projection_offsets (
    tenant_id              TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    stream_name            TEXT NOT NULL,
    consumer_name          TEXT NOT NULL,
    last_event_id          TEXT,
    last_sequence          BIGINT NOT NULL DEFAULT 0,
    status                 TEXT NOT NULL DEFAULT 'ACTIVE',
    lag_count              BIGINT NOT NULL DEFAULT 0,
    last_projected_at      TIMESTAMPTZ,
    last_error             TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_reporting_projection_offsets_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT e_document_reporting_projection_offsets_status_chk
        CHECK (status IN (
            'ACTIVE',
            'PAUSED',
            'ERROR',
            'REBUILDING',
            'DISABLED'
        )),

    CONSTRAINT e_document_reporting_projection_offsets_seq_chk
        CHECK (last_sequence >= 0 AND lag_count >= 0)
);

CREATE INDEX IF NOT EXISTS e_document_reporting_projection_offsets_stream_idx
    ON public.e_document_reporting_projection_offsets (tenant_id, stream_name, consumer_name);

CREATE INDEX IF NOT EXISTS e_document_reporting_projection_offsets_status_idx
    ON public.e_document_reporting_projection_offsets (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.e_document_reporting_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    period_id              TEXT,
    document_type          TEXT,
    e_document_id          TEXT,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT e_document_reporting_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT e_document_reporting_audit_events_type_chk
        CHECK (event_type IN (
            'E_DOCUMENT_PROJECTED',
            'E_DOCUMENT_STATUS_SUMMARY_PROJECTED',
            'E_DOCUMENT_EXPORT_BATCH_CREATED',
            'E_DOCUMENT_EXPORT_BATCH_COMPLETED',
            'E_DOCUMENT_EXPORT_BATCH_FAILED',
            'E_DOCUMENT_EXPORT_FILE_WRITTEN',
            'E_DOCUMENT_REPORTING_REBUILD_STARTED',
            'E_DOCUMENT_REPORTING_REBUILD_COMPLETED',
            'E_DOCUMENT_REPORTING_REBUILD_FAILED'
        ))
);

CREATE INDEX IF NOT EXISTS e_document_reporting_audit_events_projection_idx
    ON public.e_document_reporting_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS e_document_reporting_audit_events_period_idx
    ON public.e_document_reporting_audit_events (tenant_id, period_id);

CREATE INDEX IF NOT EXISTS e_document_reporting_audit_events_document_idx
    ON public.e_document_reporting_audit_events (tenant_id, document_type, e_document_id);

CREATE INDEX IF NOT EXISTS e_document_reporting_audit_events_correlation_idx
    ON public.e_document_reporting_audit_events (tenant_id, correlation_id);

-- 188 / FAZ 4-15.3 completion marker:
-- E_DOCUMENT_EXPORT_REPORTING_MART_IMPLEMENTED
