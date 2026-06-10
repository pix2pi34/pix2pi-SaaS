-- FAZ 3 / 9.8.1
-- TDHP / Chart of Accounts persistence
--
-- erp_chart_accounts = tenant bazli hesap plani
-- erp_account_mapping_rules = satis / procurement / vergi / odeme gibi kaynaklardan otomatik hesap secim kurallari

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_chart_accounts (
    chart_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    account_code TEXT NOT NULL,
    account_name TEXT NOT NULL,

    parent_account_code TEXT,

    account_level INTEGER NOT NULL DEFAULT 1,

    account_class TEXT,
    account_group TEXT,

    account_type TEXT NOT NULL,
    normal_balance TEXT NOT NULL,

    is_postable BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,

    currency_code TEXT NOT NULL DEFAULT 'TRY',

    tax_code TEXT,
    vat_rate NUMERIC(5, 2),

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_chart_accounts_account_level_chk
        CHECK (account_level > 0),

    CONSTRAINT erp_chart_accounts_account_type_chk
        CHECK (account_type IN (
            'asset',
            'liability',
            'equity',
            'revenue',
            'expense',
            'contra_asset',
            'contra_liability',
            'tax',
            'off_balance'
        )),

    CONSTRAINT erp_chart_accounts_normal_balance_chk
        CHECK (normal_balance IN ('debit', 'credit', 'zero')),

    CONSTRAINT erp_chart_accounts_status_chk
        CHECK (status IN ('active', 'passive', 'locked')),

    CONSTRAINT erp_chart_accounts_vat_rate_chk
        CHECK (vat_rate IS NULL OR (vat_rate >= 0 AND vat_rate <= 100))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_chart_accounts_tenant_code
    ON erp_chart_accounts (tenant_id, account_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_parent
    ON erp_chart_accounts (tenant_id, parent_account_code);

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_type
    ON erp_chart_accounts (tenant_id, account_type);

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_class_group
    ON erp_chart_accounts (tenant_id, account_class, account_group);

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_postable
    ON erp_chart_accounts (tenant_id, is_postable);

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_active
    ON erp_chart_accounts (tenant_id, is_active);

CREATE INDEX IF NOT EXISTS ix_erp_chart_accounts_tenant_tax
    ON erp_chart_accounts (tenant_id, tax_code, vat_rate);


CREATE TABLE IF NOT EXISTS erp_account_mapping_rules (
    account_mapping_rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    mapping_key TEXT NOT NULL,

    source_module TEXT NOT NULL,
    source_document_type TEXT,

    event_type TEXT,
    line_type TEXT,

    account_code TEXT NOT NULL,
    account_name TEXT,

    vat_rate NUMERIC(5, 2),

    priority INTEGER NOT NULL DEFAULT 100,

    is_default BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_account_mapping_rules_source_module_chk
        CHECK (source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')),

    CONSTRAINT erp_account_mapping_rules_priority_chk
        CHECK (priority > 0),

    CONSTRAINT erp_account_mapping_rules_status_chk
        CHECK (status IN ('active', 'passive', 'locked')),

    CONSTRAINT erp_account_mapping_rules_vat_rate_chk
        CHECK (vat_rate IS NULL OR (vat_rate >= 0 AND vat_rate <= 100))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_account_mapping_rules_tenant_key
    ON erp_account_mapping_rules (tenant_id, mapping_key)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_source
    ON erp_account_mapping_rules (tenant_id, source_module, source_document_type);

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_event_line
    ON erp_account_mapping_rules (tenant_id, event_type, line_type);

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_account
    ON erp_account_mapping_rules (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_vat
    ON erp_account_mapping_rules (tenant_id, vat_rate);

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_priority
    ON erp_account_mapping_rules (tenant_id, priority);

CREATE INDEX IF NOT EXISTS ix_erp_account_mapping_rules_tenant_default
    ON erp_account_mapping_rules (tenant_id, is_default);


ALTER TABLE erp_chart_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_account_mapping_rules ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_chart_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_account_mapping_rules FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_chart_accounts_tenant_isolation_policy
    ON erp_chart_accounts
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_account_mapping_rules_tenant_isolation_policy
    ON erp_account_mapping_rules
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
