BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.payment_methods (
    tenant_id uuid NOT NULL,
    payment_method_id uuid NOT NULL DEFAULT gen_random_uuid(),

    method_code varchar(96) NOT NULL,
    method_name varchar(255) NOT NULL,
    method_type varchar(64) NOT NULL,

    provider_code varchar(64),
    bank_code varchar(64),
    pos_provider_code varchar(64),

    default_cash_account_code varchar(32),
    default_bank_account_code varchar(32),
    default_receivable_account_code varchar(32),
    default_payable_account_code varchar(32),
    default_commission_account_code varchar(32),

    settlement_delay_days integer NOT NULL DEFAULT 0,
    commission_rate numeric(9,4) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    description text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT payment_methods_pk PRIMARY KEY (tenant_id, payment_method_id),
    CONSTRAINT payment_methods_code_unique UNIQUE (tenant_id, method_code),
    CONSTRAINT payment_methods_type_chk CHECK (
        method_type IN (
            'CASH',
            'BANK_TRANSFER',
            'CREDIT_CARD',
            'DEBIT_CARD',
            'VIRTUAL_POS',
            'WALLET',
            'MARKETPLACE_SETTLEMENT',
            'CHEQUE',
            'PROMISSORY_NOTE',
            'OTHER'
        )
    ),
    CONSTRAINT payment_methods_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT payment_methods_amount_chk CHECK (
        settlement_delay_days >= 0
        AND commission_rate >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.payment_transactions (
    tenant_id uuid NOT NULL,
    payment_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),

    transaction_no varchar(128) NOT NULL,
    transaction_type varchar(64) NOT NULL,
    transaction_direction varchar(16) NOT NULL,

    payment_method_id uuid,
    payment_method_code varchar(96),

    party_id uuid,
    party_type varchar(40),
    party_code varchar(96),
    party_title varchar(255),

    transaction_date date NOT NULL DEFAULT CURRENT_DATE,
    value_date date,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18,8) NOT NULL DEFAULT 1,

    gross_amount numeric(18,2) NOT NULL DEFAULT 0,
    commission_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount numeric(18,2) NOT NULL DEFAULT 0,
    net_amount numeric(18,2) NOT NULL DEFAULT 0,

    provider_code varchar(64),
    provider_transaction_id varchar(160),
    bank_reference_no varchar(160),
    authorization_code varchar(96),

    status varchar(40) NOT NULL DEFAULT 'DRAFT',
    settlement_status varchar(40) NOT NULL DEFAULT 'UNSETTLED',

    source_module varchar(64),
    source_document_type varchar(64),
    source_document_id uuid,
    source_document_no varchar(96),

    journal_id uuid,
    ledger_posting_batch_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT payment_transactions_pk PRIMARY KEY (tenant_id, payment_transaction_id),
    CONSTRAINT payment_transactions_no_unique UNIQUE (tenant_id, transaction_no),
    CONSTRAINT payment_transactions_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT payment_transactions_method_fk FOREIGN KEY (tenant_id, payment_method_id)
        REFERENCES erp.payment_methods (tenant_id, payment_method_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_transactions_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_transactions_journal_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_transactions_ledger_batch_fk FOREIGN KEY (tenant_id, ledger_posting_batch_id)
        REFERENCES erp.ledger_posting_batches (tenant_id, ledger_posting_batch_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_transactions_type_chk CHECK (
        transaction_type IN (
            'PAYMENT',
            'COLLECTION',
            'REFUND',
            'CHARGEBACK',
            'SETTLEMENT',
            'COMMISSION',
            'ADJUSTMENT',
            'RECONCILIATION'
        )
    ),
    CONSTRAINT payment_transactions_direction_chk CHECK (
        transaction_direction IN ('IN', 'OUT')
    ),
    CONSTRAINT payment_transactions_party_type_chk CHECK (
        party_type IS NULL OR party_type IN ('CUSTOMER', 'VENDOR', 'BANK', 'TAX_AUTHORITY', 'MARKETPLACE', 'OTHER')
    ),
    CONSTRAINT payment_transactions_status_chk CHECK (
        status IN ('DRAFT', 'READY', 'POSTED', 'FAILED', 'CANCELED', 'REVERSED')
    ),
    CONSTRAINT payment_transactions_settlement_status_chk CHECK (
        settlement_status IN ('UNSETTLED', 'PARTIALLY_SETTLED', 'SETTLED', 'FAILED', 'CANCELED')
    ),
    CONSTRAINT payment_transactions_amount_chk CHECK (
        gross_amount >= 0
        AND commission_amount >= 0
        AND tax_amount >= 0
        AND net_amount >= 0
        AND exchange_rate > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.collection_allocations (
    tenant_id uuid NOT NULL,
    collection_allocation_id uuid NOT NULL DEFAULT gen_random_uuid(),

    payment_transaction_id uuid NOT NULL,

    sales_invoice_id uuid,
    sales_invoice_no varchar(96),

    customer_id uuid,
    party_id uuid,

    allocated_amount numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    currency_code char(3) NOT NULL DEFAULT 'TRY',

    allocation_status varchar(40) NOT NULL DEFAULT 'ALLOCATED',

    allocation_date date NOT NULL DEFAULT CURRENT_DATE,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT collection_allocations_pk PRIMARY KEY (tenant_id, collection_allocation_id),
    CONSTRAINT collection_allocations_payment_fk FOREIGN KEY (tenant_id, payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE CASCADE,
    CONSTRAINT collection_allocations_invoice_fk FOREIGN KEY (tenant_id, sales_invoice_id)
        REFERENCES erp.sales_invoices (tenant_id, sales_invoice_id)
        ON DELETE SET NULL,
    CONSTRAINT collection_allocations_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT collection_allocations_status_chk CHECK (
        allocation_status IN ('ALLOCATED', 'PARTIALLY_REVERSED', 'REVERSED', 'CANCELED')
    ),
    CONSTRAINT collection_allocations_amount_chk CHECK (
        allocated_amount >= 0
        AND discount_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.payment_allocations (
    tenant_id uuid NOT NULL,
    payment_allocation_id uuid NOT NULL DEFAULT gen_random_uuid(),

    payment_transaction_id uuid NOT NULL,

    purchase_invoice_id uuid,
    purchase_invoice_no varchar(96),

    vendor_id uuid,
    party_id uuid,

    allocated_amount numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    currency_code char(3) NOT NULL DEFAULT 'TRY',

    allocation_status varchar(40) NOT NULL DEFAULT 'ALLOCATED',

    allocation_date date NOT NULL DEFAULT CURRENT_DATE,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT payment_allocations_pk PRIMARY KEY (tenant_id, payment_allocation_id),
    CONSTRAINT payment_allocations_payment_fk FOREIGN KEY (tenant_id, payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE CASCADE,
    CONSTRAINT payment_allocations_invoice_fk FOREIGN KEY (tenant_id, purchase_invoice_id)
        REFERENCES erp.procurement_purchase_invoices (tenant_id, purchase_invoice_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_allocations_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_allocations_status_chk CHECK (
        allocation_status IN ('ALLOCATED', 'PARTIALLY_REVERSED', 'REVERSED', 'CANCELED')
    ),
    CONSTRAINT payment_allocations_amount_chk CHECK (
        allocated_amount >= 0
        AND discount_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.refund_transactions (
    tenant_id uuid NOT NULL,
    refund_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),

    refund_no varchar(128) NOT NULL,

    original_payment_transaction_id uuid,
    refund_payment_transaction_id uuid,

    sales_invoice_id uuid,
    purchase_invoice_id uuid,

    party_id uuid,
    party_type varchar(40),
    party_title varchar(255),

    refund_direction varchar(16) NOT NULL,
    refund_reason_code varchar(96),
    refund_reason_message text,

    refund_date date NOT NULL DEFAULT CURRENT_DATE,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18,8) NOT NULL DEFAULT 1,

    refund_amount numeric(18,2) NOT NULL DEFAULT 0,
    commission_refund_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_refund_amount numeric(18,2) NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',

    provider_code varchar(64),
    provider_refund_id varchar(160),

    journal_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    approved_by uuid,
    approved_at timestamptz,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT refund_transactions_pk PRIMARY KEY (tenant_id, refund_transaction_id),
    CONSTRAINT refund_transactions_no_unique UNIQUE (tenant_id, refund_no),
    CONSTRAINT refund_transactions_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT refund_transactions_original_payment_fk FOREIGN KEY (tenant_id, original_payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_refund_payment_fk FOREIGN KEY (tenant_id, refund_payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_sales_invoice_fk FOREIGN KEY (tenant_id, sales_invoice_id)
        REFERENCES erp.sales_invoices (tenant_id, sales_invoice_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_purchase_invoice_fk FOREIGN KEY (tenant_id, purchase_invoice_id)
        REFERENCES erp.procurement_purchase_invoices (tenant_id, purchase_invoice_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_journal_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE SET NULL,
    CONSTRAINT refund_transactions_direction_chk CHECK (
        refund_direction IN ('IN', 'OUT')
    ),
    CONSTRAINT refund_transactions_party_type_chk CHECK (
        party_type IS NULL OR party_type IN ('CUSTOMER', 'VENDOR', 'BANK', 'MARKETPLACE', 'OTHER')
    ),
    CONSTRAINT refund_transactions_status_chk CHECK (
        status IN ('DRAFT', 'APPROVAL_WAITING', 'APPROVED', 'POSTED', 'FAILED', 'CANCELED', 'REVERSED')
    ),
    CONSTRAINT refund_transactions_amount_chk CHECK (
        refund_amount >= 0
        AND commission_refund_amount >= 0
        AND tax_refund_amount >= 0
        AND exchange_rate > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.reconciliation_runs (
    tenant_id uuid NOT NULL,
    reconciliation_run_id uuid NOT NULL DEFAULT gen_random_uuid(),

    reconciliation_no varchar(128) NOT NULL,
    reconciliation_type varchar(64) NOT NULL,

    period_start date NOT NULL,
    period_end date NOT NULL,

    party_id uuid,
    payment_method_id uuid,
    provider_code varchar(64),
    bank_code varchar(64),

    run_status varchar(40) NOT NULL DEFAULT 'DRAFT',

    expected_total_amount numeric(18,2) NOT NULL DEFAULT 0,
    actual_total_amount numeric(18,2) NOT NULL DEFAULT 0,
    difference_amount numeric(18,2) NOT NULL DEFAULT 0,

    expected_count integer NOT NULL DEFAULT 0,
    matched_count integer NOT NULL DEFAULT 0,
    unmatched_count integer NOT NULL DEFAULT 0,

    journal_id uuid,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    completed_by uuid,
    completed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT reconciliation_runs_pk PRIMARY KEY (tenant_id, reconciliation_run_id),
    CONSTRAINT reconciliation_runs_no_unique UNIQUE (tenant_id, reconciliation_no),
    CONSTRAINT reconciliation_runs_party_fk FOREIGN KEY (tenant_id, party_id)
        REFERENCES erp.master_parties (tenant_id, party_id)
        ON DELETE SET NULL,
    CONSTRAINT reconciliation_runs_payment_method_fk FOREIGN KEY (tenant_id, payment_method_id)
        REFERENCES erp.payment_methods (tenant_id, payment_method_id)
        ON DELETE SET NULL,
    CONSTRAINT reconciliation_runs_journal_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE SET NULL,
    CONSTRAINT reconciliation_runs_type_chk CHECK (
        reconciliation_type IN (
            'BANK',
            'VIRTUAL_POS',
            'MARKETPLACE',
            'CUSTOMER',
            'VENDOR',
            'CASH',
            'PAYMENT_PROVIDER',
            'OTHER'
        )
    ),
    CONSTRAINT reconciliation_runs_status_chk CHECK (
        run_status IN ('DRAFT', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED', 'REOPENED')
    ),
    CONSTRAINT reconciliation_runs_date_chk CHECK (
        period_end >= period_start
    ),
    CONSTRAINT reconciliation_runs_amount_chk CHECK (
        expected_total_amount >= 0
        AND actual_total_amount >= 0
        AND difference_amount >= 0
        AND expected_count >= 0
        AND matched_count >= 0
        AND unmatched_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.reconciliation_items (
    tenant_id uuid NOT NULL,
    reconciliation_item_id uuid NOT NULL DEFAULT gen_random_uuid(),

    reconciliation_run_id uuid NOT NULL,
    payment_transaction_id uuid,

    item_no integer NOT NULL,

    external_reference_no varchar(160),
    provider_transaction_id varchar(160),
    bank_reference_no varchar(160),

    expected_amount numeric(18,2) NOT NULL DEFAULT 0,
    actual_amount numeric(18,2) NOT NULL DEFAULT 0,
    difference_amount numeric(18,2) NOT NULL DEFAULT 0,

    reconciliation_status varchar(40) NOT NULL DEFAULT 'UNMATCHED',
    match_confidence numeric(9,4) NOT NULL DEFAULT 0,

    mismatch_reason_code varchar(96),
    mismatch_reason_message text,

    resolved_by uuid,
    resolved_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT reconciliation_items_pk PRIMARY KEY (tenant_id, reconciliation_item_id),
    CONSTRAINT reconciliation_items_run_fk FOREIGN KEY (tenant_id, reconciliation_run_id)
        REFERENCES erp.reconciliation_runs (tenant_id, reconciliation_run_id)
        ON DELETE CASCADE,
    CONSTRAINT reconciliation_items_payment_fk FOREIGN KEY (tenant_id, payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE SET NULL,
    CONSTRAINT reconciliation_items_line_unique UNIQUE (tenant_id, reconciliation_run_id, item_no),
    CONSTRAINT reconciliation_items_status_chk CHECK (
        reconciliation_status IN ('MATCHED', 'UNMATCHED', 'PARTIAL_MATCH', 'MISMATCHED', 'MANUALLY_RESOLVED', 'IGNORED')
    ),
    CONSTRAINT reconciliation_items_amount_chk CHECK (
        expected_amount >= 0
        AND actual_amount >= 0
        AND difference_amount >= 0
        AND match_confidence >= 0
        AND match_confidence <= 100
    )
);

CREATE TABLE IF NOT EXISTS erp.payment_audit_events (
    tenant_id uuid NOT NULL,
    payment_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    payment_transaction_id uuid,
    refund_transaction_id uuid,
    reconciliation_run_id uuid,

    entity_name varchar(96) NOT NULL,
    entity_id uuid,

    audit_action varchar(64) NOT NULL,

    old_value jsonb,
    new_value jsonb,

    reason_code varchar(96),
    reason_message text,

    actor_user_id uuid,
    actor_role varchar(96),

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT payment_audit_events_pk PRIMARY KEY (tenant_id, payment_audit_event_id),
    CONSTRAINT payment_audit_events_payment_fk FOREIGN KEY (tenant_id, payment_transaction_id)
        REFERENCES erp.payment_transactions (tenant_id, payment_transaction_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_audit_events_refund_fk FOREIGN KEY (tenant_id, refund_transaction_id)
        REFERENCES erp.refund_transactions (tenant_id, refund_transaction_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_audit_events_reconciliation_fk FOREIGN KEY (tenant_id, reconciliation_run_id)
        REFERENCES erp.reconciliation_runs (tenant_id, reconciliation_run_id)
        ON DELETE SET NULL,
    CONSTRAINT payment_audit_events_action_chk CHECK (
        audit_action IN (
            'CREATE',
            'UPDATE',
            'POST',
            'POST_FAILED',
            'ALLOCATE',
            'REVERSE',
            'REFUND',
            'RECONCILE',
            'MANUAL_RESOLVE',
            'CANCEL',
            'SYSTEM_MIGRATION'
        )
    )
);

CREATE INDEX IF NOT EXISTS payment_methods_type_status_idx
    ON erp.payment_methods (tenant_id, method_type, status);

CREATE INDEX IF NOT EXISTS payment_transactions_party_date_idx
    ON erp.payment_transactions (tenant_id, party_type, party_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS payment_transactions_method_status_idx
    ON erp.payment_transactions (tenant_id, payment_method_id, status, transaction_date DESC);

CREATE INDEX IF NOT EXISTS payment_transactions_provider_idx
    ON erp.payment_transactions (tenant_id, provider_code, provider_transaction_id)
    WHERE provider_transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS payment_transactions_source_idx
    ON erp.payment_transactions (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS collection_allocations_payment_idx
    ON erp.collection_allocations (tenant_id, payment_transaction_id);

CREATE INDEX IF NOT EXISTS collection_allocations_invoice_idx
    ON erp.collection_allocations (tenant_id, sales_invoice_id);

CREATE INDEX IF NOT EXISTS payment_allocations_payment_idx
    ON erp.payment_allocations (tenant_id, payment_transaction_id);

CREATE INDEX IF NOT EXISTS payment_allocations_invoice_idx
    ON erp.payment_allocations (tenant_id, purchase_invoice_id);

CREATE INDEX IF NOT EXISTS refund_transactions_original_payment_idx
    ON erp.refund_transactions (tenant_id, original_payment_transaction_id);

CREATE INDEX IF NOT EXISTS refund_transactions_party_date_idx
    ON erp.refund_transactions (tenant_id, party_type, party_id, refund_date DESC);

CREATE INDEX IF NOT EXISTS refund_transactions_provider_idx
    ON erp.refund_transactions (tenant_id, provider_code, provider_refund_id)
    WHERE provider_refund_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS reconciliation_runs_type_status_idx
    ON erp.reconciliation_runs (tenant_id, reconciliation_type, run_status, period_start, period_end);

CREATE INDEX IF NOT EXISTS reconciliation_runs_party_idx
    ON erp.reconciliation_runs (tenant_id, party_id, created_at DESC);

CREATE INDEX IF NOT EXISTS reconciliation_items_run_idx
    ON erp.reconciliation_items (tenant_id, reconciliation_run_id, item_no);

CREATE INDEX IF NOT EXISTS reconciliation_items_payment_idx
    ON erp.reconciliation_items (tenant_id, payment_transaction_id);

CREATE INDEX IF NOT EXISTS reconciliation_items_status_idx
    ON erp.reconciliation_items (tenant_id, reconciliation_status, updated_at DESC);

CREATE INDEX IF NOT EXISTS payment_audit_events_payment_idx
    ON erp.payment_audit_events (tenant_id, payment_transaction_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS payment_audit_events_entity_idx
    ON erp.payment_audit_events (tenant_id, entity_name, entity_id, occurred_at DESC);

ALTER TABLE erp.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.collection_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.refund_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.reconciliation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.reconciliation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.payment_methods FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.collection_allocations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_allocations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.refund_transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.reconciliation_runs FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.reconciliation_items FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.payment_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS payment_methods_tenant_policy ON erp.payment_methods;
CREATE POLICY payment_methods_tenant_policy ON erp.payment_methods
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS payment_transactions_tenant_policy ON erp.payment_transactions;
CREATE POLICY payment_transactions_tenant_policy ON erp.payment_transactions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS collection_allocations_tenant_policy ON erp.collection_allocations;
CREATE POLICY collection_allocations_tenant_policy ON erp.collection_allocations
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS payment_allocations_tenant_policy ON erp.payment_allocations;
CREATE POLICY payment_allocations_tenant_policy ON erp.payment_allocations
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS refund_transactions_tenant_policy ON erp.refund_transactions;
CREATE POLICY refund_transactions_tenant_policy ON erp.refund_transactions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS reconciliation_runs_tenant_policy ON erp.reconciliation_runs;
CREATE POLICY reconciliation_runs_tenant_policy ON erp.reconciliation_runs
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS reconciliation_items_tenant_policy ON erp.reconciliation_items;
CREATE POLICY reconciliation_items_tenant_policy ON erp.reconciliation_items
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS payment_audit_events_tenant_policy ON erp.payment_audit_events;
CREATE POLICY payment_audit_events_tenant_policy ON erp.payment_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.payment_methods IS 'FAZ 3-9.11 payment method master table';
COMMENT ON TABLE erp.payment_transactions IS 'FAZ 3-9.11 payment / collection transaction table';
COMMENT ON TABLE erp.collection_allocations IS 'FAZ 3-9.11 customer collection allocation table';
COMMENT ON TABLE erp.payment_allocations IS 'FAZ 3-9.11 vendor payment allocation table';
COMMENT ON TABLE erp.refund_transactions IS 'FAZ 3-9.11 refund transaction table';
COMMENT ON TABLE erp.reconciliation_runs IS 'FAZ 3-9.11 reconciliation run table';
COMMENT ON TABLE erp.reconciliation_items IS 'FAZ 3-9.11 reconciliation item table';
COMMENT ON TABLE erp.payment_audit_events IS 'FAZ 3-9.11 payment audit event table';

COMMIT;
