BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pix2pi_app') THEN
    CREATE ROLE pix2pi_app LOGIN PASSWORD 'pix2pi_app_2026_test';
  END IF;
END
$$;

ALTER ROLE pix2pi_app NOSUPERUSER NOBYPASSRLS NOCREATEROLE NOCREATEDB INHERIT;

GRANT USAGE ON SCHEMA runtime TO pix2pi_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA runtime TO pix2pi_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA runtime TO pix2pi_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA runtime TO pix2pi_app;
GRANT USAGE ON SCHEMA security TO pix2pi_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA security TO pix2pi_app;

INSERT INTO platform.tenants (id, business_code, name, slug)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'TENANT_A', 'Tenant A', 'tenant-a'),
  ('22222222-2222-2222-2222-222222222222', 'TENANT_B', 'Tenant B', 'tenant-b')
ON CONFLICT (id) DO NOTHING;

INSERT INTO runtime.notification_channels (
  id, tenant_id, business_code, channel_key, display_name, channel_type, visibility_scope, provider_key
)
VALUES
  ('66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'NTF_GLOBAL_EMAIL', 'global-email', 'Global Email Channel', 'email', 'global', 'smtp-global'),
  ('66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'NTF_TENANT_A_EMAIL', 'tenant-a-email', 'Tenant A Email Channel', 'email', 'tenant', 'smtp-tenant-a'),
  ('66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'NTF_TENANT_B_SMS', 'tenant-b-sms', 'Tenant B SMS Channel', 'sms', 'tenant', 'sms-tenant-b')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.notifications (
  id, tenant_id, channel_id, business_code, notification_key, notification_type, priority, status, title, body_text
)
VALUES
  ('77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'NTF_GLOBAL_1', 'notification-global-1', 'system_alert', 'high', 'sent', 'Global alert', 'global message'),
  ('77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'NTF_TENANT_A_1', 'notification-tenant-a-1', 'order_status', 'normal', 'queued', 'Tenant A order update', 'tenant a message'),
  ('77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'NTF_TENANT_B_1', 'notification-tenant-b-1', 'otp', 'high', 'queued', 'Tenant B otp', 'tenant b message')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.notification_recipients (
  id, tenant_id, notification_id, business_code, recipient_type, recipient_key, destination, delivery_status
)
VALUES
  ('88888888-cccc-cccc-cccc-ccccccccccc1', NULL, '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'NRC_GLOBAL_1', 'email', 'global-recipient-1', 'global@example.com', 'sent'),
  ('88888888-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'NRC_TENANT_A_1', 'email', 'tenant-a-recipient-1', 'a@example.com', 'pending'),
  ('88888888-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb3', 'NRC_TENANT_B_1', 'phone', 'tenant-b-recipient-1', '+905550000003', 'pending')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ notification channels visibility works'
         ELSE 'HATA ❌ notification channels visibility broken'
       END AS notification_channels_visibility_result
FROM runtime.notification_channels;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ notifications visibility works'
         ELSE 'HATA ❌ notifications visibility broken'
       END AS notifications_visibility_result
FROM runtime.notifications;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ notification recipients visibility works'
         ELSE 'HATA ❌ notification recipients visibility broken'
       END AS notification_recipients_visibility_result
FROM runtime.notification_recipients;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.notifications (
      tenant_id, channel_id, business_code, notification_key, notification_type, priority, status, title, body_text
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      '66666666-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
      'NTF_FORBIDDEN',
      'notification-forbidden',
      'otp',
      'high',
      'queued',
      'Forbidden tenant B notification',
      'should fail'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant notification insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant notification insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ notification channels super-admin visibility works'
         ELSE 'HATA ❌ notification channels super-admin visibility broken'
       END AS notification_channels_super_admin_result
FROM runtime.notification_channels;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ notifications super-admin visibility works'
         ELSE 'HATA ❌ notifications super-admin visibility broken'
       END AS notifications_super_admin_result
FROM runtime.notifications;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ notification recipients super-admin visibility works'
         ELSE 'HATA ❌ notification recipients super-admin visibility broken'
       END AS notification_recipients_super_admin_result
FROM runtime.notification_recipients;

ROLLBACK;
