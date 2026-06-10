BEGIN;

CREATE SCHEMA IF NOT EXISTS platform;

CREATE OR REPLACE FUNCTION platform.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS platform.job_queues (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  job_id TEXT NOT NULL,
  job_key TEXT NOT NULL,
  job_type TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  worker_group TEXT,
  priority INTEGER NOT NULL DEFAULT 100,
  job_status TEXT NOT NULL DEFAULT 'PENDING',
  schedule_status TEXT NOT NULL DEFAULT 'READY',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 3,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_by TEXT,
  locked_at TIMESTAMPTZ,
  lock_expires_at TIMESTAMPTZ,
  last_attempt_at TIMESTAMPTZ,
  next_retry_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  dead_at TIMESTAMPTZ,
  idempotency_key TEXT,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT job_queues_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT job_queues_job_id_chk CHECK (length(trim(job_id)) > 0),
  CONSTRAINT job_queues_job_key_chk CHECK (length(trim(job_key)) > 0),
  CONSTRAINT job_queues_job_type_chk CHECK (length(trim(job_type)) > 0),
  CONSTRAINT job_queues_queue_name_chk CHECK (length(trim(queue_name)) > 0),
  CONSTRAINT job_queues_priority_chk CHECK (priority >= 0),
  CONSTRAINT job_queues_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT job_queues_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT job_queues_status_chk CHECK (
    job_status IN (
      'PENDING',
      'READY',
      'SCHEDULED',
      'RUNNING',
      'RETRY_WAITING',
      'COMPLETED',
      'FAILED',
      'CANCELED',
      'DEAD'
    )
  ),
  CONSTRAINT job_queues_schedule_status_chk CHECK (
    schedule_status IN ('READY', 'DELAYED', 'PAUSED', 'BLOCKED')
  ),
  CONSTRAINT job_queues_lock_window_chk CHECK (
    lock_expires_at IS NULL OR locked_at IS NULL OR lock_expires_at > locked_at
  ),
  CONSTRAINT job_queues_tenant_job_uq UNIQUE (tenant_id, job_id)
);

CREATE TABLE IF NOT EXISTS platform.job_retry_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  job_retry_state_id TEXT NOT NULL,
  job_queue_id BIGINT NOT NULL REFERENCES platform.job_queues(id) ON DELETE CASCADE,
  job_id TEXT NOT NULL,
  retry_policy_key TEXT NOT NULL DEFAULT 'default',
  retry_status TEXT NOT NULL DEFAULT 'WAITING',
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 3,
  backoff_strategy TEXT NOT NULL DEFAULT 'EXPONENTIAL',
  backoff_seconds INTEGER NOT NULL DEFAULT 60,
  jitter_seconds INTEGER NOT NULL DEFAULT 0,
  next_retry_at TIMESTAMPTZ,
  last_retry_at TIMESTAMPTZ,
  locked_by TEXT,
  locked_at TIMESTAMPTZ,
  last_error_code TEXT,
  last_error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  retry_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT job_retry_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT job_retry_states_id_chk CHECK (length(trim(job_retry_state_id)) > 0),
  CONSTRAINT job_retry_states_job_id_chk CHECK (length(trim(job_id)) > 0),
  CONSTRAINT job_retry_states_policy_key_chk CHECK (length(trim(retry_policy_key)) > 0),
  CONSTRAINT job_retry_states_status_chk CHECK (
    retry_status IN ('WAITING', 'LOCKED', 'RETRYING', 'SUCCEEDED', 'FAILED', 'EXHAUSTED', 'CANCELED')
  ),
  CONSTRAINT job_retry_states_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT job_retry_states_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT job_retry_states_backoff_strategy_chk CHECK (
    backoff_strategy IN ('FIXED', 'LINEAR', 'EXPONENTIAL')
  ),
  CONSTRAINT job_retry_states_backoff_seconds_chk CHECK (backoff_seconds >= 0),
  CONSTRAINT job_retry_states_jitter_seconds_chk CHECK (jitter_seconds >= 0),
  CONSTRAINT job_retry_states_tenant_retry_uq UNIQUE (tenant_id, job_retry_state_id),
  CONSTRAINT job_retry_states_tenant_job_uq UNIQUE (tenant_id, job_queue_id)
);

