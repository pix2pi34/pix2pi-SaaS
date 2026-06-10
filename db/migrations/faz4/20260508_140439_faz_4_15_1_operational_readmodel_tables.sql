-- 191 — FAZ 4-15.1 Operational Readmodel Tablolari
-- Purpose:
--   Tenant-safe operational readmodel foundation for FAZ 4-R DB-L6 Reporting / Readmodel.
-- Policy:
--   Operational readmodel is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.operational_readmodel_snapshots (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    snapshot_type          TEXT NOT NULL,
    snapshot_status        TEXT NOT NULL DEFAULT 'ACTIVE',
    generated_by           TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    snapshot_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_event_id        TEXT,
    projection_version     INTEGER NOT NULL DEFAULT 1,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_readmodel_snapshots_pk
        PRIMARY KEY (tenant_id, snapshot_id),

    CONSTRAINT operational_readmodel_snapshots_type_chk
        CHECK (snapshot_type IN (
            'TENANT_HEALTH',
            'USER_ACTIVITY',
            'IMPORT_QUEUE',
            'TASK_QUEUE',
            'SERVICE_HEALTH',
            'PILOT_DASHBOARD',
            'MIXED'
        )),

    CONSTRAINT operational_readmodel_snapshots_status_chk
        CHECK (snapshot_status IN (
            'ACTIVE',
            'STALE',
            'ARCHIVED',
            'REBUILD_REQUIRED'
        )),

    CONSTRAINT operational_readmodel_snapshots_version_chk
        CHECK (projection_version > 0)
);

CREATE INDEX IF NOT EXISTS operational_readmodel_snapshots_type_idx
    ON public.operational_readmodel_snapshots (tenant_id, snapshot_type, snapshot_status);

CREATE INDEX IF NOT EXISTS operational_readmodel_snapshots_at_idx
    ON public.operational_readmodel_snapshots (tenant_id, snapshot_at DESC);

CREATE INDEX IF NOT EXISTS operational_readmodel_snapshots_correlation_idx
    ON public.operational_readmodel_snapshots (tenant_id, correlation_id);


