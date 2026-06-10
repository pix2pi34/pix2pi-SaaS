CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_profiles (
    negative_stock_policy_profile_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    policy_code text NOT NULL,
    policy_name text NOT NULL,
    policy_mode text NOT NULL DEFAULT 'BLOCK',
    allow_negative_stock boolean NOT NULL DEFAULT false,
    approval_required boolean NOT NULL DEFAULT false,
    warning_required boolean NOT NULL DEFAULT false,
    default_decision_action text NOT NULL DEFAULT 'BLOCK_DECREMENT',
    priority integer NOT NULL DEFAULT 100 CHECK (priority >= 0),
    effective_from date NOT NULL,
    effective_to date,
    status_code text NOT NULL DEFAULT 'active',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, policy_code)
);

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_rules (
    negative_stock_policy_rule_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    negative_stock_policy_profile_id text NOT NULL,
    policy_code text NOT NULL,
    rule_code text NOT NULL,
    rule_name text NOT NULL,
    policy_mode text NOT NULL DEFAULT 'BLOCK',
    decision_action text NOT NULL DEFAULT 'BLOCK_DECREMENT',
    product_id text,
    product_code text,
    category_code text,
    location_id text,
    location_code text,
    sales_channel text,
    document_type text,
    movement_type text NOT NULL DEFAULT 'SALE',
    movement_direction text NOT NULL DEFAULT 'OUT',
    allow_negative_stock boolean NOT NULL DEFAULT false,
    max_negative_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (max_negative_quantity >= 0),
    warning_threshold_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (warning_threshold_quantity >= 0),
    priority integer NOT NULL DEFAULT 100 CHECK (priority >= 0),
    effective_from date NOT NULL,
    effective_to date,
    status_code text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, rule_code),
    UNIQUE (tenant_id, negative_stock_policy_profile_id, rule_code)
);

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_exceptions (
    negative_stock_policy_exception_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    negative_stock_policy_profile_id text NOT NULL,
    negative_stock_policy_rule_id text,
    exception_code text NOT NULL,
    exception_reason text NOT NULL,
    policy_mode text NOT NULL DEFAULT 'ALLOW',
    decision_action text NOT NULL DEFAULT 'ALLOW_DECREMENT',
    product_id text,
    product_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    party_id text,
    party_code text,
    allow_negative_stock boolean NOT NULL DEFAULT true,
    max_negative_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (max_negative_quantity >= 0),
    approved_by text,
    approved_at timestamptz,
    expires_at timestamptz,
    status_code text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, exception_code)
);

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_evaluations (
    negative_stock_policy_evaluation_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    evaluation_no text NOT NULL,
    negative_stock_policy_profile_id text,
    negative_stock_policy_rule_id text,
    negative_stock_policy_exception_id text,
    source_document_id text,
    source_document_line_id text,
    stock_movement_id text,
    stock_movement_line_id text,
    product_id text,
    product_code text NOT NULL,
    location_id text,
    location_code text NOT NULL,
    movement_type text NOT NULL DEFAULT 'SALE',
    movement_direction text NOT NULL DEFAULT 'OUT',
    requested_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (requested_quantity >= 0),
    current_quantity numeric(18,4) NOT NULL DEFAULT 0,
    reserved_quantity numeric(18,4) NOT NULL DEFAULT 0,
    available_quantity numeric(18,4) NOT NULL DEFAULT 0,
    projected_quantity numeric(18,4) NOT NULL DEFAULT 0,
    negative_quantity numeric(18,4) NOT NULL DEFAULT 0,
    policy_mode text NOT NULL DEFAULT 'BLOCK',
    decision_action text NOT NULL DEFAULT 'BLOCK_DECREMENT',
    allow_negative_stock boolean NOT NULL DEFAULT false,
    evaluation_status text NOT NULL DEFAULT 'planned',
    idempotency_key text NOT NULL,
    request_id text,
    source_event_id text,
    evaluated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, evaluation_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_decisions (
    negative_stock_policy_decision_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    negative_stock_policy_evaluation_id text NOT NULL,
    negative_stock_policy_profile_id text,
    negative_stock_policy_rule_id text,
    negative_stock_policy_exception_id text,
    decision_no text NOT NULL,
    decision_action text NOT NULL,
    decision_reason text NOT NULL,
    policy_mode text NOT NULL,
    product_code text NOT NULL,
    location_code text NOT NULL,
    requested_quantity numeric(18,4) NOT NULL DEFAULT 0 CHECK (requested_quantity >= 0),
    available_quantity numeric(18,4) NOT NULL DEFAULT 0,
    projected_quantity numeric(18,4) NOT NULL DEFAULT 0,
    negative_quantity numeric(18,4) NOT NULL DEFAULT 0,
    allow_negative_stock boolean NOT NULL DEFAULT false,
    approval_required boolean NOT NULL DEFAULT false,
    approved_by text,
    approved_at timestamptz,
    status_code text NOT NULL DEFAULT 'decided',
    idempotency_key text NOT NULL,
    request_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, decision_no),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS inventory.negative_stock_policy_validation_errors (
    negative_stock_policy_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    negative_stock_policy_profile_id text,
    negative_stock_policy_rule_id text,
    negative_stock_policy_evaluation_id text,
    product_code text,
    location_code text,
    policy_code text,
    rule_code text,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, error_code, field_name, negative_stock_policy_evaluation_id)
);

