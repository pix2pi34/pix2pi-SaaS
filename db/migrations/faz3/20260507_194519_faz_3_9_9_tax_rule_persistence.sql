BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.tax_rules (
    tenant_id uuid NOT NULL,
    tax_rule_id uuid NOT NULL DEFAULT gen_random_uuid(),

    rule_code varchar(96) NOT NULL,
    rule_name varchar(255) NOT NULL,
    rule_scope varchar(64) NOT NULL DEFAULT 'GENERAL',
    rule_type varchar(64) NOT NULL DEFAULT 'VAT',

    country_code char(2) NOT NULL DEFAULT 'TR',
    tax_authority varchar(128) NOT NULL DEFAULT 'GIB',

    default_tax_rate numeric(9,4) NOT NULL DEFAULT 0,
    default_tax_account_code varchar(32),
    default_receivable_account_code varchar(32),
    default_payable_account_code varchar(32),

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    priority integer NOT NULL DEFAULT 100,

    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    description text,
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tax_rules_pk PRIMARY KEY (tenant_id, tax_rule_id),
    CONSTRAINT tax_rules_scope_chk CHECK (
        rule_scope IN (
            'GENERAL',
            'SALES',
            'PURCHASE',
            'E_BELGE',
            'EXPORT',
            'IMPORT',
            'MARKETPLACE',
            'POS'
        )
    ),
    CONSTRAINT tax_rules_type_chk CHECK (
        rule_type IN (
            'VAT',
            'WITHHOLDING',
            'STOPPAGE',
            'SCT',
            'STAMP',
            'EXEMPTION',
            'OTHER'
        )
    ),
    CONSTRAINT tax_rules_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT tax_rules_rate_chk CHECK (
        default_tax_rate >= 0
    ),
    CONSTRAINT tax_rules_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.tax_rule_versions (
    tenant_id uuid NOT NULL,
    tax_rule_version_id uuid NOT NULL DEFAULT gen_random_uuid(),
    tax_rule_id uuid NOT NULL,

    version_no integer NOT NULL DEFAULT 1,
    version_code varchar(96) NOT NULL,

    tax_rate numeric(9,4) NOT NULL DEFAULT 0,
    calculation_method varchar(64) NOT NULL DEFAULT 'PERCENTAGE',

    tax_account_code varchar(32),
    receivable_account_code varchar(32),
    payable_account_code varchar(32),
    discount_tax_behavior varchar(64) NOT NULL DEFAULT 'AFTER_DISCOUNT',

    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    change_reason text,
    legal_reference text,

    approved_by uuid,
    approved_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tax_rule_versions_pk PRIMARY KEY (tenant_id, tax_rule_version_id),
    CONSTRAINT tax_rule_versions_rule_fk FOREIGN KEY (tenant_id, tax_rule_id)
        REFERENCES erp.tax_rules (tenant_id, tax_rule_id)
        ON DELETE CASCADE,
    CONSTRAINT tax_rule_versions_version_unique UNIQUE (tenant_id, tax_rule_id, version_no),
    CONSTRAINT tax_rule_versions_code_unique UNIQUE (tenant_id, tax_rule_id, version_code),
    CONSTRAINT tax_rule_versions_rate_chk CHECK (
        tax_rate >= 0
    ),
    CONSTRAINT tax_rule_versions_method_chk CHECK (
        calculation_method IN ('PERCENTAGE', 'FIXED_AMOUNT', 'EXEMPT', 'REVERSE_CHARGE')
    ),
    CONSTRAINT tax_rule_versions_discount_behavior_chk CHECK (
        discount_tax_behavior IN ('BEFORE_DISCOUNT', 'AFTER_DISCOUNT', 'NO_TAX_ON_DISCOUNT')
    ),
    CONSTRAINT tax_rule_versions_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'SUPERSEDED', 'ARCHIVED')
    ),
    CONSTRAINT tax_rule_versions_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.tax_rule_conditions (
    tenant_id uuid NOT NULL,
    tax_rule_condition_id uuid NOT NULL DEFAULT gen_random_uuid(),
    tax_rule_version_id uuid NOT NULL,

    condition_no integer NOT NULL,
    condition_type varchar(64) NOT NULL,
    operator varchar(32) NOT NULL DEFAULT 'EQUALS',
    condition_value text NOT NULL,

    is_required boolean NOT NULL DEFAULT true,
    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tax_rule_conditions_pk PRIMARY KEY (tenant_id, tax_rule_condition_id),
    CONSTRAINT tax_rule_conditions_version_fk FOREIGN KEY (tenant_id, tax_rule_version_id)
        REFERENCES erp.tax_rule_versions (tenant_id, tax_rule_version_id)
        ON DELETE CASCADE,
    CONSTRAINT tax_rule_conditions_line_unique UNIQUE (tenant_id, tax_rule_version_id, condition_no),
    CONSTRAINT tax_rule_conditions_type_chk CHECK (
        condition_type IN (
            'PRODUCT_CATEGORY',
            'ITEM',
            'PARTY_TYPE',
            'DOCUMENT_TYPE',
            'REGION',
            'AMOUNT_RANGE',
            'TAX_EXEMPTION_CODE',
            'E_BELGE_TYPE',
            'POS_CHANNEL',
            'CUSTOM'
        )
    ),
    CONSTRAINT tax_rule_conditions_operator_chk CHECK (
        operator IN ('EQUALS', 'NOT_EQUALS', 'IN', 'NOT_IN', 'GT', 'GTE', 'LT', 'LTE', 'BETWEEN', 'MATCHES')
    ),
    CONSTRAINT tax_rule_conditions_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    )
);

