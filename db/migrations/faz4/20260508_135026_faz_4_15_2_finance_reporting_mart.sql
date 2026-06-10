-- 186 — FAZ 4-15.2 Finance Reporting Mart
-- Purpose:
--   Tenant-safe finance reporting mart foundation for FAZ 4-R DB-L6 Reporting / Readmodel.
-- Policy:
--   Reporting mart is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.finance_report_periods (
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

    CONSTRAINT finance_report_periods_pk
        PRIMARY KEY (tenant_id, period_id),

    CONSTRAINT finance_report_periods_unique_month
        UNIQUE (tenant_id, fiscal_year, fiscal_month),

    CONSTRAINT finance_report_periods_month_chk
        CHECK (fiscal_month BETWEEN 1 AND 12),

    CONSTRAINT finance_report_periods_dates_chk
        CHECK (period_end >= period_start),

    CONSTRAINT finance_report_periods_status_chk
        CHECK (status IN (
            'OPEN',
            'LOCKED',
            'CLOSED',
            'REBUILD_REQUIRED'
        ))
);

CREATE INDEX IF NOT EXISTS finance_report_periods_year_month_idx
    ON public.finance_report_periods (tenant_id, fiscal_year, fiscal_month);

CREATE INDEX IF NOT EXISTS finance_report_periods_status_idx
    ON public.finance_report_periods (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.finance_account_balances_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    account_code           TEXT NOT NULL,
    account_name           TEXT NOT NULL,
    account_type           TEXT NOT NULL DEFAULT 'UNKNOWN',
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    opening_debit          NUMERIC(18,2) NOT NULL DEFAULT 0,
    opening_credit         NUMERIC(18,2) NOT NULL DEFAULT 0,
    period_debit           NUMERIC(18,2) NOT NULL DEFAULT 0,
    period_credit          NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_debit          NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_credit         NUMERIC(18,2) NOT NULL DEFAULT 0,
    source_event_id        TEXT,
    projection_version     INTEGER NOT NULL DEFAULT 1,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT finance_account_balances_mart_pk
        PRIMARY KEY (tenant_id, period_id, account_code, currency_code),

    CONSTRAINT finance_account_balances_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.finance_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT finance_account_balances_type_chk
        CHECK (account_type IN (
            'ASSET',
            'LIABILITY',
            'EQUITY',
            'REVENUE',
            'EXPENSE',
            'TAX',
            'CASH',
            'BANK',
            'RECEIVABLE',
            'PAYABLE',
            'UNKNOWN'
        )),

    CONSTRAINT finance_account_balances_amount_chk
        CHECK (
            opening_debit >= 0
            AND opening_credit >= 0
            AND period_debit >= 0
            AND period_credit >= 0
            AND closing_debit >= 0
            AND closing_credit >= 0
        ),

    CONSTRAINT finance_account_balances_projection_version_chk
        CHECK (projection_version > 0)
);

CREATE INDEX IF NOT EXISTS finance_account_balances_account_idx
    ON public.finance_account_balances_mart (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS finance_account_balances_period_idx
    ON public.finance_account_balances_mart (tenant_id, period_id);

CREATE INDEX IF NOT EXISTS finance_account_balances_type_idx
    ON public.finance_account_balances_mart (tenant_id, period_id, account_type);

CREATE INDEX IF NOT EXISTS finance_account_balances_payload_gin_idx
    ON public.finance_account_balances_mart USING GIN (metadata);


CREATE TABLE IF NOT EXISTS public.finance_income_expense_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    report_line_id         TEXT NOT NULL,
    line_type              TEXT NOT NULL,
    line_code              TEXT NOT NULL,
    line_name              TEXT NOT NULL,
    amount                 NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    source_account_codes   JSONB NOT NULL DEFAULT '[]'::jsonb,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT finance_income_expense_mart_pk
        PRIMARY KEY (tenant_id, period_id, report_line_id),

    CONSTRAINT finance_income_expense_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.finance_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT finance_income_expense_line_type_chk
        CHECK (line_type IN (
            'REVENUE',
            'COGS',
            'GROSS_PROFIT',
            'OPERATING_EXPENSE',
            'OPERATING_PROFIT',
            'TAX',
            'NET_PROFIT',
            'OTHER'
        ))
);

CREATE INDEX IF NOT EXISTS finance_income_expense_line_type_idx
    ON public.finance_income_expense_mart (tenant_id, period_id, line_type);

CREATE INDEX IF NOT EXISTS finance_income_expense_amount_idx
    ON public.finance_income_expense_mart (tenant_id, period_id, amount DESC);