CREATE TABLE IF NOT EXISTS public.operational_tenant_health_readmodel (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    tenant_status          TEXT NOT NULL DEFAULT 'ACTIVE',
    health_status          TEXT NOT NULL DEFAULT 'UNKNOWN',
    open_issue_count       INTEGER NOT NULL DEFAULT 0,
    critical_issue_count   INTEGER NOT NULL DEFAULT 0,
    active_user_count      INTEGER NOT NULL DEFAULT 0,
    import_batch_count     INTEGER NOT NULL DEFAULT 0,
    failed_import_count    INTEGER NOT NULL DEFAULT 0,
    pending_uat_count      INTEGER NOT NULL DEFAULT 0,
    last_activity_at       TIMESTAMPTZ,
    last_import_at         TIMESTAMPTZ,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_tenant_health_readmodel_pk
        PRIMARY KEY (tenant_id, snapshot_id),

    CONSTRAINT operational_tenant_health_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE CASCADE,

    CONSTRAINT operational_tenant_health_tenant_status_chk
        CHECK (tenant_status IN (
            'ACTIVE',
            'TRIAL',
            'SUSPENDED',
            'CLOSED'
        )),

    CONSTRAINT operational_tenant_health_status_chk
        CHECK (health_status IN (
            'OK',
            'WARN',
            'CRITICAL',
            'UNKNOWN'
        )),

    CONSTRAINT operational_tenant_health_count_chk
        CHECK (
            open_issue_count >= 0
            AND critical_issue_count >= 0
            AND active_user_count >= 0
            AND import_batch_count >= 0
            AND failed_import_count >= 0
            AND pending_uat_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS operational_tenant_health_status_idx
    ON public.operational_tenant_health_readmodel (tenant_id, health_status);

CREATE INDEX IF NOT EXISTS operational_tenant_health_activity_idx
    ON public.operational_tenant_health_readmodel (tenant_id, last_activity_at DESC);


CREATE TABLE IF NOT EXISTS public.operational_user_activity_readmodel (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    user_id                TEXT NOT NULL,
    user_role              TEXT NOT NULL DEFAULT 'USER',
    user_status            TEXT NOT NULL DEFAULT 'ACTIVE',
    last_login_at          TIMESTAMPTZ,
    last_action_at         TIMESTAMPTZ,
    action_count           INTEGER NOT NULL DEFAULT 0,
    failed_login_count     INTEGER NOT NULL DEFAULT 0,
    device_count           INTEGER NOT NULL DEFAULT 0,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_user_activity_readmodel_pk
        PRIMARY KEY (tenant_id, snapshot_id, user_id),

    CONSTRAINT operational_user_activity_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE CASCADE,

    CONSTRAINT operational_user_activity_status_chk
        CHECK (user_status IN (
            'ACTIVE',
            'INVITED',
            'LOCKED',
            'DISABLED'
        )),

    CONSTRAINT operational_user_activity_count_chk
        CHECK (
            action_count >= 0
            AND failed_login_count >= 0
            AND device_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS operational_user_activity_user_idx
    ON public.operational_user_activity_readmodel (tenant_id, user_id);

CREATE INDEX IF NOT EXISTS operational_user_activity_last_action_idx
    ON public.operational_user_activity_readmodel (tenant_id, last_action_at DESC);

CREATE INDEX IF NOT EXISTS operational_user_activity_role_idx
    ON public.operational_user_activity_readmodel (tenant_id, user_role, user_status);


CREATE TABLE IF NOT EXISTS public.operational_import_queue_readmodel (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    import_batch_id        TEXT NOT NULL,
    import_type            TEXT NOT NULL,
    import_status          TEXT NOT NULL,
    total_rows             INTEGER NOT NULL DEFAULT 0,
    valid_rows             INTEGER NOT NULL DEFAULT 0,
    invalid_rows           INTEGER NOT NULL DEFAULT 0,
    committed_rows         INTEGER NOT NULL DEFAULT 0,
    failed_rows            INTEGER NOT NULL DEFAULT 0,
    owner_user_id          TEXT,
    created_by             TEXT NOT NULL,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_import_queue_readmodel_pk
        PRIMARY KEY (tenant_id, snapshot_id, import_batch_id),

    CONSTRAINT operational_import_queue_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE CASCADE,

    CONSTRAINT operational_import_queue_type_chk
        CHECK (import_type IN (
            'CUSTOMER',
            'PRODUCT',
            'STOCK',
            'FINANCE_DOCUMENT',
            'MIXED'
        )),

    CONSTRAINT operational_import_queue_status_chk
        CHECK (import_status IN (
            'CREATED',
            'DRY_RUN_STARTED',
            'DRY_RUN_COMPLETED',
            'VALIDATION_FAILED',
            'VALIDATED',
            'COMMIT_STARTED',
            'COMMITTED',
            'ROLLBACK_REQUIRED',
            'ROLLED_BACK',
            'FAILED',
            'CANCELED'
        )),

    CONSTRAINT operational_import_queue_count_chk
        CHECK (
            total_rows >= 0
            AND valid_rows >= 0
            AND invalid_rows >= 0
            AND committed_rows >= 0
            AND failed_rows >= 0
        )
);

CREATE INDEX IF NOT EXISTS operational_import_queue_status_idx
    ON public.operational_import_queue_readmodel (tenant_id, import_status, created_at DESC);

CREATE INDEX IF NOT EXISTS operational_import_queue_type_idx
    ON public.operational_import_queue_readmodel (tenant_id, import_type);

CREATE INDEX IF NOT EXISTS operational_import_queue_owner_idx
    ON public.operational_import_queue_readmodel (tenant_id, owner_user_id);


CREATE TABLE IF NOT EXISTS public.operational_task_queue_readmodel (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    task_id                TEXT NOT NULL,
    task_type              TEXT NOT NULL,
    task_status            TEXT NOT NULL DEFAULT 'OPEN',
    priority               TEXT NOT NULL DEFAULT 'NORMAL',
    assigned_to            TEXT,
    due_at                 TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    source_ref             TEXT,
    correlation_id         TEXT NOT NULL,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_task_queue_readmodel_pk
        PRIMARY KEY (tenant_id, snapshot_id, task_id),

    CONSTRAINT operational_task_queue_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE CASCADE,

    CONSTRAINT operational_task_queue_type_chk
        CHECK (task_type IN (
            'UAT',
            'IMPORT_REVIEW',
            'BUG',
            'SUPPORT',
            'TRAINING',
            'CUTOVER',
            'GO_NO_GO',
            'OTHER'
        )),

    CONSTRAINT operational_task_queue_status_chk
        CHECK (task_status IN (
            'OPEN',
            'IN_PROGRESS',
            'BLOCKED',
            'COMPLETED',
            'CANCELED'
        )),

    CONSTRAINT operational_task_queue_priority_chk
        CHECK (priority IN (
            'LOW',
            'NORMAL',
            'HIGH',
            'CRITICAL'
        ))
);

CREATE INDEX IF NOT EXISTS operational_task_queue_status_idx
    ON public.operational_task_queue_readmodel (tenant_id, task_status, priority);

CREATE INDEX IF NOT EXISTS operational_task_queue_assigned_idx
    ON public.operational_task_queue_readmodel (tenant_id, assigned_to);

CREATE INDEX IF NOT EXISTS operational_task_queue_due_idx
    ON public.operational_task_queue_readmodel (tenant_id, due_at);


CREATE TABLE IF NOT EXISTS public.operational_service_health_readmodel (
    tenant_id              TEXT NOT NULL,
    snapshot_id            TEXT NOT NULL,
    service_name           TEXT NOT NULL,
    service_status         TEXT NOT NULL DEFAULT 'UNKNOWN',
    health_endpoint        TEXT,
    last_check_at          TIMESTAMPTZ,
    response_time_ms       INTEGER NOT NULL DEFAULT 0,
    error_count            INTEGER NOT NULL DEFAULT 0,
    warning_count          INTEGER NOT NULL DEFAULT 0,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_service_health_readmodel_pk
        PRIMARY KEY (tenant_id, snapshot_id, service_name),

    CONSTRAINT operational_service_health_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE CASCADE,

    CONSTRAINT operational_service_health_status_chk
        CHECK (service_status IN (
            'UP',
            'DEGRADED',
            'DOWN',
            'UNKNOWN'
        )),

    CONSTRAINT operational_service_health_count_chk
        CHECK (
            response_time_ms >= 0
            AND error_count >= 0
            AND warning_count >= 0
        )
);

CREATE INDEX IF NOT EXISTS operational_service_health_status_idx
    ON public.operational_service_health_readmodel (tenant_id, service_status);

CREATE INDEX IF NOT EXISTS operational_service_health_name_idx
    ON public.operational_service_health_readmodel (tenant_id, service_name);

CREATE INDEX IF NOT EXISTS operational_service_health_check_idx
    ON public.operational_service_health_readmodel (tenant_id, last_check_at DESC);


CREATE TABLE IF NOT EXISTS public.operational_readmodel_projection_offsets (
    tenant_id              TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    stream_name            TEXT NOT NULL,
    consumer_name          TEXT NOT NULL,
    last_event_id          TEXT,
    last_sequence          BIGINT NOT NULL DEFAULT 0,
    status                 TEXT NOT NULL DEFAULT 'ACTIVE',
    lag_count              BIGINT NOT NULL DEFAULT 0,
    last_projected_at      TIMESTAMPTZ,
    last_error             TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_readmodel_projection_offsets_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT operational_readmodel_projection_offsets_status_chk
        CHECK (status IN (
            'ACTIVE',
            'PAUSED',
            'ERROR',
            'REBUILDING',
            'DISABLED'
        )),

    CONSTRAINT operational_readmodel_projection_offsets_seq_chk
        CHECK (last_sequence >= 0 AND lag_count >= 0)
);

CREATE INDEX IF NOT EXISTS operational_readmodel_projection_offsets_stream_idx
    ON public.operational_readmodel_projection_offsets (tenant_id, stream_name, consumer_name);

CREATE INDEX IF NOT EXISTS operational_readmodel_projection_offsets_status_idx
    ON public.operational_readmodel_projection_offsets (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.operational_readmodel_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    snapshot_id            TEXT,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operational_readmodel_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT operational_readmodel_audit_events_snapshot_fk
        FOREIGN KEY (tenant_id, snapshot_id)
        REFERENCES public.operational_readmodel_snapshots (tenant_id, snapshot_id)
        ON DELETE SET NULL,

    CONSTRAINT operational_readmodel_audit_events_type_chk
        CHECK (event_type IN (
            'OPERATIONAL_SNAPSHOT_CREATED',
            'TENANT_HEALTH_PROJECTED',
            'USER_ACTIVITY_PROJECTED',
            'IMPORT_QUEUE_PROJECTED',
            'TASK_QUEUE_PROJECTED',
            'SERVICE_HEALTH_PROJECTED',
            'OPERATIONAL_OFFSET_UPDATED',
            'OPERATIONAL_REBUILD_STARTED',
            'OPERATIONAL_REBUILD_COMPLETED',
            'OPERATIONAL_REBUILD_FAILED'
        ))
);

CREATE INDEX IF NOT EXISTS operational_readmodel_audit_events_projection_idx
    ON public.operational_readmodel_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS operational_readmodel_audit_events_snapshot_idx
    ON public.operational_readmodel_audit_events (tenant_id, snapshot_id);

CREATE INDEX IF NOT EXISTS operational_readmodel_audit_events_correlation_idx
    ON public.operational_readmodel_audit_events (tenant_id, correlation_id);

-- 191 / FAZ 4-15.1 completion marker:
-- OPERATIONAL_READMODEL_TABLES_IMPLEMENTED
