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

INSERT INTO runtime.service_registry_services (
  id, tenant_id, business_code, service_key, display_name, service_kind, visibility_scope, protocol, base_path, health_path, default_port, owner_team
)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'SRV_GLOBAL_GATEWAY', 'gateway-public', 'Gateway Public', 'gateway', 'global', 'https', '/', '/health', 9010, 'platform'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'SRV_TENANT_A_IDENTITY', 'identity-api', 'Identity API', 'api', 'tenant', 'http', '/api/v1', '/health', 9001, 'identity'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'SRV_TENANT_B_ERP', 'erp-core', 'ERP Core', 'api', 'tenant', 'http', '/api/v1', '/health', 9030, 'erp')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.service_registry_instances (
  id, service_id, tenant_id, instance_key, node_name, host, port, status, version, heartbeat_interval_seconds
)
VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'gateway-public-01', 'node-a', '10.0.0.10', 9010, 'healthy', '1.0.0', 30),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'identity-api-01', 'node-a', '10.0.0.11', 9001, 'healthy', '1.0.0', 30),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'erp-core-01', 'node-b', '10.0.0.12', 9030, 'healthy', '1.0.0', 30)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.service_registry_heartbeats (
  id, service_id, instance_id, tenant_id, status, response_time_ms
)
VALUES
  ('cccccccc-cccc-cccc-cccc-ccccccccccc1', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, 'healthy', 22),
  ('cccccccc-cccc-cccc-cccc-ccccccccccc2', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', 'healthy', 18),
  ('cccccccc-cccc-cccc-cccc-ccccccccccc3', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', 'healthy', 25)
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ registry service visibility works'
         ELSE 'HATA ❌ registry service visibility broken'
       END AS registry_service_visibility_result
FROM runtime.service_registry_services;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ registry instance visibility works'
         ELSE 'HATA ❌ registry instance visibility broken'
       END AS registry_instance_visibility_result
FROM runtime.service_registry_instances;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.service_registry_services (
      tenant_id, business_code, service_key, display_name, service_kind, visibility_scope, protocol
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'SRV_FORBIDDEN',
      'forbidden-api',
      'Forbidden API',
      'api',
      'tenant',
      'http'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant service insert succeeded';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'OK ✅ cross tenant service insert blocked by RLS';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ registry super-admin service visibility works'
         ELSE 'HATA ❌ registry super-admin service visibility broken'
       END AS registry_service_super_admin_result
FROM runtime.service_registry_services;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ registry super-admin instance visibility works'
         ELSE 'HATA ❌ registry super-admin instance visibility broken'
       END AS registry_instance_super_admin_result
FROM runtime.service_registry_instances;

ROLLBACK;