CREATE TABLE IF NOT EXISTS platform.tenant_job_scopes (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  tenant_job_scope_id TEXT NOT NULL,
  scope_key TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  job_type TEXT NOT NULL,
  scope_status TEXT NOT NULL DEFAULT 'ACTIVE',
  worker_group TEXT,
  concurrency_limit INTEGER NOT NULL DEFAULT 1,
  rate_limit_per_minute INTEGER NOT NULL DEFAULT 0,
  priority_floor INTEGER NOT NULL DEFAULT 0,
  priority_ceiling INTEGER NOT NULL DEFAULT 1000,
  max_pending_jobs INTEGER NOT NULL DEFAULT 0,
  max_running_jobs INTEGER NOT NULL DEFAULT 0,
  allow_retry BOOLEAN NOT NULL DEFAULT true,
  allow_dlq BOOLEAN NOT NULL DEFAULT true,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  scope_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  effective_until TIMESTAMPTZ,
  CONSTRAINT tenant_job_scopes_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT tenant_job_scopes_id_chk CHECK (length(trim(tenant_job_scope_id)) > 0),
  CONSTRAINT tenant_job_scopes_scope_key_chk CHECK (length(trim(scope_key)) > 0),
  CONSTRAINT tenant_job_scopes_queue_name_chk CHECK (length(trim(queue_name)) > 0),
  CONSTRAINT tenant_job_scopes_job_type_chk CHECK (length(trim(job_type)) > 0),
  CONSTRAINT tenant_job_scopes_status_chk CHECK (
    scope_status IN ('ACTIVE', 'PAUSED', 'SUSPENDED', 'ARCHIVED')
  ),
  CONSTRAINT tenant_job_scopes_concurrency_chk CHECK (concurrency_limit >= 0),
  CONSTRAINT tenant_job_scopes_rate_limit_chk CHECK (rate_limit_per_minute >= 0),
  CONSTRAINT tenant_job_scopes_priority_floor_chk CHECK (priority_floor >= 0),
  CONSTRAINT tenant_job_scopes_priority_ceiling_chk CHECK (priority_ceiling >= priority_floor),
  CONSTRAINT tenant_job_scopes_max_pending_chk CHECK (max_pending_jobs >= 0),
  CONSTRAINT tenant_job_scopes_max_running_chk CHECK (max_running_jobs >= 0),
  CONSTRAINT tenant_job_scopes_window_chk CHECK (
    effective_until IS NULL OR effective_until > effective_from
  ),
  CONSTRAINT tenant_job_scopes_tenant_scope_uq UNIQUE (tenant_id, tenant_job_scope_id),
  CONSTRAINT tenant_job_scopes_tenant_queue_type_uq UNIQUE (tenant_id, queue_name, job_type)
);

CREATE TABLE IF NOT EXISTS platform.dead_job_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  dead_job_state_id TEXT NOT NULL,
  job_queue_id BIGINT NOT NULL REFERENCES platform.job_queues(id) ON DELETE CASCADE,
  job_id TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  job_type TEXT NOT NULL,
  dead_reason TEXT NOT NULL,
  dead_status TEXT NOT NULL DEFAULT 'OPEN',
  poison_job BOOLEAN NOT NULL DEFAULT false,
  failed_attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  last_error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  replay_requested_by TEXT,
  replay_request_reason TEXT,
  replay_requested_at TIMESTAMPTZ,
  replayed_by TEXT,
  replayed_at TIMESTAMPTZ,
  archived_by TEXT,
  archived_at TIMESTAMPTZ,
  dead_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT dead_job_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT dead_job_states_id_chk CHECK (length(trim(dead_job_state_id)) > 0),
  CONSTRAINT dead_job_states_job_id_chk CHECK (length(trim(job_id)) > 0),
  CONSTRAINT dead_job_states_queue_name_chk CHECK (length(trim(queue_name)) > 0),
  CONSTRAINT dead_job_states_job_type_chk CHECK (length(trim(job_type)) > 0),
  CONSTRAINT dead_job_states_reason_chk CHECK (length(trim(dead_reason)) > 0),
  CONSTRAINT dead_job_states_status_chk CHECK (
    dead_status IN ('OPEN', 'REPLAY_REQUESTED', 'REPLAYED', 'ARCHIVED', 'IGNORED')
  ),
  CONSTRAINT dead_job_states_failed_attempt_count_chk CHECK (failed_attempt_count >= 0),
  CONSTRAINT dead_job_states_tenant_dead_uq UNIQUE (tenant_id, dead_job_state_id),
  CONSTRAINT dead_job_states_tenant_job_uq UNIQUE (tenant_id, job_queue_id)
);

