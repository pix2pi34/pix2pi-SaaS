CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.user_tenant_memberships (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_code text NOT NULL,
    status text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_auth_user_tenant_memberships_user_id
    ON auth.user_tenant_memberships (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_user_tenant_memberships_tenant_id
    ON auth.user_tenant_memberships (tenant_id);

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
    revoked_at timestamptz,
    ip_address inet,
    user_agent text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auth_login_sessions_tenant_user
    ON auth.login_sessions (tenant_id, user_id);

CREATE INDEX IF NOT EXISTS idx_auth_login_sessions_refresh_token_id
    ON auth.login_sessions (refresh_token_id);

CREATE INDEX IF NOT EXISTS idx_auth_login_sessions_access_expires_at
    ON auth.login_sessions (access_expires_at);
