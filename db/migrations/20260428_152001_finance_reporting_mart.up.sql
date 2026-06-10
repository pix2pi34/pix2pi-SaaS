CREATE SCHEMA IF NOT EXISTS reporting_mart;

CREATE TABLE IF NOT EXISTS reporting_mart.finance_daily_summaries (
    finance_daily_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    summary_date date NOT NULL,
    currency_code text NOT NULL DEFAULT 'TRY',
    gross_sales_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_sales_amount numeric(18,4) NOT NULL DEFAULT 0,
    tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    discount_amount numeric(18,4) NOT NULL DEFAULT 0,
    refund_amount numeric(18,4) NOT NULL DEFAULT 0,
    collection_amount numeric(18,4) NOT NULL DEFAULT 0,
    receivable_amount numeric(18,4) NOT NULL DEFAULT 0,
    payable_amount numeric(18,4) NOT NULL DEFAULT 0,
    journal_count integer NOT NULL DEFAULT 0 CHECK (journal_count >= 0),
    document_count integer NOT NULL DEFAULT 0 CHECK (document_count >= 0),
    source_event_count integer NOT NULL DEFAULT 0 CHECK (source_event_count >= 0),
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, summary_date, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.finance_journal_summaries (
    finance_journal_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    account_code text NOT NULL,
    account_name text,
    currency_code text NOT NULL DEFAULT 'TRY',
    debit_amount numeric(18,4) NOT NULL DEFAULT 0,
    credit_amount numeric(18,4) NOT NULL DEFAULT 0,
    balance_amount numeric(18,4) NOT NULL DEFAULT 0,
    journal_line_count integer NOT NULL DEFAULT 0 CHECK (journal_line_count >= 0),
    journal_count integer NOT NULL DEFAULT 0 CHECK (journal_count >= 0),
    first_journal_date date,
    last_journal_date date,
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, account_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.finance_tax_summaries (
    finance_tax_summary_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    tax_code text NOT NULL,
    tax_rate numeric(9,4),
    currency_code text NOT NULL DEFAULT 'TRY',
    taxable_base_amount numeric(18,4) NOT NULL DEFAULT 0,
    calculated_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    collected_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    deductible_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    net_tax_amount numeric(18,4) NOT NULL DEFAULT 0,
    document_count integer NOT NULL DEFAULT 0 CHECK (document_count >= 0),
    line_count integer NOT NULL DEFAULT 0 CHECK (line_count >= 0),
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, tax_code, currency_code)
);

CREATE TABLE IF NOT EXISTS reporting_mart.finance_tenant_kpis (
    finance_tenant_kpi_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    period_key text NOT NULL,
    currency_code text NOT NULL DEFAULT 'TRY',
    total_revenue numeric(18,4) NOT NULL DEFAULT 0,
    total_expense numeric(18,4) NOT NULL DEFAULT 0,
    gross_profit numeric(18,4) NOT NULL DEFAULT 0,
    net_cashflow numeric(18,4) NOT NULL DEFAULT 0,
    open_receivable numeric(18,4) NOT NULL DEFAULT 0,
    open_payable numeric(18,4) NOT NULL DEFAULT 0,
    sales_document_count integer NOT NULL DEFAULT 0 CHECK (sales_document_count >= 0),
    purchase_document_count integer NOT NULL DEFAULT 0 CHECK (purchase_document_count >= 0),
    active_customer_count integer NOT NULL DEFAULT 0 CHECK (active_customer_count >= 0),
    active_vendor_count integer NOT NULL DEFAULT 0 CHECK (active_vendor_count >= 0),
    last_source_event_id text,
    rebuild_version integer NOT NULL DEFAULT 1,
    generated_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_key, currency_code)
);

CREATE INDEX IF NOT EXISTS idx_finance_daily_summaries_tenant_date
    ON reporting_mart.finance_daily_summaries (tenant_id, summary_date);

CREATE INDEX IF NOT EXISTS idx_finance_daily_summaries_tenant_currency
    ON reporting_mart.finance_daily_summaries (tenant_id, currency_code);

CREATE INDEX IF NOT EXISTS idx_finance_journal_summaries_tenant_period
    ON reporting_mart.finance_journal_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_finance_journal_summaries_tenant_account
    ON reporting_mart.finance_journal_summaries (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS idx_finance_tax_summaries_tenant_period
    ON reporting_mart.finance_tax_summaries (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_finance_tax_summaries_tenant_tax
    ON reporting_mart.finance_tax_summaries (tenant_id, tax_code);

CREATE INDEX IF NOT EXISTS idx_finance_tenant_kpis_tenant_period
    ON reporting_mart.finance_tenant_kpis (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_finance_tenant_kpis_tenant_currency
    ON reporting_mart.finance_tenant_kpis (tenant_id, currency_code);
