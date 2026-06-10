-- 185 — FAZ 4-15.5 Search / Index Projection Tablolari
-- Purpose:
--   Tenant-safe search/readmodel projection foundation for FAZ 4-R reporting.
-- Policy:
--   Search projection is readmodel-only.
--   It does not activate live external provider/GIB/bank/POS flows.
--   CLOSED_POLICY_GATE_REFERENCE_ONLY

CREATE TABLE IF NOT EXISTS public.search_projection_sources (
    tenant_id              TEXT NOT NULL,
    projection_source_id   TEXT NOT NULL,
    source_type            TEXT NOT NULL,
    source_name            TEXT NOT NULL,
    source_version         TEXT NOT NULL DEFAULT 'v1',
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    last_event_id          TEXT,
    last_projected_at      TIMESTAMPTZ,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT search_projection_sources_pk
        PRIMARY KEY (tenant_id, projection_source_id),

    CONSTRAINT search_projection_sources_type_chk
        CHECK (source_type IN (
            'CUSTOMER',
            'PRODUCT',
            'STOCK',
            'FINANCE_DOCUMENT',
            'IMPORT_BATCH',
            'E_DOCUMENT',
            'PAYMENT',
            'GENERIC'
        ))
);

CREATE INDEX IF NOT EXISTS search_projection_sources_type_idx
    ON public.search_projection_sources (tenant_id, source_type, is_active);

CREATE INDEX IF NOT EXISTS search_projection_sources_last_projected_idx
    ON public.search_projection_sources (tenant_id, last_projected_at DESC);


CREATE TABLE IF NOT EXISTS public.search_index_documents (
    tenant_id              TEXT NOT NULL,
    search_document_id     TEXT NOT NULL,
    entity_type            TEXT NOT NULL,
    entity_id              TEXT NOT NULL,
    entity_ref             TEXT,
    title                  TEXT NOT NULL,
    subtitle               TEXT,
    searchable_text        TEXT NOT NULL,
    search_vector          TSVECTOR,
    status                 TEXT NOT NULL DEFAULT 'ACTIVE',
    source_event_id        TEXT,
    source_updated_at      TIMESTAMPTZ,
    projection_version     INTEGER NOT NULL DEFAULT 1,
    ranking_score          NUMERIC(12,4) NOT NULL DEFAULT 0,
    payload                JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT search_index_documents_pk
        PRIMARY KEY (tenant_id, search_document_id),

    CONSTRAINT search_index_documents_entity_unique
        UNIQUE (tenant_id, entity_type, entity_id),

    CONSTRAINT search_index_documents_entity_type_chk
        CHECK (entity_type IN (
            'CUSTOMER',
            'PRODUCT',
            'STOCK_ITEM',
            'FINANCE_DOCUMENT',
            'IMPORT_BATCH',
            'E_DOCUMENT',
            'PAYMENT',
            'WAREHOUSE',
            'USER',
            'GENERIC'
        )),

    CONSTRAINT search_index_documents_status_chk
        CHECK (status IN (
            'ACTIVE',
            'ARCHIVED',
            'DELETED',
            'REBUILD_REQUIRED'
        )),

    CONSTRAINT search_index_documents_projection_version_chk
        CHECK (projection_version > 0)
);

