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

INSERT INTO runtime.plugins (
  id, tenant_id, business_code, plugin_key, display_name, version_no, visibility_scope, source_type, lifecycle_status, entrypoint_ref
)
VALUES
  ('19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'PLG_GLOBAL_1', 'global-logger', 'Global Logger Plugin', '1.0.0', 'global', 'builtin', 'published', 'internal/plugins/logger'),
  ('19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'PLG_TENANT_A_1', 'tenant-a-exporter', 'Tenant A Exporter', '1.2.0', 'tenant', 'local', 'published', 'internal/plugins/exporter'),
  ('19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'PLG_TENANT_B_1', 'tenant-b-crm', 'Tenant B CRM', '2.0.1', 'tenant', 'marketplace', 'published', 'marketplace/crm')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.plugin_states (
  id, tenant_id, plugin_id, business_code, state_key, desired_state, current_state, install_ref
)
VALUES
  ('20202020-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'PLS_GLOBAL_1', 'plugin-state-global-1', 'active', 'active', 'install-global-1'),
  ('20202020-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'PLS_TENANT_A_1', 'plugin-state-tenant-a-1', 'active', 'degraded', 'install-a-1'),
  ('20202020-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '19191919-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'PLS_TENANT_B_1', 'plugin-state-tenant-b-1', 'active', 'active', 'install-b-1')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ plugins visibility works'
         ELSE 'HATA ❌ plugins visibility broken'
       END AS plugins_visibility_result
FROM runtime.plugins;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ plugin states visibility works'
         ELSE 'HATA ❌ plugin states visibility broken'
       END AS plugin_states_visibility_result
FROM runtime.plugin_states;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.plugins (
      tenant_id, business_code, plugin_key, display_name, version_no, visibility_scope, source_type, lifecycle_status, entrypoint_ref
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'PLG_FORBIDDEN',
      'plugin-forbidden',
      'Forbidden Plugin',
      '1.0.0',
      'tenant',
      'local',
      'published',
      'internal/plugins/forbidden'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant plugin insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant plugin insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ plugins super-admin visibility works'
         ELSE 'HATA ❌ plugins super-admin visibility broken'
       END AS plugins_super_admin_result
FROM runtime.plugins;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ plugin states super-admin visibility works'
         ELSE 'HATA ❌ plugin states super-admin visibility broken'
       END AS plugin_states_super_admin_result
FROM runtime.plugin_states;

ROLLBACK;
