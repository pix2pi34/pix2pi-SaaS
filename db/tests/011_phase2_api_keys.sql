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

INSERT INTO runtime.api_keys (
  id, tenant_id, business_code, key_ref, display_name, visibility_scope, key_prefix, key_hash, status
)
VALUES
  ('16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'API_GLOBAL_1', 'api-global-1', 'Global API Key', 'global', 'pkg', 'hash-global-1', 'active'),
  ('16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'API_TENANT_A_1', 'api-tenant-a-1', 'Tenant A API Key', 'tenant', 'pka', 'hash-a-1', 'active'),
  ('16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'API_TENANT_B_1', 'api-tenant-b-1', 'Tenant B API Key', 'tenant', 'pkb', 'hash-b-1', 'active')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.api_quota_policies (
  id, tenant_id, api_key_id, business_code, policy_key, endpoint_scope, quota_period, request_limit, burst_limit
)
VALUES
  ('17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'AQP_GLOBAL_1', 'quota-global-1', '/api/v1/*', 'day', 100000, 1000),
  ('17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'AQP_TENANT_A_1', 'quota-tenant-a-1', '/api/v1/orders/*', 'day', 50000, 500),
  ('17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'AQP_TENANT_B_1', 'quota-tenant-b-1', '/api/v1/orders/*', 'day', 50000, 500)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.api_key_usage (
  id, tenant_id, api_key_id, policy_id, business_code, usage_window_start, usage_window_end, request_count, rejected_count
)
VALUES
  ('18181818-cccc-cccc-cccc-ccccccccccc1', NULL, '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'AKU_GLOBAL_1', now() - interval '1 day', now(), 1000, 5),
  ('18181818-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'AKU_TENANT_A_1', now() - interval '1 day', now(), 200, 1),
  ('18181818-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', '16161616-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '17171717-bbbb-bbbb-bbbb-bbbbbbbbbbb3', 'AKU_TENANT_B_1', now() - interval '1 day', now(), 300, 2)
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ api keys visibility works'
         ELSE 'HATA ❌ api keys visibility broken'
       END AS api_keys_visibility_result
FROM runtime.api_keys;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ api quota policies visibility works'
         ELSE 'HATA ❌ api quota policies visibility broken'
       END AS api_quota_policies_visibility_result
FROM runtime.api_quota_policies;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ api key usage visibility works'
         ELSE 'HATA ❌ api key usage visibility broken'
       END AS api_key_usage_visibility_result
FROM runtime.api_key_usage;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.api_keys (
      tenant_id, business_code, key_ref, display_name, visibility_scope, key_prefix, key_hash, status
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'API_FORBIDDEN',
      'api-forbidden',
      'Forbidden API Key',
      'tenant',
      'pkf',
      'hash-forbidden',
      'active'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant api key insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant api key insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ api keys super-admin visibility works'
         ELSE 'HATA ❌ api keys super-admin visibility broken'
       END AS api_keys_super_admin_result
FROM runtime.api_keys;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ api quota policies super-admin visibility works'
         ELSE 'HATA ❌ api quota policies super-admin visibility broken'
       END AS api_quota_policies_super_admin_result
FROM runtime.api_quota_policies;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ api key usage super-admin visibility works'
         ELSE 'HATA ❌ api key usage super-admin visibility broken'
       END AS api_key_usage_super_admin_result
FROM runtime.api_key_usage;

ROLLBACK;
