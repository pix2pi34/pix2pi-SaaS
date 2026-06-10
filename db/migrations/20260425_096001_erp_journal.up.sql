-- FAZ 3 / 9.6.1
-- ERP Turkiye canli cekirdegi
-- Journal header / journal line persistence
--
-- Ana mantik:
-- erp_journal_entries = muhasebe fisi header
-- erp_journal_lines   = borc / alacak satirlari
--
-- Not:
-- Bu migration muhasebe fis persist zeminidir.
-- Ledger posting, account balance ve TDHP mapping sonraki adimlarda baglanir.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_journal_entries (
    journal_entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    journal_no TEXT NOT NULL,

    journal_date DATE NOT NULL DEFAULT CURRENT_DATE,
    posting_date DATE,

    fiscal_year INTEGER,
    fiscal_period TEXT,

    source_module TEXT NOT NULL DEFAULT 'manual',
    source_document_type TEXT,
    source_document_id UUID,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    description TEXT,

    total_debit NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_credit NUMERIC(18, 2) NOT NULL DEFAULT 0,

    status TEXT NOT NULL DEFAULT 'draft',

    posted_at TIMESTAMPTZ,
    posted_by TEXT,

    reversed_at TIMESTAMPTZ,
    reversed_by TEXT,
    reversal_journal_entry_id UUID REFERENCES erp_journal_entries(journal_entry_id) ON DELETE RESTRICT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_journal_entries_status_chk
        CHECK (status IN ('draft', 'posted', 'reversed', 'cancelled')),

    CONSTRAINT erp_journal_entries_source_module_chk
        CHECK (source_module IN ('manual', 'sales', 'procurement', 'payment', 'inventory', 'tax', 'export', 'system')),

    CONSTRAINT erp_journal_entries_amount_chk
        CHECK (
            exchange_rate > 0
            AND total_debit >= 0
            AND total_credit >= 0
        ),

    CONSTRAINT erp_journal_entries_posted_balance_chk
        CHECK (
            status <> 'posted'
            OR total_debit = total_credit
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_journal_entries_tenant_no
    ON erp_journal_entries (tenant_id, journal_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_date
    ON erp_journal_entries (tenant_id, journal_date);

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_posting_date
    ON erp_journal_entries (tenant_id, posting_date);

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_status
    ON erp_journal_entries (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_source
    ON erp_journal_entries (tenant_id, source_module, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_fiscal
    ON erp_journal_entries (tenant_id, fiscal_year, fiscal_period);

CREATE INDEX IF NOT EXISTS ix_erp_journal_entries_tenant_reversal
    ON erp_journal_entries (tenant_id, reversal_journal_entry_id);


CREATE TABLE IF NOT EXISTS erp_journal_lines (
    journal_line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    journal_entry_id UUID NOT NULL REFERENCES erp_journal_entries(journal_entry_id) ON DELETE CASCADE,

    line_no INTEGER NOT NULL,

    account_code TEXT NOT NULL,
    account_name TEXT,

    description TEXT,

    debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    currency_code TEXT NOT NULL DEFAULT 'TRY',
    exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1,

    local_debit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
    local_credit_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,

    party_id UUID REFERENCES erp_parties(party_id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES erp_customers(customer_id) ON DELETE RESTRICT,
    vendor_id UUID REFERENCES erp_vendors(vendor_id) ON DELETE RESTRICT,
    item_id UUID REFERENCES erp_items(item_id) ON DELETE RESTRICT,

    cost_center_code TEXT,
    project_code TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_journal_lines_status_chk
        CHECK (status IN ('active', 'cancelled', 'deleted')),

    CONSTRAINT erp_journal_lines_line_no_chk
        CHECK (line_no > 0),

    CONSTRAINT erp_journal_lines_amount_chk
        CHECK (
            exchange_rate > 0
            AND debit_amount >= 0
            AND credit_amount >= 0
            AND local_debit_amount >= 0
            AND local_credit_amount >= 0
            AND (
                (debit_amount > 0 AND credit_amount = 0)
                OR
                (credit_amount > 0 AND debit_amount = 0)
            )
            AND (
                (local_debit_amount > 0 AND local_credit_amount = 0)
                OR
                (local_credit_amount > 0 AND local_debit_amount = 0)
            )
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_journal_lines_tenant_entry_line
    ON erp_journal_lines (tenant_id, journal_entry_id, line_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_account
    ON erp_journal_lines (tenant_id, account_code);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_party
    ON erp_journal_lines (tenant_id, party_id);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_customer
    ON erp_journal_lines (tenant_id, customer_id);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_vendor
    ON erp_journal_lines (tenant_id, vendor_id);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_item
    ON erp_journal_lines (tenant_id, item_id);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_cost_center
    ON erp_journal_lines (tenant_id, cost_center_code);

CREATE INDEX IF NOT EXISTS ix_erp_journal_lines_tenant_project
    ON erp_journal_lines (tenant_id, project_code);


ALTER TABLE erp_journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_journal_lines ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_journal_entries FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_journal_lines FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_journal_entries_tenant_isolation_policy
    ON erp_journal_entries
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_journal_lines_tenant_isolation_policy
    ON erp_journal_lines
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