CREATE TABLE IF NOT EXISTS public.finance_tax_summary_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    tax_summary_id         TEXT NOT NULL,
    tax_type               TEXT NOT NULL,
    tax_rate               NUMERIC(5,2) NOT NULL DEFAULT 0,
    taxable_amount         NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    direction              TEXT NOT NULL DEFAULT 'OUTPUT',
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    source_document_count  INTEGER NOT NULL DEFAULT 0,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT finance_tax_summary_mart_pk
        PRIMARY KEY (tenant_id, period_id, tax_summary_id),

    CONSTRAINT finance_tax_summary_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.finance_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT finance_tax_summary_type_chk
        CHECK (tax_type IN (
            'KDV',
            'STOPAJ',
            'OTV',
            'OTHER'
        )),

    CONSTRAINT finance_tax_summary_direction_chk
        CHECK (direction IN (
            'INPUT',
            'OUTPUT',
            'NET'
        )),

    CONSTRAINT finance_tax_summary_amount_chk
        CHECK (
            tax_rate >= 0
            AND taxable_amount >= 0
            AND tax_amount >= 0
            AND source_document_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS finance_tax_summary_type_idx
    ON public.finance_tax_summary_mart (tenant_id, period_id, tax_type, direction);

CREATE INDEX IF NOT EXISTS finance_tax_summary_rate_idx
    ON public.finance_tax_summary_mart (tenant_id, period_id, tax_rate);


CREATE TABLE IF NOT EXISTS public.finance_ar_ap_aging_mart (
    tenant_id              TEXT NOT NULL,
    aging_id               TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    party_id               TEXT NOT NULL,
    party_type             TEXT NOT NULL,
    party_name             TEXT NOT NULL,
    account_code           TEXT,
    document_ref           TEXT,
    due_date               DATE,
    bucket                 TEXT NOT NULL,
    outstanding_amount     NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT finance_ar_ap_aging_mart_pk
        PRIMARY KEY (tenant_id, aging_id),

    CONSTRAINT finance_ar_ap_aging_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.finance_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT finance_ar_ap_aging_party_type_chk
        CHECK (party_type IN (
            'CUSTOMER',
            'SUPPLIER',
            'EMPLOYEE',
            'OTHER'
        )),

    CONSTRAINT finance_ar_ap_aging_bucket_chk
        CHECK (bucket IN (
            'CURRENT',
            'DUE_1_30',
            'DUE_31_60',
            'DUE_61_90',
            'DUE_90_PLUS',
            'UNKNOWN'
        )),

    CONSTRAINT finance_ar_ap_aging_amount_chk
        CHECK (outstanding_amount >= 0)
);

CREATE INDEX IF NOT EXISTS finance_ar_ap_aging_party_idx
    ON public.finance_ar_ap_aging_mart (tenant_id, period_id, party_type, party_id);

CREATE INDEX IF NOT EXISTS finance_ar_ap_aging_bucket_idx
    ON public.finance_ar_ap_aging_mart (tenant_id, period_id, bucket);

CREATE INDEX IF NOT EXISTS finance_ar_ap_aging_due_date_idx
    ON public.finance_ar_ap_aging_mart (tenant_id, due_date);


CREATE TABLE IF NOT EXISTS public.finance_reporting_projection_offsets (
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

    CONSTRAINT finance_reporting_projection_offsets_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT finance_reporting_projection_offsets_status_chk
        CHECK (status IN (
            'ACTIVE',
            'PAUSED',
            'ERROR',
            'REBUILDING',
            'DISABLED'
        )),

    CONSTRAINT finance_reporting_projection_offsets_seq_chk
        CHECK (last_sequence >= 0 AND lag_count >= 0)
);

CREATE INDEX IF NOT EXISTS finance_reporting_projection_offsets_stream_idx
    ON public.finance_reporting_projection_offsets (tenant_id, stream_name, consumer_name);

CREATE INDEX IF NOT EXISTS finance_reporting_projection_offsets_status_idx
    ON public.finance_reporting_projection_offsets (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.finance_reporting_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    period_id              TEXT,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT finance_reporting_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT finance_reporting_audit_events_type_chk
        CHECK (event_type IN (
            'FINANCE_PERIOD_CREATED',
            'FINANCE_PERIOD_LOCKED',
            'FINANCE_ACCOUNT_BALANCE_PROJECTED',
            'FINANCE_INCOME_EXPENSE_PROJECTED',
            'FINANCE_TAX_SUMMARY_PROJECTED',
            'FINANCE_AR_AP_AGING_PROJECTED',
            'FINANCE_REPORTING_REBUILD_STARTED',
            'FINANCE_REPORTING_REBUILD_COMPLETED',
            'FINANCE_REPORTING_REBUILD_FAILED'
        ))
);

CREATE INDEX IF NOT EXISTS finance_reporting_audit_events_projection_idx
    ON public.finance_reporting_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS finance_reporting_audit_events_period_idx
    ON public.finance_reporting_audit_events (tenant_id, period_id);

CREATE INDEX IF NOT EXISTS finance_reporting_audit_events_correlation_idx
    ON public.finance_reporting_audit_events (tenant_id, correlation_id);

-- 186 / FAZ 4-15.2 completion marker:
-- FINANCE_REPORTING_MART_IMPLEMENTED
