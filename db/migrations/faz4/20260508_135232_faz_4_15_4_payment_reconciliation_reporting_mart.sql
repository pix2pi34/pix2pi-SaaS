-- 187 — FAZ 4-15.4 Payment / Reconciliation Reporting Mart
-- Purpose:
--   Tenant-safe payment and reconciliation reporting mart foundation for FAZ 4-R DB-L6 Reporting / Readmodel.
-- Policy:
--   Reporting mart is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.payment_report_periods (
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

    CONSTRAINT payment_report_periods_pk
        PRIMARY KEY (tenant_id, period_id),

    CONSTRAINT payment_report_periods_unique_month
        UNIQUE (tenant_id, fiscal_year, fiscal_month),

    CONSTRAINT payment_report_periods_month_chk
        CHECK (fiscal_month BETWEEN 1 AND 12),

    CONSTRAINT payment_report_periods_dates_chk
        CHECK (period_end >= period_start),

    CONSTRAINT payment_report_periods_status_chk
        CHECK (status IN (
            'OPEN',
            'LOCKED',
            'CLOSED',
            'REBUILD_REQUIRED'
        ))
);

CREATE INDEX IF NOT EXISTS payment_report_periods_year_month_idx
    ON public.payment_report_periods (tenant_id, fiscal_year, fiscal_month);

CREATE INDEX IF NOT EXISTS payment_report_periods_status_idx
    ON public.payment_report_periods (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.payment_attempts_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    payment_attempt_id     TEXT NOT NULL,
    provider_code          TEXT NOT NULL,
    payment_channel        TEXT NOT NULL,
    operation_type         TEXT NOT NULL,
    status                 TEXT NOT NULL,
    amount                 NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    provider_transaction_id TEXT,
    idempotency_key        TEXT,
    correlation_id         TEXT NOT NULL,
    source_event_id        TEXT,
    attempted_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at           TIMESTAMPTZ,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_attempts_mart_pk
        PRIMARY KEY (tenant_id, period_id, payment_attempt_id),

    CONSTRAINT payment_attempts_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.payment_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT payment_attempts_operation_type_chk
        CHECK (operation_type IN (
            'AUTHORIZE',
            'CAPTURE',
            'REFUND',
            'VOID',
            'WEBHOOK_VERIFY',
            'SIMULATION'
        )),

    CONSTRAINT payment_attempts_status_chk
        CHECK (status IN (
            'CREATED',
            'AUTHORIZED',
            'CAPTURED',
            'REFUNDED',
            'VOIDED',
            'FAILED',
            'REVIEW_REQUIRED'
        )),

    CONSTRAINT payment_attempts_channel_chk
        CHECK (payment_channel IN (
            'CARD',
            'CASH',
            'BANK_TRANSFER',
            'WALLET',
            'SIMULATION',
            'OTHER'
        )),

    CONSTRAINT payment_attempts_amount_chk
        CHECK (amount >= 0)
);

CREATE INDEX IF NOT EXISTS payment_attempts_provider_idx
    ON public.payment_attempts_mart (tenant_id, period_id, provider_code);

CREATE INDEX IF NOT EXISTS payment_attempts_status_idx
    ON public.payment_attempts_mart (tenant_id, period_id, status);

CREATE INDEX IF NOT EXISTS payment_attempts_transaction_idx
    ON public.payment_attempts_mart (tenant_id, provider_transaction_id);

CREATE INDEX IF NOT EXISTS payment_attempts_correlation_idx
    ON public.payment_attempts_mart (tenant_id, correlation_id);

CREATE INDEX IF NOT EXISTS payment_attempts_metadata_gin_idx
    ON public.payment_attempts_mart USING GIN (metadata);


CREATE TABLE IF NOT EXISTS public.payment_reconciliation_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    reconciliation_id      TEXT NOT NULL,
    provider_code          TEXT NOT NULL,
    payment_attempt_id     TEXT,
    provider_transaction_id TEXT,
    internal_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,
    provider_amount        NUMERIC(18,2) NOT NULL DEFAULT 0,
    difference_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    reconciliation_status  TEXT NOT NULL DEFAULT 'PENDING',
    matched_at             TIMESTAMPTZ,
    reviewed_by            TEXT,
    review_note            TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_reconciliation_mart_pk
        PRIMARY KEY (tenant_id, period_id, reconciliation_id),

    CONSTRAINT payment_reconciliation_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.payment_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT payment_reconciliation_status_chk
        CHECK (reconciliation_status IN (
            'PENDING',
            'MATCHED',
            'MISMATCH',
            'MISSING_INTERNAL',
            'MISSING_PROVIDER',
            'MANUAL_REVIEW',
            'RESOLVED'
        )),

    CONSTRAINT payment_reconciliation_amount_chk
        CHECK (
            internal_amount >= 0
            AND provider_amount >= 0
        )
);

CREATE INDEX IF NOT EXISTS payment_reconciliation_provider_idx
    ON public.payment_reconciliation_mart (tenant_id, period_id, provider_code);

CREATE INDEX IF NOT EXISTS payment_reconciliation_status_idx
    ON public.payment_reconciliation_mart (tenant_id, period_id, reconciliation_status);

CREATE INDEX IF NOT EXISTS payment_reconciliation_attempt_idx
    ON public.payment_reconciliation_mart (tenant_id, payment_attempt_id);

CREATE INDEX IF NOT EXISTS payment_reconciliation_transaction_idx
    ON public.payment_reconciliation_mart (tenant_id, provider_transaction_id);


