BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS erp;

CREATE TABLE IF NOT EXISTS erp.tdhp_charts (
    tenant_id uuid NOT NULL,
    tdhp_chart_id uuid NOT NULL DEFAULT gen_random_uuid(),

    chart_code varchar(96) NOT NULL,
    chart_name varchar(255) NOT NULL,

    country_code char(2) NOT NULL DEFAULT 'TR',
    accounting_standard varchar(64) NOT NULL DEFAULT 'TDHP',
    chart_scope varchar(64) NOT NULL DEFAULT 'GENERAL',

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    description text,
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tdhp_charts_pk PRIMARY KEY (tenant_id, tdhp_chart_id),
    CONSTRAINT tdhp_charts_code_unique UNIQUE (tenant_id, chart_code),
    CONSTRAINT tdhp_charts_standard_chk CHECK (
        accounting_standard IN ('TDHP', 'IFRS', 'LOCAL_GAAP', 'CUSTOM')
    ),
    CONSTRAINT tdhp_charts_scope_chk CHECK (
        chart_scope IN ('GENERAL', 'RETAIL', 'MARKETPLACE', 'POS', 'ACCOUNTANT_PORTAL', 'CUSTOM')
    ),
    CONSTRAINT tdhp_charts_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT tdhp_charts_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.tdhp_chart_versions (
    tenant_id uuid NOT NULL,
    tdhp_chart_version_id uuid NOT NULL DEFAULT gen_random_uuid(),
    tdhp_chart_id uuid NOT NULL,

    version_no integer NOT NULL DEFAULT 1,
    version_code varchar(96) NOT NULL,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    legal_reference text,
    change_reason text,

    approved_by uuid,
    approved_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tdhp_chart_versions_pk PRIMARY KEY (tenant_id, tdhp_chart_version_id),
    CONSTRAINT tdhp_chart_versions_chart_fk FOREIGN KEY (tenant_id, tdhp_chart_id)
        REFERENCES erp.tdhp_charts (tenant_id, tdhp_chart_id)
        ON DELETE CASCADE,
    CONSTRAINT tdhp_chart_versions_version_unique UNIQUE (tenant_id, tdhp_chart_id, version_no),
    CONSTRAINT tdhp_chart_versions_code_unique UNIQUE (tenant_id, tdhp_chart_id, version_code),
    CONSTRAINT tdhp_chart_versions_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'SUPERSEDED', 'ARCHIVED')
    ),
    CONSTRAINT tdhp_chart_versions_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.tdhp_accounts (
    tenant_id uuid NOT NULL,
    tdhp_account_id uuid NOT NULL DEFAULT gen_random_uuid(),
    tdhp_chart_version_id uuid NOT NULL,

    account_code varchar(32) NOT NULL,
    account_name varchar(255) NOT NULL,
    account_level integer NOT NULL DEFAULT 1,

    parent_account_code varchar(32),
    account_group_code varchar(32),
    account_class_code varchar(32),

    account_type varchar(64) NOT NULL,
    normal_balance varchar(16) NOT NULL,

    is_leaf boolean NOT NULL DEFAULT true,
    is_active boolean NOT NULL DEFAULT true,
    is_system_account boolean NOT NULL DEFAULT false,

    tax_related boolean NOT NULL DEFAULT false,
    cash_related boolean NOT NULL DEFAULT false,
    receivable_related boolean NOT NULL DEFAULT false,
    payable_related boolean NOT NULL DEFAULT false,
    inventory_related boolean NOT NULL DEFAULT false,

    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    description text,
    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tdhp_accounts_pk PRIMARY KEY (tenant_id, tdhp_account_id),
    CONSTRAINT tdhp_accounts_version_fk FOREIGN KEY (tenant_id, tdhp_chart_version_id)
        REFERENCES erp.tdhp_chart_versions (tenant_id, tdhp_chart_version_id)
        ON DELETE CASCADE,
    CONSTRAINT tdhp_accounts_code_unique UNIQUE (tenant_id, tdhp_chart_version_id, account_code),
    CONSTRAINT tdhp_accounts_level_chk CHECK (
        account_level >= 1 AND account_level <= 9
    ),
    CONSTRAINT tdhp_accounts_type_chk CHECK (
        account_type IN (
            'ASSET',
            'LIABILITY',
            'EQUITY',
            'REVENUE',
            'EXPENSE',
            'COST',
            'MEMORANDUM',
            'OTHER'
        )
    ),
    CONSTRAINT tdhp_accounts_normal_balance_chk CHECK (
        normal_balance IN ('DEBIT', 'CREDIT')
    ),
    CONSTRAINT tdhp_accounts_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.account_mapping_sets (
    tenant_id uuid NOT NULL,
    account_mapping_set_id uuid NOT NULL DEFAULT gen_random_uuid(),

    mapping_code varchar(96) NOT NULL,
    mapping_name varchar(255) NOT NULL,

    source_domain varchar(64) NOT NULL,
    target_chart_id uuid,

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

    CONSTRAINT account_mapping_sets_pk PRIMARY KEY (tenant_id, account_mapping_set_id),
    CONSTRAINT account_mapping_sets_code_unique UNIQUE (tenant_id, mapping_code),
    CONSTRAINT account_mapping_sets_chart_fk FOREIGN KEY (tenant_id, target_chart_id)
        REFERENCES erp.tdhp_charts (tenant_id, tdhp_chart_id)
        ON DELETE SET NULL,
    CONSTRAINT account_mapping_sets_domain_chk CHECK (
        source_domain IN (
            'SALES',
            'PROCUREMENT',
            'INVENTORY',
            'PAYMENT',
            'COLLECTION',
            'REFUND',
            'RECONCILIATION',
            'E_BELGE',
            'MARKETPLACE',
            'POS',
            'EXPORT',
            'CUSTOM'
        )
    ),
    CONSTRAINT account_mapping_sets_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'ARCHIVED')
    ),
    CONSTRAINT account_mapping_sets_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.account_mapping_versions (
    tenant_id uuid NOT NULL,
    account_mapping_version_id uuid NOT NULL DEFAULT gen_random_uuid(),
    account_mapping_set_id uuid NOT NULL,

    version_no integer NOT NULL DEFAULT 1,
    version_code varchar(96) NOT NULL,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',
    valid_from date NOT NULL DEFAULT CURRENT_DATE,
    valid_to date,

    change_reason text,
    approved_by uuid,
    approved_at timestamptz,

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT account_mapping_versions_pk PRIMARY KEY (tenant_id, account_mapping_version_id),
    CONSTRAINT account_mapping_versions_set_fk FOREIGN KEY (tenant_id, account_mapping_set_id)
        REFERENCES erp.account_mapping_sets (tenant_id, account_mapping_set_id)
        ON DELETE CASCADE,
    CONSTRAINT account_mapping_versions_version_unique UNIQUE (tenant_id, account_mapping_set_id, version_no),
    CONSTRAINT account_mapping_versions_code_unique UNIQUE (tenant_id, account_mapping_set_id, version_code),
    CONSTRAINT account_mapping_versions_status_chk CHECK (
        status IN ('DRAFT', 'ACTIVE', 'PASSIVE', 'SUPERSEDED', 'ARCHIVED')
    ),
    CONSTRAINT account_mapping_versions_date_chk CHECK (
        valid_to IS NULL OR valid_to >= valid_from
    )
);

