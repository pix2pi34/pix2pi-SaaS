BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.journal_headers (
    tenant_id uuid NOT NULL,
    journal_id uuid NOT NULL DEFAULT gen_random_uuid(),

    journal_no varchar(96) NOT NULL,
    journal_type varchar(64) NOT NULL DEFAULT 'GENERAL',
    journal_source varchar(64) NOT NULL DEFAULT 'MANUAL',

    document_type varchar(64),
    document_id uuid,
    document_no varchar(96),

    source_module varchar(64),
    source_event_id uuid,
    source_event_type varchar(128),

    accounting_date date NOT NULL DEFAULT CURRENT_DATE,
    document_date date,
    posting_date date,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,

    total_debit numeric(18, 2) NOT NULL DEFAULT 0,
    total_credit numeric(18, 2) NOT NULL DEFAULT 0,
    line_count integer NOT NULL DEFAULT 0,

    status varchar(40) NOT NULL DEFAULT 'DRAFT',
    posting_status varchar(40) NOT NULL DEFAULT 'UNPOSTED',

    description text,

    reversal_of_journal_id uuid,
    reversed_by_journal_id uuid,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    approved_by uuid,
    approved_at timestamptz,
    posted_by uuid,
    posted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT journal_headers_pk PRIMARY KEY (tenant_id, journal_id),
    CONSTRAINT journal_headers_no_unique UNIQUE (tenant_id, journal_no),
    CONSTRAINT journal_headers_type_chk CHECK (
        journal_type IN (
            'GENERAL',
            'SALES',
            'PURCHASE',
            'INVENTORY',
            'PAYMENT',
            'COLLECTION',
            'REFUND',
            'RECONCILIATION',
            'OPENING',
            'CLOSING',
            'ADJUSTMENT',
            'REVERSAL'
        )
    ),
    CONSTRAINT journal_headers_source_chk CHECK (
        journal_source IN (
            'MANUAL',
            'SYSTEM',
            'EVENT',
            'IMPORT',
            'E_BELGE',
            'POS',
            'MARKETPLACE',
            'PROCUREMENT',
            'SALES'
        )
    ),
    CONSTRAINT journal_headers_status_chk CHECK (
        status IN (
            'DRAFT',
            'READY',
            'APPROVAL_WAITING',
            'APPROVED',
            'POSTED',
            'REVERSED',
            'CANCELED',
            'FAILED'
        )
    ),
    CONSTRAINT journal_headers_posting_status_chk CHECK (
        posting_status IN (
            'UNPOSTED',
            'POSTING',
            'POSTED',
            'FAILED',
            'REVERSED'
        )
    ),
    CONSTRAINT journal_headers_amount_chk CHECK (
        total_debit >= 0
        AND total_credit >= 0
        AND line_count >= 0
        AND exchange_rate > 0
    )
);

CREATE TABLE IF NOT EXISTS erp.journal_lines (
    tenant_id uuid NOT NULL,
    journal_line_id uuid NOT NULL DEFAULT gen_random_uuid(),
    journal_id uuid NOT NULL,

    line_no integer NOT NULL,

    account_code varchar(32) NOT NULL,
    account_name varchar(255),
    tdhp_account_id uuid,

    line_description text,

    debit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    credit_amount numeric(18, 2) NOT NULL DEFAULT 0,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    exchange_rate numeric(18, 8) NOT NULL DEFAULT 1,
    foreign_debit_amount numeric(18, 2) NOT NULL DEFAULT 0,
    foreign_credit_amount numeric(18, 2) NOT NULL DEFAULT 0,

    party_id uuid,
    party_type varchar(32),
    cost_center_id uuid,
    project_id uuid,
    warehouse_id uuid,
    item_id uuid,

    tax_rule_id uuid,
    tax_rate numeric(9, 4),
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,

    source_line_id uuid,
    source_line_type varchar(96),

    is_system_line boolean NOT NULL DEFAULT false,
    is_reversal_line boolean NOT NULL DEFAULT false,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT journal_lines_pk PRIMARY KEY (tenant_id, journal_line_id),
    CONSTRAINT journal_lines_header_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE CASCADE,
    CONSTRAINT journal_lines_line_unique UNIQUE (tenant_id, journal_id, line_no),
    CONSTRAINT journal_lines_amount_chk CHECK (
        debit_amount >= 0
        AND credit_amount >= 0
        AND foreign_debit_amount >= 0
        AND foreign_credit_amount >= 0
        AND tax_amount >= 0
        AND exchange_rate > 0
    ),
    CONSTRAINT journal_lines_debit_credit_chk CHECK (
        (debit_amount > 0 AND credit_amount = 0)
        OR (credit_amount > 0 AND debit_amount = 0)
        OR (debit_amount = 0 AND credit_amount = 0)
    ),
    CONSTRAINT journal_lines_party_type_chk CHECK (
        party_type IS NULL OR party_type IN ('CUSTOMER', 'VENDOR', 'EMPLOYEE', 'BANK', 'TAX_AUTHORITY', 'OTHER')
    )
);

