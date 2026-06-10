CREATE SCHEMA IF NOT EXISTS reporting_mart;

CREATE TABLE IF NOT EXISTS reporting_mart.ebelge_daily_summaries (
    ebelge_daily_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    summary_date date NOT NULL,
    period_key text NOT NULL,
    ebelge_type text NOT NULL,
    status_code text NOT NULL DEFAULT 'all',
    issued_count integer NOT NULL DEFAULT 0 CHECK (issued_count >= 0),
    sent_count integer NOT NULL DEFAULT 0 CHECK (sent_count >= 0),
    accepted_count integer NOT NULL DEFAULT 0 CHECK (accepted_count >= 0),
    rejected_count integer NOT NULL DEFAULT 0 CHECK (rejected_count >= 0),
    cancelled_count integer NOT NULL DEFAULT 0 CHECK (cancelled_count >= 0),
    failed_count integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    total_gross_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_net_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_document_id text,
    last_error_code text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, summary_date, ebelge_type, status_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.ebelge_document_status_summaries (
    ebelge_document_status_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    ebelge_type text NOT NULL,
    status_code text NOT NULL,
    direction text NOT NULL DEFAULT 'outbound',
    document_count integer NOT NULL DEFAULT 0 CHECK (document_count >= 0),
    total_gross_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_net_amount numeric(18,4) NOT NULL DEFAULT 0,
    first_document_date date,
    last_document_date date,
    last_document_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, ebelge_type, status_code, direction)
);

CREATE TABLE IF NOT EXISTS reporting_mart.ebelge_error_summaries (
    ebelge_error_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    ebelge_type text NOT NULL,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    blocking_count integer NOT NULL DEFAULT 0 CHECK (blocking_count >= 0),
    retryable_count integer NOT NULL DEFAULT 0 CHECK (retryable_count >= 0),
    last_error_message text,
    last_document_id text,
    last_seen_at timestamptz,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, ebelge_type, error_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.accounting_export_batch_summaries (
    accounting_export_batch_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    export_type text NOT NULL DEFAULT 'accounting',
    status_code text NOT NULL,
    batch_count integer NOT NULL DEFAULT 0 CHECK (batch_count >= 0),
    file_count integer NOT NULL DEFAULT 0 CHECK (file_count >= 0),
    record_count integer NOT NULL DEFAULT 0 CHECK (record_count >= 0),
    success_count integer NOT NULL DEFAULT 0 CHECK (success_count >= 0),
    failed_count integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    last_export_batch_id text,
    last_file_uri text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, export_type, status_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.accounting_export_provider_summaries (
    accounting_export_provider_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    export_type text NOT NULL DEFAULT 'accounting',
    status_code text NOT NULL DEFAULT 'all',
    exported_debit_amount numeric(18,4) NOT NULL DEFAULT 0,
    exported_credit_amount numeric(18,4) NOT NULL DEFAULT 0,
    exported_balance_amount numeric(18,4) NOT NULL DEFAULT 0,
    exported_document_count integer NOT NULL DEFAULT 0 CHECK (exported_document_count >= 0),
    exported_journal_count integer NOT NULL DEFAULT 0 CHECK (exported_journal_count >= 0),
    exported_line_count integer NOT NULL DEFAULT 0 CHECK (exported_line_count >= 0),
    pending_count integer NOT NULL DEFAULT 0 CHECK (pending_count >= 0),
    failed_count integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    last_success_at timestamptz,
    last_failure_at timestamptz,
    last_export_batch_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, export_type, status_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.accounting_export_error_summaries (
    accounting_export_error_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    export_type text NOT NULL DEFAULT 'accounting',
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    blocking_count integer NOT NULL DEFAULT 0 CHECK (blocking_count >= 0),
    retryable_count integer NOT NULL DEFAULT 0 CHECK (retryable_count >= 0),
    last_error_message text,
    last_export_batch_id text,
    last_seen_at timestamptz,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, export_type, error_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.accounting_export_tenant_kpis (
    accounting_export_tenant_kpi_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL DEFAULT 'ALL',
    export_type text NOT NULL DEFAULT 'accounting',
    status_code text NOT NULL DEFAULT 'all',
    total_export_amount numeric(18,4) NOT NULL DEFAULT 0,
    successful_export_amount numeric(18,4) NOT NULL DEFAULT 0,
    failed_export_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_export_batches integer NOT NULL DEFAULT 0 CHECK (total_export_batches >= 0),
    total_export_files integer NOT NULL DEFAULT 0 CHECK (total_export_files >= 0),
    total_export_records integer NOT NULL DEFAULT 0 CHECK (total_export_records >= 0),
    successful_export_batches integer NOT NULL DEFAULT 0 CHECK (successful_export_batches >= 0),
    failed_export_batches integer NOT NULL DEFAULT 0 CHECK (failed_export_batches >= 0),
    pending_export_batches integer NOT NULL DEFAULT 0 CHECK (pending_export_batches >= 0),
    export_success_rate numeric(9,4) NOT NULL DEFAULT 0,
    last_export_at timestamptz,
    last_failure_at timestamptz,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, export_type, status_code)
);

CREATE INDEX IF NOT EXISTS idx_ebelge_daily_tenant_date
    ON reporting_mart.ebelge_daily_summaries (tenant_id, summary_date);

CREATE INDEX IF NOT EXISTS idx_ebelge_daily_tenant_type_status
    ON reporting_mart.ebelge_daily_summaries (tenant_id, ebelge_type, status_code);

CREATE INDEX IF NOT EXISTS idx_ebelge_status_tenant_period
    ON reporting_mart.ebelge_document_status_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_ebelge_status_tenant_type_status
    ON reporting_mart.ebelge_document_status_summaries (tenant_id, ebelge_type, status_code);

CREATE INDEX IF NOT EXISTS idx_ebelge_error_tenant_period
    ON reporting_mart.ebelge_error_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_ebelge_error_tenant_type_error
    ON reporting_mart.ebelge_error_summaries (tenant_id, ebelge_type, error_code);

CREATE INDEX IF NOT EXISTS idx_export_batch_tenant_period
    ON reporting_mart.accounting_export_batch_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_export_batch_tenant_provider_status
    ON reporting_mart.accounting_export_batch_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_export_provider_tenant_period
    ON reporting_mart.accounting_export_provider_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_export_provider_tenant_provider
    ON reporting_mart.accounting_export_provider_summaries (tenant_id, provider_code);

CREATE INDEX IF NOT EXISTS idx_export_provider_tenant_status
    ON reporting_mart.accounting_export_provider_summaries (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_export_error_tenant_period
    ON reporting_mart.accounting_export_error_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_export_error_tenant_provider_error
    ON reporting_mart.accounting_export_error_summaries (tenant_id, provider_code, error_code);

CREATE INDEX IF NOT EXISTS idx_export_kpi_tenant_period
    ON reporting_mart.accounting_export_tenant_kpis (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_export_kpi_tenant_provider
    ON reporting_mart.accounting_export_tenant_kpis (tenant_id, provider_code);

CREATE INDEX IF NOT EXISTS idx_export_kpi_tenant_status
    ON reporting_mart.accounting_export_tenant_kpis (tenant_id, status_code);
