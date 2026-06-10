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

CREATE TABLE IF NOT EXISTS platform.workflow_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  workflow_instance_id TEXT NOT NULL,
  workflow_key TEXT NOT NULL,
  workflow_name TEXT NOT NULL,
  workflow_version INTEGER NOT NULL DEFAULT 1,
  business_ref_type TEXT,
  business_ref_id TEXT,
  status TEXT NOT NULL DEFAULT 'CREATED',
  current_step_key TEXT,
  correlation_id TEXT NOT NULL,
  idempotency_key TEXT,
  input_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  state_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT,
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  CONSTRAINT workflow_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT workflow_states_instance_id_chk CHECK (length(trim(workflow_instance_id)) > 0),
  CONSTRAINT workflow_states_version_chk CHECK (workflow_version > 0),
  CONSTRAINT workflow_states_status_chk CHECK (
    status IN (
      'CREATED',
      'RUNNING',
      'WAITING_APPROVAL',
      'WAITING_EVENT',
      'COMPENSATING',
      'COMPLETED',
      'FAILED',
      'CANCELED'
    )
  ),
  CONSTRAINT workflow_states_tenant_instance_uq UNIQUE (tenant_id, workflow_instance_id),
  CONSTRAINT workflow_states_tenant_correlation_uq UNIQUE (tenant_id, workflow_key, correlation_id)
);

CREATE TABLE IF NOT EXISTS platform.workflow_steps (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  workflow_state_id BIGINT NOT NULL REFERENCES platform.workflow_states(id) ON DELETE CASCADE,
  step_key TEXT NOT NULL,
  step_name TEXT NOT NULL,
  step_order INTEGER NOT NULL DEFAULT 0,
  step_type TEXT NOT NULL DEFAULT 'TASK',
  status TEXT NOT NULL DEFAULT 'PENDING',
  depends_on_step_key TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retry_count INTEGER NOT NULL DEFAULT 3,
  retry_after_at TIMESTAMPTZ,
  locked_by TEXT,
  locked_at TIMESTAMPTZ,
  input_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  output_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  skipped_at TIMESTAMPTZ,
  CONSTRAINT workflow_steps_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT workflow_steps_order_chk CHECK (step_order >= 0),
  CONSTRAINT workflow_steps_retry_count_chk CHECK (retry_count >= 0),
  CONSTRAINT workflow_steps_max_retry_count_chk CHECK (max_retry_count >= 0),
  CONSTRAINT workflow_steps_type_chk CHECK (
    step_type IN (
      'TASK',
      'APPROVAL',
      'EVENT_WAIT',
      'COMPENSATION',
      'NOTIFICATION',
      'WEBHOOK',
      'SYSTEM'
    )
  ),
  CONSTRAINT workflow_steps_status_chk CHECK (
    status IN (
      'PENDING',
      'RUNNING',
      'WAITING',
      'WAITING_APPROVAL',
      'APPROVED',
      'REJECTED',
      'COMPLETED',
      'FAILED',
      'SKIPPED',
      'COMPENSATED'
    )
  ),
  CONSTRAINT workflow_steps_tenant_workflow_step_uq UNIQUE (tenant_id, workflow_state_id, step_key)
);

CREATE TABLE IF NOT EXISTS platform.workflow_approval_records (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  workflow_state_id BIGINT NOT NULL REFERENCES platform.workflow_states(id) ON DELETE CASCADE,
  workflow_step_id BIGINT REFERENCES platform.workflow_steps(id) ON DELETE SET NULL,
  approval_record_id TEXT NOT NULL,
  approval_key TEXT NOT NULL,
  approver_type TEXT NOT NULL DEFAULT 'USER',
  approver_ref TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  requested_by TEXT NOT NULL,
  decided_by TEXT,
  decision_reason TEXT,
  request_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  decision_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  CONSTRAINT workflow_approval_records_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT workflow_approval_records_id_chk CHECK (length(trim(approval_record_id)) > 0),
  CONSTRAINT workflow_approval_records_approver_type_chk CHECK (
    approver_type IN ('USER', 'ROLE', 'GROUP', 'SYSTEM')
  ),
  CONSTRAINT workflow_approval_records_status_chk CHECK (
    status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELED', 'EXPIRED')
  ),
  CONSTRAINT workflow_approval_records_tenant_record_uq UNIQUE (tenant_id, approval_record_id)
);

CREATE TABLE IF NOT EXISTS platform.workflow_compensation_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  workflow_state_id BIGINT NOT NULL REFERENCES platform.workflow_states(id) ON DELETE CASCADE,
  workflow_step_id BIGINT REFERENCES platform.workflow_steps(id) ON DELETE SET NULL,
  compensation_state_id TEXT NOT NULL,
  compensation_key TEXT NOT NULL,
  source_step_key TEXT,
  trigger_reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 3,
  input_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  output_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  CONSTRAINT workflow_compensation_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT workflow_compensation_states_id_chk CHECK (length(trim(compensation_state_id)) > 0),
  CONSTRAINT workflow_compensation_states_attempt_chk CHECK (attempt_count >= 0),
  CONSTRAINT workflow_compensation_states_max_attempt_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT workflow_compensation_states_status_chk CHECK (
    status IN ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'SKIPPED')
  ),
  CONSTRAINT workflow_compensation_states_tenant_state_uq UNIQUE (tenant_id, compensation_state_id),
  CONSTRAINT workflow_compensation_states_tenant_workflow_key_uq UNIQUE (tenant_id, workflow_state_id, compensation_key)
);

