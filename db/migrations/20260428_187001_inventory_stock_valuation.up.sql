CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.stock_valuation_profiles (
    stock_valuation_profile_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    valuation_profile_code text NOT NULL,
    valuation_profile_name text NOT NULL,
    valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE',
    costing_scope text NOT NULL DEFAULT 'tenant_product_location',
    currency_code text NOT NULL DEFAULT 'TRY',
    allow_manual_cost boolean NOT NULL DEFAULT false,
    allow_revaluation boolean NOT NULL DEFAULT true,
    rounding_scale integer NOT NULL DEFAULT 4 CHECK (rounding_scale >= 0),
    effective_from date NOT NULL,
    effective_to date,
    status_code text NOT NULL DEFAULT 'active',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, valuation_profile_code)
);

CREATE TABLE IF NOT EXISTS inventory.stock_valuation_layers (
    stock_valuation_layer_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_valuation_profile_id text NOT NULL,
    valuation_layer_no text NOT NULL,
    valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE',
    product_id text,
    product_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    layer_date date NOT NULL,
    period_key text NOT NULL,
    source_movement_id text,
    source_movement_line_id text,
    source_document_id text,
    source_document_line_id text,
    quantity numeric(18,4) NOT NULL DEFAULT 0,
    remaining_quantity numeric(18,4) NOT NULL DEFAULT 0,
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    average_unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    remaining_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    layer_status text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, valuation_layer_no),
    UNIQUE (tenant_id, source_movement_line_id)
);

CREATE TABLE IF NOT EXISTS inventory.stock_valuation_entries (
    stock_valuation_entry_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_valuation_profile_id text NOT NULL,
    stock_valuation_layer_id text,
    valuation_entry_no text NOT NULL,
    valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE',
    entry_type text NOT NULL DEFAULT 'movement_cost',
    product_id text,
    product_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    movement_type text NOT NULL,
    movement_direction text NOT NULL,
    source_movement_id text NOT NULL,
    source_movement_line_id text NOT NULL,
    source_document_id text,
    source_document_line_id text,
    quantity numeric(18,4) NOT NULL DEFAULT 0,
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    previous_unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    new_unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    valuation_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    idempotency_key text NOT NULL,
    request_id text,
    entry_status text NOT NULL DEFAULT 'planned',
    valued_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, valuation_entry_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_valuation_adjustments (
    stock_valuation_adjustment_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_valuation_profile_id text NOT NULL,
    stock_valuation_entry_id text,
    adjustment_no text NOT NULL,
    adjustment_type text NOT NULL DEFAULT 'manual_revaluation',
    valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE',
    product_id text,
    product_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    adjustment_date date NOT NULL,
    period_key text NOT NULL,
    quantity numeric(18,4) NOT NULL DEFAULT 0,
    unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    previous_unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    new_unit_cost numeric(18,4) NOT NULL DEFAULT 0,
    adjustment_amount numeric(18,4) NOT NULL DEFAULT 0,
    valuation_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    adjustment_reason text NOT NULL,
    approval_required boolean NOT NULL DEFAULT true,
    approved_by text,
    approved_at timestamptz,
    idempotency_key text NOT NULL,
    request_id text,
    status_code text NOT NULL DEFAULT 'planned',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, adjustment_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_revaluation_runs (
    stock_revaluation_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_valuation_profile_id text NOT NULL,
    run_no text NOT NULL,
    run_mode text NOT NULL DEFAULT 'dry_run',
    valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE',
    revaluation_scope text NOT NULL DEFAULT 'tenant',
    product_code text,
    location_code text,
    period_key text,
    revaluation_date date NOT NULL,
    status_code text NOT NULL DEFAULT 'planned',
    scanned_layer_count integer NOT NULL DEFAULT 0 CHECK (scanned_layer_count >= 0),
    valued_entry_count integer NOT NULL DEFAULT 0 CHECK (valued_entry_count >= 0),
    adjusted_entry_count integer NOT NULL DEFAULT 0 CHECK (adjusted_entry_count >= 0),
    failed_entry_count integer NOT NULL DEFAULT 0 CHECK (failed_entry_count >= 0),
    total_quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    valuation_amount numeric(18,4) NOT NULL DEFAULT 0,
    currency_code text NOT NULL DEFAULT 'TRY',
    idempotency_key text NOT NULL,
    request_id text,
    started_at timestamptz,
    finished_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, run_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.stock_valuation_validation_errors (
    stock_valuation_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stock_valuation_profile_id text,
    stock_valuation_layer_id text,
    stock_valuation_entry_id text,
    stock_valuation_adjustment_id text,
    stock_revaluation_run_id text,
    product_code text,
    location_code text,
    valuation_method text,
    period_key text,
    quantity numeric(18,4) NOT NULL DEFAULT 0,
    total_cost_amount numeric(18,4) NOT NULL DEFAULT 0,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, error_code, field_name, stock_valuation_entry_id)
);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_profiles_tenant_code
    ON inventory.stock_valuation_profiles (tenant_id, valuation_profile_code);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_profiles_tenant_status
    ON inventory.stock_valuation_profiles (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_layers_tenant_profile
    ON inventory.stock_valuation_layers (tenant_id, stock_valuation_profile_id);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_layers_tenant_product_location
    ON inventory.stock_valuation_layers (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_layers_tenant_period
    ON inventory.stock_valuation_layers (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_entries_tenant_profile
    ON inventory.stock_valuation_entries (tenant_id, stock_valuation_profile_id);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_entries_tenant_movement
    ON inventory.stock_valuation_entries (tenant_id, source_movement_id, source_movement_line_id);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_entries_tenant_product_location
    ON inventory.stock_valuation_entries (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_adjustments_tenant_profile
    ON inventory.stock_valuation_adjustments (tenant_id, stock_valuation_profile_id);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_adjustments_tenant_product_location
    ON inventory.stock_valuation_adjustments (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_adjustments_tenant_status
    ON inventory.stock_valuation_adjustments (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_revaluation_runs_tenant_profile
    ON inventory.stock_revaluation_runs (tenant_id, stock_valuation_profile_id);

CREATE INDEX IF NOT EXISTS idx_stock_revaluation_runs_tenant_status
    ON inventory.stock_revaluation_runs (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_stock_revaluation_runs_tenant_period
    ON inventory.stock_revaluation_runs (tenant_id, period_key);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_errors_tenant_profile
    ON inventory.stock_valuation_validation_errors (tenant_id, stock_valuation_profile_id);

CREATE INDEX IF NOT EXISTS idx_stock_valuation_errors_tenant_status
    ON inventory.stock_valuation_validation_errors (tenant_id, status_code);
