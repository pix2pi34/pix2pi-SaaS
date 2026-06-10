CREATE SCHEMA IF NOT EXISTS platform_security;

CREATE TABLE IF NOT EXISTS platform_security.role_matrix_profiles (
    role_matrix_profile_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    profile_code text NOT NULL,
    profile_name text NOT NULL,
    profile_scope text NOT NULL DEFAULT 'tenant',
    profile_version text NOT NULL DEFAULT 'v1',
    default_role_code text NOT NULL DEFAULT 'operator',
    enforce_mode text NOT NULL DEFAULT 'contract_only',
    status_code text NOT NULL DEFAULT 'active',
    created_by text,
    approved_by text,
    approved_at timestamptz,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, profile_code)
);

CREATE TABLE IF NOT EXISTS platform_security.role_definitions (
    role_definition_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    role_matrix_profile_id text NOT NULL,
    role_code text NOT NULL,
    role_name text NOT NULL,
    role_group text NOT NULL DEFAULT 'tenant',
    role_scope text NOT NULL DEFAULT 'tenant',
    role_level integer NOT NULL DEFAULT 100 CHECK (role_level >= 0),
    is_system_role boolean NOT NULL DEFAULT false,
    is_support_role boolean NOT NULL DEFAULT false,
    is_super_admin_boundary boolean NOT NULL DEFAULT false,
    can_cross_tenant boolean NOT NULL DEFAULT false,
    status_code text NOT NULL DEFAULT 'active',
    description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, role_code),
    UNIQUE (tenant_id, role_matrix_profile_id, role_code)
);

CREATE TABLE IF NOT EXISTS platform_security.permission_definitions (
    permission_definition_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    permission_code text NOT NULL,
    permission_name text NOT NULL,
    resource_area text NOT NULL,
    resource_name text NOT NULL,
    action_code text NOT NULL,
    permission_scope text NOT NULL DEFAULT 'tenant',
    panel_route text,
    api_route text,
    http_method text,
    requires_audit boolean NOT NULL DEFAULT true,
    high_risk boolean NOT NULL DEFAULT false,
    status_code text NOT NULL DEFAULT 'active',
    description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, permission_code),
    UNIQUE (tenant_id, resource_area, resource_name, action_code)
);

CREATE TABLE IF NOT EXISTS platform_security.role_permission_matrix (
    role_permission_matrix_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    role_matrix_profile_id text NOT NULL,
    role_definition_id text NOT NULL,
    permission_definition_id text NOT NULL,
    role_code text NOT NULL,
    permission_code text NOT NULL,
    resource_area text NOT NULL,
    action_code text NOT NULL,
    allow_access boolean NOT NULL DEFAULT false,
    deny_reason text,
    requires_audit boolean NOT NULL DEFAULT true,
    requires_approval boolean NOT NULL DEFAULT false,
    high_risk boolean NOT NULL DEFAULT false,
    status_code text NOT NULL DEFAULT 'active',
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, role_code, permission_code),
    UNIQUE (tenant_id, role_definition_id, permission_definition_id)
);

CREATE TABLE IF NOT EXISTS platform_security.role_scope_rules (
    role_scope_rule_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    role_matrix_profile_id text NOT NULL,
    role_definition_id text NOT NULL,
    role_code text NOT NULL,
    permission_code text,
    scope_rule_code text NOT NULL,
    super_admin_boundary_mode text NOT NULL DEFAULT 'tenant_locked',
    cross_tenant_boundary_mode text NOT NULL DEFAULT 'deny',
    scope_type text NOT NULL DEFAULT 'tenant',
    scope_value text NOT NULL DEFAULT 'current_tenant',
    panel_scope text NOT NULL DEFAULT 'tenant_panel',
    api_scope text NOT NULL DEFAULT 'tenant_api',
    data_scope text NOT NULL DEFAULT 'tenant_data',
    allow_cross_tenant boolean NOT NULL DEFAULT false,
    allow_support_access boolean NOT NULL DEFAULT false,
    support_access_reason text,
    requires_audit boolean NOT NULL DEFAULT true,
    status_code text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, role_code, scope_rule_code)
);

CREATE TABLE IF NOT EXISTS platform_security.role_matrix_validation_errors (
    role_matrix_validation_error_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    role_matrix_profile_id text,
    role_definition_id text,
    permission_definition_id text,
    role_permission_matrix_id text,
    role_scope_rule_id text,
    role_code text,
    permission_code text,
    resource_area text,
    action_code text,
    error_code text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    field_name text,
    error_message text NOT NULL,
    status_code text NOT NULL DEFAULT 'open',
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    UNIQUE (tenant_id, error_code, field_name, role_code, permission_code)
);

CREATE INDEX IF NOT EXISTS idx_role_matrix_profiles_tenant_code
    ON platform_security.role_matrix_profiles (tenant_id, profile_code);

CREATE INDEX IF NOT EXISTS idx_role_matrix_profiles_tenant_status
    ON platform_security.role_matrix_profiles (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_role_definitions_tenant_profile
    ON platform_security.role_definitions (tenant_id, role_matrix_profile_id);

CREATE INDEX IF NOT EXISTS idx_role_definitions_tenant_role
    ON platform_security.role_definitions (tenant_id, role_code);

CREATE INDEX IF NOT EXISTS idx_role_definitions_tenant_group
    ON platform_security.role_definitions (tenant_id, role_group);

CREATE INDEX IF NOT EXISTS idx_permission_definitions_tenant_code
    ON platform_security.permission_definitions (tenant_id, permission_code);

CREATE INDEX IF NOT EXISTS idx_permission_definitions_tenant_resource
    ON platform_security.permission_definitions (tenant_id, resource_area, resource_name);

CREATE INDEX IF NOT EXISTS idx_permission_definitions_tenant_action
    ON platform_security.permission_definitions (tenant_id, action_code);

CREATE INDEX IF NOT EXISTS idx_role_permission_matrix_tenant_role
    ON platform_security.role_permission_matrix (tenant_id, role_code);

CREATE INDEX IF NOT EXISTS idx_role_permission_matrix_tenant_permission
    ON platform_security.role_permission_matrix (tenant_id, permission_code);

CREATE INDEX IF NOT EXISTS idx_role_permission_matrix_tenant_resource
    ON platform_security.role_permission_matrix (tenant_id, resource_area, action_code);

CREATE INDEX IF NOT EXISTS idx_role_scope_rules_tenant_role
    ON platform_security.role_scope_rules (tenant_id, role_code);

CREATE INDEX IF NOT EXISTS idx_role_scope_rules_tenant_scope
    ON platform_security.role_scope_rules (tenant_id, scope_type, scope_value);

CREATE INDEX IF NOT EXISTS idx_role_matrix_errors_tenant_profile
    ON platform_security.role_matrix_validation_errors (tenant_id, role_matrix_profile_id);

CREATE INDEX IF NOT EXISTS idx_role_matrix_errors_tenant_status
    ON platform_security.role_matrix_validation_errors (tenant_id, status_code);
