CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.login_smoke_runs (
    id uuid PRIMARY KEY,
    run_code text NOT NULL UNIQUE,
    phase text NOT NULL,
    step text NOT NULL,
    status text NOT NULL,
    pass_count integer NOT NULL DEFAULT 0,
    fail_count integer NOT NULL DEFAULT 0,
    checked_steps jsonb NOT NULL DEFAULT '[]'::jsonb,
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_auth_login_smoke_runs_status
    ON auth.login_smoke_runs (status);

CREATE INDEX IF NOT EXISTS idx_auth_login_smoke_runs_started_at
    ON auth.login_smoke_runs (started_at);