CREATE TABLE IF NOT EXISTS erp.tax_rule_audit_events (
    tenant_id uuid NOT NULL,
    tax_rule_audit_event_id uuid NOT NULL DEFAULT gen_random_uuid(),

    tax_rule_id uuid,
    tax_rule_version_id uuid,

    audit_action varchar(64) NOT NULL,
    entity_name varchar(96) NOT NULL,
    entity_id uuid,

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

    CONSTRAINT tax_rule_audit_events_pk PRIMARY KEY (tenant_id, tax_rule_audit_event_id),
    CONSTRAINT tax_rule_audit_events_rule_fk FOREIGN KEY (tenant_id, tax_rule_id)
        REFERENCES erp.tax_rules (tenant_id, tax_rule_id)
        ON DELETE SET NULL,
    CONSTRAINT tax_rule_audit_events_version_fk FOREIGN KEY (tenant_id, tax_rule_version_id)
        REFERENCES erp.tax_rule_versions (tenant_id, tax_rule_version_id)
        ON DELETE SET NULL,
    CONSTRAINT tax_rule_audit_events_action_chk CHECK (
        audit_action IN (
            'CREATE',
            'UPDATE',
            'ACTIVATE',
            'PASSIVATE',
            'APPROVE',
            'SUPERSEDE',
            'ARCHIVE',
            'DELETE',
            'CALCULATION_TEST',
            'SYSTEM_MIGRATION'
        )
    )
);

ALTER TABLE erp.tax_rules
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_id uuid,
    ADD COLUMN IF NOT EXISTS rule_code varchar(96),
    ADD COLUMN IF NOT EXISTS rule_name varchar(255),
    ADD COLUMN IF NOT EXISTS rule_scope varchar(64) DEFAULT 'GENERAL',
    ADD COLUMN IF NOT EXISTS rule_type varchar(64) DEFAULT 'VAT',
    ADD COLUMN IF NOT EXISTS country_code char(2) DEFAULT 'TR',
    ADD COLUMN IF NOT EXISTS tax_authority varchar(128) DEFAULT 'GIB',
    ADD COLUMN IF NOT EXISTS default_tax_rate numeric(9,4) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS default_tax_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS default_receivable_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS default_payable_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS status varchar(40) DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS priority integer DEFAULT 100,
    ADD COLUMN IF NOT EXISTS valid_from date DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS valid_to date,
    ADD COLUMN IF NOT EXISTS description text,
    ADD COLUMN IF NOT EXISTS correlation_id varchar(128),
    ADD COLUMN IF NOT EXISTS request_id varchar(128),
    ADD COLUMN IF NOT EXISTS created_by uuid,
    ADD COLUMN IF NOT EXISTS updated_by uuid,
    ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
    ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE erp.tax_rule_versions
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_version_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_id uuid,
    ADD COLUMN IF NOT EXISTS version_no integer DEFAULT 1,
    ADD COLUMN IF NOT EXISTS version_code varchar(96),
    ADD COLUMN IF NOT EXISTS tax_rate numeric(9,4) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS calculation_method varchar(64) DEFAULT 'PERCENTAGE',
    ADD COLUMN IF NOT EXISTS tax_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS receivable_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS payable_account_code varchar(32),
    ADD COLUMN IF NOT EXISTS discount_tax_behavior varchar(64) DEFAULT 'AFTER_DISCOUNT',
    ADD COLUMN IF NOT EXISTS valid_from date DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS valid_to date,
    ADD COLUMN IF NOT EXISTS status varchar(40) DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS change_reason text,
    ADD COLUMN IF NOT EXISTS legal_reference text,
    ADD COLUMN IF NOT EXISTS approved_by uuid,
    ADD COLUMN IF NOT EXISTS approved_at timestamptz,
    ADD COLUMN IF NOT EXISTS correlation_id varchar(128),
    ADD COLUMN IF NOT EXISTS request_id varchar(128),
    ADD COLUMN IF NOT EXISTS created_by uuid,
    ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

