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

CREATE TABLE IF NOT EXISTS platform.notifications (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  notification_id TEXT NOT NULL,
  notification_key TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  notification_status TEXT NOT NULL DEFAULT 'CREATED',
  priority INTEGER NOT NULL DEFAULT 100,
  subject_type TEXT NOT NULL,
  subject_ref TEXT NOT NULL,
  recipient_type TEXT NOT NULL,
  recipient_ref TEXT NOT NULL,
  recipient_display_name TEXT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  template_key TEXT,
  locale TEXT NOT NULL DEFAULT 'tr-TR',
  channels TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  dedupe_key TEXT,
  idempotency_key TEXT,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  scheduled_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  queued_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  CONSTRAINT notifications_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT notifications_id_chk CHECK (length(trim(notification_id)) > 0),
  CONSTRAINT notifications_key_chk CHECK (length(trim(notification_key)) > 0),
  CONSTRAINT notifications_type_chk CHECK (
    notification_type IN ('SYSTEM', 'SECURITY', 'BILLING', 'WORKFLOW', 'WEBHOOK', 'JOB', 'ERP', 'MARKETING', 'SUPPORT')
  ),
  CONSTRAINT notifications_status_chk CHECK (
    notification_status IN ('CREATED', 'QUEUED', 'PARTIAL_SENT', 'SENT', 'FAILED', 'CANCELED', 'EXPIRED')
  ),
  CONSTRAINT notifications_priority_chk CHECK (priority >= 0),
  CONSTRAINT notifications_subject_type_chk CHECK (
    subject_type IN ('TENANT', 'USER', 'APP', 'SERVICE', 'WORKFLOW', 'JOB', 'WEBHOOK', 'PLUGIN', 'SYSTEM')
  ),
  CONSTRAINT notifications_recipient_type_chk CHECK (
    recipient_type IN ('USER', 'ROLE', 'GROUP', 'TENANT', 'EMAIL', 'PHONE', 'DEVICE', 'SYSTEM')
  ),
  CONSTRAINT notifications_subject_ref_chk CHECK (length(trim(subject_ref)) > 0),
  CONSTRAINT notifications_recipient_ref_chk CHECK (length(trim(recipient_ref)) > 0),
  CONSTRAINT notifications_title_chk CHECK (length(trim(title)) > 0),
  CONSTRAINT notifications_body_chk CHECK (length(trim(body)) > 0),
  CONSTRAINT notifications_expiry_chk CHECK (
    expires_at IS NULL OR scheduled_at IS NULL OR expires_at > scheduled_at
  ),
  CONSTRAINT notifications_tenant_notification_uq UNIQUE (tenant_id, notification_id),
  CONSTRAINT notifications_tenant_key_uq UNIQUE (tenant_id, notification_key)
);

