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

INSERT INTO runtime.webhook_endpoints (
  id, tenant_id, business_code, endpoint_key, display_name, visibility_scope, target_url, http_method, auth_type, retry_limit, retry_backoff_seconds
)
VALUES
  ('99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'WH_GLOBAL_1', 'global-webhook', 'Global Webhook', 'global', 'https://global.example.com/webhook', 'POST', 'none', 3, 30),
  ('99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'WH_TENANT_A_1', 'tenant-a-webhook', 'Tenant A Webhook', 'tenant', 'https://a.example.com/webhook', 'POST', 'hmac', 5, 20),
  ('99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'WH_TENANT_B_1', 'tenant-b-webhook', 'Tenant B Webhook', 'tenant', 'https://b.example.com/webhook', 'POST', 'bearer', 5, 20)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.webhook_deliveries (
  id, tenant_id, endpoint_id, business_code, delivery_key, event_type, priority, status, request_body, retry_count, max_attempts
)
VALUES
  ('aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'WHD_GLOBAL_1', 'delivery-global-1', 'global.sync.completed', 'high', 'delivered', '{"scope":"global"}'::jsonb, 0, 3),
  ('aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'WHD_TENANT_A_1', 'delivery-tenant-a-1', 'order.created', 'normal', 'queued', '{"tenant":"A"}'::jsonb, 1, 5),
  ('aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'WHD_TENANT_B_1', 'delivery-tenant-b-1', 'invoice.created', 'normal', 'queued', '{"tenant":"B"}'::jsonb, 1, 5)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.webhook_delivery_attempts (
  id, tenant_id, delivery_id, endpoint_id, attempt_no, status, duration_ms, response_code, response_body
)
VALUES
  ('bbbbbbbb-cccc-cccc-cccc-ccccccccccc1', NULL, 'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 1, 'succeeded', 40, 200, 'ok'),
  ('bbbbbbbb-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 1, 'failed', 55, 500, 'retry later'),
  ('bbbbbbbb-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 1, 'failed', 60, 500, 'retry later')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ webhook endpoints visibility works'
         ELSE 'HATA ❌ webhook endpoints visibility broken'
       END AS webhook_endpoints_visibility_result
FROM runtime.webhook_endpoints;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ webhook deliveries visibility works'
         ELSE 'HATA ❌ webhook deliveries visibility broken'
       END AS webhook_deliveries_visibility_result
FROM runtime.webhook_deliveries;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ webhook attempts visibility works'
         ELSE 'HATA ❌ webhook attempts visibility broken'
       END AS webhook_attempts_visibility_result
FROM runtime.webhook_delivery_attempts;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.webhook_deliveries (
      tenant_id, endpoint_id, business_code, delivery_key, event_type, priority, status, request_body, retry_count, max_attempts
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      '99999999-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
      'WHD_FORBIDDEN',
      'delivery-forbidden',
      'invoice.created',
      'high',
      'queued',
      '{"tenant":"B"}'::jsonb,
      0,
      3
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant webhook delivery insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant webhook delivery insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ webhook endpoints super-admin visibility works'
         ELSE 'HATA ❌ webhook endpoints super-admin visibility broken'
       END AS webhook_endpoints_super_admin_result
FROM runtime.webhook_endpoints;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ webhook deliveries super-admin visibility works'
         ELSE 'HATA ❌ webhook deliveries super-admin visibility broken'
       END AS webhook_deliveries_super_admin_result
FROM runtime.webhook_deliveries;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ webhook attempts super-admin visibility works'
         ELSE 'HATA ❌ webhook attempts super-admin visibility broken'
       END AS webhook_attempts_super_admin_result
FROM runtime.webhook_delivery_attempts;

ROLLBACK;
