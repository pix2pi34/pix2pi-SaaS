BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.export_runs (
    tenant_id uuid NOT NULL,
    export_run_id uuid NOT NULL DEFAULT gen_random_uuid(),

    export_run_no varchar(128) NOT NULL,
    export_type varchar(64) NOT NULL,
    target_system varchar(64) NOT NULL,
    export_format varchar(32) NOT NULL,

    period_start date,
    period_end date,

    source_module varchar(64) NOT NULL DEFAULT 'ERP',
    source_scope varchar(96) NOT NULL DEFAULT 'ACCOUNTING',

    run_status varchar(40) NOT NULL DEFAULT 'DRAFT',

    total_record_count integer NOT NULL DEFAULT 0,
    exported_record_count integer NOT NULL DEFAULT 0,
    skipped_record_count integer NOT NULL DEFAULT 0,
    validation_error_count integer NOT NULL DEFAULT 0,
    file_count integer NOT NULL DEFAULT 0,

    requested_by uuid,
    requested_at timestamptz NOT NULL DEFAULT now(),
    started_at timestamptz,
    completed_at timestamptz,

    idempotency_key varchar(160),
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT export_runs_pk PRIMARY KEY (tenant_id, export_run_id),
    CONSTRAINT export_runs_no_unique UNIQUE (tenant_id, export_run_no),
    CONSTRAINT export_runs_idempotency_unique UNIQUE (tenant_id, idempotency_key),
    CONSTRAINT export_runs_type_chk CHECK (
        export_type IN (
            'ACCOUNTING_EXPORT',
            'LEDGER_EXPORT',
            'JOURNAL_EXPORT',
            'SALES_EXPORT',
            'PROCUREMENT_EXPORT',
            'INVENTORY_EXPORT',
            'PAYMENT_EXPORT',
            'E_BELGE_EXPORT',
            'ACCOUNTANT_PORTAL_EXPORT',
            'AUDIT_EXPORT',
            'CUSTOM'
        )
    ),
    CONSTRAINT export_runs_target_system_chk CHECK (
        target_system IN (
            'LOGO',
            'MIKRO',
            'ZIRVE',
            'ETA',
            'EXCEL',
            'PDF',
            'CSV',
            'JSON',
            'XML',
            'TDHP',
            'CUSTOM'
        )
    ),
    CONSTRAINT export_runs_format_chk CHECK (
        export_format IN ('CSV', 'XLSX', 'PDF', 'JSON', 'XML', 'TXT', 'ZIP', 'UBL', 'CUSTOM')
    ),
    CONSTRAINT export_runs_status_chk CHECK (
        run_status IN (
            'DRAFT',
            'VALIDATING',
            'VALIDATION_FAILED',
            'READY',
            'GENERATING',
            'GENERATED',
            'DELIVERED',
            'FAILED',
            'CANCELED',
            'ARCHIVED'
        )
    ),
    CONSTRAINT export_runs_count_chk CHECK (
        total_record_count >= 0
        AND exported_record_count >= 0
        AND skipped_record_count >= 0
        AND validation_error_count >= 0
        AND file_count >= 0
    ),
    CONSTRAINT export_runs_period_chk CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

CREATE TABLE IF NOT EXISTS erp.export_files (
    tenant_id uuid NOT NULL,
    export_file_id uuid NOT NULL DEFAULT gen_random_uuid(),
    export_run_id uuid NOT NULL,

    file_no varchar(128) NOT NULL,
    file_name varchar(255) NOT NULL,
    file_type varchar(64) NOT NULL,
    file_format varchar(32) NOT NULL,

    storage_ref text,
    public_url text,

    file_hash varchar(160),
    file_size_bytes bigint NOT NULL DEFAULT 0,
    line_count integer NOT NULL DEFAULT 0,
    record_count integer NOT NULL DEFAULT 0,

    file_status varchar(40) NOT NULL DEFAULT 'CREATED',

    generated_at timestamptz NOT NULL DEFAULT now(),
    delivered_at timestamptz,
    archived_at timestamptz,

    provider_code varchar(64),
    provider_delivery_id varchar(160),
    delivery_error_code varchar(96),
    delivery_error_message text,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT export_files_pk PRIMARY KEY (tenant_id, export_file_id),
    CONSTRAINT export_files_run_fk FOREIGN KEY (tenant_id, export_run_id)
        REFERENCES erp.export_runs (tenant_id, export_run_id)
        ON DELETE CASCADE,
    CONSTRAINT export_files_no_unique UNIQUE (tenant_id, export_run_id, file_no),
    CONSTRAINT export_files_type_chk CHECK (
        file_type IN (
            'JOURNAL_FILE',
            'LEDGER_FILE',
            'ACCOUNT_FILE',
            'SALES_FILE',
            'PURCHASE_FILE',
            'INVENTORY_FILE',
            'PAYMENT_FILE',
            'VALIDATION_REPORT',
            'SUMMARY_REPORT',
            'ZIP_PACKAGE',
            'CUSTOM'
        )
    ),
    CONSTRAINT export_files_format_chk CHECK (
        file_format IN ('CSV', 'XLSX', 'PDF', 'JSON', 'XML', 'TXT', 'ZIP', 'UBL', 'CUSTOM')
    ),
    CONSTRAINT export_files_status_chk CHECK (
        file_status IN ('CREATED', 'GENERATED', 'DELIVERED', 'FAILED', 'ARCHIVED', 'DELETED')
    ),
    CONSTRAINT export_files_size_chk CHECK (
        file_size_bytes >= 0
        AND line_count >= 0
        AND record_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.export_file_records (
    tenant_id uuid NOT NULL,
    export_file_record_id uuid NOT NULL DEFAULT gen_random_uuid(),
    export_run_id uuid NOT NULL,
    export_file_id uuid,

    record_no integer NOT NULL,

    source_table varchar(128),
    source_record_id uuid,
    source_document_type varchar(96),
    source_document_id uuid,
    source_document_no varchar(128),

    record_status varchar(40) NOT NULL DEFAULT 'READY',

    record_payload jsonb,
    rendered_line text,

    validation_status varchar(40) NOT NULL DEFAULT 'NOT_VALIDATED',
    validation_error_count integer NOT NULL DEFAULT 0,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT export_file_records_pk PRIMARY KEY (tenant_id, export_file_record_id),
    CONSTRAINT export_file_records_run_fk FOREIGN KEY (tenant_id, export_run_id)
        REFERENCES erp.export_runs (tenant_id, export_run_id)
        ON DELETE CASCADE,
    CONSTRAINT export_file_records_file_fk FOREIGN KEY (tenant_id, export_file_id)
        REFERENCES erp.export_files (tenant_id, export_file_id)
        ON DELETE SET NULL,
    CONSTRAINT export_file_records_no_unique UNIQUE (tenant_id, export_run_id, record_no),
    CONSTRAINT export_file_records_status_chk CHECK (
        record_status IN ('READY', 'EXPORTED', 'SKIPPED', 'FAILED')
    ),
    CONSTRAINT export_file_records_validation_status_chk CHECK (
        validation_status IN ('NOT_VALIDATED', 'PASS', 'FAIL', 'WARN')
    ),
    CONSTRAINT export_file_records_count_chk CHECK (
        record_no >= 1
        AND validation_error_count >= 0
    )
);

CREATE TABLE IF NOT EXISTS erp.export_validations (
    tenant_id uuid NOT NULL,
    export_validation_id uuid NOT NULL DEFAULT gen_random_uuid(),
    export_run_id uuid NOT NULL,
    export_file_id uuid,
    export_file_record_id uuid,

    validation_code varchar(128) NOT NULL,
    validation_name varchar(255) NOT NULL,
    validation_scope varchar(64) NOT NULL,
    validation_level varchar(32) NOT NULL DEFAULT 'ERROR',

    validation_status varchar(40) NOT NULL DEFAULT 'FAIL',

    source_table varchar(128),
    source_record_id uuid,
    field_name varchar(128),

    expected_value text,
    actual_value text,

    message text NOT NULL,
    remediation_hint text,

    resolved boolean NOT NULL DEFAULT false,
    resolved_by uuid,
    resolved_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT export_validations_pk PRIMARY KEY (tenant_id, export_validation_id),
    CONSTRAINT export_validations_run_fk FOREIGN KEY (tenant_id, export_run_id)
        REFERENCES erp.export_runs (tenant_id, export_run_id)
        ON DELETE CASCADE,
    CONSTRAINT export_validations_file_fk FOREIGN KEY (tenant_id, export_file_id)
        REFERENCES erp.export_files (tenant_id, export_file_id)
        ON DELETE SET NULL,
    CONSTRAINT export_validations_record_fk FOREIGN KEY (tenant_id, export_file_record_id)
        REFERENCES erp.export_file_records (tenant_id, export_file_record_id)
        ON DELETE SET NULL,
    CONSTRAINT export_validations_scope_chk CHECK (
        validation_scope IN (
            'RUN',
            'FILE',
            'RECORD',
            'FIELD',
            'ACCOUNTING',
            'TAX',
            'TDHP',
            'PROVIDER_FORMAT',
            'DELIVERY',
            'CUSTOM'
        )
    ),
    CONSTRAINT export_validations_level_chk CHECK (
        validation_level IN ('INFO', 'WARN', 'ERROR', 'BLOCKER')
    ),
    CONSTRAINT export_validations_status_chk CHECK (
        validation_status IN ('PASS', 'FAIL', 'WARN', 'IGNORED')
    )
);

CREATE TABLE IF NOT EXISTS erp.export_audit_events (
    tenant_id uuid NOT NULL,
    export_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    export_run_id uuid,
    export_file_id uuid,

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

    CONSTRAINT export_audit_events_pk PRIMARY KEY (tenant_id, export_audit_event_id),
    CONSTRAINT export_audit_events_run_fk FOREIGN KEY (tenant_id, export_run_id)
        REFERENCES erp.export_runs (tenant_id, export_run_id)
        ON DELETE SET NULL,
    CONSTRAINT export_audit_events_file_fk FOREIGN KEY (tenant_id, export_file_id)
        REFERENCES erp.export_files (tenant_id, export_file_id)
        ON DELETE SET NULL,
    CONSTRAINT export_audit_events_action_chk CHECK (
        audit_action IN (
            'CREATE',
            'VALIDATE',
            'VALIDATION_FAILED',
            'GENERATE',
            'GENERATE_FAILED',
            'DELIVER',
            'DELIVER_FAILED',
            'ARCHIVE',
            'CANCEL',
            'SYSTEM_MIGRATION'
        )
    )
);

CREATE INDEX IF NOT EXISTS export_runs_type_target_status_idx
    ON erp.export_runs (tenant_id, export_type, target_system, run_status);

CREATE INDEX IF NOT EXISTS export_runs_period_idx
    ON erp.export_runs (tenant_id, period_start, period_end);

CREATE INDEX IF NOT EXISTS export_runs_requested_idx
    ON erp.export_runs (tenant_id, requested_at DESC);

CREATE INDEX IF NOT EXISTS export_files_run_idx
    ON erp.export_files (tenant_id, export_run_id, file_no);

CREATE INDEX IF NOT EXISTS export_files_status_idx
    ON erp.export_files (tenant_id, file_status, generated_at DESC);

CREATE INDEX IF NOT EXISTS export_files_hash_idx
    ON erp.export_files (tenant_id, file_hash)
    WHERE file_hash IS NOT NULL;

CREATE INDEX IF NOT EXISTS export_file_records_run_idx
    ON erp.export_file_records (tenant_id, export_run_id, record_no);

CREATE INDEX IF NOT EXISTS export_file_records_file_idx
    ON erp.export_file_records (tenant_id, export_file_id, record_no);

CREATE INDEX IF NOT EXISTS export_file_records_source_idx
    ON erp.export_file_records (tenant_id, source_table, source_record_id);

CREATE INDEX IF NOT EXISTS export_file_records_document_idx
    ON erp.export_file_records (tenant_id, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS export_validations_run_idx
    ON erp.export_validations (tenant_id, export_run_id, validation_status, validation_level);

CREATE INDEX IF NOT EXISTS export_validations_file_idx
    ON erp.export_validations (tenant_id, export_file_id, validation_status);

CREATE INDEX IF NOT EXISTS export_validations_record_idx
    ON erp.export_validations (tenant_id, export_file_record_id, validation_status);

CREATE INDEX IF NOT EXISTS export_validations_code_idx
    ON erp.export_validations (tenant_id, validation_code, validation_scope);

CREATE INDEX IF NOT EXISTS export_audit_events_run_idx
    ON erp.export_audit_events (tenant_id, export_run_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS export_audit_events_file_idx
    ON erp.export_audit_events (tenant_id, export_file_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS export_audit_events_entity_idx
    ON erp.export_audit_events (tenant_id, entity_name, entity_id, occurred_at DESC);

ALTER TABLE erp.export_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.export_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.export_file_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.export_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.export_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.export_runs FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.export_files FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.export_file_records FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.export_validations FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.export_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS export_runs_tenant_policy ON erp.export_runs;
CREATE POLICY export_runs_tenant_policy ON erp.export_runs
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS export_files_tenant_policy ON erp.export_files;
CREATE POLICY export_files_tenant_policy ON erp.export_files
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS export_file_records_tenant_policy ON erp.export_file_records;
CREATE POLICY export_file_records_tenant_policy ON erp.export_file_records
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS export_validations_tenant_policy ON erp.export_validations;
CREATE POLICY export_validations_tenant_policy ON erp.export_validations
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS export_audit_events_tenant_policy ON erp.export_audit_events;
CREATE POLICY export_audit_events_tenant_policy ON erp.export_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.export_runs IS 'FAZ 3-9.12 export run table';
COMMENT ON TABLE erp.export_files IS 'FAZ 3-9.12 export file table';
COMMENT ON TABLE erp.export_file_records IS 'FAZ 3-9.12 export file record table';
COMMENT ON TABLE erp.export_validations IS 'FAZ 3-9.12 export validation table';
COMMENT ON TABLE erp.export_audit_events IS 'FAZ 3-9.12 export audit event table';

COMMIT;
