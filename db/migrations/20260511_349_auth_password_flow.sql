CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.user_password_credentials (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL UNIQUE,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    password_set_at timestamptz NOT NULL,
    password_changed_at timestamptz NOT NULL,
    status text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auth_user_password_credentials_email
    ON auth.user_password_credentials (email);

CREATE INDEX IF NOT EXISTS idx_auth_user_password_credentials_status
    ON auth.user_password_credentials (status);

CREATE TABLE IF NOT EXISTS auth.password_reset_tokens (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    email text NOT NULL,
    reset_token_hash text NOT NULL UNIQUE,
    issued_at timestamptz NOT NULL,
    expires_at timestamptz NOT NULL,
    consumed_at timestamptz,
    ip_address inet,
    user_agent text
);

CREATE INDEX IF NOT EXISTS idx_auth_password_reset_tokens_user_id
    ON auth.password_reset_tokens (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_password_reset_tokens_email
    ON auth.password_reset_tokens (email);

CREATE INDEX IF NOT EXISTS idx_auth_password_reset_tokens_expires_at
    ON auth.password_reset_tokens (expires_at);

CREATE TABLE IF NOT EXISTS auth.password_flow_events (
    id uuid PRIMARY KEY,
    user_id uuid,
    tenant_id uuid,
    email text,
    event_type text NOT NULL,
    result text NOT NULL,
    reason_code text NOT NULL,
    correlation_id text NOT NULL,
    ip_address inet,
    user_agent text,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auth_password_flow_events_user_id
    ON auth.password_flow_events (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_password_flow_events_email
    ON auth.password_flow_events (email);

CREATE INDEX IF NOT EXISTS idx_auth_password_flow_events_correlation
    ON auth.password_flow_events (correlation_id);

CREATE TABLE IF NOT EXISTS auth.login_sessions (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    session_id text NOT NULL UNIQUE,
    access_token_id text NOT NULL UNIQUE,
    refresh_token_id text NOT NULL UNIQUE,
    issued_at timestamptz NOT NULL,
    access_expires_at timestamptz NOT NULL,
    refresh_expires_at timestamptz NOT NULL,
    last_seen_at timestamptz,
    revoked_at timestamptz,
    ip_address inet,
    user_agent text,
    created_at timestamptz NOT NULL DEFAULT now()
);