ALTER TABLE erp.tax_rule_conditions
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_condition_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_version_id uuid,
    ADD COLUMN IF NOT EXISTS condition_no integer,
    ADD COLUMN IF NOT EXISTS condition_type varchar(64),
    ADD COLUMN IF NOT EXISTS operator varchar(32) DEFAULT 'EQUALS',
    ADD COLUMN IF NOT EXISTS condition_value text,
    ADD COLUMN IF NOT EXISTS is_required boolean DEFAULT true,
    ADD COLUMN IF NOT EXISTS status varchar(40) DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
    ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE erp.tax_rule_audit_events
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_audit_event_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_id uuid,
    ADD COLUMN IF NOT EXISTS tax_rule_version_id uuid,
    ADD COLUMN IF NOT EXISTS audit_action varchar(64),
    ADD COLUMN IF NOT EXISTS entity_name varchar(96),
    ADD COLUMN IF NOT EXISTS entity_id uuid,
    ADD COLUMN IF NOT EXISTS old_value jsonb,
    ADD COLUMN IF NOT EXISTS new_value jsonb,
    ADD COLUMN IF NOT EXISTS reason_code varchar(96),
    ADD COLUMN IF NOT EXISTS reason_message text,
    ADD COLUMN IF NOT EXISTS actor_user_id uuid,
    ADD COLUMN IF NOT EXISTS actor_role varchar(96),
    ADD COLUMN IF NOT EXISTS correlation_id varchar(128),
    ADD COLUMN IF NOT EXISTS request_id varchar(128),
    ADD COLUMN IF NOT EXISTS occurred_at timestamptz DEFAULT now(),
    ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS tax_rules_code_uidx
    ON erp.tax_rules (tenant_id, rule_code);

CREATE INDEX IF NOT EXISTS tax_rules_scope_type_status_idx
    ON erp.tax_rules (tenant_id, rule_scope, rule_type, status);

CREATE INDEX IF NOT EXISTS tax_rules_validity_idx
    ON erp.tax_rules (tenant_id, valid_from DESC, valid_to);

CREATE INDEX IF NOT EXISTS tax_rule_versions_rule_idx
    ON erp.tax_rule_versions (tenant_id, tax_rule_id, version_no DESC);

CREATE INDEX IF NOT EXISTS tax_rule_versions_status_validity_idx
    ON erp.tax_rule_versions (tenant_id, status, valid_from DESC, valid_to);

CREATE INDEX IF NOT EXISTS tax_rule_conditions_version_idx
    ON erp.tax_rule_conditions (tenant_id, tax_rule_version_id, condition_no);

CREATE INDEX IF NOT EXISTS tax_rule_conditions_type_idx
    ON erp.tax_rule_conditions (tenant_id, condition_type, operator);

CREATE INDEX IF NOT EXISTS tax_rule_audit_events_rule_idx
    ON erp.tax_rule_audit_events (tenant_id, tax_rule_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS tax_rule_audit_events_version_idx
    ON erp.tax_rule_audit_events (tenant_id, tax_rule_version_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS tax_rule_audit_events_action_idx
    ON erp.tax_rule_audit_events (tenant_id, audit_action, occurred_at DESC);

ALTER TABLE erp.tax_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.tax_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_conditions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.tax_rule_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tax_rules_tenant_policy ON erp.tax_rules;
CREATE POLICY tax_rules_tenant_policy ON erp.tax_rules
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS tax_rule_versions_tenant_policy ON erp.tax_rule_versions;
CREATE POLICY tax_rule_versions_tenant_policy ON erp.tax_rule_versions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS tax_rule_conditions_tenant_policy ON erp.tax_rule_conditions;
CREATE POLICY tax_rule_conditions_tenant_policy ON erp.tax_rule_conditions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS tax_rule_audit_events_tenant_policy ON erp.tax_rule_audit_events;
CREATE POLICY tax_rule_audit_events_tenant_policy ON erp.tax_rule_audit_events
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.tax_rules IS 'FAZ 3-9.9 tax rule master table';
COMMENT ON TABLE erp.tax_rule_versions IS 'FAZ 3-9.9 tax rule version table';
COMMENT ON TABLE erp.tax_rule_conditions IS 'FAZ 3-9.9 tax rule condition table';
COMMENT ON TABLE erp.tax_rule_audit_events IS 'FAZ 3-9.9 tax rule audit event table';

COMMIT;