CREATE TABLE IF NOT EXISTS platform.job_audit_events (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  job_audit_event_id TEXT NOT NULL,
  job_queue_id BIGINT REFERENCES platform.job_queues(id) ON DELETE SET NULL,
  job_retry_state_id BIGINT REFERENCES platform.job_retry_states(id) ON DELETE SET NULL,
  dead_job_state_id BIGINT REFERENCES platform.dead_job_states(id) ON DELETE SET NULL,
  job_id TEXT,
  queue_name TEXT,
  job_type TEXT,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL DEFAULT 'AUDIT_ONLY',
  actor_type TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_ref TEXT,
  status_before TEXT,
  status_after TEXT,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  idempotency_key TEXT,
  audit_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT job_audit_events_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT job_audit_events_id_chk CHECK (length(trim(job_audit_event_id)) > 0),
  CONSTRAINT job_audit_events_event_type_chk CHECK (
    event_type IN (
      'JOB_CREATED',
      'JOB_SCHEDULED',
      'JOB_LOCKED',
      'JOB_STARTED',
      'JOB_COMPLETED',
      'JOB_FAILED',
      'JOB_RETRY_SCHEDULED',
      'JOB_RETRY_EXHAUSTED',
      'JOB_DEAD_CREATED',
      'JOB_REPLAY_REQUESTED',
      'JOB_REPLAYED',
      'JOB_CANCELED',
      'JOB_SCOPE_CHANGED'
    )
  ),
  CONSTRAINT job_audit_events_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'RETRY', 'DEAD', 'AUDIT_ONLY')
  ),
  CONSTRAINT job_audit_events_actor_type_chk CHECK (
    actor_type IN ('SYSTEM', 'SERVICE', 'WORKER', 'OPERATOR', 'USER')
  ),
  CONSTRAINT job_audit_events_tenant_event_uq UNIQUE (tenant_id, job_audit_event_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_job_queues_tenant_idempotency
  ON platform.job_queues (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_queues_tenant_status
  ON platform.job_queues (tenant_id, job_status);

CREATE INDEX IF NOT EXISTS idx_job_queues_queue_status_priority
  ON platform.job_queues (tenant_id, queue_name, job_status, priority, available_at);

CREATE INDEX IF NOT EXISTS idx_job_queues_type_status
  ON platform.job_queues (tenant_id, job_type, job_status);

CREATE INDEX IF NOT EXISTS idx_job_queues_worker_group
  ON platform.job_queues (tenant_id, worker_group, job_status)
  WHERE worker_group IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_queues_available_at
  ON platform.job_queues (available_at)
  WHERE job_status IN ('PENDING', 'READY', 'SCHEDULED', 'RETRY_WAITING');

CREATE INDEX IF NOT EXISTS idx_job_queues_locked_at
  ON platform.job_queues (locked_at)
  WHERE locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_queues_next_retry
  ON platform.job_queues (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_queues_correlation
  ON platform.job_queues (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_queues_created_at
  ON platform.job_queues (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_retry_states_tenant_status
  ON platform.job_retry_states (tenant_id, retry_status);

CREATE INDEX IF NOT EXISTS idx_job_retry_states_job
  ON platform.job_retry_states (tenant_id, job_queue_id);

CREATE INDEX IF NOT EXISTS idx_job_retry_states_next_retry
  ON platform.job_retry_states (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_retry_states_locked
  ON platform.job_retry_states (locked_at)
  WHERE locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_retry_states_policy
  ON platform.job_retry_states (tenant_id, retry_policy_key);

CREATE INDEX IF NOT EXISTS idx_tenant_job_scopes_tenant_status
  ON platform.tenant_job_scopes (tenant_id, scope_status);

CREATE INDEX IF NOT EXISTS idx_tenant_job_scopes_queue_type
  ON platform.tenant_job_scopes (tenant_id, queue_name, job_type);

CREATE INDEX IF NOT EXISTS idx_tenant_job_scopes_worker_group
  ON platform.tenant_job_scopes (tenant_id, worker_group)
  WHERE worker_group IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tenant_job_scopes_effective_until
  ON platform.tenant_job_scopes (effective_until)
  WHERE effective_until IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_dead_job_states_tenant_status
  ON platform.dead_job_states (tenant_id, dead_status);

CREATE INDEX IF NOT EXISTS idx_dead_job_states_job
  ON platform.dead_job_states (tenant_id, job_queue_id);

CREATE INDEX IF NOT EXISTS idx_dead_job_states_queue_type
  ON platform.dead_job_states (tenant_id, queue_name, job_type, dead_status);

CREATE INDEX IF NOT EXISTS idx_dead_job_states_poison
  ON platform.dead_job_states (tenant_id, poison_job)
  WHERE poison_job = true;

CREATE INDEX IF NOT EXISTS idx_dead_job_states_replay_requested
  ON platform.dead_job_states (tenant_id, replay_requested_at)
  WHERE replay_requested_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_dead_job_states_created_at
  ON platform.dead_job_states (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_audit_events_tenant_created
  ON platform.job_audit_events (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_audit_events_job
  ON platform.job_audit_events (tenant_id, job_queue_id, created_at DESC)
  WHERE job_queue_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_audit_events_event_type
  ON platform.job_audit_events (tenant_id, event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_audit_events_decision
  ON platform.job_audit_events (tenant_id, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_audit_events_correlation
  ON platform.job_audit_events (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_job_audit_events_request_id
  ON platform.job_audit_events (tenant_id, request_id)
  WHERE request_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_job_queues_updated_at ON platform.job_queues;
CREATE TRIGGER trg_job_queues_updated_at
BEFORE UPDATE ON platform.job_queues
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_job_retry_states_updated_at ON platform.job_retry_states;
CREATE TRIGGER trg_job_retry_states_updated_at
BEFORE UPDATE ON platform.job_retry_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_tenant_job_scopes_updated_at ON platform.tenant_job_scopes;
CREATE TRIGGER trg_tenant_job_scopes_updated_at
BEFORE UPDATE ON platform.tenant_job_scopes
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_dead_job_states_updated_at ON platform.dead_job_states;
CREATE TRIGGER trg_dead_job_states_updated_at
BEFORE UPDATE ON platform.dead_job_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.job_queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.job_retry_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.tenant_job_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.job_audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.dead_job_states ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.job_queues FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.job_retry_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.tenant_job_scopes FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.job_audit_events FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.dead_job_states FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS job_queues_tenant_isolation ON platform.job_queues;
CREATE POLICY job_queues_tenant_isolation
ON platform.job_queues
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS job_retry_states_tenant_isolation ON platform.job_retry_states;
CREATE POLICY job_retry_states_tenant_isolation
ON platform.job_retry_states
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS tenant_job_scopes_tenant_isolation ON platform.tenant_job_scopes;
CREATE POLICY tenant_job_scopes_tenant_isolation
ON platform.tenant_job_scopes
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS job_audit_events_tenant_isolation ON platform.job_audit_events;
CREATE POLICY job_audit_events_tenant_isolation
ON platform.job_audit_events
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

DROP POLICY IF EXISTS dead_job_states_tenant_isolation ON platform.dead_job_states;
CREATE POLICY dead_job_states_tenant_isolation
ON platform.dead_job_states
FOR ALL
USING (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
)
WITH CHECK (
  tenant_id = COALESCE(
    NULLIF(current_setting('pix2pi.tenant_id', true), ''),
    NULLIF(current_setting('app.tenant_id', true), ''),
    NULLIF(current_setting('request.tenant_id', true), '')
  )
);

COMMENT ON TABLE platform.job_queues IS 'FAZ 2-6.3 job queue persistence table.';
COMMENT ON TABLE platform.job_retry_states IS 'FAZ 2-6.3 job retry/backoff persistence table.';
COMMENT ON TABLE platform.tenant_job_scopes IS 'FAZ 2-6.3 tenant job scope persistence table.';
COMMENT ON TABLE platform.job_audit_events IS 'FAZ 2-6.3 job audit event persistence table.';
COMMENT ON TABLE platform.dead_job_states IS 'FAZ 2-6.3 dead job state persistence table.';

COMMIT;