CREATE TABLE IF NOT EXISTS erp.account_mapping_rules (
    tenant_id uuid NOT NULL,
    account_mapping_rule_id uuid NOT NULL DEFAULT gen_random_uuid(),
    account_mapping_version_id uuid NOT NULL,

    rule_no integer NOT NULL,
    rule_code varchar(96) NOT NULL,
    rule_name varchar(255) NOT NULL,

    source_object_type varchar(64) NOT NULL,
    source_event_type varchar(96),
    source_code varchar(128),
    source_condition jsonb,

    debit_account_code varchar(32),
    credit_account_code varchar(32),
    tax_account_code varchar(32),
    discount_account_code varchar(32),
    cost_account_code varchar(32),

    debit_tdhp_account_id uuid,
    credit_tdhp_account_id uuid,
    tax_tdhp_account_id uuid,

    mapping_strategy varchar(64) NOT NULL DEFAULT 'STATIC',
    priority integer NOT NULL DEFAULT 100,

    status varchar(40) NOT NULL DEFAULT 'ACTIVE',

    correlation_id varchar(128),
    request_id varchar(128),

    created_by uuid,
    updated_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT account_mapping_rules_pk PRIMARY KEY (tenant_id, account_mapping_rule_id),
    CONSTRAINT account_mapping_rules_version_fk FOREIGN KEY (tenant_id, account_mapping_version_id)
        REFERENCES erp.account_mapping_versions (tenant_id, account_mapping_version_id)
        ON DELETE CASCADE,
    CONSTRAINT account_mapping_rules_debit_account_fk FOREIGN KEY (tenant_id, debit_tdhp_account_id)
        REFERENCES erp.tdhp_accounts (tenant_id, tdhp_account_id)
        ON DELETE SET NULL,
    CONSTRAINT account_mapping_rules_credit_account_fk FOREIGN KEY (tenant_id, credit_tdhp_account_id)
        REFERENCES erp.tdhp_accounts (tenant_id, tdhp_account_id)
        ON DELETE SET NULL,
    CONSTRAINT account_mapping_rules_tax_account_fk FOREIGN KEY (tenant_id, tax_tdhp_account_id)
        REFERENCES erp.tdhp_accounts (tenant_id, tdhp_account_id)
        ON DELETE SET NULL,
    CONSTRAINT account_mapping_rules_rule_unique UNIQUE (tenant_id, account_mapping_version_id, rule_no),
    CONSTRAINT account_mapping_rules_code_unique UNIQUE (tenant_id, account_mapping_version_id, rule_code),
    CONSTRAINT account_mapping_rules_source_object_chk CHECK (
        source_object_type IN (
            'SALES_INVOICE',
            'SALES_ORDER',
            'DELIVERY',
            'PURCHASE_INVOICE',
            'PURCHASE_ORDER',
            'RECEIPT',
            'STOCK_MOVEMENT',
            'PAYMENT',
            'COLLECTION',
            'REFUND',
            'BANK_TRANSACTION',
            'E_BELGE',
            'MARKETPLACE_COMMISSION',
            'POS_SALE',
            'CUSTOM'
        )
    ),
    CONSTRAINT account_mapping_rules_strategy_chk CHECK (
        mapping_strategy IN ('STATIC', 'CONDITION_BASED', 'TAX_RULE_BASED', 'ITEM_BASED', 'PARTY_BASED', 'CUSTOM')
    ),
    CONSTRAINT account_mapping_rules_status_chk CHECK (
        status IN ('ACTIVE', 'PASSIVE', 'ARCHIVED')
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS tdhp_charts_code_uidx
    ON erp.tdhp_charts (tenant_id, chart_code);

CREATE INDEX IF NOT EXISTS tdhp_charts_status_idx
    ON erp.tdhp_charts (tenant_id, status, valid_from DESC);

CREATE INDEX IF NOT EXISTS tdhp_chart_versions_chart_idx
    ON erp.tdhp_chart_versions (tenant_id, tdhp_chart_id, version_no DESC);

CREATE INDEX IF NOT EXISTS tdhp_chart_versions_status_idx
    ON erp.tdhp_chart_versions (tenant_id, status, valid_from DESC);

CREATE INDEX IF NOT EXISTS tdhp_accounts_version_code_idx
    ON erp.tdhp_accounts (tenant_id, tdhp_chart_version_id, account_code);

CREATE INDEX IF NOT EXISTS tdhp_accounts_parent_idx
    ON erp.tdhp_accounts (tenant_id, tdhp_chart_version_id, parent_account_code);

CREATE INDEX IF NOT EXISTS tdhp_accounts_type_idx
    ON erp.tdhp_accounts (tenant_id, account_type, normal_balance);

CREATE UNIQUE INDEX IF NOT EXISTS account_mapping_sets_code_uidx
    ON erp.account_mapping_sets (tenant_id, mapping_code);

CREATE INDEX IF NOT EXISTS account_mapping_sets_domain_status_idx
    ON erp.account_mapping_sets (tenant_id, source_domain, status);

CREATE INDEX IF NOT EXISTS account_mapping_versions_set_idx
    ON erp.account_mapping_versions (tenant_id, account_mapping_set_id, version_no DESC);

CREATE INDEX IF NOT EXISTS account_mapping_versions_status_idx
    ON erp.account_mapping_versions (tenant_id, status, valid_from DESC);

CREATE INDEX IF NOT EXISTS account_mapping_rules_version_idx
    ON erp.account_mapping_rules (tenant_id, account_mapping_version_id, rule_no);

CREATE INDEX IF NOT EXISTS account_mapping_rules_source_idx
    ON erp.account_mapping_rules (tenant_id, source_object_type, source_event_type, priority);

CREATE INDEX IF NOT EXISTS account_mapping_rules_accounts_idx
    ON erp.account_mapping_rules (tenant_id, debit_account_code, credit_account_code, tax_account_code);

ALTER TABLE erp.tdhp_charts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.tdhp_chart_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.tdhp_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_rules ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp.tdhp_charts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.tdhp_chart_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.tdhp_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_sets FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE erp.account_mapping_rules FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tdhp_charts_tenant_policy ON erp.tdhp_charts;
CREATE POLICY tdhp_charts_tenant_policy ON erp.tdhp_charts
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS tdhp_chart_versions_tenant_policy ON erp.tdhp_chart_versions;
CREATE POLICY tdhp_chart_versions_tenant_policy ON erp.tdhp_chart_versions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS tdhp_accounts_tenant_policy ON erp.tdhp_accounts;
CREATE POLICY tdhp_accounts_tenant_policy ON erp.tdhp_accounts
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS account_mapping_sets_tenant_policy ON erp.account_mapping_sets;
CREATE POLICY account_mapping_sets_tenant_policy ON erp.account_mapping_sets
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS account_mapping_versions_tenant_policy ON erp.account_mapping_versions;
CREATE POLICY account_mapping_versions_tenant_policy ON erp.account_mapping_versions
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

DROP POLICY IF EXISTS account_mapping_rules_tenant_policy ON erp.account_mapping_rules;
CREATE POLICY account_mapping_rules_tenant_policy ON erp.account_mapping_rules
    USING (tenant_id::text = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));

COMMENT ON TABLE erp.tdhp_charts IS 'FAZ 3-9.8 TDHP chart master table';
COMMENT ON TABLE erp.tdhp_chart_versions IS 'FAZ 3-9.8 TDHP chart version table';
COMMENT ON TABLE erp.tdhp_accounts IS 'FAZ 3-9.8 TDHP account table';
COMMENT ON TABLE erp.account_mapping_sets IS 'FAZ 3-9.8 account mapping set table';
COMMENT ON TABLE erp.account_mapping_versions IS 'FAZ 3-9.8 account mapping version table';
COMMENT ON TABLE erp.account_mapping_rules IS 'FAZ 3-9.8 account mapping rule table';

COMMIT;
