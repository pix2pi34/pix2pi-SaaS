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

CREATE TABLE IF NOT EXISTS platform.webhook_deliveries (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  webhook_delivery_id TEXT NOT NULL,
  webhook_endpoint_id TEXT NOT NULL,
  app_id TEXT,
  integration_key TEXT,
  event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_version TEXT NOT NULL DEFAULT 'v1',
  target_url TEXT NOT NULL,
  method TEXT NOT NULL DEFAULT 'POST',
  status TEXT NOT NULL DEFAULT 'PENDING',
  priority INTEGER NOT NULL DEFAULT 100,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 5,
  next_retry_at TIMESTAMPTZ,
  last_attempt_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  dlq_at TIMESTAMPTZ,
  request_headers JSONB NOT NULL DEFAULT '{}'::jsonb,
  request_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_status_code INTEGER,
  response_headers JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_body TEXT,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  correlation_id TEXT,
  causation_id TEXT,
  idempotency_key TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT webhook_deliveries_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT webhook_deliveries_id_chk CHECK (length(trim(webhook_delivery_id)) > 0),
  CONSTRAINT webhook_deliveries_endpoint_id_chk CHECK (length(trim(webhook_endpoint_id)) > 0),
  CONSTRAINT webhook_deliveries_event_id_chk CHECK (length(trim(event_id)) > 0),
  CONSTRAINT webhook_deliveries_event_type_chk CHECK (length(trim(event_type)) > 0),
  CONSTRAINT webhook_deliveries_target_url_chk CHECK (length(trim(target_url)) > 0),
  CONSTRAINT webhook_deliveries_method_chk CHECK (
    method IN ('POST', 'PUT', 'PATCH')
  ),
  CONSTRAINT webhook_deliveries_status_chk CHECK (
    status IN (
      'PENDING',
      'SCHEDULED',
      'DELIVERING',
      'DELIVERED',
      'RETRY_WAITING',
      'FAILED',
      'DLQ',
      'CANCELED'
    )
  ),
  CONSTRAINT webhook_deliveries_priority_chk CHECK (priority >= 0),
  CONSTRAINT webhook_deliveries_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT webhook_deliveries_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT webhook_deliveries_response_status_chk CHECK (
    response_status_code IS NULL OR (response_status_code >= 100 AND response_status_code <= 599)
  ),
  CONSTRAINT webhook_deliveries_tenant_delivery_uq UNIQUE (tenant_id, webhook_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.webhook_retry_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  webhook_retry_state_id TEXT NOT NULL,
  webhook_delivery_id BIGINT NOT NULL REFERENCES platform.webhook_deliveries(id) ON DELETE CASCADE,
  retry_policy_key TEXT NOT NULL DEFAULT 'default',
  retry_status TEXT NOT NULL DEFAULT 'WAITING',
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 5,
  backoff_strategy TEXT NOT NULL DEFAULT 'EXPONENTIAL',
  backoff_seconds INTEGER NOT NULL DEFAULT 60,
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
  CONSTRAINT webhook_retry_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT webhook_retry_states_id_chk CHECK (length(trim(webhook_retry_state_id)) > 0),
  CONSTRAINT webhook_retry_states_policy_key_chk CHECK (length(trim(retry_policy_key)) > 0),
  CONSTRAINT webhook_retry_states_status_chk CHECK (
    retry_status IN ('WAITING', 'LOCKED', 'RETRYING', 'SUCCEEDED', 'FAILED', 'EXHAUSTED', 'CANCELED')
  ),
  CONSTRAINT webhook_retry_states_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT webhook_retry_states_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT webhook_retry_states_backoff_strategy_chk CHECK (
    backoff_strategy IN ('FIXED', 'LINEAR', 'EXPONENTIAL')
  ),
  CONSTRAINT webhook_retry_states_backoff_seconds_chk CHECK (backoff_seconds >= 0),
  CONSTRAINT webhook_retry_states_tenant_retry_uq UNIQUE (tenant_id, webhook_retry_state_id),
  CONSTRAINT webhook_retry_states_tenant_delivery_uq UNIQUE (tenant_id, webhook_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.webhook_dlq_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  webhook_dlq_state_id TEXT NOT NULL,
  webhook_delivery_id BIGINT NOT NULL REFERENCES platform.webhook_deliveries(id) ON DELETE CASCADE,
  dlq_reason TEXT NOT NULL,
  dlq_status TEXT NOT NULL DEFAULT 'OPEN',
  poison_message BOOLEAN NOT NULL DEFAULT false,
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
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT webhook_dlq_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT webhook_dlq_states_id_chk CHECK (length(trim(webhook_dlq_state_id)) > 0),
  CONSTRAINT webhook_dlq_states_reason_chk CHECK (length(trim(dlq_reason)) > 0),
  CONSTRAINT webhook_dlq_states_status_chk CHECK (
    dlq_status IN ('OPEN', 'REPLAY_REQUESTED', 'REPLAYED', 'ARCHIVED', 'IGNORED')
  ),
  CONSTRAINT webhook_dlq_states_failed_attempt_count_chk CHECK (failed_attempt_count >= 0),
  CONSTRAINT webhook_dlq_states_tenant_dlq_uq UNIQUE (tenant_id, webhook_dlq_state_id),
  CONSTRAINT webhook_dlq_states_tenant_delivery_uq UNIQUE (tenant_id, webhook_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.webhook_signature_metadata (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  webhook_signature_metadata_id TEXT NOT NULL,
  webhook_delivery_id BIGINT NOT NULL REFERENCES platform.webhook_deliveries(id) ON DELETE CASCADE,
  signature_version TEXT NOT NULL DEFAULT 'v1',
  signature_algorithm TEXT NOT NULL DEFAULT 'HMAC_SHA256',
  signature_header_name TEXT NOT NULL DEFAULT 'X-Pix2pi-Signature',
  timestamp_header_name TEXT NOT NULL DEFAULT 'X-Pix2pi-Timestamp',
  secret_ref TEXT NOT NULL,
  payload_hash TEXT NOT NULL,
  signature_hash TEXT NOT NULL,
  signing_status TEXT NOT NULL DEFAULT 'SIGNED',
  verification_status TEXT NOT NULL DEFAULT 'NOT_VERIFIED',
  signed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  verified_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT webhook_signature_metadata_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT webhook_signature_metadata_id_chk CHECK (length(trim(webhook_signature_metadata_id)) > 0),
  CONSTRAINT webhook_signature_metadata_secret_ref_chk CHECK (length(trim(secret_ref)) > 0),
  CONSTRAINT webhook_signature_metadata_payload_hash_chk CHECK (length(trim(payload_hash)) > 0),
  CONSTRAINT webhook_signature_metadata_signature_hash_chk CHECK (length(trim(signature_hash)) > 0),
  CONSTRAINT webhook_signature_metadata_algorithm_chk CHECK (
    signature_algorithm IN ('HMAC_SHA256', 'HMAC_SHA512')
  ),
  CONSTRAINT webhook_signature_metadata_signing_status_chk CHECK (
    signing_status IN ('PENDING', 'SIGNED', 'FAILED')
  ),
  CONSTRAINT webhook_signature_metadata_verification_status_chk CHECK (
    verification_status IN ('NOT_VERIFIED', 'VALID', 'INVALID', 'EXPIRED', 'FAILED')
  ),
  CONSTRAINT webhook_signature_metadata_tenant_signature_uq UNIQUE (tenant_id, webhook_signature_metadata_id),
  CONSTRAINT webhook_signature_metadata_tenant_delivery_uq UNIQUE (tenant_id, webhook_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.webhook_delivery_audit_events (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  webhook_delivery_audit_event_id TEXT NOT NULL,
  webhook_delivery_id BIGINT REFERENCES platform.webhook_deliveries(id) ON DELETE SET NULL,
  webhook_retry_state_id BIGINT REFERENCES platform.webhook_retry_states(id) ON DELETE SET NULL,
  webhook_dlq_state_id BIGINT REFERENCES platform.webhook_dlq_states(id) ON DELETE SET NULL,
  webhook_signature_metadata_id BIGINT REFERENCES platform.webhook_signature_metadata(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL DEFAULT 'AUDIT_ONLY',
  actor_type TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_ref TEXT,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  idempotency_key TEXT,
  status_before TEXT,
  status_after TEXT,
  audit_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT webhook_delivery_audit_events_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT webhook_delivery_audit_events_id_chk CHECK (length(trim(webhook_delivery_audit_event_id)) > 0),
  CONSTRAINT webhook_delivery_audit_events_event_type_chk CHECK (
    event_type IN (
      'WEBHOOK_DELIVERY_CREATED',
      'WEBHOOK_DELIVERY_SCHEDULED',
      'WEBHOOK_DELIVERY_ATTEMPTED',
      'WEBHOOK_DELIVERY_DELIVERED',
      'WEBHOOK_DELIVERY_FAILED',
      'WEBHOOK_DELIVERY_RETRY_SCHEDULED',
      'WEBHOOK_DELIVERY_RETRY_EXHAUSTED',
      'WEBHOOK_DELIVERY_DLQ_CREATED',
      'WEBHOOK_DELIVERY_REPLAY_REQUESTED',
      'WEBHOOK_DELIVERY_REPLAYED',
      'WEBHOOK_SIGNATURE_SIGNED',
      'WEBHOOK_SIGNATURE_VERIFIED',
      'WEBHOOK_DELIVERY_CANCELED'
    )
  ),
  CONSTRAINT webhook_delivery_audit_events_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'RETRY', 'DLQ', 'AUDIT_ONLY')
  ),
  CONSTRAINT webhook_delivery_audit_events_actor_type_chk CHECK (
    actor_type IN ('SYSTEM', 'SERVICE', 'WORKER', 'OPERATOR', 'USER')
  ),
  CONSTRAINT webhook_delivery_audit_events_tenant_event_uq UNIQUE (tenant_id, webhook_delivery_audit_event_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_deliveries_tenant_idempotency
  ON platform.webhook_deliveries (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_tenant_status
  ON platform.webhook_deliveries (tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_endpoint_status
  ON platform.webhook_deliveries (tenant_id, webhook_endpoint_id, status);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_event
  ON platform.webhook_deliveries (tenant_id, event_id, event_type);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_next_retry
  ON platform.webhook_deliveries (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_created_at
  ON platform.webhook_deliveries (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_correlation
  ON platform.webhook_deliveries (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_retry_states_tenant_status
  ON platform.webhook_retry_states (tenant_id, retry_status);

CREATE INDEX IF NOT EXISTS idx_webhook_retry_states_delivery
  ON platform.webhook_retry_states (tenant_id, webhook_delivery_id);

CREATE INDEX IF NOT EXISTS idx_webhook_retry_states_next_retry
  ON platform.webhook_retry_states (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_retry_states_locked
  ON platform.webhook_retry_states (locked_at)
  WHERE locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_retry_states_policy
  ON platform.webhook_retry_states (tenant_id, retry_policy_key);

CREATE INDEX IF NOT EXISTS idx_webhook_dlq_states_tenant_status
  ON platform.webhook_dlq_states (tenant_id, dlq_status);

CREATE INDEX IF NOT EXISTS idx_webhook_dlq_states_delivery
  ON platform.webhook_dlq_states (tenant_id, webhook_delivery_id);

CREATE INDEX IF NOT EXISTS idx_webhook_dlq_states_poison
  ON platform.webhook_dlq_states (tenant_id, poison_message)
  WHERE poison_message = true;

CREATE INDEX IF NOT EXISTS idx_webhook_dlq_states_replay_requested
  ON platform.webhook_dlq_states (tenant_id, replay_requested_at)
  WHERE replay_requested_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_dlq_states_created_at
  ON platform.webhook_dlq_states (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_signature_metadata_delivery
  ON platform.webhook_signature_metadata (tenant_id, webhook_delivery_id);

CREATE INDEX IF NOT EXISTS idx_webhook_signature_metadata_status
  ON platform.webhook_signature_metadata (tenant_id, signing_status, verification_status);

CREATE INDEX IF NOT EXISTS idx_webhook_signature_metadata_secret_ref
  ON platform.webhook_signature_metadata (tenant_id, secret_ref);

CREATE INDEX IF NOT EXISTS idx_webhook_signature_metadata_signed_at
  ON platform.webhook_signature_metadata (signed_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_tenant_created
  ON platform.webhook_delivery_audit_events (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_delivery
  ON platform.webhook_delivery_audit_events (tenant_id, webhook_delivery_id, created_at DESC)
  WHERE webhook_delivery_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_event_type
  ON platform.webhook_delivery_audit_events (tenant_id, event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_decision
  ON platform.webhook_delivery_audit_events (tenant_id, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_correlation
  ON platform.webhook_delivery_audit_events (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_audit_events_request_id
  ON platform.webhook_delivery_audit_events (tenant_id, request_id)
  WHERE request_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_webhook_deliveries_updated_at ON platform.webhook_deliveries;
CREATE TRIGGER trg_webhook_deliveries_updated_at
BEFORE UPDATE ON platform.webhook_deliveries
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_webhook_retry_states_updated_at ON platform.webhook_retry_states;
CREATE TRIGGER trg_webhook_retry_states_updated_at
BEFORE UPDATE ON platform.webhook_retry_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_webhook_dlq_states_updated_at ON platform.webhook_dlq_states;
CREATE TRIGGER trg_webhook_dlq_states_updated_at
BEFORE UPDATE ON platform.webhook_dlq_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_webhook_signature_metadata_updated_at ON platform.webhook_signature_metadata;
CREATE TRIGGER trg_webhook_signature_metadata_updated_at
BEFORE UPDATE ON platform.webhook_signature_metadata
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.webhook_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_retry_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_dlq_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_signature_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_delivery_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.webhook_deliveries FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_retry_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_dlq_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_signature_metadata FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.webhook_delivery_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS webhook_deliveries_tenant_isolation ON platform.webhook_deliveries;
CREATE POLICY webhook_deliveries_tenant_isolation
ON platform.webhook_deliveries
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

DROP POLICY IF EXISTS webhook_retry_states_tenant_isolation ON platform.webhook_retry_states;
CREATE POLICY webhook_retry_states_tenant_isolation
ON platform.webhook_retry_states
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

DROP POLICY IF EXISTS webhook_dlq_states_tenant_isolation ON platform.webhook_dlq_states;
CREATE POLICY webhook_dlq_states_tenant_isolation
ON platform.webhook_dlq_states
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

DROP POLICY IF EXISTS webhook_signature_metadata_tenant_isolation ON platform.webhook_signature_metadata;
CREATE POLICY webhook_signature_metadata_tenant_isolation
ON platform.webhook_signature_metadata
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

DROP POLICY IF EXISTS webhook_delivery_audit_events_tenant_isolation ON platform.webhook_delivery_audit_events;
CREATE POLICY webhook_delivery_audit_events_tenant_isolation
ON platform.webhook_delivery_audit_events
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

COMMENT ON TABLE platform.webhook_deliveries IS 'FAZ 2-6.6 webhook delivery persistence table.';
COMMENT ON TABLE platform.webhook_retry_states IS 'FAZ 2-6.6 webhook retry state persistence table.';
COMMENT ON TABLE platform.webhook_dlq_states IS 'FAZ 2-6.6 webhook DLQ state persistence table.';
COMMENT ON TABLE platform.webhook_signature_metadata IS 'FAZ 2-6.6 webhook signature metadata persistence table.';
COMMENT ON TABLE platform.webhook_delivery_audit_events IS 'FAZ 2-6.6 webhook delivery audit event persistence table.';

COMMIT;
