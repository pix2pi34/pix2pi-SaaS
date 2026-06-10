-- 189 — FAZ 4-15.6 Materialized View / Cache Projection Standardi
-- Purpose:
--   Tenant-safe materialized view and cache projection standard for FAZ 4-R DB-L6 Reporting / Readmodel.
-- Policy:
--   Projection/cache standard is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.materialized_projection_definitions (
    tenant_id              TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    projection_type        TEXT NOT NULL,
    source_domain          TEXT NOT NULL,
    refresh_strategy       TEXT NOT NULL DEFAULT 'MANUAL',
    cache_strategy         TEXT NOT NULL DEFAULT 'NONE',
    ttl_seconds            INTEGER NOT NULL DEFAULT 0,
    stale_after_seconds    INTEGER NOT NULL DEFAULT 0,
    rebuild_required       BOOLEAN NOT NULL DEFAULT FALSE,
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    source_query_hash      TEXT,
    owner_team             TEXT NOT NULL DEFAULT 'platform',
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT materialized_projection_definitions_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT materialized_projection_definitions_type_chk
        CHECK (projection_type IN (
            'MATERIALIZED_VIEW',
            'CACHE_TABLE',
            'HYBRID',
            'EXTERNAL_CACHE'
        )),

    CONSTRAINT materialized_projection_definitions_refresh_chk
        CHECK (refresh_strategy IN (
            'MANUAL',
            'SCHEDULED',
            'EVENT_DRIVEN',
            'TTL',
            'ON_DEMAND'
        )),

    CONSTRAINT materialized_projection_definitions_cache_chk
        CHECK (cache_strategy IN (
            'NONE',
            'POSTGRES',
            'REDIS',
            'MEMORY',
            'HYBRID'
        )),

    CONSTRAINT materialized_projection_definitions_ttl_chk
        CHECK (ttl_seconds >= 0 AND stale_after_seconds >= 0)
);

CREATE INDEX IF NOT EXISTS materialized_projection_definitions_domain_idx
    ON public.materialized_projection_definitions (tenant_id, source_domain, is_active);

CREATE INDEX IF NOT EXISTS materialized_projection_definitions_refresh_idx
    ON public.materialized_projection_definitions (tenant_id, refresh_strategy);

CREATE INDEX IF NOT EXISTS materialized_projection_definitions_cache_idx
    ON public.materialized_projection_definitions (tenant_id, cache_strategy);


CREATE TABLE IF NOT EXISTS public.projection_cache_profiles (
    tenant_id              TEXT NOT NULL,
    cache_profile_id       TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    cache_backend          TEXT NOT NULL DEFAULT 'POSTGRES',
    ttl_seconds            INTEGER NOT NULL DEFAULT 300,
    stale_after_seconds    INTEGER NOT NULL DEFAULT 60,
    max_entries            INTEGER NOT NULL DEFAULT 0,
    invalidation_strategy  TEXT NOT NULL DEFAULT 'EVENT_DRIVEN',
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT projection_cache_profiles_pk
        PRIMARY KEY (tenant_id, cache_profile_id),

    CONSTRAINT projection_cache_profiles_projection_fk
        FOREIGN KEY (tenant_id, projection_name)
        REFERENCES public.materialized_projection_definitions (tenant_id, projection_name)
        ON DELETE CASCADE,

    CONSTRAINT projection_cache_profiles_backend_chk
        CHECK (cache_backend IN (
            'POSTGRES',
            'REDIS',
            'MEMORY',
            'HYBRID'
        )),

    CONSTRAINT projection_cache_profiles_invalidation_chk
        CHECK (invalidation_strategy IN (
            'EVENT_DRIVEN',
            'TTL',
            'MANUAL',
            'WRITE_THROUGH',
            'FULL_REBUILD'
        )),

    CONSTRAINT projection_cache_profiles_ttl_chk
        CHECK (
            ttl_seconds >= 0
            AND stale_after_seconds >= 0
            AND max_entries >= 0
        )
);

CREATE INDEX IF NOT EXISTS projection_cache_profiles_projection_idx
    ON public.projection_cache_profiles (tenant_id, projection_name, is_active);

