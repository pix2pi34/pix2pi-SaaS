-- FAZ 3 / 9.11.1
-- Fiscal Period + Document Sequence persistence

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS erp_fiscal_years (
    fiscal_year_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    fiscal_year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    status TEXT NOT NULL DEFAULT 'open',

    closed_at TIMESTAMPTZ,
    closed_by TEXT,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_fiscal_years_year_chk
        CHECK (fiscal_year >= 2000 AND fiscal_year <= 2100),

    CONSTRAINT erp_fiscal_years_date_range_chk
        CHECK (year_end_date >= year_start_date),

    CONSTRAINT erp_fiscal_years_status_chk
        CHECK (status IN ('open', 'locked', 'closed', 'archived'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_fiscal_years_tenant_year
    ON erp_fiscal_years (tenant_id, fiscal_year)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_fiscal_years_tenant_status
    ON erp_fiscal_years (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_fiscal_years_tenant_dates
    ON erp_fiscal_years (tenant_id, year_start_date, year_end_date);


CREATE TABLE IF NOT EXISTS erp_fiscal_periods (
    fiscal_period_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    fiscal_year INTEGER NOT NULL,
    fiscal_period TEXT NOT NULL,
    period_no INTEGER NOT NULL,

    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,

    status TEXT NOT NULL DEFAULT 'open',

    closed_at TIMESTAMPTZ,
    closed_by TEXT,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_fiscal_periods_year_chk
        CHECK (fiscal_year >= 2000 AND fiscal_year <= 2100),

    CONSTRAINT erp_fiscal_periods_period_no_chk
        CHECK (period_no >= 1 AND period_no <= 13),

    CONSTRAINT erp_fiscal_periods_date_range_chk
        CHECK (period_end_date >= period_start_date),

    CONSTRAINT erp_fiscal_periods_status_chk
        CHECK (status IN ('open', 'locked', 'closed'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_fiscal_periods_tenant_period
    ON erp_fiscal_periods (tenant_id, fiscal_period)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_fiscal_periods_tenant_year_no
    ON erp_fiscal_periods (tenant_id, fiscal_year, period_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_fiscal_periods_tenant_status
    ON erp_fiscal_periods (tenant_id, status);

CREATE INDEX IF NOT EXISTS ix_erp_fiscal_periods_tenant_dates
    ON erp_fiscal_periods (tenant_id, period_start_date, period_end_date);


CREATE TABLE IF NOT EXISTS erp_document_sequences (
    document_sequence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    document_module TEXT NOT NULL,
    document_type TEXT NOT NULL,

    fiscal_year INTEGER,

    prefix TEXT NOT NULL DEFAULT '',
    suffix TEXT NOT NULL DEFAULT '',

    current_no BIGINT NOT NULL DEFAULT 0,
    min_no BIGINT NOT NULL DEFAULT 1,
    max_no BIGINT,

    padding INTEGER NOT NULL DEFAULT 6,

    reset_policy TEXT NOT NULL DEFAULT 'yearly',

    is_active BOOLEAN NOT NULL DEFAULT true,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_document_sequences_module_chk
        CHECK (document_module IN ('sales', 'procurement', 'journal', 'ledger', 'cashbank', 'inventory', 'tax', 'system')),

    CONSTRAINT erp_document_sequences_number_chk
        CHECK (
            current_no >= 0
            AND min_no > 0
            AND (max_no IS NULL OR max_no >= min_no)
            AND padding >= 1
            AND padding <= 20
        ),

    CONSTRAINT erp_document_sequences_reset_policy_chk
        CHECK (reset_policy IN ('never', 'yearly', 'monthly', 'daily')),

    CONSTRAINT erp_document_sequences_status_chk
        CHECK (status IN ('active', 'passive', 'locked'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_document_sequences_tenant_module_type_year
    ON erp_document_sequences (tenant_id, document_module, document_type, COALESCE(fiscal_year, 0))
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_document_sequences_tenant_module
    ON erp_document_sequences (tenant_id, document_module, document_type);

CREATE INDEX IF NOT EXISTS ix_erp_document_sequences_tenant_active
    ON erp_document_sequences (tenant_id, is_active);

CREATE INDEX IF NOT EXISTS ix_erp_document_sequences_tenant_status
    ON erp_document_sequences (tenant_id, status);


CREATE TABLE IF NOT EXISTS erp_document_number_allocations (
    document_number_allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id TEXT NOT NULL,

    document_sequence_id UUID NOT NULL REFERENCES erp_document_sequences(document_sequence_id) ON DELETE RESTRICT,

    document_module TEXT NOT NULL,
    document_type TEXT NOT NULL,

    document_no TEXT NOT NULL,
    allocated_no BIGINT NOT NULL,

    fiscal_year INTEGER,
    fiscal_period TEXT,

    source_document_id UUID,

    allocation_status TEXT NOT NULL DEFAULT 'allocated',

    allocated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    allocated_by TEXT,

    confirmed_at TIMESTAMPTZ,
    confirmed_by TEXT,

    cancelled_at TIMESTAMPTZ,
    cancelled_by TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    created_by TEXT,
    updated_by TEXT,

    CONSTRAINT erp_document_number_allocations_module_chk
        CHECK (document_module IN ('sales', 'procurement', 'journal', 'ledger', 'cashbank', 'inventory', 'tax', 'system')),

    CONSTRAINT erp_document_number_allocations_allocated_no_chk
        CHECK (allocated_no > 0),

    CONSTRAINT erp_document_number_allocations_status_chk
        CHECK (allocation_status IN ('allocated', 'confirmed', 'cancelled'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_erp_document_number_allocations_tenant_no
    ON erp_document_number_allocations (tenant_id, document_module, document_type, document_no)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_erp_document_number_allocations_tenant_sequence
    ON erp_document_number_allocations (tenant_id, document_sequence_id);

CREATE INDEX IF NOT EXISTS ix_erp_document_number_allocations_tenant_source
    ON erp_document_number_allocations (tenant_id, source_document_id);

CREATE INDEX IF NOT EXISTS ix_erp_document_number_allocations_tenant_fiscal
    ON erp_document_number_allocations (tenant_id, fiscal_year, fiscal_period);

CREATE INDEX IF NOT EXISTS ix_erp_document_number_allocations_tenant_status
    ON erp_document_number_allocations (tenant_id, allocation_status);


ALTER TABLE erp_fiscal_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_fiscal_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_document_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_document_number_allocations ENABLE ROW LEVEL SECURITY;

ALTER TABLE erp_fiscal_years FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_fiscal_periods FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_document_sequences FORCE ROW LEVEL SECURITY;
ALTER TABLE erp_document_number_allocations FORCE ROW LEVEL SECURITY;

CREATE POLICY erp_fiscal_years_tenant_isolation_policy
    ON erp_fiscal_years
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_fiscal_periods_tenant_isolation_policy
    ON erp_fiscal_periods
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_document_sequences_tenant_isolation_policy
    ON erp_document_sequences
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));

CREATE POLICY erp_document_number_allocations_tenant_isolation_policy
    ON erp_document_number_allocations
    USING (tenant_id = current_setting('app.tenant_id', true))
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true));
