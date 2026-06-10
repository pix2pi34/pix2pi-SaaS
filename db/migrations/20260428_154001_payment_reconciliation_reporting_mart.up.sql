CREATE SCHEMA IF NOT EXISTS reporting_mart;

CREATE TABLE IF NOT EXISTS reporting_mart.payment_attempt_summaries (
    payment_attempt_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    summary_date date NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    payment_method text NOT NULL DEFAULT 'unknown',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    success_count integer NOT NULL DEFAULT 0 CHECK (success_count >= 0),
    failed_count integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    cancelled_count integer NOT NULL DEFAULT 0 CHECK (cancelled_count >= 0),
    refunded_count integer NOT NULL DEFAULT 0 CHECK (refunded_count >= 0),
    total_attempt_amount numeric(18,4) NOT NULL DEFAULT 0,
    authorized_amount numeric(18,4) NOT NULL DEFAULT 0,
    captured_amount numeric(18,4) NOT NULL DEFAULT 0,
    refunded_amount numeric(18,4) NOT NULL DEFAULT 0,
    failed_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_payment_attempt_id text,
    last_error_code text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, summary_date, provider_code, payment_method, status_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.payment_provider_summaries (
    payment_provider_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    payment_method text NOT NULL DEFAULT 'all',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    transaction_count integer NOT NULL DEFAULT 0 CHECK (transaction_count >= 0),
    successful_transaction_count integer NOT NULL DEFAULT 0 CHECK (successful_transaction_count >= 0),
    failed_transaction_count integer NOT NULL DEFAULT 0 CHECK (failed_transaction_count >= 0),
    total_transaction_amount numeric(18,4) NOT NULL DEFAULT 0,
    successful_transaction_amount numeric(18,4) NOT NULL DEFAULT 0,
    failed_transaction_amount numeric(18,4) NOT NULL DEFAULT 0,
    provider_fee_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_provider_amount numeric(18,4) NOT NULL DEFAULT 0,
    success_rate numeric(9,4) NOT NULL DEFAULT 0,
    last_payment_attempt_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, payment_method, status_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.settlement_summaries (
    settlement_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    settlement_date date NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    settlement_status text NOT NULL DEFAULT 'all',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    settlement_count integer NOT NULL DEFAULT 0 CHECK (settlement_count >= 0),
    transaction_count integer NOT NULL DEFAULT 0 CHECK (transaction_count >= 0),
    gross_settlement_amount numeric(18,4) NOT NULL DEFAULT 0,
    provider_fee_amount numeric(18,4) NOT NULL DEFAULT 0,
    chargeback_amount numeric(18,4) NOT NULL DEFAULT 0,
    refund_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_settlement_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_settlement_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, settlement_date, provider_code, settlement_status, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.reconciliation_difference_summaries (
    reconciliation_difference_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL,
    difference_type text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    currency_code text NOT NULL DEFAULT 'TRY',
    difference_count integer NOT NULL DEFAULT 0 CHECK (difference_count >= 0),
    blocking_difference_count integer NOT NULL DEFAULT 0 CHECK (blocking_difference_count >= 0),
    system_amount numeric(18,4) NOT NULL DEFAULT 0,
    provider_amount numeric(18,4) NOT NULL DEFAULT 0,
    difference_amount numeric(18,4) NOT NULL DEFAULT 0,
    resolved_amount numeric(18,4) NOT NULL DEFAULT 0,
    open_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_reconciliation_id text,
    last_difference_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, difference_type, status_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.commission_summaries (
    commission_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL DEFAULT 'ALL',
    commission_type text NOT NULL DEFAULT 'platform',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    source_transaction_count integer NOT NULL DEFAULT 0 CHECK (source_transaction_count >= 0),
    gross_amount numeric(18,4) NOT NULL DEFAULT 0,
    tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    platform_commission_amount numeric(18,4) NOT NULL DEFAULT 0,
    payment_fee_amount numeric(18,4) NOT NULL DEFAULT 0,
    partner_commission_amount numeric(18,4) NOT NULL DEFAULT 0,
    merchant_net_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_commission_event_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, commission_type, status_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.merchant_payout_summaries (
    merchant_payout_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    payout_date date NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL DEFAULT 'ALL',
    merchant_account_id text NOT NULL DEFAULT 'ALL',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    payout_count integer NOT NULL DEFAULT 0 CHECK (payout_count >= 0),
    transaction_count integer NOT NULL DEFAULT 0 CHECK (transaction_count >= 0),
    gross_payout_amount numeric(18,4) NOT NULL DEFAULT 0,
    commission_amount numeric(18,4) NOT NULL DEFAULT 0,
    fee_amount numeric(18,4) NOT NULL DEFAULT 0,
    withheld_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_payout_amount numeric(18,4) NOT NULL DEFAULT 0,
    last_payout_id text,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, payout_date, provider_code, merchant_account_id, status_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.payment_reconciliation_tenant_kpis (
    payment_reconciliation_tenant_kpi_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    provider_code text NOT NULL DEFAULT 'ALL',
    status_code text NOT NULL DEFAULT 'all',
    currency_code text NOT NULL DEFAULT 'TRY',
    total_payment_attempts integer NOT NULL DEFAULT 0 CHECK (total_payment_attempts >= 0),
    successful_payment_attempts integer NOT NULL DEFAULT 0 CHECK (successful_payment_attempts >= 0),
    failed_payment_attempts integer NOT NULL DEFAULT 0 CHECK (failed_payment_attempts >= 0),
    total_payment_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_settlement_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_difference_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_commission_amount numeric(18,4) NOT NULL DEFAULT 0,
    total_payout_amount numeric(18,4) NOT NULL DEFAULT 0,
    open_reconciliation_amount numeric(18,4) NOT NULL DEFAULT 0,
    payment_success_rate numeric(9,4) NOT NULL DEFAULT 0,
    reconciliation_match_rate numeric(9,4) NOT NULL DEFAULT 0,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, provider_code, status_code, currency_code)
);

CREATE INDEX IF NOT EXISTS idx_payment_attempt_tenant_date
    ON reporting_mart.payment_attempt_summaries (tenant_id, summary_date);

CREATE INDEX IF NOT EXISTS idx_payment_attempt_tenant_provider_status
    ON reporting_mart.payment_attempt_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_payment_provider_tenant_period
    ON reporting_mart.payment_provider_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_payment_provider_tenant_provider_status
    ON reporting_mart.payment_provider_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_settlement_tenant_date
    ON reporting_mart.settlement_summaries (tenant_id, settlement_date);

CREATE INDEX IF NOT EXISTS idx_settlement_tenant_provider_status
    ON reporting_mart.settlement_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_reconciliation_diff_tenant_period
    ON reporting_mart.reconciliation_difference_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_reconciliation_diff_tenant_provider_status
    ON reporting_mart.reconciliation_difference_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_commission_tenant_period
    ON reporting_mart.commission_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_commission_tenant_provider_type
    ON reporting_mart.commission_summaries (tenant_id, provider_code, commission_type);

CREATE INDEX IF NOT EXISTS idx_payout_tenant_date
    ON reporting_mart.merchant_payout_summaries (tenant_id, payout_date);

CREATE INDEX IF NOT EXISTS idx_payout_tenant_provider_status
    ON reporting_mart.merchant_payout_summaries (tenant_id, provider_code, status_code);

CREATE INDEX IF NOT EXISTS idx_payment_recon_kpi_tenant_period
    ON reporting_mart.payment_reconciliation_tenant_kpis (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_payment_recon_kpi_tenant_provider_status
    ON reporting_mart.payment_reconciliation_tenant_kpis (tenant_id, provider_code, status_code);