CREATE INDEX IF NOT EXISTS projection_cache_profiles_backend_idx
    ON public.projection_cache_profiles (tenant_id, cache_backend);


CREATE TABLE IF NOT EXISTS public.projection_cache_entries (
    tenant_id              TEXT NOT NULL,
    cache_key              TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    cache_profile_id       TEXT,
    entity_type            TEXT NOT NULL,
    entity_id              TEXT NOT NULL,
    cache_status           TEXT NOT NULL DEFAULT 'ACTIVE',
    payload                JSONB NOT NULL DEFAULT '{}'::jsonb,
    payload_hash           TEXT,
    valid_from             TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at             TIMESTAMPTZ,
    invalidated_at         TIMESTAMPTZ,
    invalidation_reason    TEXT,
    hit_count              BIGINT NOT NULL DEFAULT 0,
    last_hit_at            TIMESTAMPTZ,
    source_event_id        TEXT,
    projection_version     INTEGER NOT NULL DEFAULT 1,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT projection_cache_entries_pk
        PRIMARY KEY (tenant_id, cache_key),

    CONSTRAINT projection_cache_entries_projection_fk
        FOREIGN KEY (tenant_id, projection_name)
        REFERENCES public.materialized_projection_definitions (tenant_id, projection_name)
        ON DELETE CASCADE,

    CONSTRAINT projection_cache_entries_profile_fk
        FOREIGN KEY (tenant_id, cache_profile_id)
        REFERENCES public.projection_cache_profiles (tenant_id, cache_profile_id)
        ON DELETE SET NULL,

    CONSTRAINT projection_cache_entries_entity_unique
        UNIQUE (tenant_id, projection_name, entity_type, entity_id),

    CONSTRAINT projection_cache_entries_status_chk
        CHECK (cache_status IN (
            'ACTIVE',
            'STALE',
            'EXPIRED',
            'INVALIDATED',
            'REBUILD_REQUIRED'
        )),

    CONSTRAINT projection_cache_entries_hit_chk
        CHECK (hit_count >= 0 AND projection_version > 0)
);

CREATE INDEX IF NOT EXISTS projection_cache_entries_projection_idx
    ON public.projection_cache_entries (tenant_id, projection_name, cache_status);