CREATE INDEX IF NOT EXISTS search_index_documents_entity_idx
    ON public.search_index_documents (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS search_index_documents_status_idx
    ON public.search_index_documents (tenant_id, status);

CREATE INDEX IF NOT EXISTS search_index_documents_updated_idx
    ON public.search_index_documents (tenant_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS search_index_documents_ref_idx
    ON public.search_index_documents (tenant_id, entity_ref);

CREATE INDEX IF NOT EXISTS search_index_documents_payload_gin_idx
    ON public.search_index_documents USING GIN (payload);

CREATE INDEX IF NOT EXISTS search_index_documents_vector_gin_idx
    ON public.search_index_documents USING GIN (search_vector);


CREATE TABLE IF NOT EXISTS public.search_index_terms (
    tenant_id              TEXT NOT NULL,
    term_id                TEXT NOT NULL,
    search_document_id     TEXT NOT NULL,
    entity_type            TEXT NOT NULL,
    term                   TEXT NOT NULL,
    normalized_term        TEXT NOT NULL,
    term_type              TEXT NOT NULL DEFAULT 'TEXT',
    weight                 NUMERIC(12,4) NOT NULL DEFAULT 1,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT search_index_terms_pk
        PRIMARY KEY (tenant_id, term_id),

    CONSTRAINT search_index_terms_document_fk
        FOREIGN KEY (tenant_id, search_document_id)
        REFERENCES public.search_index_documents (tenant_id, search_document_id)
        ON DELETE CASCADE,

    CONSTRAINT search_index_terms_type_chk
        CHECK (term_type IN (
            'TEXT',
            'CODE',
            'BARCODE',
            'TAX_NO',
            'OEM',
            'EQUIVALENT',
            'PHONE',
            'EMAIL',
            'DOCUMENT_NO'
        )),

    CONSTRAINT search_index_terms_weight_chk
        CHECK (weight >= 0)
);

CREATE INDEX IF NOT EXISTS search_index_terms_document_idx
    ON public.search_index_terms (tenant_id, search_document_id);

CREATE INDEX IF NOT EXISTS search_index_terms_normalized_idx
    ON public.search_index_terms (tenant_id, normalized_term);

CREATE INDEX IF NOT EXISTS search_index_terms_type_idx
    ON public.search_index_terms (tenant_id, term_type, normalized_term);

CREATE INDEX IF NOT EXISTS search_index_terms_entity_idx
    ON public.search_index_terms (tenant_id, entity_type);


CREATE TABLE IF NOT EXISTS public.search_projection_offsets (
    tenant_id              TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    stream_name            TEXT NOT NULL,
    consumer_name          TEXT NOT NULL,
    last_event_id          TEXT,
    last_sequence          BIGINT NOT NULL DEFAULT 0,
    status                 TEXT NOT NULL DEFAULT 'ACTIVE',
    lag_count              BIGINT NOT NULL DEFAULT 0,
    last_error             TEXT,
    last_projected_at      TIMESTAMPTZ,
    metadata               JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT search_projection_offsets_pk
        PRIMARY KEY (tenant_id, projection_name),

    CONSTRAINT search_projection_offsets_status_chk
        CHECK (status IN (
            'ACTIVE',
            'PAUSED',
            'ERROR',
            'REBUILDING',
            'DISABLED'
        )),

    CONSTRAINT search_projection_offsets_sequence_chk
        CHECK (last_sequence >= 0 AND lag_count >= 0)
);

CREATE INDEX IF NOT EXISTS search_projection_offsets_stream_idx
    ON public.search_projection_offsets (tenant_id, stream_name, consumer_name);

CREATE INDEX IF NOT EXISTS search_projection_offsets_status_idx
    ON public.search_projection_offsets (tenant_id, status);


CREATE TABLE IF NOT EXISTS public.search_projection_rebuild_jobs (
    tenant_id              TEXT NOT NULL,
    rebuild_job_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    scope_type             TEXT NOT NULL,
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

    CONSTRAINT search_projection_rebuild_jobs_pk
        PRIMARY KEY (tenant_id, rebuild_job_id),

    CONSTRAINT search_projection_rebuild_jobs_scope_chk
        CHECK (scope_type IN (
            'TENANT',
            'ENTITY_TYPE',
            'ENTITY_ID',
            'IMPORT_BATCH',
            'DATE_RANGE',
            'FULL'
        )),

    CONSTRAINT search_projection_rebuild_jobs_status_chk
        CHECK (status IN (
            'QUEUED',
            'RUNNING',
            'COMPLETED',
            'FAILED',
            'CANCELED'
        )),

    CONSTRAINT search_projection_rebuild_jobs_count_chk
        CHECK (
            total_items >= 0
            AND processed_items >= 0
            AND failed_items >= 0
        )
);

CREATE INDEX IF NOT EXISTS search_projection_rebuild_jobs_status_idx
    ON public.search_projection_rebuild_jobs (tenant_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS search_projection_rebuild_jobs_projection_idx
    ON public.search_projection_rebuild_jobs (tenant_id, projection_name, created_at DESC);


CREATE TABLE IF NOT EXISTS public.search_projection_audit_events (
    tenant_id              TEXT NOT NULL,
    audit_event_id         TEXT NOT NULL,
    projection_name        TEXT NOT NULL,
    event_type             TEXT NOT NULL,
    entity_type            TEXT,
    entity_id              TEXT,
    actor_id               TEXT NOT NULL,
    correlation_id         TEXT NOT NULL,
    event_payload          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT search_projection_audit_events_pk
        PRIMARY KEY (tenant_id, audit_event_id),

    CONSTRAINT search_projection_audit_events_type_chk
        CHECK (event_type IN (
            'SEARCH_DOCUMENT_INDEXED',
            'SEARCH_DOCUMENT_UPDATED',
            'SEARCH_DOCUMENT_DELETED',
            'SEARCH_TERMS_REBUILT',
            'SEARCH_PROJECTION_OFFSET_UPDATED',
            'SEARCH_REBUILD_JOB_CREATED',
            'SEARCH_REBUILD_JOB_STARTED',
            'SEARCH_REBUILD_JOB_COMPLETED',
            'SEARCH_REBUILD_JOB_FAILED'
        ))
);

CREATE INDEX IF NOT EXISTS search_projection_audit_events_projection_idx
    ON public.search_projection_audit_events (tenant_id, projection_name, created_at DESC);

CREATE INDEX IF NOT EXISTS search_projection_audit_events_entity_idx
    ON public.search_projection_audit_events (tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS search_projection_audit_events_correlation_idx
    ON public.search_projection_audit_events (tenant_id, correlation_id);

-- 185 / FAZ 4-15.5 completion marker:
-- SEARCH_INDEX_PROJECTION_TABLES_IMPLEMENTED
