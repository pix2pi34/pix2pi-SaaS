CREATE SCHEMA IF NOT EXISTS platform_security;

CREATE TABLE IF NOT EXISTS platform_security.audit_event_streams (
    audit_event_stream_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    stream_code text NOT NULL,
    stream_name text NOT NULL,
    stream_scope text NOT NULL DEFAULT 'tenant',
    stream_type text NOT NULL DEFAULT 'security',
    audit_event_id text,
    decision text NOT NULL DEFAULT 'STREAM_READY',
    event_hash text,
    retention_policy_code text NOT NULL DEFAULT 'security_audit_default',
    immutable_required boolean NOT NULL DEFAULT true,
    hash_chain_enabled boolean NOT NULL DEFAULT true,
    status_code text NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, stream_code)
);

CREATE TABLE IF NOT EXISTS platform_security.audit_events (
    audit_event_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    audit_event_stream_id text NOT NULL,
    audit_event_no text NOT NULL,
    event_type text NOT NULL,
    event_source text NOT NULL,
    event_category text NOT NULL DEFAULT 'security',
    actor_user_id text,
    actor_role_code text,
    permission_code text,
    resource_area text NOT NULL,
    resource_name text NOT NULL,
    resource_id text,
    action_code text NOT NULL,
    decision text NOT NULL,
    deny_reason text,
    boundary_status text,
    high_risk boolean NOT NULL DEFAULT false,
    audit_required boolean NOT NULL DEFAULT true,
    request_id text,
    correlation_id text,
    source_route text,
    http_method text,
    source_service text,
    source_event_id text,
    source_job_id text,
    event_payload_ref text,
    event_payload_hash text,
    event_hash text NOT NULL,
    previous_event_hash text,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    ingested_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, audit_event_no),
    UNIQUE (tenant_id, event_hash)
);

CREATE TABLE IF NOT EXISTS platform_security.audit_actor_contexts (
    audit_actor_context_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    audit_event_id text NOT NULL,
    actor_user_id text,
    actor_role_code text,
    actor_role_group text,
    actor_session_id text,
    actor_ip_hash text,
    actor_user_agent_hash text,
    auth_subject text,
    jwt_tenant_id text,
    header_tenant_id text,
    actor_boundary_mode text NOT NULL DEFAULT 'tenant',
    support_access_reason text,
    super_admin_boundary_mode text NOT NULL DEFAULT 'tenant_locked',
    cross_tenant_boundary_mode text NOT NULL DEFAULT 'deny',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, audit_event_id)
);

CREATE TABLE IF NOT EXISTS platform_security.audit_resource_contexts (
    audit_resource_context_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    audit_event_id text NOT NULL,
    resource_area text NOT NULL,
    resource_name text NOT NULL,
    resource_id text,
    resource_owner_tenant_id text,
    resource_scope text NOT NULL DEFAULT 'tenant',
    source_route text,
    api_route text,
    panel_route text,
    http_method text,
    permission_code text,
    action_code text NOT NULL,
    data_scope text NOT NULL DEFAULT 'tenant_data',
    contains_sensitive_data boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, audit_event_id, resource_area, resource_name, action_code)
);

CREATE TABLE IF NOT EXISTS platform_security.audit_decision_contexts (
    audit_decision_context_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    audit_event_id text NOT NULL,
    decision text NOT NULL,
    allow_access boolean NOT NULL DEFAULT false,
    deny_reason text,
    deny_reason_code text,
    boundary_status text,
    permission_code text,
    role_code text,
    resource_area text,
    action_code text,
    high_risk boolean NOT NULL DEFAULT false,
    approval_required boolean NOT NULL DEFAULT false,
    audit_required boolean NOT NULL DEFAULT true,
    decision_source text NOT NULL DEFAULT 'permission_guard',
    decision_policy_version text NOT NULL DEFAULT 'v1',
    decided_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, audit_event_id)
);

CREATE TABLE IF NOT EXISTS platform_security.audit_integrity_chain (
    audit_integrity_chain_id text PRIMARY KEY,
    tenant_id text NOT NULL,
    audit_event_stream_id text NOT NULL,
    audit_event_id text NOT NULL,
    chain_no bigint NOT NULL CHECK (chain_no > 0),
    event_hash text NOT NULL,
    previous_event_hash text,
    chain_hash text NOT NULL,
    hash_algorithm text NOT NULL DEFAULT 'sha256',
    immutable_status text NOT NULL DEFAULT 'pending',
    verified_at timestamptz,
    verification_status text NOT NULL DEFAULT 'not_verified',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, audit_event_stream_id, chain_no),
    UNIQUE (tenant_id, audit_event_id),
    UNIQUE (tenant_id, chain_hash)
);

CREATE INDEX IF NOT EXISTS idx_audit_event_streams_tenant_code
    ON platform_security.audit_event_streams (tenant_id, stream_code);

CREATE INDEX IF NOT EXISTS idx_audit_event_streams_tenant_status
    ON platform_security.audit_event_streams (tenant_id, status_code);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_stream
    ON platform_security.audit_events (tenant_id, audit_event_stream_id);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_occurred
    ON platform_security.audit_events (tenant_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_actor
    ON platform_security.audit_events (tenant_id, actor_user_id);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_permission
    ON platform_security.audit_events (tenant_id, permission_code);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_resource
    ON platform_security.audit_events (tenant_id, resource_area, resource_name);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_decision
    ON platform_security.audit_events (tenant_id, decision);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_request
    ON platform_security.audit_events (tenant_id, request_id);

CREATE INDEX IF NOT EXISTS idx_audit_actor_contexts_tenant_event
    ON platform_security.audit_actor_contexts (tenant_id, audit_event_id);

CREATE INDEX IF NOT EXISTS idx_audit_actor_contexts_tenant_actor
    ON platform_security.audit_actor_contexts (tenant_id, actor_user_id);

CREATE INDEX IF NOT EXISTS idx_audit_resource_contexts_tenant_event
    ON platform_security.audit_resource_contexts (tenant_id, audit_event_id);

CREATE INDEX IF NOT EXISTS idx_audit_resource_contexts_tenant_resource
    ON platform_security.audit_resource_contexts (tenant_id, resource_area, resource_name);

CREATE INDEX IF NOT EXISTS idx_audit_decision_contexts_tenant_event
    ON platform_security.audit_decision_contexts (tenant_id, audit_event_id);

CREATE INDEX IF NOT EXISTS idx_audit_decision_contexts_tenant_decision
    ON platform_security.audit_decision_contexts (tenant_id, decision);

CREATE INDEX IF NOT EXISTS idx_audit_integrity_chain_tenant_stream
    ON platform_security.audit_integrity_chain (tenant_id, audit_event_stream_id);

CREATE INDEX IF NOT EXISTS idx_audit_integrity_chain_tenant_chain
    ON platform_security.audit_integrity_chain (tenant_id, audit_event_stream_id, chain_no);
