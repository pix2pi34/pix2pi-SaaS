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

INSERT INTO runtime.idempotency_keys (
  id, tenant_id, business_code, scope_key, idempotency_key, request_fingerprint, status, response_code, resource_type, resource_id
)
VALUES
  ('44444444-dddd-dddd-dddd-ddddddddddd1', NULL, 'IDEMP_GLOBAL_1', 'api.global.sync', 'idem-global-1', 'fp-global-1', 'completed', 200, 'sync_run', 'sync-1'),
  ('44444444-dddd-dddd-dddd-ddddddddddd2', '11111111-1111-1111-1111-111111111111', 'IDEMP_TENANT_A_1', 'api.order.create', 'idem-tenant-a-1', 'fp-a-1', 'completed', 201, 'sales_order', 'so-a-1'),
  ('44444444-dddd-dddd-dddd-ddddddddddd3', '22222222-2222-2222-2222-222222222222', 'IDEMP_TENANT_B_1', 'api.order.create', 'idem-tenant-b-1', 'fp-b-1', 'completed', 201, 'sales_order', 'so-b-1')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.dedupe_records (
  id, tenant_id, business_code, dedupe_scope, dedupe_key, dedupe_hash, status, owner_ref
)
VALUES
  ('55555555-eeee-eeee-eeee-eeeeeeeeeee1', NULL, 'DEDUPE_GLOBAL_1', 'event.global.sync', 'dedupe-global-1', 'hash-global-1', 'active', 'global-sync'),
  ('55555555-eeee-eeee-eeee-eeeeeeeeeee2', '11111111-1111-1111-1111-111111111111', 'DEDUPE_TENANT_A_1', 'job.email.send', 'dedupe-a-1', 'hash-a-1', 'active', 'worker-a'),
  ('55555555-eeee-eeee-eeee-eeeeeeeeeee3', '22222222-2222-2222-2222-222222222222', 'DEDUPE_TENANT_B_1', 'job.export.run', 'dedupe-b-1', 'hash-b-1', 'active', 'worker-b')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ idempotency visibility works'
         ELSE 'HATA ❌ idempotency visibility broken'
       END AS idempotency_visibility_result
FROM runtime.idempotency_keys;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ dedupe visibility works'
         ELSE 'HATA ❌ dedupe visibility broken'
       END AS dedupe_visibility_result
FROM runtime.dedupe_records;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.idempotency_keys (
      tenant_id, business_code, scope_key, idempotency_key, request_fingerprint, status, response_code, resource_type, resource_id
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'IDEMP_FORBIDDEN',
      'api.order.create',
      'idem-forbidden',
      'fp-forbidden',
      'reserved',
      202,
      'sales_order',
      'so-forbidden'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant idempotency insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant idempotency insert blocked';
  END;
END;
$$;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.dedupe_records (
      tenant_id, business_code, dedupe_scope, dedupe_key, dedupe_hash, status, owner_ref
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'DEDUPE_FORBIDDEN',
      'job.export.run',
      'dedupe-forbidden',
      'hash-forbidden',
      'active',
      'worker-forbidden'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant dedupe insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant dedupe insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ idempotency super-admin visibility works'
         ELSE 'HATA ❌ idempotency super-admin visibility broken'
       END AS idempotency_super_admin_result
FROM runtime.idempotency_keys;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ dedupe super-admin visibility works'
         ELSE 'HATA ❌ dedupe super-admin visibility broken'
       END AS dedupe_super_admin_result
FROM runtime.dedupe_records;

ROLLBACK;
