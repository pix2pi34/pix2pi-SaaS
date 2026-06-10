CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.login_error_events (
    id uuid PRIMARY KEY,
    tenant_id uuid,
    user_id uuid,
    email text,
    error_code text NOT NULL,
    http_status integer NOT NULL,
    correlation_id text NOT NULL,
    ip_address inet,
    user_agent text,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auth_login_error_events_code
    ON auth.login_error_events (error_code);

CREATE INDEX IF NOT EXISTS idx_auth_login_error_events_correlation
    ON auth.login_error_events (correlation_id);

CREATE INDEX IF NOT EXISTS idx_auth_login_error_events_occurred_at
    ON auth.login_error_events (occurred_at);

CREATE INDEX IF NOT EXISTS idx_auth_login_error_events_tenant_user
    ON auth.login_error_events (tenant_id, user_id);
