CREATE SCHEMA IF NOT EXISTS tenant_onboarding;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS tenant_onboarding.business_onboarding_requests (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL UNIQUE,
    owner_user_id uuid NOT NULL,
    tenant_slug text NOT NULL UNIQUE,
    business_name text NOT NULL,
    tax_or_tckn text NOT NULL,
    address_line text NOT NULL,
    city text NOT NULL,
    district text NOT NULL,
    sector_code text NOT NULL,
    branch_name text NOT NULL,
    currency_code text NOT NULL,
    language_code text NOT NULL,
    first_role_code text NOT NULL,
    onboarding_status text NOT NULL,
    completed_at timestamptz,
    correlation_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_onboarding_requests_owner_user
    ON tenant_onboarding.business_onboarding_requests (owner_user_id);

CREATE INDEX IF NOT EXISTS idx_business_onboarding_requests_status
    ON tenant_onboarding.business_onboarding_requests (onboarding_status);

CREATE TABLE IF NOT EXISTS tenant_onboarding.business_onboarding_audit_events (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    owner_user_id uuid NOT NULL,
    event_type text NOT NULL,
    result text NOT NULL,
    reason_code text NOT NULL,
    correlation_id text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_onboarding_audit_events_tenant
    ON tenant_onboarding.business_onboarding_audit_events (tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_onboarding_audit_events_correlation
    ON tenant_onboarding.business_onboarding_audit_events (correlation_id);

CREATE TABLE IF NOT EXISTS core.tenants (
    id uuid PRIMARY KEY,
    slug text NOT NULL UNIQUE,
    name text NOT NULL,
    status text NOT NULL,
    default_language text NOT NULL,
    default_currency text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.legal_entities (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    legal_name text NOT NULL,
    tax_or_tckn text NOT NULL,
    address_line text NOT NULL,
    city text NOT NULL,
    district text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, tax_or_tckn)
);

CREATE TABLE IF NOT EXISTS core.branches (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    legal_entity_id uuid NOT NULL,
    branch_name text NOT NULL,
    status text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.user_tenant_memberships (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_code text NOT NULL,
    status text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, user_id, role_code)
);
