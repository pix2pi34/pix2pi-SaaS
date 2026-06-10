-- FAZ 3 / 9.9.1
-- Tax / KDV / Tevkifat persistence
--
-- erp_tax_codes = tenant bazli vergi kodlari
-- erp_tax_rates = oran ve gecerlilik araliklari
-- erp_tax_transactions = belge/fis kaynakli vergi hareketleri

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_tax_codes (
    tax_code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    tax_code TEXT NOT NULL,
    tax_name TEXT NOT NULL,

    tax_type TEXT NOT NULL,

    account_code TEXT,
    account_name TEXT,

    is_recoverable BOOLEAN NOT NULL DEFAULT false,
    is_payable BOOLEAN NOT NULL DEFAULT true,
    is_withholding BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_tax_codes_tax_type_chk
        CHECK (tax_type IN ('vat', 'withholding', 'stamp', 'excise', 'income_tax', 'corporate_tax', 'other')),

    CONSTRAINT erp_tax_codes_status_chk
        CHECK (status IN ('active', 'passive', 'locked'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_tax_codes_tenant_code
    ON erp_tax_codes (tenant_id, tax_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_tax_codes_tenant_type
    ON erp_tax_codes (tenant_id, tax_type);

CREATE INDEX IF NOT EXISTS ix_erp_tax_codes_tenant_account
    ON erp_tax_codes (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_tax_codes_tenant_active
    ON erp_tax_codes (tenant_id, is_active);

CREATE INDEX IF NOT EXISTS ix_erp_tax_codes_tenant_withholding
    ON erp_tax_codes (tenant_id, is_withholding);


CREATE TABLE IF NOT EXISTS erp_tax_rates (
    tax_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    tax_code_id UUID NOT NULL REFERENCES erp_tax_codes(tax_code_id) ON DELETE RESTRICT,

    tax_code TEXT NOT NULL,

    rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 0,

    withholding_numerator INTEGER,
    withholding_denominator INTEGER,

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    is_default BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_tax_rates_rate_chk
        CHECK (rate_percent >= 0 AND rate_percent <= 100),

    CONSTRAINT erp_tax_rates_withholding_ratio_chk
        CHECK (
            (withholding_numerator IS NULL AND withholding_denominator IS NULL)
            OR
            (
                withholding_numerator IS NOT NULL
                AND withholding_denominator IS NOT NULL
                AND withholding_numerator >= 0
                AND withholding_denominator > 0
                AND withholding_numerator <= withholding_denominator
            )
        ),

    CONSTRAINT erp_tax_rates_valid_range_chk
        CHECK (valid_to IS NULL OR valid_to >= valid_from),

    CONSTRAINT erp_tax_rates_status_chk
        CHECK (status IN ('active', 'passive', 'locked'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_tax_rates_tenant_code_rate_valid
    ON erp_tax_rates (tenant_id, tax_code, rate_percent, valid_from)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_tax_rates_tenant_code
    ON erp_tax_rates (tenant_id, tax_code);

CREATE INDEX IF NOT EXISTS ix_erp_tax_rates_tenant_tax_code_id
    ON erp_tax_rates (tenant_id, tax_code_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_rates_tenant_valid
    ON erp_tax_rates (tenant_id, valid_from, valid_to);

CREATE INDEX IF NOT EXISTS ix_erp_tax_rates_tenant_default
    ON erp_tax_rates (tenant_id, is_default);

CREATE INDEX IF NOT EXISTS ix_erp_tax_rates_tenant_active
    ON erp_tax_rates (tenant_id, is_active);


CREATE TABLE IF NOT EXISTS erp_tax_transactions (
    tax_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    tax_code_id UUID REFERENCES erp_tax_codes(tax_code_id) ON DELETE RESTRICT,
    tax_rate_id UUID REFERENCES erp_tax_rates(tax_rate_id) ON DELETE RESTRICT,

    tax_code TEXT NOT NULL,
    tax_name TEXT,

    tax_type TEXT NOT NULL,

    source_module TEXT NOT NULL,
    source_document_type TEXT,
    source_document_id UUID,
    source_line_id UUID,

    journal_entry_id UUID REFERENCES erp_journal_entries(journal_entry_id) ON DELETE RESTRICT,
    journal_line_id UUID REFERENCES erp_journal_lines(journal_line_id) ON DELETE RESTRICT,

    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    fiscal_year INTEGER NOT NULL,
    fiscal_period TEXT NOT NULL,

    base_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    withholding_numerator INTEGER,
    withholding_denominator INTEGER,
    withholding_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    payable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    recoverable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    local_base_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_tax_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    direction TEXT NOT NULL,

    party_id UUID REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,

    status TEXT NOT NULL DEFAULT 'posted',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_tax_transactions_tax_type_chk
        CHECK (tax_type IN ('vat', 'withholding', 'stamp', 'excise', 'income_tax', 'corporate_tax', 'other')),

    CONSTRAINT erp_tax_transactions_source_module_chk
        CHECK (source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')),

    CONSTRAINT erp_tax_transactions_direction_chk
        CHECK (direction IN ('payable', 'recoverable', 'neutral')),

    CONSTRAINT erp_tax_transactions_amount_chk
        CHECK (
            base_amount >= 0
            AND rate_percent >= 0
            AND rate_percent <= 100
            AND tax_amount >= 0
            AND withholding_amount >= 0
            AND payable_amount >= 0
            AND recoverable_amount >= 0
            AND exchange_rate > 0
            AND local_base_amount >= 0
            AND local_tax_amount >= 0
        ),

    CONSTRAINT erp_tax_transactions_withholding_ratio_chk
        CHECK (
            (withholding_numerator IS NULL AND withholding_denominator IS NULL)
            OR
            (
                withholding_numerator IS NOT NULL
                AND withholding_denominator IS NOT NULL
                AND withholding_numerator >= 0
                AND withholding_denominator > 0
                AND withholding_numerator <= withholding_denominator
            )
        ),

    CONSTRAINT erp_tax_transactions_status_chk
        CHECK (status IN ('draft', 'posted', 'reversed', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_code_date
    ON erp_tax_transactions (tenant_id, tax_code, transaction_date);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_type
    ON erp_tax_transactions (tenant_id, tax_type);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_fiscal
    ON erp_tax_transactions (tenant_id, fiscal_year, fiscal_period);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_source
    ON erp_tax_transactions (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_journal
    ON erp_tax_transactions (tenant_id, journal_entry_id, journal_line_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_party
    ON erp_tax_transactions (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_customer
    ON erp_tax_transactions (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_vendor
    ON erp_tax_transactions (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_direction
    ON erp_tax_transactions (tenant_id, direction);

CREATE INDEX IF NOT EXISTS ix_erp_tax_transactions_tenant_status
    ON erp_tax_transactions (tenant_id, status);


ALTER TABLE erp_tax_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_tax_transactions ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_tax_codes FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_tax_rates FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_tax_transactions FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_tax_codes_tenant_isolation_policy
    ON erp_tax_codes
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_tax_rates_tenant_isolation_policy
    ON erp_tax_rates
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_tax_transactions_tenant_isolation_policy
    ON erp_tax_transactions
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
