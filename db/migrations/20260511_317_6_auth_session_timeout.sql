CREATE SCHEMA IF NOT EXISTS auth;

ALTER TABLE auth.login_sessions
    ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;

CREATE TABLE IF NOT EXISTS auth.session_timeout_events (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    session_id text NOT NULL,
    event_type text NOT NULL,
    reason_code text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    access_token_id text,
    refresh_token_id text,
    ip_address inet,
    user_agent text
);

CREATE INDEX IF NOT EXISTS idx_auth_session_timeout_events_session_id
    ON auth.session_timeout_events (session_id);

CREATE INDEX IF NOT EXISTS idx_auth_session_timeout_events_tenant_user
    ON auth.session_timeout_events (tenant_id, user_id);

CREATE INDEX IF NOT EXISTS idx_auth_session_timeout_events_occurred_at
    ON auth.session_timeout_events (occurred_at);

CREATE INDEX IF NOT EXISTS idx_auth_login_sessions_last_seen_at
    ON auth.login_sessions (last_seen_at);

CREATE INDEX IF NOT EXISTS idx_auth_login_sessions_revoked_at
    ON auth.login_sessions (revoked_at);
