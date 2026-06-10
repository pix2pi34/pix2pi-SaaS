BEGIN;

CREATE SCHEMA IF NOT EXISTS runtime;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'runtime' AND t.typname = 'notification_channel_type_enum'
  ) THEN
    CREATE TYPE runtime.notification_channel_type_enum AS ENUM (
      'email',
      'sms',
      'push',
      'in_app'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'notification_status_enum'
  ) THEN
    CREATE TYPE runtime.notification_status_enum AS ENUM (
      'queued',
      'processing',
      'sent',
      'partially_sent',
      'failed',
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
    WHERE n.nspname = 'runtime' AND t.typname = 'notification_recipient_type_enum'
  ) THEN
    CREATE TYPE runtime.notification_recipient_type_enum AS ENUM (
      'user',
      'email',
      'phone',
      'device',
      'topic'
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
    WHERE n.nspname = 'runtime' AND t.typname = 'notification_recipient_status_enum'
  ) THEN
    CREATE TYPE runtime.notification_recipient_status_enum AS ENUM (
      'pending',
      'sent',
      'failed',
      'skipped'
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

CREATE TABLE IF NOT EXISTS runtime.notification_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  channel_key text NOT NULL,
  display_name text NOT NULL,
  channel_type runtime.notification_channel_type_enum NOT NULL,
  visibility_scope runtime.registry_visibility_scope_enum NOT NULL DEFAULT 'tenant',
  provider_key text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (channel_key ~ '^[a-z0-9][a-z0-9._-]*$'),
  CHECK (display_name <> ''),
  CHECK (provider_key <> ''),
  CHECK (
    (visibility_scope = 'global' AND tenant_id IS NULL)
    OR
    (visibility_scope <> 'global' AND tenant_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_channels_tenant_channel_key
ON runtime.notification_channels (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  channel_key
);

CREATE INDEX IF NOT EXISTS ix_notification_channels_tenant_id
ON runtime.notification_channels (tenant_id);

CREATE INDEX IF NOT EXISTS ix_notification_channels_type
ON runtime.notification_channels (channel_type);

CREATE TABLE IF NOT EXISTS runtime.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES runtime.notification_channels(id) ON DELETE RESTRICT,
  business_code text NOT NULL,
  notification_key text NOT NULL,
  notification_type text NOT NULL,
  priority runtime.job_priority_enum NOT NULL DEFAULT 'normal',
  status runtime.notification_status_enum NOT NULL DEFAULT 'queued',
  title text NOT NULL,
  body_text text NOT NULL DEFAULT '',
  body_html text NOT NULL DEFAULT '',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_ref_type text,
  source_ref_id text,
  scheduled_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (notification_key ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]*$'),
  CHECK (notification_type <> ''),
  CHECK (title <> ''),
  CHECK (sent_at IS NULL OR sent_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_tenant_notification_key
ON runtime.notifications (
  coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
  notification_key
);

CREATE INDEX IF NOT EXISTS ix_notifications_tenant_id
ON runtime.notifications (tenant_id);

CREATE INDEX IF NOT EXISTS ix_notifications_channel_id
ON runtime.notifications (channel_id);

CREATE INDEX IF NOT EXISTS ix_notifications_status
ON runtime.notifications (status);

CREATE INDEX IF NOT EXISTS ix_notifications_scheduled_at
ON runtime.notifications (scheduled_at);

CREATE TABLE IF NOT EXISTS runtime.notification_recipients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES platform.tenants(id) ON DELETE CASCADE,
  notification_id uuid NOT NULL REFERENCES runtime.notifications(id) ON DELETE CASCADE,
  business_code text NOT NULL,
  recipient_type runtime.notification_recipient_type_enum NOT NULL,
  recipient_key text NOT NULL,
  destination text NOT NULL,
  delivery_status runtime.notification_recipient_status_enum NOT NULL DEFAULT 'pending',
  error_message text,
  delivered_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (business_code <> ''),
  CHECK (recipient_key <> ''),
  CHECK (destination <> ''),
  CHECK (delivered_at IS NULL OR delivered_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_recipients_notification_recipient
ON runtime.notification_recipients (
  notification_id,
  recipient_key,
  destination
);

CREATE INDEX IF NOT EXISTS ix_notification_recipients_tenant_id
ON runtime.notification_recipients (tenant_id);

CREATE INDEX IF NOT EXISTS ix_notification_recipients_notification_id
ON runtime.notification_recipients (notification_id);

CREATE INDEX IF NOT EXISTS ix_notification_recipients_delivery_status
ON runtime.notification_recipients (delivery_status);

DROP TRIGGER IF EXISTS trg_notification_channels_touch_updated_at
ON runtime.notification_channels;

CREATE TRIGGER trg_notification_channels_touch_updated_at
BEFORE UPDATE ON runtime.notification_channels
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_notifications_touch_updated_at
ON runtime.notifications;

CREATE TRIGGER trg_notifications_touch_updated_at
BEFORE UPDATE ON runtime.notifications
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

DROP TRIGGER IF EXISTS trg_notification_recipients_touch_updated_at
ON runtime.notification_recipients;

CREATE TRIGGER trg_notification_recipients_touch_updated_at
BEFORE UPDATE ON runtime.notification_recipients
FOR EACH ROW
EXECUTE FUNCTION runtime.touch_updated_at();

ALTER TABLE runtime.notification_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.notification_channels FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.notifications FORCE ROW LEVEL SECURITY;

ALTER TABLE runtime.notification_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE runtime.notification_recipients FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS p_notification_channels_select ON runtime.notification_channels;
CREATE POLICY p_notification_channels_select
ON runtime.notification_channels
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_notification_channels_insert ON runtime.notification_channels;
CREATE POLICY p_notification_channels_insert
ON runtime.notification_channels
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notification_channels_update ON runtime.notification_channels;
CREATE POLICY p_notification_channels_update
ON runtime.notification_channels
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notification_channels_delete ON runtime.notification_channels;
CREATE POLICY p_notification_channels_delete
ON runtime.notification_channels
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notifications_select ON runtime.notifications;
CREATE POLICY p_notifications_select
ON runtime.notifications
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_notifications_insert ON runtime.notifications;
CREATE POLICY p_notifications_insert
ON runtime.notifications
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notifications_update ON runtime.notifications;
CREATE POLICY p_notifications_update
ON runtime.notifications
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notifications_delete ON runtime.notifications;
CREATE POLICY p_notifications_delete
ON runtime.notifications
FOR DELETE
USING (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notification_recipients_select ON runtime.notification_recipients;
CREATE POLICY p_notification_recipients_select
ON runtime.notification_recipients
FOR SELECT
USING (security.tenant_or_global_row_visible(tenant_id));

DROP POLICY IF EXISTS p_notification_recipients_insert ON runtime.notification_recipients;
CREATE POLICY p_notification_recipients_insert
ON runtime.notification_recipients
FOR INSERT
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notification_recipients_update ON runtime.notification_recipients;
CREATE POLICY p_notification_recipients_update
ON runtime.notification_recipients
FOR UPDATE
USING (security.tenant_only_row_mutable(tenant_id))
WITH CHECK (security.tenant_only_row_mutable(tenant_id));

DROP POLICY IF EXISTS p_notification_recipients_delete ON runtime.notification_recipients;
CREATE POLICY p_notification_recipients_delete
ON runtime.notification_recipients
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
