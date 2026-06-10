BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.e_belge_documents (
    tenant_id uuid NOT NULL,
    e_belge_id uuid NOT NULL DEFAULT gen_random_uuid(),

    document_type varchar(32) NOT NULL,
    direction varchar(16) NOT NULL,

    source_module varchar(64) NOT NULL,
    source_document_id uuid,
    source_document_no varchar(96),

    e_belge_no varchar(96),
    e_belge_uuid varchar(128),
    provider_code varchar(64),
    provider_document_id varchar(128),
    provider_envelope_id varchar(128),

    party_id uuid,
    party_type varchar(32),
    party_title varchar(255),
    tax_identity_no varchar(32),
    tax_office varchar(128),

    issue_date date NOT NULL,
    document_date date,
    due_date date,

    currency_code char(3) NOT NULL DEFAULT 'TRY',
    gross_amount numeric(18, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(18, 2) NOT NULL DEFAULT 0,
    tax_amount numeric(18, 2) NOT NULL DEFAULT 0,
    net_amount numeric(18, 2) NOT NULL DEFAULT 0,

    current_status varchar(40) NOT NULL DEFAULT 'DRAFT',
    last_provider_status varchar(80),
    last_error_code varchar(96),
    last_error_message text,

    retry_count integer NOT NULL DEFAULT 0,
    max_retry_count integer NOT NULL DEFAULT 5,

    cancel_requested_at timestamptz,
    canceled_at timestamptz,

    payload_hash varchar(128),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT e_belge_documents_pk PRIMARY KEY (tenant_id, e_belge_id),
    CONSTRAINT e_belge_documents_type_chk CHECK (
        document_type IN (
            'E_FATURA',
            'E_ARSIV',
            'E_IRSALIYE',
            'E_ADISYON',
            'E_MUSTAHSIL',
            'E_SERBEST_MESLEK'
        )
    ),
    CONSTRAINT e_belge_documents_direction_chk CHECK (
        direction IN ('OUTBOUND', 'INBOUND')
    ),
    CONSTRAINT e_belge_documents_status_chk CHECK (
        current_status IN (
            'DRAFT',
            'READY',
            'QUEUED',
            'SENDING',
            'SENT',
            'DELIVERED',
            'ACCEPTED',
            'REJECTED',
            'FAILED',
            'RETRY_WAITING',
            'CANCEL_REQUESTED',
            'CANCELED'
        )
    ),
    CONSTRAINT e_belge_documents_amount_chk CHECK (
        gross_amount >= 0
        AND discount_amount >= 0
        AND tax_amount >= 0
        AND net_amount >= 0
    ),
    CONSTRAINT e_belge_documents_retry_chk CHECK (
        retry_count >= 0
        AND max_retry_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.e_belge_status_history (
    tenant_id uuid NOT NULL,
    status_event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    e_belge_id uuid NOT NULL,

    from_status varchar(40),
    to_status varchar(40) NOT NULL,

    provider_code varchar(64),
    provider_status_code varchar(96),
    provider_status_message text,

    reason_code varchar(96),
    reason_message text,

    correlation_id varchar(128),
    request_id varchar(128),

    occurred_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,

    CONSTRAINT e_belge_status_history_pk PRIMARY KEY (tenant_id, status_event_id),
    CONSTRAINT e_belge_status_history_document_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS erp.e_belge_retry_queue (
    tenant_id uuid NOT NULL,
    retry_id uuid NOT NULL DEFAULT gen_random_uuid(),
    e_belge_id uuid NOT NULL,

    operation_type varchar(40) NOT NULL,
    retry_status varchar(32) NOT NULL DEFAULT 'WAITING',

    attempt_no integer NOT NULL DEFAULT 1,
    max_attempt_no integer NOT NULL DEFAULT 5,

    scheduled_at timestamptz NOT NULL DEFAULT now(),
    started_at timestamptz,
    completed_at timestamptz,

    last_error_code varchar(96),
    last_error_message text,

    idempotency_key varchar(160) NOT NULL,
    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT e_belge_retry_queue_pk PRIMARY KEY (tenant_id, retry_id),
    CONSTRAINT e_belge_retry_queue_document_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE CASCADE,
    CONSTRAINT e_belge_retry_queue_operation_chk CHECK (
        operation_type IN ('SEND', 'STATUS_CHECK', 'CANCEL', 'REBUILD_PAYLOAD')
    ),
    CONSTRAINT e_belge_retry_queue_status_chk CHECK (
        retry_status IN ('WAITING', 'RUNNING', 'DONE', 'FAILED', 'CANCELED')
    ),
    CONSTRAINT e_belge_retry_queue_attempt_chk CHECK (
        attempt_no >= 1
        AND max_attempt_no >= 1
        AND attempt_no <= max_attempt_no
    )
);

CREATE TABLE IF NOT EXISTS erp.e_belge_cancel_requests (
    tenant_id uuid NOT NULL,
    cancel_request_id uuid NOT NULL DEFAULT gen_random_uuid(),
    e_belge_id uuid NOT NULL,

    cancel_status varchar(32) NOT NULL DEFAULT 'REQUESTED',
    cancel_reason_code varchar(96),
    cancel_reason_message text,

    provider_code varchar(64),
    provider_cancel_id varchar(128),
    provider_status_code varchar(96),
    provider_status_message text,

    requested_by uuid,
    requested_at timestamptz NOT NULL DEFAULT now(),
    approved_by uuid,
    approved_at timestamptz,
    completed_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT e_belge_cancel_requests_pk PRIMARY KEY (tenant_id, cancel_request_id),
    CONSTRAINT e_belge_cancel_requests_document_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE CASCADE,
    CONSTRAINT e_belge_cancel_requests_status_chk CHECK (
        cancel_status IN ('REQUESTED', 'APPROVED', 'SENT', 'DONE', 'REJECTED', 'FAILED')
    )
);

CREATE TABLE IF NOT EXISTS erp.e_belge_provider_payloads (
    tenant_id uuid NOT NULL,
    payload_id uuid NOT NULL DEFAULT gen_random_uuid(),
    e_belge_id uuid NOT NULL,

    payload_type varchar(40) NOT NULL,
    payload_format varchar(32) NOT NULL DEFAULT 'JSON',
    payload_hash varchar(128) NOT NULL,

    storage_ref text,
    payload_preview jsonb,

    provider_code varchar(64),
    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT e_belge_provider_payloads_pk PRIMARY KEY (tenant_id, payload_id),
    CONSTRAINT e_belge_provider_payloads_document_fk FOREIGN KEY (tenant_id, e_belge_id)
        REFERENCES erp.e_belge_documents (tenant_id, e_belge_id)
        ON DELETE CASCADE,
    CONSTRAINT e_belge_provider_payloads_type_chk CHECK (
        payload_type IN ('REQUEST', 'RESPONSE', 'STATUS_RESPONSE', 'CANCEL_REQUEST', 'CANCEL_RESPONSE')
    ),
    CONSTRAINT e_belge_provider_payloads_format_chk CHECK (
        payload_format IN ('JSON', 'XML', 'UBL', 'PDF', 'TEXT')
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS e_belge_documents_provider_doc_uidx
    ON erp.e_belge_documents (tenant_id, provider_code, provider_document_id)
    WHERE provider_code IS NOT NULL AND provider_document_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS e_belge_documents_tenant_status_idx
    ON erp.e_belge_documents (tenant_id, current_status, created_at DESC);

CREATE INDEX IF NOT EXISTS e_belge_documents_tenant_type_date_idx
    ON erp.e_belge_documents (tenant_id, document_type, issue_date DESC);

CREATE INDEX IF NOT EXISTS e_belge_documents_party_idx
    ON erp.e_belge_documents (tenant_id, party_id)
    WHERE party_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS e_belge_status_history_document_idx
    ON erp.e_belge_status_history (tenant_id, e_belge_id, occurred_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS e_belge_retry_queue_idempotency_uidx
    ON erp.e_belge_retry_queue (tenant_id, idempotency_key);

CREATE INDEX IF NOT EXISTS e_belge_retry_queue_due_idx
    ON erp.e_belge_retry_queue (tenant_id, retry_status, scheduled_at)
    WHERE retry_status IN ('WAITING', 'FAILED');

CREATE INDEX IF NOT EXISTS e_belge_cancel_requests_document_idx
    ON erp.e_belge_cancel_requests (tenant_id, e_belge_id, requested_at DESC);

CREATE INDEX IF NOT EXISTS e_belge_provider_payloads_document_idx
    ON erp.e_belge_provider_payloads (tenant_id, e_belge_id, created_at DESC);

ALTER TABLE erp.e_belge_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_retry_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_cancel_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_provider_payloads ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.e_belge_documents FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_status_history FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_retry_queue FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_cancel_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.e_belge_provider_payloads FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS e_belge_documents_tenant_policy ON erp.e_belge_documents;
CREATE POLICY e_belge_documents_tenant_policy ON erp.e_belge_documents
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS e_belge_status_history_tenant_policy ON erp.e_belge_status_history;
CREATE POLICY e_belge_status_history_tenant_policy ON erp.e_belge_status_history
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS e_belge_retry_queue_tenant_policy ON erp.e_belge_retry_queue;
CREATE POLICY e_belge_retry_queue_tenant_policy ON erp.e_belge_retry_queue
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS e_belge_cancel_requests_tenant_policy ON erp.e_belge_cancel_requests;
CREATE POLICY e_belge_cancel_requests_tenant_policy ON erp.e_belge_cancel_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS e_belge_provider_payloads_tenant_policy ON erp.e_belge_provider_payloads;
CREATE POLICY e_belge_provider_payloads_tenant_policy ON erp.e_belge_provider_payloads
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.e_belge_documents IS 'FAZ 3-9.10 e-Belge ana dokuman tablosu';
COMMENT ON TABLE erp.e_belge_status_history IS 'FAZ 3-9.10 e-Belge status lifecycle tablosu';
COMMENT ON TABLE erp.e_belge_retry_queue IS 'FAZ 3-9.10 e-Belge retry queue tablosu';
COMMENT ON TABLE erp.e_belge_cancel_requests IS 'FAZ 3-9.10 e-Belge cancel request tablosu';
COMMENT ON TABLE erp.e_belge_provider_payloads IS 'FAZ 3-9.10 e-Belge provider payload audit tablosu';

COMMIT;