CREATE TABLE IF NOT EXISTS platform.workflow_audit_events (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  workflow_state_id BIGINT REFERENCES platform.workflow_states(id) ON DELETE SET NULL,
  workflow_step_id BIGINT REFERENCES platform.workflow_steps(id) ON DELETE SET NULL,
  approval_record_id BIGINT REFERENCES platform.workflow_approval_records(id) ON DELETE SET NULL,
  compensation_state_id BIGINT REFERENCES platform.workflow_compensation_states(id) ON DELETE SET NULL,
  workflow_audit_event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_subtype TEXT,
  actor_type TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_ref TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  event_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT workflow_audit_events_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT workflow_audit_events_event_id_chk CHECK (length(trim(workflow_audit_event_id)) > 0),
  CONSTRAINT workflow_audit_events_event_type_chk CHECK (length(trim(event_type)) > 0),
  CONSTRAINT workflow_audit_events_actor_type_chk CHECK (
    actor_type IN ('USER', 'SYSTEM', 'SERVICE', 'OPERATOR', 'WORKER')
  ),
  CONSTRAINT workflow_audit_events_tenant_event_uq UNIQUE (tenant_id, workflow_audit_event_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workflow_states_tenant_idempotency
  ON platform.workflow_states (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workflow_states_tenant_status
  ON platform.workflow_states (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_workflow_states_current_step
  ON platform.workflow_states (tenant_id, current_step_key);

CREATE INDEX IF NOT EXISTS idx_workflow_states_business_ref
  ON platform.workflow_states (tenant_id, business_ref_type, business_ref_id);

CREATE INDEX IF NOT EXISTS idx_workflow_states_updated_at
  ON platform.workflow_states (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_workflow_steps_tenant_status
  ON platform.workflow_steps (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_workflow_steps_tenant_step
  ON platform.workflow_steps (tenant_id, workflow_state_id, step_key);

CREATE INDEX IF NOT EXISTS idx_workflow_steps_retry_after
  ON platform.workflow_steps (tenant_id, retry_after_at)
  WHERE retry_after_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workflow_steps_locked_at
  ON platform.workflow_steps (locked_at)
  WHERE locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workflow_approval_records_tenant_status
  ON platform.workflow_approval_records (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_workflow_approval_records_approver
  ON platform.workflow_approval_records (tenant_id, approver_type, approver_ref, status);

CREATE INDEX IF NOT EXISTS idx_workflow_approval_records_workflow
  ON platform.workflow_approval_records (tenant_id, workflow_state_id);

CREATE INDEX IF NOT EXISTS idx_workflow_approval_records_expires_at
  ON platform.workflow_approval_records (expires_at)
  WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workflow_compensation_states_tenant_status
  ON platform.workflow_compensation_states (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_workflow_compensation_states_workflow
  ON platform.workflow_compensation_states (tenant_id, workflow_state_id);

CREATE INDEX IF NOT EXISTS idx_workflow_compensation_states_step
  ON platform.workflow_compensation_states (tenant_id, workflow_step_id);

CREATE INDEX IF NOT EXISTS idx_workflow_audit_events_tenant_workflow_created
  ON platform.workflow_audit_events (tenant_id, workflow_state_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workflow_audit_events_tenant_event_type
  ON platform.workflow_audit_events (tenant_id, event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workflow_audit_events_correlation
  ON platform.workflow_audit_events (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workflow_audit_events_created_at
  ON platform.workflow_audit_events (created_at DESC);

DROP TRIGGER IF EXISTS trg_workflow_states_updated_at ON platform.workflow_states;
CREATE TRIGGER trg_workflow_states_updated_at
BEFORE UPDATE ON platform.workflow_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_steps_updated_at ON platform.workflow_steps;
CREATE TRIGGER trg_workflow_steps_updated_at
BEFORE UPDATE ON platform.workflow_steps
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_approval_records_updated_at ON platform.workflow_approval_records;
CREATE TRIGGER trg_workflow_approval_records_updated_at
BEFORE UPDATE ON platform.workflow_approval_records
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_workflow_compensation_states_updated_at ON platform.workflow_compensation_states;
CREATE TRIGGER trg_workflow_compensation_states_updated_at
BEFORE UPDATE ON platform.workflow_compensation_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.workflow_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_approval_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_compensation_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.workflow_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_steps FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_approval_records FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_compensation_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.workflow_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS workflow_states_tenant_isolation ON platform.workflow_states;
CREATE POLICY workflow_states_tenant_isolation
ON platform.workflow_states
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

DROP POLICY IF EXISTS workflow_steps_tenant_isolation ON platform.workflow_steps;
CREATE POLICY workflow_steps_tenant_isolation
ON platform.workflow_steps
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

DROP POLICY IF EXISTS workflow_approval_records_tenant_isolation ON platform.workflow_approval_records;
CREATE POLICY workflow_approval_records_tenant_isolation
ON platform.workflow_approval_records
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

DROP POLICY IF EXISTS workflow_compensation_states_tenant_isolation ON platform.workflow_compensation_states;
CREATE POLICY workflow_compensation_states_tenant_isolation
ON platform.workflow_compensation_states
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

DROP POLICY IF EXISTS workflow_audit_events_tenant_isolation ON platform.workflow_audit_events;
CREATE POLICY workflow_audit_events_tenant_isolation
ON platform.workflow_audit_events
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

COMMENT ON TABLE platform.workflow_states IS 'FAZ 2-6.7 workflow instance/state persistence table.';
COMMENT ON TABLE platform.workflow_steps IS 'FAZ 2-6.7 workflow step runtime persistence table.';
COMMENT ON TABLE platform.workflow_approval_records IS 'FAZ 2-6.7 workflow approval decision persistence table.';
COMMENT ON TABLE platform.workflow_compensation_states IS 'FAZ 2-6.7 workflow compensation state persistence table.';
COMMENT ON TABLE platform.workflow_audit_events IS 'FAZ 2-6.7 workflow immutable audit event persistence table.';

COMMIT;
