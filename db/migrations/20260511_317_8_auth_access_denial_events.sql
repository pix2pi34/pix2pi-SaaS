CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.access_denial_events (
    id uuid PRIMARY KEY,
    tenant_id uuid,
    user_id uuid,
    role_code text,
    route_path text NOT NULL,
    action_code text NOT NULL,
    denial_code text NOT NULL,
    http_status integer NOT NULL,
    correlation_id text NOT NULL,
    ip_address inet,
    user_agent text,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auth_access_denial_events_code
    ON auth.access_denial_events (denial_code);

CREATE INDEX IF NOT EXISTS idx_auth_access_denial_events_correlation
    ON auth.access_denial_events (correlation_id);

CREATE INDEX IF NOT EXISTS idx_auth_access_denial_events_tenant_user
    ON auth.access_denial_events (tenant_id, user_id);

CREATE INDEX IF NOT EXISTS idx_auth_access_denial_events_route_path
    ON auth.access_denial_events (route_path);

CREATE INDEX IF NOT EXISTS idx_auth_access_denial_events_occurred_at
    ON auth.access_denial_events (occurred_at);
