BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.ledger_posting_batches (
    tenant_id uuid NOT NULL,
    ledger_posting_batch_id uuid NOT NULL DEFAULT gen_random_uuid(),

    batch_no varchar(96) NOT NULL,
    batch_type varchar(64) NOT NULL DEFAULT 'JOURNAL_POSTING',
    source_module varchar(64) NOT NULL DEFAULT 'ERP',

    fiscal_year integer NOT NULL,
    period_no integer NOT NULL,

    batch_status varchar(40) NOT NULL DEFAULT 'OPEN',
    posting_started_at timestamptz,
    posting_completed_at timestamptz,

    journal_count integer NOT NULL DEFAULT 0,
    movement_count integer NOT NULL DEFAULT 0,

    total_debit numeric(18, 2) NOT NULL DEFAULT 0,
    total_credit numeric(18, 2) NOT NULL DEFAULT 0,
    difference_amount numeric(18, 2) NOT NULL DEFAULT 0,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    posted_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ledger_posting_batches_pk PRIMARY KEY (tenant_id, ledger_posting_batch_id),
    CONSTRAINT ledger_posting_batches_no_unique UNIQUE (tenant_id, batch_no),
    CONSTRAINT ledger_posting_batches_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT ledger_posting_batches_type_chk CHECK (
        batch_type IN (
            'JOURNAL_POSTING',
            'OPENING_BALANCE',
            'CLOSING_BALANCE',
            'ADJUSTMENT',
            'REVERSAL',
            'REBUILD',
            'IMPORT'
        )
    ),
    CONSTRAINT ledger_posting_batches_status_chk CHECK (
        batch_status IN (
            'OPEN',
            'POSTING',
            'POSTED',
            'FAILED',
            'REVERSED',
            'CANCELED'
        )
    ),
    CONSTRAINT ledger_posting_batches_period_chk CHECK (
        fiscal_year >= 2000
        AND fiscal_year <= 2100
        AND period_no >= 1
        AND period_no <= 12
    ),
    CONSTRAINT ledger_posting_batches_amount_chk CHECK (
        journal_count >= 0
        AND movement_count >= 0
        AND total_debit >= 0
        AND total_credit >= 0
        AND difference_amount >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.ledger_account_movements (
    tenant_id uuid NOT NULL,
    ledger_movement_id uuid NOT NULL DEFAULT gen_random_uuid(),

    ledger_posting_batch_id uuid,
    journal_id uuid NOT NULL,
    journal_line_id uuid NOT NULL,

    movement_no varchar(128) NOT NULL,

    fiscal_year integer NOT NULL,
    period_no integer NOT NULL,
    accounting_date date NOT NULL,

    account_code varchar(32) NOT NULL,
    account_name varchar(255),
    tdhp_account_id uuid,

    movement_side varchar(16) NOT NULL,
    debit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    credit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    balance_effect numeric(18, 2) NOT NULL DEFAULT 0,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,
    foreign_debit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    foreign_credit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    foreign_balance_effect numeric(18, 2) NOT NULL DEFAULT 0,

    party_id uuid,
    party_type varchar(32),
    cost_center_id uuid,
    project_id uuid,
    warehouse_id uuid,
    item_id uuid,

    source_module varchar(64),
    source_document_type varchar(64),
    source_document_id uuid,
    source_document_no varchar(96),
    source_event_id uuid,

    is_reversal boolean NOT NULL DEFAULT false,
    reversal_of_movement_id uuid,

    posting_status varchar(40) NOT NULL DEFAULT 'POSTED',

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ledger_account_movements_pk PRIMARY KEY (tenant_id, ledger_movement_id),
    CONSTRAINT ledger_account_movements_batch_fk FOREIGN KEY (tenant_id, ledger_posting_batch_id)
        REFERENCES erp.ledger_posting_batches (tenant_id, ledger_posting_batch_id)
        ON DELETE SET NULL,
    CONSTRAINT ledger_account_movements_journal_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE RESTRICT,
    CONSTRAINT ledger_account_movements_journal_line_fk FOREIGN KEY (tenant_id, journal_line_id)
        REFERENCES erp.journal_lines (tenant_id, journal_line_id)
        ON DELETE RESTRICT,
    CONSTRAINT ledger_account_movements_tdhp_account_fk FOREIGN KEY (tenant_id, tdhp_account_id)
        REFERENCES erp.tdhp_accounts (tenant_id, tdhp_account_id)
        ON DELETE SET NULL,
    CONSTRAINT ledger_account_movements_reversal_fk FOREIGN KEY (tenant_id, reversal_of_movement_id)
        REFERENCES erp.ledger_account_movements (tenant_id, ledger_movement_id)
        ON DELETE SET NULL,
    CONSTRAINT ledger_account_movements_no_unique UNIQUE (tenant_id, movement_no),
    CONSTRAINT ledger_account_movements_period_chk CHECK (
        fiscal_year >= 2000
        AND fiscal_year <= 2100
        AND period_no >= 1
        AND period_no <= 12
    ),
    CONSTRAINT ledger_account_movements_side_chk CHECK (
        movement_side IN ('DEBIT', 'CREDIT')
    ),
    CONSTRAINT ledger_account_movements_amount_chk CHECK (
        debit_amount >= 0
        AND credit_amount >= 0
        AND foreign_debit_amount >= 0
        AND foreign_credit_amount >= 0
        AND exchange_rate > 0
    ),
    CONSTRAINT ledger_account_movements_debit_credit_chk CHECK (
        (movement_side = 'DEBIT' AND debit_amount > 0 AND credit_amount = 0)
        OR (movement_side = 'CREDIT' AND credit_amount > 0 AND debit_amount = 0)
    ),
    CONSTRAINT ledger_account_movements_posting_status_chk CHECK (
        posting_status IN ('POSTED', 'REVERSED', 'CANCELED')
    )
);

CREATE TABLE IF NOT EXISTS erp.ledger_balances (
    tenant_id uuid NOT NULL,
    ledger_balance_id uuid NOT NULL DEFAULT gen_random_uuid(),

    fiscal_year integer NOT NULL,
    period_no integer NOT NULL,

    account_code varchar(32) NOT NULL,
    account_name varchar(255),
    tdhp_account_id uuid,

    currency_code char(3) NOT NULL DEFAULT 'TRY',

    opening_debit numeric(18, 2) NOT NULL DEFAULT 0,
    opening_credit numeric(18, 2) NOT NULL DEFAULT 0,
    period_debit numeric(18, 2) NOT NULL DEFAULT 0,
    period_credit numeric(18, 2) NOT NULL DEFAULT 0,
    closing_debit numeric(18, 2) NOT NULL DEFAULT 0,
    closing_credit numeric(18, 2) NOT NULL DEFAULT 0,

    movement_count integer NOT NULL DEFAULT 0,

    last_movement_at timestamptz,
    last_rebuild_at timestamptz,

    balance_status varchar(40) NOT NULL DEFAULT 'CURRENT',

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ledger_balances_pk PRIMARY KEY (tenant_id, ledger_balance_id),
    CONSTRAINT ledger_balances_account_fk FOREIGN KEY (tenant_id, tdhp_account_id)
        REFERENCES erp.tdhp_accounts (tenant_id, tdhp_account_id)
        ON DELETE SET NULL,
    CONSTRAINT ledger_balances_period_unique UNIQUE (tenant_id, fiscal_year, period_no, account_code, currency_code),
    CONSTRAINT ledger_balances_period_chk CHECK (
        fiscal_year >= 2000
        AND fiscal_year <= 2100
        AND period_no >= 1
        AND period_no <= 12
    ),
    CONSTRAINT ledger_balances_amount_chk CHECK (
        opening_debit >= 0
        AND opening_credit >= 0
        AND period_debit >= 0
        AND period_credit >= 0
        AND closing_debit >= 0
        AND closing_credit >= 0
        AND movement_count >= 0
    ),
    CONSTRAINT ledger_balances_status_chk CHECK (
        balance_status IN ('CURRENT', 'STALE', 'REBUILDING', 'LOCKED', 'CLOSED')
    )
);

CREATE TABLE IF NOT EXISTS erp.ledger_period_closures (
    tenant_id uuid NOT NULL,
    ledger_period_closure_id uuid NOT NULL DEFAULT gen_random_uuid(),

    fiscal_year integer NOT NULL,
    period_no integer NOT NULL,

    closure_status varchar(40) NOT NULL DEFAULT 'OPEN',

    total_debit numeric(18, 2) NOT NULL DEFAULT 0,
    total_credit numeric(18, 2) NOT NULL DEFAULT 0,
    difference_amount numeric(18, 2) NOT NULL DEFAULT 0,

    balance_count integer NOT NULL DEFAULT 0,
    movement_count integer NOT NULL DEFAULT 0,

    closed_by uuid,
    closed_at timestamptz,
    reopened_by uuid,
    reopened_at timestamptz,

    reason_code varchar(96),
    reason_message text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ledger_period_closures_pk PRIMARY KEY (tenant_id, ledger_period_closure_id),
    CONSTRAINT ledger_period_closures_period_unique UNIQUE (tenant_id, fiscal_year, period_no),
    CONSTRAINT ledger_period_closures_period_chk CHECK (
        fiscal_year >= 2000
        AND fiscal_year <= 2100
        AND period_no >= 1
        AND period_no <= 12
    ),
    CONSTRAINT ledger_period_closures_status_chk CHECK (
        closure_status IN ('OPEN', 'CLOSING', 'CLOSED', 'REOPENED', 'LOCKED')
    ),
    CONSTRAINT ledger_period_closures_amount_chk CHECK (
        total_debit >= 0
        AND total_credit >= 0
        AND difference_amount >= 0
        AND balance_count >= 0
        AND movement_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.ledger_reconciliation_audit_events (
    tenant_id uuid NOT NULL,
    ledger_reconciliation_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    ledger_posting_batch_id uuid,
    fiscal_year integer NOT NULL,
    period_no integer NOT NULL,

    audit_action varchar(64) NOT NULL,
    audit_status varchar(40) NOT NULL DEFAULT 'RECORDED',

    expected_debit numeric(18, 2) NOT NULL DEFAULT 0,
    expected_credit numeric(18, 2) NOT NULL DEFAULT 0,
    actual_debit numeric(18, 2) NOT NULL DEFAULT 0,
    actual_credit numeric(18, 2) NOT NULL DEFAULT 0,
    difference_amount numeric(18, 2) NOT NULL DEFAULT 0,

    error_code varchar(96),
    error_message text,

    actor_user_id uuid,

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ledger_reconciliation_audit_events_pk PRIMARY KEY (tenant_id, ledger_reconciliation_audit_event_id),
    CONSTRAINT ledger_reconciliation_audit_events_batch_fk FOREIGN KEY (tenant_id, ledger_posting_batch_id)
        REFERENCES erp.ledger_posting_batches (tenant_id, ledger_posting_batch_id)
        ON DELETE SET NULL,
    CONSTRAINT ledger_reconciliation_audit_events_period_chk CHECK (
        fiscal_year >= 2000
        AND fiscal_year <= 2100
        AND period_no >= 1
        AND period_no <= 12
    ),
    CONSTRAINT ledger_reconciliation_audit_events_action_chk CHECK (
        audit_action IN (
            'POSTING_RECONCILE',
            'BALANCE_REBUILD',
            'PERIOD_CLOSE',
            'PERIOD_REOPEN',
            'DIFFERENCE_DETECTED',
            'DIFFERENCE_RESOLVED',
            'SYSTEM_AUDIT'
        )
    ),
    CONSTRAINT ledger_reconciliation_audit_events_status_chk CHECK (
        audit_status IN ('RECORDED', 'PASS', 'FAIL', 'WARN')
    ),
    CONSTRAINT ledger_reconciliation_audit_events_amount_chk CHECK (
        expected_debit >= 0
        AND expected_credit >= 0
        AND actual_debit >= 0
        AND actual_credit >= 0
        AND difference_amount >= 0
    )
);

CREATE INDEX IF NOT EXISTS ledger_posting_batches_status_idx
    ON erp.ledger_posting_batches (tenant_id, batch_status, fiscal_year, period_no);

CREATE INDEX IF NOT EXISTS ledger_posting_batches_created_idx
    ON erp.ledger_posting_batches (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ledger_account_movements_account_date_idx
    ON erp.ledger_account_movements (tenant_id, account_code, accounting_date DESC);

CREATE INDEX IF NOT EXISTS ledger_account_movements_period_idx
    ON erp.ledger_account_movements (tenant_id, fiscal_year, period_no, account_code);

CREATE INDEX IF NOT EXISTS ledger_account_movements_journal_idx
    ON erp.ledger_account_movements (tenant_id, journal_id, journal_line_id);

CREATE INDEX IF NOT EXISTS ledger_account_movements_source_idx
    ON erp.ledger_account_movements (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS ledger_account_movements_party_idx
    ON erp.ledger_account_movements (tenant_id, party_type, party_id)
    WHERE party_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS ledger_account_movements_dimension_idx
    ON erp.ledger_account_movements (tenant_id, cost_center_id, project_id, warehouse_id, item_id);

CREATE INDEX IF NOT EXISTS ledger_balances_account_period_idx
    ON erp.ledger_balances (tenant_id, account_code, fiscal_year, period_no);

CREATE INDEX IF NOT EXISTS ledger_balances_status_idx
    ON erp.ledger_balances (tenant_id, balance_status, fiscal_year, period_no);

CREATE INDEX IF NOT EXISTS ledger_period_closures_status_idx
    ON erp.ledger_period_closures (tenant_id, closure_status, fiscal_year, period_no);

CREATE INDEX IF NOT EXISTS ledger_reconciliation_audit_events_period_idx
    ON erp.ledger_reconciliation_audit_events (tenant_id, fiscal_year, period_no, occurred_at DESC);

CREATE INDEX IF NOT EXISTS ledger_reconciliation_audit_events_action_idx
    ON erp.ledger_reconciliation_audit_events (tenant_id, audit_action, audit_status, occurred_at DESC);

ALTER TABLE erp.ledger_posting_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_account_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_period_closures ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_reconciliation_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.ledger_posting_batches FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_account_movements FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_balances FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_period_closures FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.ledger_reconciliation_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ledger_posting_batches_tenant_policy ON erp.ledger_posting_batches;
CREATE POLICY ledger_posting_batches_tenant_policy ON erp.ledger_posting_batches
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS ledger_account_movements_tenant_policy ON erp.ledger_account_movements;
CREATE POLICY ledger_account_movements_tenant_policy ON erp.ledger_account_movements
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS ledger_balances_tenant_policy ON erp.ledger_balances;
CREATE POLICY ledger_balances_tenant_policy ON erp.ledger_balances
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS ledger_period_closures_tenant_policy ON erp.ledger_period_closures;
CREATE POLICY ledger_period_closures_tenant_policy ON erp.ledger_period_closures
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS ledger_reconciliation_audit_events_tenant_policy ON erp.ledger_reconciliation_audit_events;
CREATE POLICY ledger_reconciliation_audit_events_tenant_policy ON erp.ledger_reconciliation_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.ledger_posting_batches IS 'FAZ 3-9.7 ledger posting batch table';
COMMENT ON TABLE erp.ledger_account_movements IS 'FAZ 3-9.7 ledger account movement table';
COMMENT ON TABLE erp.ledger_balances IS 'FAZ 3-9.7 ledger account balance table';
COMMENT ON TABLE erp.ledger_period_closures IS 'FAZ 3-9.7 ledger period closure table';
COMMENT ON TABLE erp.ledger_reconciliation_audit_events IS 'FAZ 3-9.7 ledger reconciliation audit event table';

COMMIT;
