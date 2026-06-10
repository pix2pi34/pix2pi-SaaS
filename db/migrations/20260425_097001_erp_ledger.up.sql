-- FAZ 3 / 9.7.1
-- Ledger balance / account movement persistence
--
-- erp_account_movements = posted journal line -> hesap hareketi
-- erp_ledger_balances   = dönemsel hesap bakiye özeti

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_account_movements (
    account_movement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    journal_entry_id UUID NOT NULL REFERENCES erp_journal_entries(journal_entry_id) ON DELETE RESTRICT,
    journal_line_id UUID NOT NULL REFERENCES erp_journal_lines(journal_line_id) ON DELETE RESTRICT,

    movement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    posting_date DATE NOT NULL DEFAULT CURRENT_DATE,

    fiscal_year INTEGER NOT NULL,
    fiscal_period TEXT NOT NULL,

    account_code TEXT NOT NULL,
    account_name TEXT,

    description TEXT,

    debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    local_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    direction TEXT NOT NULL,

    source_module TEXT NOT NULL DEFAULT 'manual',
    source_document_type TEXT,
    source_document_id UUID,

    party_id UUID REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,
    item_id UUID REFERENCES erp_items(item_id) ON DELETE RESTRICT,

    cost_center_code TEXT,
    project_code TEXT,

    status TEXT NOT NULL DEFAULT 'posted',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_account_movements_direction_chk
        CHECK (direction IN ('debit', 'credit')),

    CONSTRAINT erp_account_movements_status_chk
        CHECK (status IN ('posted', 'reversed', 'cancelled')),

    CONSTRAINT erp_account_movements_source_module_chk
        CHECK (source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')),

    CONSTRAINT erp_account_movements_amount_chk
        CHECK (
            exchange_rate > 0
            AND debit_amount >= 0
            AND credit_amount >= 0
            AND local_debit_amount >= 0
            AND local_credit_amount >= 0
            AND (
                (direction = 'debit' AND debit_amount > 0 AND credit_amount = 0 AND local_debit_amount > 0 AND local_credit_amount = 0)
                OR
                (direction = 'credit' AND credit_amount > 0 AND debit_amount = 0 AND local_credit_amount > 0 AND local_debit_amount = 0)
            )
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_account_movements_tenant_journal_line
    ON erp_account_movements (tenant_id, journal_line_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_account_date
    ON erp_account_movements (tenant_id, account_code, posting_date);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_fiscal
    ON erp_account_movements (tenant_id, fiscal_year, fiscal_period);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_source
    ON erp_account_movements (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_party
    ON erp_account_movements (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_customer
    ON erp_account_movements (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_vendor
    ON erp_account_movements (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_item
    ON erp_account_movements (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_cost_center
    ON erp_account_movements (tenant_id, cost_center_code);

CREATE INDEX IF NOT EXISTS ix_erp_account_movements_tenant_project
    ON erp_account_movements (tenant_id, project_code);


CREATE TABLE IF NOT EXISTS erp_ledger_balances (
    ledger_balance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    fiscal_year INTEGER NOT NULL,
    fiscal_period TEXT NOT NULL,

    account_code TEXT NOT NULL,
    account_name TEXT,

    currency_code TEXT NOT NULL DEFAULT 'TRY',

    opening_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    opening_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    period_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    period_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    closing_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    closing_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    balance_side TEXT NOT NULL DEFAULT 'zero',
    balance_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    party_id UUID REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,

    cost_center_code TEXT,
    project_code TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    calculated_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_ledger_balances_balance_side_chk
        CHECK (balance_side IN ('debit', 'credit', 'zero')),

    CONSTRAINT erp_ledger_balances_status_chk
        CHECK (status IN ('active', 'closed', 'locked')),

    CONSTRAINT erp_ledger_balances_amount_chk
        CHECK (
            opening_debit_amount >= 0
            AND opening_credit_amount >= 0
            AND period_debit_amount >= 0
            AND period_credit_amount >= 0
            AND closing_debit_amount >= 0
            AND closing_credit_amount >= 0
            AND balance_amount >= 0
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_ledger_balances_tenant_period_account_dims
    ON erp_ledger_balances (
        tenant_id,
        fiscal_year,
        fiscal_period,
        account_code,
        currency_code,
        COALESCE(party_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(customer_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(vendor_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(cost_center_code, ''),
        COALESCE(project_code, '')
    )
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_account
    ON erp_ledger_balances (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_fiscal
    ON erp_ledger_balances (tenant_id, fiscal_year, fiscal_period);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_party
    ON erp_ledger_balances (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_customer
    ON erp_ledger_balances (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_vendor
    ON erp_ledger_balances (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_cost_center
    ON erp_ledger_balances (tenant_id, cost_center_code);

CREATE INDEX IF NOT EXISTS ix_erp_ledger_balances_tenant_project
    ON erp_ledger_balances (tenant_id, project_code);


ALTER TABLE erp_account_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_ledger_balances ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_account_movements FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_ledger_balances FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_account_movements_tenant_isolation_policy
    ON erp_account_movements
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_ledger_balances_tenant_isolation_policy
    ON erp_ledger_balances
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