CREATE TABLE IF NOT EXISTS erp.journal_status_history (
    tenant_id uuid NOT NULL,
    journal_status_event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    journal_id uuid NOT NULL,

    from_status varchar(40),
    to_status varchar(40) NOT NULL,

    from_posting_status varchar(40),
    to_posting_status varchar(40),

    reason_code varchar(96),
    reason_message text,

    actor_user_id uuid,
    actor_role varchar(96),

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT journal_status_history_pk PRIMARY KEY (tenant_id, journal_status_event_id),
    CONSTRAINT journal_status_history_header_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS erp.journal_posting_audit_events (
    tenant_id uuid NOT NULL,
    journal_posting_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    journal_id uuid NOT NULL,

    audit_action varchar(64) NOT NULL,
    posting_attempt_no integer NOT NULL DEFAULT 1,

    balanced_before_posting boolean NOT NULL DEFAULT false,
    total_debit numeric(18, 2) NOT NULL DEFAULT 0,
    total_credit numeric(18, 2) NOT NULL DEFAULT 0,
    difference_amount numeric(18, 2) NOT NULL DEFAULT 0,

    result_status varchar(40) NOT NULL DEFAULT 'RECORDED',
    error_code varchar(96),
    error_message text,

    correlation_id varchar(128),
    request_id varchar(128),

    actor_user_id uuid,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT journal_posting_audit_events_pk PRIMARY KEY (tenant_id, journal_posting_audit_event_id),
    CONSTRAINT journal_posting_audit_events_header_fk FOREIGN KEY (tenant_id, journal_id)
        REFERENCES erp.journal_headers (tenant_id, journal_id)
        ON DELETE CASCADE,
    CONSTRAINT journal_posting_audit_events_action_chk CHECK (
        audit_action IN (
            'VALIDATE',
            'APPROVE',
            'POST',
            'POST_FAILED',
            'REVERSE',
            'CANCEL',
            'REPLAY',
            'SYSTEM_REBUILD'
        )
    ),
    CONSTRAINT journal_posting_audit_events_result_chk CHECK (
        result_status IN ('RECORDED', 'PASS', 'FAIL', 'WARN')
    ),
    CONSTRAINT journal_posting_audit_events_amount_chk CHECK (
        total_debit >= 0
        AND total_credit >= 0
        AND difference_amount >= 0
        AND posting_attempt_no >= 1
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS journal_headers_idempotency_uidx
    ON erp.journal_headers (tenant_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS journal_headers_status_idx
    ON erp.journal_headers (tenant_id, status, posting_status, accounting_date DESC);

CREATE INDEX IF NOT EXISTS journal_headers_source_document_idx
    ON erp.journal_headers (tenant_id, source_module, document_type, document_id);

CREATE INDEX IF NOT EXISTS journal_headers_source_event_idx
    ON erp.journal_headers (tenant_id, source_event_id, source_event_type)
    WHERE source_event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS journal_headers_reversal_idx
    ON erp.journal_headers (tenant_id, reversal_of_journal_id, reversed_by_journal_id);

CREATE INDEX IF NOT EXISTS journal_lines_header_idx
    ON erp.journal_lines (tenant_id, journal_id, line_no);

CREATE INDEX IF NOT EXISTS journal_lines_account_idx
    ON erp.journal_lines (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS journal_lines_party_idx
    ON erp.journal_lines (tenant_id, party_type, party_id)
    WHERE party_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS journal_lines_dimension_idx
    ON erp.journal_lines (tenant_id, cost_center_id, project_id, warehouse_id, item_id);

CREATE INDEX IF NOT EXISTS journal_status_history_header_idx
    ON erp.journal_status_history (tenant_id, journal_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS journal_posting_audit_events_header_idx
    ON erp.journal_posting_audit_events (tenant_id, journal_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS journal_posting_audit_events_action_idx
    ON erp.journal_posting_audit_events (tenant_id, audit_action, result_status, occurred_at DESC);

ALTER TABLE erp.journal_headers ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_posting_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.journal_headers FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_lines FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_status_history FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.journal_posting_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS journal_headers_tenant_policy ON erp.journal_headers;
CREATE POLICY journal_headers_tenant_policy ON erp.journal_headers
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS journal_lines_tenant_policy ON erp.journal_lines;
CREATE POLICY journal_lines_tenant_policy ON erp.journal_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS journal_status_history_tenant_policy ON erp.journal_status_history;
CREATE POLICY journal_status_history_tenant_policy ON erp.journal_status_history
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS journal_posting_audit_events_tenant_policy ON erp.journal_posting_audit_events;
CREATE POLICY journal_posting_audit_events_tenant_policy ON erp.journal_posting_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.journal_headers IS 'FAZ 3-9.6 journal header table';
COMMENT ON TABLE erp.journal_lines IS 'FAZ 3-9.6 journal line table';
COMMENT ON TABLE erp.journal_status_history IS 'FAZ 3-9.6 journal status lifecycle table';
COMMENT ON TABLE erp.journal_posting_audit_events IS 'FAZ 3-9.6 journal posting audit event table';

COMMIT;