CREATE TABLE IF NOT EXISTS platform.notification_channel_deliveries (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  notification_channel_delivery_id TEXT NOT NULL,
  notification_row_id BIGINT NOT NULL REFERENCES platform.notifications(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  channel TEXT NOT NULL,
  provider_key TEXT,
  provider_message_id TEXT,
  delivery_status TEXT NOT NULL DEFAULT 'PENDING',
  endpoint_ref TEXT,
  destination TEXT NOT NULL,
  subject TEXT,
  content_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  provider_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempt_count INTEGER NOT NULL DEFAULT 3,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  next_retry_at TIMESTAMPTZ,
  last_attempt_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  idempotency_key TEXT,
  request_id TEXT,
  correlation_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT NOT NULL DEFAULT 'system',
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT notification_channel_deliveries_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT notification_channel_deliveries_id_chk CHECK (length(trim(notification_channel_delivery_id)) > 0),
  CONSTRAINT notification_channel_deliveries_notification_id_chk CHECK (length(trim(notification_id)) > 0),
  CONSTRAINT notification_channel_deliveries_channel_chk CHECK (
    channel IN ('EMAIL', 'SMS', 'PUSH', 'IN_APP', 'WEBHOOK')
  ),
  CONSTRAINT notification_channel_deliveries_status_chk CHECK (
    delivery_status IN ('PENDING', 'SCHEDULED', 'SENDING', 'SENT', 'DELIVERED', 'RETRY_WAITING', 'FAILED', 'CANCELED')
  ),
  CONSTRAINT notification_channel_deliveries_destination_chk CHECK (length(trim(destination)) > 0),
  CONSTRAINT notification_channel_deliveries_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT notification_channel_deliveries_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT notification_channel_deliveries_tenant_delivery_uq UNIQUE (tenant_id, notification_channel_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.notification_channel_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  notification_channel_state_id TEXT NOT NULL,
  notification_row_id BIGINT NOT NULL REFERENCES platform.notifications(id) ON DELETE CASCADE,
  notification_channel_delivery_id BIGINT REFERENCES platform.notification_channel_deliveries(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  channel TEXT NOT NULL,
  state_status TEXT NOT NULL DEFAULT 'PENDING',
  email_state TEXT,
  sms_state TEXT,
  push_state TEXT,
  in_app_state TEXT,
  webhook_state TEXT,
  provider_key TEXT,
  provider_ref TEXT,
  recipient_ref TEXT NOT NULL,
  destination_hash TEXT,
  last_provider_status TEXT,
  last_provider_status_at TIMESTAMPTZ,
  state_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT notification_channel_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT notification_channel_states_id_chk CHECK (length(trim(notification_channel_state_id)) > 0),
  CONSTRAINT notification_channel_states_notification_id_chk CHECK (length(trim(notification_id)) > 0),
  CONSTRAINT notification_channel_states_recipient_ref_chk CHECK (length(trim(recipient_ref)) > 0),
  CONSTRAINT notification_channel_states_channel_chk CHECK (
    channel IN ('EMAIL', 'SMS', 'PUSH', 'IN_APP', 'WEBHOOK')
  ),
  CONSTRAINT notification_channel_states_status_chk CHECK (
    state_status IN ('PENDING', 'ACTIVE', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED', 'OPENED', 'CLICKED', 'CANCELED')
  ),
  CONSTRAINT notification_channel_states_email_state_chk CHECK (
    email_state IS NULL OR email_state IN ('PENDING', 'SENT', 'DELIVERED', 'BOUNCED', 'OPENED', 'CLICKED', 'FAILED')
  ),
  CONSTRAINT notification_channel_states_sms_state_chk CHECK (
    sms_state IS NULL OR sms_state IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'UNDELIVERED')
  ),
  CONSTRAINT notification_channel_states_push_state_chk CHECK (
    push_state IS NULL OR push_state IN ('PENDING', 'SENT', 'DELIVERED', 'OPENED', 'FAILED')
  ),
  CONSTRAINT notification_channel_states_tenant_state_uq UNIQUE (tenant_id, notification_channel_state_id),
  CONSTRAINT notification_channel_states_tenant_channel_uq UNIQUE (tenant_id, notification_id, channel, recipient_ref)
);

CREATE TABLE IF NOT EXISTS platform.notification_retry_states (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  notification_retry_state_id TEXT NOT NULL,
  notification_row_id BIGINT NOT NULL REFERENCES platform.notifications(id) ON DELETE CASCADE,
  notification_channel_delivery_id BIGINT REFERENCES platform.notification_channel_deliveries(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  channel TEXT NOT NULL,
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
  CONSTRAINT notification_retry_states_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT notification_retry_states_id_chk CHECK (length(trim(notification_retry_state_id)) > 0),
  CONSTRAINT notification_retry_states_notification_id_chk CHECK (length(trim(notification_id)) > 0),
  CONSTRAINT notification_retry_states_channel_chk CHECK (
    channel IN ('EMAIL', 'SMS', 'PUSH', 'IN_APP', 'WEBHOOK')
  ),
  CONSTRAINT notification_retry_states_policy_key_chk CHECK (length(trim(retry_policy_key)) > 0),
  CONSTRAINT notification_retry_states_status_chk CHECK (
    retry_status IN ('WAITING', 'LOCKED', 'RETRYING', 'SUCCEEDED', 'FAILED', 'EXHAUSTED', 'CANCELED')
  ),
  CONSTRAINT notification_retry_states_attempt_count_chk CHECK (attempt_count >= 0),
  CONSTRAINT notification_retry_states_max_attempt_count_chk CHECK (max_attempt_count >= 0),
  CONSTRAINT notification_retry_states_backoff_strategy_chk CHECK (
    backoff_strategy IN ('FIXED', 'LINEAR', 'EXPONENTIAL')
  ),
  CONSTRAINT notification_retry_states_backoff_seconds_chk CHECK (backoff_seconds >= 0),
  CONSTRAINT notification_retry_states_jitter_seconds_chk CHECK (jitter_seconds >= 0),
  CONSTRAINT notification_retry_states_tenant_retry_uq UNIQUE (tenant_id, notification_retry_state_id),
  CONSTRAINT notification_retry_states_tenant_delivery_uq UNIQUE (tenant_id, notification_channel_delivery_id)
);

CREATE TABLE IF NOT EXISTS platform.notification_delivery_audit_events (
  id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  notification_delivery_audit_event_id TEXT NOT NULL,
  notification_row_id BIGINT REFERENCES platform.notifications(id) ON DELETE SET NULL,
  notification_channel_delivery_id BIGINT REFERENCES platform.notification_channel_deliveries(id) ON DELETE SET NULL,
  notification_channel_state_id BIGINT REFERENCES platform.notification_channel_states(id) ON DELETE SET NULL,
  notification_retry_state_id BIGINT REFERENCES platform.notification_retry_states(id) ON DELETE SET NULL,
  notification_id TEXT,
  channel TEXT,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL DEFAULT 'AUDIT_ONLY',
  actor_type TEXT NOT NULL DEFAULT 'SYSTEM',
  actor_ref TEXT,
  status_before TEXT,
  status_after TEXT,
  provider_key TEXT,
  provider_message_id TEXT,
  request_id TEXT,
  correlation_id TEXT,
  causation_id TEXT,
  idempotency_key TEXT,
  audit_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT notification_delivery_audit_events_tenant_id_chk CHECK (length(trim(tenant_id)) > 0),
  CONSTRAINT notification_delivery_audit_events_id_chk CHECK (length(trim(notification_delivery_audit_event_id)) > 0),
  CONSTRAINT notification_delivery_audit_events_channel_chk CHECK (
    channel IS NULL OR channel IN ('EMAIL', 'SMS', 'PUSH', 'IN_APP', 'WEBHOOK')
  ),
  CONSTRAINT notification_delivery_audit_events_event_type_chk CHECK (
    event_type IN (
      'NOTIFICATION_CREATED',
      'NOTIFICATION_QUEUED',
      'NOTIFICATION_SENT',
      'NOTIFICATION_FAILED',
      'NOTIFICATION_CANCELED',
      'CHANNEL_DELIVERY_CREATED',
      'CHANNEL_DELIVERY_SCHEDULED',
      'CHANNEL_DELIVERY_SENT',
      'CHANNEL_DELIVERY_DELIVERED',
      'CHANNEL_DELIVERY_FAILED',
      'CHANNEL_RETRY_SCHEDULED',
      'CHANNEL_RETRY_EXHAUSTED',
      'EMAIL_STATE_UPDATED',
      'SMS_STATE_UPDATED',
      'PUSH_STATE_UPDATED',
      'IN_APP_STATE_UPDATED',
      'WEBHOOK_STATE_UPDATED'
    )
  ),
  CONSTRAINT notification_delivery_audit_events_decision_chk CHECK (
    decision IN ('ALLOW', 'DENY', 'RETRY', 'AUDIT_ONLY')
  ),
  CONSTRAINT notification_delivery_audit_events_actor_type_chk CHECK (
    actor_type IN ('SYSTEM', 'SERVICE', 'WORKER', 'OPERATOR', 'USER')
  ),
  CONSTRAINT notification_delivery_audit_events_tenant_event_uq UNIQUE (tenant_id, notification_delivery_audit_event_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_tenant_idempotency
  ON platform.notifications (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_tenant_dedupe
  ON platform.notifications (tenant_id, dedupe_key)
  WHERE dedupe_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_tenant_status
  ON platform.notifications (tenant_id, notification_status);

CREATE INDEX IF NOT EXISTS idx_notifications_type_status
  ON platform.notifications (tenant_id, notification_type, notification_status);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient
  ON platform.notifications (tenant_id, recipient_type, recipient_ref);

CREATE INDEX IF NOT EXISTS idx_notifications_subject
  ON platform.notifications (tenant_id, subject_type, subject_ref);

CREATE INDEX IF NOT EXISTS idx_notifications_scheduled
  ON platform.notifications (tenant_id, scheduled_at)
  WHERE scheduled_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_expires
  ON platform.notifications (expires_at)
  WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_correlation
  ON platform.notifications (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_notification
  ON platform.notification_channel_deliveries (tenant_id, notification_row_id);

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_channel_status
  ON platform.notification_channel_deliveries (tenant_id, channel, delivery_status);

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_provider
  ON platform.notification_channel_deliveries (tenant_id, provider_key, provider_message_id)
  WHERE provider_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_next_retry
  ON platform.notification_channel_deliveries (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_scheduled
  ON platform.notification_channel_deliveries (scheduled_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_channel_deliveries_tenant_idempotency
  ON platform.notification_channel_deliveries (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_deliveries_correlation
  ON platform.notification_channel_deliveries (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_states_notification
  ON platform.notification_channel_states (tenant_id, notification_row_id);

CREATE INDEX IF NOT EXISTS idx_notification_channel_states_delivery
  ON platform.notification_channel_states (tenant_id, notification_channel_delivery_id)
  WHERE notification_channel_delivery_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_states_channel_status
  ON platform.notification_channel_states (tenant_id, channel, state_status);

CREATE INDEX IF NOT EXISTS idx_notification_channel_states_provider_ref
  ON platform.notification_channel_states (tenant_id, provider_key, provider_ref)
  WHERE provider_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_channel_states_last_provider_status
  ON platform.notification_channel_states (last_provider_status_at DESC)
  WHERE last_provider_status_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_tenant_status
  ON platform.notification_retry_states (tenant_id, retry_status);

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_notification
  ON platform.notification_retry_states (tenant_id, notification_row_id);

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_delivery
  ON platform.notification_retry_states (tenant_id, notification_channel_delivery_id)
  WHERE notification_channel_delivery_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_next_retry
  ON platform.notification_retry_states (tenant_id, next_retry_at)
  WHERE next_retry_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_locked
  ON platform.notification_retry_states (locked_at)
  WHERE locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_retry_states_policy
  ON platform.notification_retry_states (tenant_id, retry_policy_key);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_tenant_created
  ON platform.notification_delivery_audit_events (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_notification
  ON platform.notification_delivery_audit_events (tenant_id, notification_row_id, created_at DESC)
  WHERE notification_row_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_delivery
  ON platform.notification_delivery_audit_events (tenant_id, notification_channel_delivery_id, created_at DESC)
  WHERE notification_channel_delivery_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_event_type
  ON platform.notification_delivery_audit_events (tenant_id, event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_decision
  ON platform.notification_delivery_audit_events (tenant_id, decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_correlation
  ON platform.notification_delivery_audit_events (tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notification_delivery_audit_events_request_id
  ON platform.notification_delivery_audit_events (tenant_id, request_id)
  WHERE request_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_notifications_updated_at ON platform.notifications;
CREATE TRIGGER trg_notifications_updated_at
BEFORE UPDATE ON platform.notifications
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_notification_channel_deliveries_updated_at ON platform.notification_channel_deliveries;
CREATE TRIGGER trg_notification_channel_deliveries_updated_at
BEFORE UPDATE ON platform.notification_channel_deliveries
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_notification_channel_states_updated_at ON platform.notification_channel_states;
CREATE TRIGGER trg_notification_channel_states_updated_at
BEFORE UPDATE ON platform.notification_channel_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

DROP TRIGGER IF EXISTS trg_notification_retry_states_updated_at ON platform.notification_retry_states;
CREATE TRIGGER trg_notification_retry_states_updated_at
BEFORE UPDATE ON platform.notification_retry_states
FOR EACH ROW
EXECUTE FUNCTION platform.set_updated_at();

ALTER TABLE platform.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_channel_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_channel_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_retry_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_delivery_audit_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE platform.notifications FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_channel_deliveries FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_channel_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_retry_states FORCE ROW LEVEL SECURITY;
ALTER TABLE platform.notification_delivery_audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_tenant_isolation ON platform.notifications;
CREATE POLICY notifications_tenant_isolation
ON platform.notifications
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

DROP POLICY IF EXISTS notification_channel_deliveries_tenant_isolation ON platform.notification_channel_deliveries;
CREATE POLICY notification_channel_deliveries_tenant_isolation
ON platform.notification_channel_deliveries
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

DROP POLICY IF EXISTS notification_channel_states_tenant_isolation ON platform.notification_channel_states;
CREATE POLICY notification_channel_states_tenant_isolation
ON platform.notification_channel_states
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

DROP POLICY IF EXISTS notification_retry_states_tenant_isolation ON platform.notification_retry_states;
CREATE POLICY notification_retry_states_tenant_isolation
ON platform.notification_retry_states
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

DROP POLICY IF EXISTS notification_delivery_audit_events_tenant_isolation ON platform.notification_delivery_audit_events;
CREATE POLICY notification_delivery_audit_events_tenant_isolation
ON platform.notification_delivery_audit_events
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

COMMENT ON TABLE platform.notifications IS 'FAZ 2-6.5 notification persistence table.';
COMMENT ON TABLE platform.notification_channel_deliveries IS 'FAZ 2-6.5 notification channel delivery persistence table.';
COMMENT ON TABLE platform.notification_channel_states IS 'FAZ 2-6.5 email/SMS/push/in-app/webhook channel state persistence table.';
COMMENT ON TABLE platform.notification_retry_states IS 'FAZ 2-6.5 notification retry state persistence table.';
COMMENT ON TABLE platform.notification_delivery_audit_events IS 'FAZ 2-6.5 notification delivery audit event persistence table.';

COMMIT;
