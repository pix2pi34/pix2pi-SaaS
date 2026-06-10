BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'job_priority_enum'
  ) THEN
    CREATE TYPE runtime.job_priority_enum AS ENUM (
      'critical',
      'high',
      'normal',
      'low'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'job_status_enum'
  ) THEN
    CREATE TYPE runtime.job_status_enum AS ENUM (
      'queued',
      'running',
      'succeeded',
      'failed',
      'dead_letter',
      'cancelled'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'job_attempt_status_enum'
  ) THEN
    CREATE TYPE runtime.job_attempt_status_enum AS ENUM (
      'started',
      'succeeded',
      'failed',
      'timeout',
      'cancelled'
    );
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION runtime.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS runtime.job_queues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  queue_key text NOT NULL,
  display_name text NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  is_enabled boolean NOT NULL DEFAULT true,
  max_concurrency integer NOT NULL DEFAULT 1,
  retry_limit integer NOT NULL DEFAULT 3,
  retry_backoff_seconds integer NOT NULL DEFAULT 30,
  dead_letter_queue_key text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (queue_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (display_name <> ''),
  CHECK (max_concurrency BETWEEN 1 AND 1024),
  CHECK (retry_limit BETWEEN 0 AND 100),
  CHECK (retry_backoff_seconds BETWEEN 0 AND 86400),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_job_queues_tenant_queue_key
ON runtime.job_queues (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  queue_key
);

CREATE INDEX IF NOT EXISTS ix_job_queues_tenant_id
ON runtime.job_queues (tenant_id);

CREATE TABLE IF NOT EXISTS runtime.jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  queue_id uuid NOT NULL REFERENCES runtime.job_queues(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  job_key text NOT NULL,
  job_type text NOT NULL,
  priority runtime.job_priority_enum NOT NULL DEFAULT 'normal',
  status runtime.job_status_enum NOT NULL DEFAULT 'queued',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  dedupe_key text,
  available_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  finished_at timestamptz,
  retry_count integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 3,
  last_error text,
  locked_by text,
  locked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (job_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (job_type <> ''),
  CHECK (retry_count BETWEEN 0 AND 1000),
  CHECK (max_attempts BETWEEN 1 AND 1000),
  CHECK (started_at IS NULL OR started_at >= created_at),
  CHECK (finished_at IS NULL OR finished_at >= created_at),
  CHECK (locked_at IS NULL OR locked_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_tenant_job_key
ON runtime.jobs (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  job_key
);

CREATE INDEX IF NOT EXISTS ix_jobs_tenant_id
ON runtime.jobs (tenant_id);

CREATE INDEX IF NOT EXISTS ix_jobs_queue_id
ON runtime.jobs (queue_id);

CREATE INDEX IF NOT EXISTS ix_jobs_status_available_at
ON runtime.jobs (status, available_at);

CREATE INDEX IF NOT EXISTS ix_jobs_dedupe_key
ON runtime.jobs (dedupe_key);

CREATE TABLE IF NOT EXISTS runtime.job_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES runtime.jobs(id) ON DELETE CASCADE,
  queue_id uuid NOT NULL REFERENCES runtime.job_queues(id) ON DELETE CASCADE,
  attempt_no integer NOT NULL,
  status runtime.job_attempt_status_enum NOT NULL,
  worker_id text,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  duration_ms integer,
  error_message text,
  result_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (attempt_no BETWEEN 1 AND 1000),
  CHECK (duration_ms IS NULL OR duration_ms >= 0),
  CHECK (finished_at IS NULL OR finished_at >= started_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_job_attempts_job_attempt_no
ON runtime.job_attempts (job_id, attempt_no);

CREATE INDEX IF NOT EXISTS ix_job_attempts_tenant_id
ON runtime.job_attempts (tenant_id);

CREATE INDEX IF NOT EXISTS ix_job_attempts_queue_id
ON runtime.job_attempts (queue_id);

CREATE INDEX IF NOT EXISTS ix_job_attempts_status
ON runtime.job_attempts (status);

CREATE OR REPLACE FUNCTION runtime.validate_job_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_queue_tenant_id uuid;
  v_queue_visibility_scope runtime.registry_visibility_scope_enum;
BEGIN
  SELECT q.tenant_id, q.visibility_scope
    INTO v_queue_tenant_id, v_queue_visibility_scope
  FROM runtime.job_queues q
  WHERE q.id = NEW.queue_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'job queue not found: %', NEW.queue_id;
  END IF;

  IF v_queue_visibility_scope = 'global' THEN
    IF NEW.tenant_id IS NOT NULL THEN
      RAISE EXCEPTION 'global queue job must have tenant_id = null';
    END IF;
  ELSE
    IF NEW.tenant_id IS NULL THEN
      RAISE EXCEPTION 'tenant queue job must have tenant_id';
    END IF;

    IF NEW.tenant_id <> v_queue_tenant_id THEN
      RAISE EXCEPTION 'job tenant_id must match queue tenant_id';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION runtime.validate_job_attempt_scope()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_job_tenant_id uuid;
  v_job_queue_id uuid;
BEGIN
  SELECT j.tenant_id, j.queue_id
    INTO v_job_tenant_id, v_job_queue_id
  FROM runtime.jobs j
  WHERE j.id = NEW.job_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'job not found: %', NEW.job_id;
  END IF;

  IF NEW.queue_id <> v_job_queue_id THEN
    RAISE EXCEPTION 'job attempt queue_id must match job.queue_id';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_job_tenant_id THEN
    RAISE EXCEPTION 'job attempt tenant_id must match job tenant_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_queues_touch_updated_at
ON runtime.job_queues;

CREATE TRIGGER trg_job_queues_touch_updated_at
BEFORE UPDATE ON runtime.job_queues
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_jobs_touch_updated_at
ON runtime.jobs;

CREATE TRIGGER trg_jobs_touch_updated_at
BEFORE UPDATE ON runtime.jobs
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_jobs_validate_scope
ON runtime.jobs;

CREATE TRIGGER trg_jobs_validate_scope
BEFORE INSERT OR UPDATE ON runtime.jobs
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_job_scope();

DROP TRIGGER IF EXISTS trg_job_attempts_validate_scope
ON runtime.job_attempts;

CREATE TRIGGER trg_job_attempts_validate_scope
BEFORE INSERT OR UPDATE ON runtime.job_attempts
FOR EACH ROW
EXECUTE FUNCTION runtime.validate_job_attempt_scope();

ALTER TABLE runtime.job_queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.job_queues FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.jobs FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.job_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.job_attempts FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_job_queues_select ON runtime.job_queues;
CREATE POLICY p_job_queues_select
ON runtime.job_queues
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_job_queues_insert ON runtime.job_queues;
CREATE POLICY p_job_queues_insert
ON runtime.job_queues
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_job_queues_update ON runtime.job_queues;
CREATE POLICY p_job_queues_update
ON runtime.job_queues
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_job_queues_delete ON runtime.job_queues;
CREATE POLICY p_job_queues_delete
ON runtime.job_queues
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_jobs_select ON runtime.jobs;
CREATE POLICY p_jobs_select
ON runtime.jobs
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_jobs_insert ON runtime.jobs;
CREATE POLICY p_jobs_insert
ON runtime.jobs
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_jobs_update ON runtime.jobs;
CREATE POLICY p_jobs_update
ON runtime.jobs
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_jobs_delete ON runtime.jobs;
CREATE POLICY p_jobs_delete
ON runtime.jobs
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_job_attempts_select ON runtime.job_attempts;
CREATE POLICY p_job_attempts_select
ON runtime.job_attempts
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_job_attempts_insert ON runtime.job_attempts;
CREATE POLICY p_job_attempts_insert
ON runtime.job_attempts
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_job_attempts_delete ON runtime.job_attempts;
CREATE POLICY p_job_attempts_delete
ON runtime.job_attempts
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_app') THEN
    GRANT USAGE ON SCHEMA runtime TO pix2pi_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA runtime TO pix2pi_app;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA runtime TO pix2pi_app;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA runtime TO pix2pi_app;
  END IF;
END
$$;

COMMIT;