CREATE INDEX IF NOT EXISTS idx_negative_policy_profiles_tenant_policy
    ON inventory.negative_stock_policy_profiles (tenant_id, policy_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_profiles_tenant_status
    ON inventory.negative_stock_policy_profiles (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_rules_tenant_profile
    ON inventory.negative_stock_policy_rules (tenant_id, negative_stock_policy_profile_id);

CREATE INDEX IF NOT EXISTS idx_negative_policy_rules_tenant_product
    ON inventory.negative_stock_policy_rules (tenant_id, product_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_rules_tenant_location
    ON inventory.negative_stock_policy_rules (tenant_id, location_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_rules_tenant_priority
    ON inventory.negative_stock_policy_rules (tenant_id, priority);

CREATE INDEX IF NOT EXISTS idx_negative_policy_exceptions_tenant_profile
    ON inventory.negative_stock_policy_exceptions (tenant_id, negative_stock_policy_profile_id);

CREATE INDEX IF NOT EXISTS idx_negative_policy_exceptions_tenant_product_location
    ON inventory.negative_stock_policy_exceptions (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_exceptions_tenant_expires
    ON inventory.negative_stock_policy_exceptions (tenant_id, expires_at);

CREATE INDEX IF NOT EXISTS idx_negative_policy_evaluations_tenant_product_location
    ON inventory.negative_stock_policy_evaluations (tenant_id, product_code, location_code);

CREATE INDEX IF NOT EXISTS idx_negative_policy_evaluations_tenant_status
    ON inventory.negative_stock_policy_evaluations (tenant_id, evaluation_status);

CREATE INDEX IF NOT EXISTS idx_negative_policy_evaluations_tenant_movement
    ON inventory.negative_stock_policy_evaluations (tenant_id, stock_movement_id, stock_movement_line_id);

CREATE INDEX IF NOT EXISTS idx_negative_policy_decisions_tenant_evaluation
    ON inventory.negative_stock_policy_decisions (tenant_id, negative_stock_policy_evaluation_id);

CREATE INDEX IF NOT EXISTS idx_negative_policy_decisions_tenant_action
    ON inventory.negative_stock_policy_decisions (tenant_id, decision_action);

CREATE INDEX IF NOT EXISTS idx_negative_policy_errors_tenant_profile
    ON inventory.negative_stock_policy_validation_errors (tenant_id, negative_stock_policy_profile_id);

CREATE INDEX IF NOT EXISTS idx_negative_policy_errors_tenant_status
    ON inventory.negative_stock_policy_validation_errors (tenant_id, status_code);
