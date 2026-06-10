-- FAZ 7-5P.4 Payment DB Migration / PostgreSQL Repository
-- Purpose: payment_attempts and payment_attempt_events persistence foundation.
-- This migration is tenant-safe by design.

CREATE TABLE IF NOT EXISTS payment_attempts (
    tenant_id TEXT NOT NULL,
    attempt_id TEXT NOT NULL,
    invoice_id TEXT NOT NULL,
    subscription_id TEXT NOT NULL DEFAULT '',
    provider_code TEXT NOT NULL,
    correlation_id TEXT NOT NULL,
    request_id TEXT NOT NULL DEFAULT '',
    idempotency_key TEXT NOT NULL,
    amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
    currency TEXT NOT NULL,
    status TEXT NOT NULL CHECK (
        status IN ('CREATED', 'AUTHORIZED', 'CAPTURED', 'REFUNDED', 'VOIDED', 'FAILED')
    ),
    provider_transaction_id TEXT NULL,
    failure_code TEXT NULL,
    failure_message TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT payment_attempts_pkey PRIMARY KEY (tenant_id, attempt_id),
    CONSTRAINT payment_attempts_tenant_idempotency_unique UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_tenant_provider_transaction
    ON payment_attempts (tenant_id, provider_transaction_id)
    WHERE provider_transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_payment_attempts_tenant_status
    ON payment_attempts (tenant_id, status);

CREATE TABLE IF NOT EXISTS payment_attempt_events (
    event_id BIGSERIAL PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    attempt_id TEXT NOT NULL,
    from_status TEXT NOT NULL DEFAULT '',
    to_status TEXT NOT NULL,
    operation TEXT NOT NULL DEFAULT '',
    provider_code TEXT NOT NULL,
    provider_transaction_id TEXT NULL,
    error_code TEXT NULL,
    message TEXT NOT NULL DEFAULT '',
    correlation_id TEXT NOT NULL,
    idempotency_key TEXT NOT NULL,
    audit_required BOOLEAN NOT NULL DEFAULT TRUE,
    real_payment BOOLEAN NOT NULL DEFAULT FALSE,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT payment_attempt_events_attempt_fk
        FOREIGN KEY (tenant_id, attempt_id)
        REFERENCES payment_attempts (tenant_id, attempt_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_payment_attempt_events_tenant_attempt_event
    ON payment_attempt_events (tenant_id, attempt_id, event_id);

CREATE INDEX IF NOT EXISTS idx_payment_attempt_events_tenant_correlation
    ON payment_attempt_events (tenant_id, correlation_id);