CREATE INDEX IF NOT EXISTS projection_cache_entries_entity_idx
    ON public.projection_cache_entries (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS projection_cache_entries_expires_idx
    ON public.projection_cache_entries (tenant_id, expires_at);

CREATE INDEX IF NOT EXISTS projection_cache_entries_payload_gin_idx
    ON public.projection_cache_entries USING GIN (payload);

CREATE INDEX IF NOT EXISTS projection_cache_entries_metadata_gin_idx
    ON public.projection_cache_entries USING GIN (metadata);


CREATE TABLE IF NOT EXISTS public.materialized_projection_dependencies (
    tenant_id              TEXT NOT NULL,
    dependency_id          TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    source_table           TEXT NOT NULL,
    source_entity_type     TEXT NOT NULL,
    dependency_type        TEXT NOT NULL DEFAULT 'READ',
    is_required            BOOLEAN NOT NULL DEFAULT TRUE,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT materialized_projection_dependencies_pk
        PRIMARY KEY (tenant_id, dependency_id),

    CONSTRAINT materialized_projection_dependencies_projection_fk
        FOREIGN KEY (tenant_id, projection_name)
        REFERENCES public.materialized_projection_definitions (tenant_id, projection_name)
        ON DELETE CASCADE,

    CONSTRAINT materialized_projection_dependencies_type_chk
        CHECK (dependency_type IN (
            'READ',
            'EVENT',
            'JOIN',
            'LOOKUP',
            'AGGREGATE'
        ))
);

CREATE INDEX IF NOT EXISTS materialized_projection_dependencies_projection_idx
    ON public.materialized_projection_dependencies (tenant_id, projection_name);

CREATE INDEX IF NOT EXISTS materialized_projection_dependencies_source_idx
    ON public.materialized_projection_dependencies (tenant_id, source_table, source_entity_type);


CREATE TABLE IF NOT EXISTS public.materialized_projection_refresh_jobs (
    tenant_id              TEXT NOT NULL,
    refresh_job_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    refresh_scope          TEXT NOT NULL DEFAULT 'FULL',
    scope_ref              TEXT,
    status                 TEXT NOT NULL DEFAULT 'QUEUED',
    requested_by           TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    total_items            INTEGER NOT NULL DEFAULT 0,
    processed_items        INTEGER NOT NULL DEFAULT 0,
    failed_items           INTEGER NOT NULL DEFAULT 0,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    error_message          TEXT,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT materialized_projection_refresh_jobs_pk
        PRIMARY KEY (tenant_id, refresh_job_id),

    CONSTRAINT materialized_projection_refresh_jobs_projection_fk
        FOREIGN KEY (tenant_id, projection_name)
        REFERENCES public.materialized_projection_definitions (tenant_id, projection_name)
        ON DELETE CASCADE,

    CONSTRAINT materialized_projection_refresh_jobs_scope_chk
        CHECK (refresh_scope IN (
            'FULL',
            'TENANT',
            'ENTITY_TYPE',
            'ENTITY_ID',
            'DATE_RANGE',
            'CACHE_KEY'
        )),

    CONSTRAINT materialized_projection_refresh_jobs_status_chk
        CHECK (status IN (
            'QUEUED',
            'RUNNING',
            'COMPLETED',
            'FAILED',
            'CANCELED'
        )),

    CONSTRAINT materialized_projection_refresh_jobs_count_chk
        CHECK (
            total_items >= 0
            AND processed_items >= 0
            AND failed_items >= 0
        )
);

CREATE INDEX IF NOT EXISTS materialized_projection_refresh_jobs_status_idx
    ON public.materialized_projection_refresh_jobs (tenant_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS materialized_projection_refresh_jobs_projection_idx
    ON public.materialized_projection_refresh_jobs (tenant_id, projection_name, created_at DESC);


CREATE TABLE IF NOT EXISTS public.materialized_projection_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT materialized_projection_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT materialized_projection_audit_events_projection_fk
        FOREIGN KEY (tenant_id, projection_name)
        REFERENCES public.materialized_projection_definitions (tenant_id, projection_name)
        ON DELETE CASCADE,

    CONSTRAINT materialized_projection_audit_events_type_chk
        CHECK (event_type IN (
            'PROJECTION_DEFINED',
            'CACHE_PROFILE_DEFINED',
            'CACHE_ENTRY_WRITTEN',
            'CACHE_ENTRY_HIT',
            'CACHE_ENTRY_INVALIDATED',
            'REFRESH_JOB_CREATED',
            'REFRESH_JOB_STARTED',
            'REFRESH_JOB_COMPLETED',
            'REFRESH_JOB_FAILED',
            'MATERIALIZED_VIEW_REFRESHED'
        ))
);

CREATE INDEX IF NOT EXISTS materialized_projection_audit_events_projection_idx
    ON public.materialized_projection_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS materialized_projection_audit_events_correlation_idx
    ON public.materialized_projection_audit_events (tenant_id, correlation_id);


CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_projection_cache_health AS
SELECT
    tenant_id,
    projection_name,
    COUNT(*)::BIGINT AS total_cache_entries,
    COUNT(*) FILTER (WHERE cache_status = 'ACTIVE')::BIGINT AS active_cache_entries,
    COUNT(*) FILTER (WHERE cache_status = 'STALE')::BIGINT AS stale_cache_entries,
    COUNT(*) FILTER (WHERE cache_status = 'EXPIRED')::BIGINT AS expired_cache_entries,
    COALESCE(SUM(hit_count), 0)::BIGINT AS total_hit_count,
    MAX(updated_at) AS last_cache_update_at
FROM public.projection_cache_entries
GROUP BY tenant_id, projection_name;

CREATE UNIQUE INDEX IF NOT EXISTS mv_projection_cache_health_pk
    ON public.mv_projection_cache_health (tenant_id, projection_name);

-- 189 / FAZ 4-15.6 completion marker:
-- MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_IMPLEMENTED
