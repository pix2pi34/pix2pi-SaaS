CREATE SCHEMA IF NOT EXISTS tenant_onboarding;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS commercial;
CREATE SCHEMA IF NOT EXISTS pos;
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS tenant_onboarding.pilot_tenant_opening_runs (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    owner_user_id uuid NOT NULL,
    tenant_slug text NOT NULL,
    default_language text NOT NULL,
    default_currency text NOT NULL,
    default_plan_code text NOT NULL,
    branch_id uuid NOT NULL,
    register_id uuid NOT NULL,
    opening_status text NOT NULL,
    correlation_id text NOT NULL,
    completed_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_pilot_tenant_opening_runs_owner
    ON tenant_onboarding.pilot_tenant_opening_runs (owner_user_id);

CREATE INDEX IF NOT EXISTS idx_pilot_tenant_opening_runs_status
    ON tenant_onboarding.pilot_tenant_opening_runs (opening_status);

CREATE INDEX IF NOT EXISTS idx_pilot_tenant_opening_runs_correlation
    ON tenant_onboarding.pilot_tenant_opening_runs (correlation_id);

CREATE TABLE IF NOT EXISTS tenant_onboarding.pilot_tenant_opening_audit_events (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    owner_user_id uuid NOT NULL,
    event_type text NOT NULL,
    result text NOT NULL,
    reason_code text NOT NULL,
    correlation_id text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pilot_tenant_opening_audit_events_tenant
    ON tenant_onboarding.pilot_tenant_opening_audit_events (tenant_id);

CREATE INDEX IF NOT EXISTS idx_pilot_tenant_opening_audit_events_correlation
    ON tenant_onboarding.pilot_tenant_opening_audit_events (correlation_id);

CREATE TABLE IF NOT EXISTS core.tenant_configs (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL UNIQUE,
    tenant_slug text NOT NULL UNIQUE,
    default_language text NOT NULL,
    default_currency text NOT NULL,
    timezone text NOT NULL,
    opening_mode text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commercial.tenant_plan_bindings (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL UNIQUE,
    plan_code text NOT NULL,
    status text NOT NULL,
    started_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pos.registers (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    register_name text NOT NULL,
    register_code text NOT NULL,
    status text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, register_code)
);