CREATE TABLE IF NOT EXISTS public.payment_settlement_summary_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    settlement_summary_id  TEXT NOT NULL,
    provider_code          TEXT NOT NULL,
    settlement_date        DATE NOT NULL,
    gross_amount           NUMERIC(18,2) NOT NULL DEFAULT 0,
    fee_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    net_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    refund_amount          NUMERIC(18,2) NOT NULL DEFAULT 0,
    chargeback_amount      NUMERIC(18,2) NOT NULL DEFAULT 0,
    transaction_count      INTEGER NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    status                 TEXT NOT NULL DEFAULT 'DRAFT',
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_settlement_summary_mart_pk
        PRIMARY KEY (tenant_id, period_id, settlement_summary_id),

    CONSTRAINT payment_settlement_summary_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.payment_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT payment_settlement_summary_status_chk
        CHECK (status IN (
            'DRAFT',
            'RECONCILED',
            'MISMATCH',
            'LOCKED'
        )),

    CONSTRAINT payment_settlement_summary_amount_chk
        CHECK (
            gross_amount >= 0
            AND fee_amount >= 0
            AND net_amount >= 0
            AND refund_amount >= 0
            AND chargeback_amount >= 0
            AND transaction_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS payment_settlement_summary_provider_idx
    ON public.payment_settlement_summary_mart (tenant_id, period_id, provider_code);

CREATE INDEX IF NOT EXISTS payment_settlement_summary_date_idx
    ON public.payment_settlement_summary_mart (tenant_id, settlement_date);


CREATE TABLE IF NOT EXISTS public.payment_fee_summary_mart (
    tenant_id              TEXT NOT NULL,
    period_id              TEXT NOT NULL,
    fee_summary_id         TEXT NOT NULL,
    provider_code          TEXT NOT NULL,
    fee_type               TEXT NOT NULL,
    fee_amount             NUMERIC(18,2) NOT NULL DEFAULT 0,
    base_amount            NUMERIC(18,2) NOT NULL DEFAULT 0,
    effective_rate         NUMERIC(8,4) NOT NULL DEFAULT 0,
    currency_code          TEXT NOT NULL DEFAULT 'TRY',
    transaction_count      INTEGER NOT NULL DEFAULT 0,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_fee_summary_mart_pk
        PRIMARY KEY (tenant_id, period_id, fee_summary_id),

    CONSTRAINT payment_fee_summary_period_fk
        FOREIGN KEY (tenant_id, period_id)
        REFERENCES public.payment_report_periods (tenant_id, period_id)
        ON DELETE CASCADE,

    CONSTRAINT payment_fee_summary_type_chk
        CHECK (fee_type IN (
            'PROVIDER_COMMISSION',
            'BANK_COMMISSION',
            'PLATFORM_COMMISSION',
            'REFUND_FEE',
            'CHARGEBACK_FEE',
            'OTHER'
        )),

    CONSTRAINT payment_fee_summary_amount_chk
        CHECK (
            fee_amount >= 0
            AND base_amount >= 0
            AND effective_rate >= 0
            AND transaction_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS payment_fee_summary_provider_idx
    ON public.payment_fee_summary_mart (tenant_id, period_id, provider_code);

CREATE INDEX IF NOT EXISTS payment_fee_summary_type_idx
    ON public.payment_fee_summary_mart (tenant_id, period_id, fee_type);


CREATE TABLE IF NOT EXISTS public.payment_reporting_projection_offsets (
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

    CONSTRAINT payment_reporting_projection_offsets_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT payment_reporting_projection_offsets_status_chk
        CHECK (status IN (
            'ACTIVE',
            'PAUSED',
            'ERROR',
            'REBUILDING',
            'DISABLED'
        )),

    CONSTRAINT payment_reporting_projection_offsets_seq_chk
        CHECK (last_sequence >= 0 AND lag_count >= 0)
);

CREATE INDEX IF NOT EXISTS payment_reporting_projection_offsets_stream_idx
    ON public.payment_reporting_projection_offsets (tenant_id, stream_name, consumer_name);

CREATE INDEX IF NOT EXISTS payment_reporting_projection_offsets_status_idx
    ON public.payment_reporting_projection_offsets (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.payment_reporting_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    period_id              TEXT,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_reporting_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT payment_reporting_audit_events_type_chk
        CHECK (event_type IN (
            'PAYMENT_ATTEMPT_PROJECTED',
            'PAYMENT_RECONCILIATION_MATCHED',
            'PAYMENT_RECONCILIATION_MISMATCH',
            'PAYMENT_SETTLEMENT_PROJECTED',
            'PAYMENT_FEE_PROJECTED',
            'PAYMENT_REPORTING_REBUILD_STARTED',
            'PAYMENT_REPORTING_REBUILD_COMPLETED',
            'PAYMENT_REPORTING_REBUILD_FAILED'
        ))
);

CREATE INDEX IF NOT EXISTS payment_reporting_audit_events_projection_idx
    ON public.payment_reporting_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS payment_reporting_audit_events_period_idx
    ON public.payment_reporting_audit_events (tenant_id, period_id);

CREATE INDEX IF NOT EXISTS payment_reporting_audit_events_correlation_idx
    ON public.payment_reporting_audit_events (tenant_id, correlation_id);

-- 187 / FAZ 4-15.4 completion marker:
-- PAYMENT_RECONCILIATION_REPORTING_MART_IMPLEMENTED
