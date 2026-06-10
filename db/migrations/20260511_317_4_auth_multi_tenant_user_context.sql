CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.user_current_tenant_preferences (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    session_id text NOT NULL,
    tenant_id uuid NOT NULL,
    role_code text NOT NULL,
    selected_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, session_id)
);

CREATE INDEX IF NOT EXISTS idx_auth_user_current_tenant_preferences_user_id
    ON auth.user_current_tenant_preferences (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_user_current_tenant_preferences_tenant_id
    ON auth.user_current_tenant_preferences (tenant_id);

CREATE INDEX IF NOT EXISTS idx_auth_user_current_tenant_preferences_session_id
    ON auth.user_current_tenant_preferences (session_id);

CREATE INDEX IF NOT EXISTS idx_auth_user_tenant_memberships_user_status
    ON auth.user_tenant_memberships (user_id, status);

CREATE INDEX IF NOT EXISTS idx_auth_user_tenant_memberships_tenant_user_status
    ON auth.user_tenant_memberships (tenant_id, user_id, status);
