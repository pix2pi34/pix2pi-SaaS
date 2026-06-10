-- FAZ 3 / 9.10.1
-- Cash / Bank / Payment persistence

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_cash_accounts (
    cash_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    cash_code TEXT NOT NULL,
    cash_name TEXT NOT NULL,

    account_code TEXT,
    account_name TEXT,

    currency_code TEXT NOT NULL DEFAULT 'TRY',

    opening_balance NUMERIC(18, 2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(18, 2) NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_cash_accounts_status_chk
        CHECK (status IN ('active', 'passive', 'locked')),

    CONSTRAINT erp_cash_accounts_balance_chk
        CHECK (opening_balance >= 0 AND current_balance >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_cash_accounts_tenant_code
    ON erp_cash_accounts (tenant_id, cash_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_cash_accounts_tenant_account
    ON erp_cash_accounts (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_cash_accounts_tenant_active
    ON erp_cash_accounts (tenant_id, is_active);


CREATE TABLE IF NOT EXISTS erp_bank_accounts (
    bank_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    bank_code TEXT NOT NULL,
    bank_name TEXT NOT NULL,

    branch_code TEXT,
    branch_name TEXT,

    iban TEXT,
    account_no TEXT,

    account_code TEXT,
    account_name TEXT,

    currency_code TEXT NOT NULL DEFAULT 'TRY',

    opening_balance NUMERIC(18, 2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(18, 2) NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_bank_accounts_status_chk
        CHECK (status IN ('active', 'passive', 'locked')),

    CONSTRAINT erp_bank_accounts_balance_chk
        CHECK (opening_balance >= 0 AND current_balance >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_bank_accounts_tenant_code
    ON erp_bank_accounts (tenant_id, bank_code)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_bank_accounts_tenant_iban
    ON erp_bank_accounts (tenant_id, iban);

CREATE INDEX IF NOT EXISTS ix_erp_bank_accounts_tenant_account
    ON erp_bank_accounts (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_bank_accounts_tenant_active
    ON erp_bank_accounts (tenant_id, is_active);


CREATE TABLE IF NOT EXISTS erp_payment_transactions (
    payment_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    payment_no TEXT NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,

    payment_type TEXT NOT NULL,
    payment_direction TEXT NOT NULL,
    payment_method TEXT NOT NULL,

    cash_account_id UUID REFERENCES erp_cash_accounts(cash_account_id) ON DELETE RESTRICT,
    bank_account_id UUID REFERENCES erp_bank_accounts(bank_account_id) ON DELETE RESTRICT,

    party_id UUID REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,

    source_module TEXT NOT NULL DEFAULT 'manual',
    source_document_type TEXT,
    source_document_id UUID,

    journal_entry_id UUID REFERENCES erp_journal_entries(journal_entry_id) ON DELETE RESTRICT,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    fee_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_fee_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    net_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_net_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'draft',

    posted_at TIMESTAMPTZ,
    posted_by TEXT,

    cancelled_at TIMESTAMPTZ,
    cancelled_by TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_payment_transactions_payment_type_chk
        CHECK (payment_type IN ('collection', 'payment', 'transfer', 'refund', 'fee', 'adjustment')),

    CONSTRAINT erp_payment_transactions_direction_chk
        CHECK (payment_direction IN ('in', 'out', 'neutral')),

    CONSTRAINT erp_payment_transactions_method_chk
        CHECK (payment_method IN ('cash', 'bank_transfer', 'credit_card', 'debit_card', 'pos', 'check', 'promissory_note', 'other')),

    CONSTRAINT erp_payment_transactions_source_module_chk
        CHECK (source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')),

    CONSTRAINT erp_payment_transactions_status_chk
        CHECK (status IN ('draft', 'posted', 'cancelled', 'reversed')),

    CONSTRAINT erp_payment_transactions_amount_chk
        CHECK (
            exchange_rate > 0
            AND amount >= 0
            AND local_amount >= 0
            AND fee_amount >= 0
            AND local_fee_amount >= 0
            AND net_amount >= 0
            AND local_net_amount >= 0
        ),

    CONSTRAINT erp_payment_transactions_account_presence_chk
        CHECK (
            cash_account_id IS NOT NULL
            OR bank_account_id IS NOT NULL
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_payment_transactions_tenant_no
    ON erp_payment_transactions (tenant_id, payment_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_date
    ON erp_payment_transactions (tenant_id, payment_date);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_type
    ON erp_payment_transactions (tenant_id, payment_type);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_direction
    ON erp_payment_transactions (tenant_id, payment_direction);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_method
    ON erp_payment_transactions (tenant_id, payment_method);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_cash
    ON erp_payment_transactions (tenant_id, cash_account_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_bank
    ON erp_payment_transactions (tenant_id, bank_account_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_party
    ON erp_payment_transactions (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_customer
    ON erp_payment_transactions (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_vendor
    ON erp_payment_transactions (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_source
    ON erp_payment_transactions (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_journal
    ON erp_payment_transactions (tenant_id, journal_entry_id);

CREATE INDEX IF NOT EXISTS ix_erp_payment_transactions_tenant_status
    ON erp_payment_transactions (tenant_id, status);


ALTER TABLE erp_cash_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_payment_transactions ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_cash_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_bank_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_payment_transactions FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_cash_accounts_tenant_isolation_policy
    ON erp_cash_accounts
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_bank_accounts_tenant_isolation_policy
    ON erp_bank_accounts
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_payment_transactions_tenant_isolation_policy
    ON erp_payment_transactions
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
