CREATE SCHEMA IF NOT EXISTS panel_admin;

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_runs (
    runtime_flow_run_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    flow_run_no text NOT NULL,
    flow_type text NOT NULL,
    flow_name text NOT NULL,
    flow_source text NOT NULL DEFAULT 'system',
    source_service text,
    source_route text,
    source_event_id text,
    source_job_id text,
    request_id text,
    correlation_id text,
    actor_user_id text,
    actor_role_code text,
    status_code text NOT NULL DEFAULT 'started',
    severity text NOT NULL DEFAULT 'info',
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    duration_ms integer NOT NULL DEFAULT 0 CHECK (duration_ms >= 0),
    step_count integer NOT NULL DEFAULT 0 CHECK (step_count >= 0),
    success_step_count integer NOT NULL DEFAULT 0 CHECK (success_step_count >= 0),
    failed_step_count integer NOT NULL DEFAULT 0 CHECK (failed_step_count >= 0),
    warning_count integer NOT NULL DEFAULT 0 CHECK (warning_count >= 0),
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    panel_visibility text NOT NULL DEFAULT 'tenant_admin',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, flow_run_no)
);

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_steps (
    runtime_flow_step_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    runtime_flow_run_id text NOT NULL,
    step_no integer NOT NULL CHECK (step_no > 0),
    step_key text NOT NULL,
    step_name text NOT NULL,
    step_type text NOT NULL DEFAULT 'operation',
    service_name text,
    route_path text,
    http_method text,
    event_type text,
    job_type text,
    request_id text,
    correlation_id text,
    status_code text NOT NULL DEFAULT 'planned',
    severity text NOT NULL DEFAULT 'info',
    started_at timestamptz,
    finished_at timestamptz,
    duration_ms integer NOT NULL DEFAULT 0 CHECK (duration_ms >= 0),
    retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    error_code text,
    error_message text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, runtime_flow_run_id, step_no),
    UNIQUE (tenant_id, runtime_flow_run_id, step_key)
);

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_events (
    runtime_flow_event_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    runtime_flow_run_id text NOT NULL,
    runtime_flow_step_id text,
    event_no integer NOT NULL CHECK (event_no > 0),
    event_type text NOT NULL,
    event_name text NOT NULL,
    source_service text,
    source_event_id text,
    request_id text,
    correlation_id text,
    status_code text NOT NULL DEFAULT 'recorded',
    severity text NOT NULL DEFAULT 'info',
    event_at timestamptz NOT NULL DEFAULT now(),
    payload_ref text,
    payload_hash text,
    error_code text,
    error_message text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, runtime_flow_run_id, event_no)
);

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_snapshots (
    runtime_flow_snapshot_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    runtime_flow_run_id text NOT NULL,
    snapshot_no integer NOT NULL CHECK (snapshot_no > 0),
    snapshot_type text NOT NULL DEFAULT 'summary',
    flow_type text NOT NULL,
    status_code text NOT NULL,
    progress_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent >= 0),
    current_step_key text,
    current_step_name text,
    step_count integer NOT NULL DEFAULT 0 CHECK (step_count >= 0),
    success_step_count integer NOT NULL DEFAULT 0 CHECK (success_step_count >= 0),
    failed_step_count integer NOT NULL DEFAULT 0 CHECK (failed_step_count >= 0),
    warning_count integer NOT NULL DEFAULT 0 CHECK (warning_count >= 0),
    error_count integer NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    last_request_id text,
    last_correlation_id text,
    snapshot_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, runtime_flow_run_id, snapshot_no)
);

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_error_links (
    runtime_flow_error_link_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    runtime_flow_run_id text NOT NULL,
    runtime_flow_step_id text,
    runtime_flow_event_id text,
    error_source text NOT NULL DEFAULT 'runtime',
    error_code text NOT NULL,
    error_message text NOT NULL,
    severity text NOT NULL DEFAULT 'error',
    request_id text,
    correlation_id text,
    source_event_id text,
    source_job_id text,
    service_name text,
    route_path text,
    issue_status text NOT NULL DEFAULT 'open',
    linked_incident_id text,
    linked_audit_id text,
    first_seen_at timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, runtime_flow_run_id, error_code, runtime_flow_step_id)
);

CREATE TABLE IF NOT EXISTS panel_admin.runtime_flow_timeline_views (
    runtime_flow_timeline_view_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    runtime_flow_run_id text NOT NULL,
    timeline_order integer NOT NULL CHECK (timeline_order > 0),
    timeline_type text NOT NULL DEFAULT 'step',
    timeline_title text NOT NULL,
    timeline_status text NOT NULL,
    timeline_severity text NOT NULL DEFAULT 'info',
    step_key text,
    service_name text,
    route_path text,
    event_type text,
    request_id text,
    correlation_id text,
    started_at timestamptz,
    finished_at timestamptz,
    duration_ms integer NOT NULL DEFAULT 0 CHECK (duration_ms >= 0),
    display_group text NOT NULL DEFAULT 'runtime',
    panel_visibility text NOT NULL DEFAULT 'tenant_admin',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, runtime_flow_run_id, timeline_order),
    UNIQUE (tenant_id, runtime_flow_run_id, display_group, timeline_order)
);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_runs_tenant_status
    ON panel_admin.runtime_flow_runs (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_runs_tenant_started
    ON panel_admin.runtime_flow_runs (tenant_id, started_at);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_runs_tenant_type
    ON panel_admin.runtime_flow_runs (tenant_id, flow_type);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_runs_tenant_request
    ON panel_admin.runtime_flow_runs (tenant_id, request_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_steps_tenant_run
    ON panel_admin.runtime_flow_steps (tenant_id, runtime_flow_run_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_steps_tenant_status
    ON panel_admin.runtime_flow_steps (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_steps_tenant_service
    ON panel_admin.runtime_flow_steps (tenant_id, service_name);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_events_tenant_run
    ON panel_admin.runtime_flow_events (tenant_id, runtime_flow_run_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_events_tenant_type
    ON panel_admin.runtime_flow_events (tenant_id, event_type);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_snapshots_tenant_run
    ON panel_admin.runtime_flow_snapshots (tenant_id, runtime_flow_run_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_errors_tenant_run
    ON panel_admin.runtime_flow_error_links (tenant_id, runtime_flow_run_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_errors_tenant_status
    ON panel_admin.runtime_flow_error_links (tenant_id, issue_status);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_errors_tenant_request
    ON panel_admin.runtime_flow_error_links (tenant_id, request_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_timeline_tenant_run
    ON panel_admin.runtime_flow_timeline_views (tenant_id, runtime_flow_run_id);

CREATE INDEX IF NOT EXISTS idx_runtime_flow_timeline_tenant_order
    ON panel_admin.runtime_flow_timeline_views (tenant_id, runtime_flow_run_id, timeline_order);
