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
  ('dddddddd-dddd-dddd-dddd-ddddddddddd1', NULL, 'SRV_GLOBAL_GATEWAY_MC', 'gateway-public-mc', 'Gateway Public MC', 'gateway', 'global', 'https', '/', '/health', 9010, 'platform'),
  ('dddddddd-dddd-dddd-dddd-ddddddddddd2', '11111111-1111-1111-1111-111111111111', 'SRV_TENANT_A_API_MC', 'tenant-a-api-mc', 'Tenant A API MC', 'api', 'tenant', 'http', '/api/v1', '/health', 9001, 'tenant-a'),
  ('dddddddd-dddd-dddd-dddd-ddddddddddd3', '22222222-2222-2222-2222-222222222222', 'SRV_TENANT_B_API_MC', 'tenant-b-api-mc', 'Tenant B API MC', 'api', 'tenant', 'http', '/api/v1', '/health', 9002, 'tenant-b')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.service_registry_instances (
  id, service_id, tenant_id, instance_key, node_name, host, port, status, version, heartbeat_interval_seconds
)
VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee1', 'dddddddd-dddd-dddd-dddd-ddddddddddd1', NULL, 'gateway-public-mc-01', 'node-a', '10.0.1.10', 9010, 'healthy', '1.0.0', 30),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee2', 'dddddddd-dddd-dddd-dddd-ddddddddddd2', '11111111-1111-1111-1111-111111111111', 'tenant-a-api-mc-01', 'node-a', '10.0.1.11', 9001, 'healthy', '1.0.0', 30),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee3', 'dddddddd-dddd-dddd-dddd-ddddddddddd3', '22222222-2222-2222-2222-222222222222', 'tenant-b-api-mc-01', 'node-b', '10.0.1.12', 9002, 'healthy', '1.0.0', 30)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.mission_control_incidents (
  id, tenant_id, business_code, incident_key, service_id, instance_id, title, summary, severity, status, source, owner_team, opened_by
)
VALUES
  ('f1111111-1111-1111-1111-111111111111', NULL, 'INC_GLOBAL_GATEWAY', 'inc-global-gateway', 'dddddddd-dddd-dddd-dddd-ddddddddddd1', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee1', 'Global gateway degraded', 'global gateway latency spike', 'high', 'open', 'monitoring', 'platform', 'system'),
  ('f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'INC_TENANT_A_API', 'inc-tenant-a-api', 'dddddddd-dddd-dddd-dddd-ddddddddddd2', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee2', 'Tenant A API timeout', 'tenant a timeout spike', 'medium', 'open', 'monitoring', 'tenant-a', 'system'),
  ('f3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'INC_TENANT_B_API', 'inc-tenant-b-api', 'dddddddd-dddd-dddd-dddd-ddddddddddd3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee3', 'Tenant B API timeout', 'tenant b timeout spike', 'medium', 'open', 'monitoring', 'tenant-b', 'system')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.mission_control_actions (
  id, tenant_id, business_code, incident_id, service_id, instance_id, action_type, action_status, requested_by, requested_reason, executed_by, result_message
)
VALUES
  ('a1111111-1111-1111-1111-111111111111', NULL, 'ACT_GLOBAL_GATEWAY_NOTE', 'f1111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-ddddddddddd1', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee1', 'note', 'succeeded', 'system', 'initial global note', 'system', 'global note saved'),
  ('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'ACT_TENANT_A_RESTART', 'f2222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-ddddddddddd2', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee2', 'restart', 'succeeded', 'operator-a', 'restart requested', 'operator-a', 'restart completed'),
  ('a3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'ACT_TENANT_B_NOTE', 'f3333333-3333-3333-3333-333333333333', 'dddddddd-dddd-dddd-dddd-ddddddddddd3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee3', 'note', 'succeeded', 'operator-b', 'note requested', 'operator-b', 'note saved')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ mission control incident visibility works'
         ELSE 'HATA ❌ mission control incident visibility broken'
       END AS mission_control_incident_visibility_result
FROM runtime.mission_control_incidents;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ mission control action visibility works'
         ELSE 'HATA ❌ mission control action visibility broken'
       END AS mission_control_action_visibility_result
FROM runtime.mission_control_actions;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.mission_control_incidents (
      tenant_id, business_code, incident_key, service_id, instance_id, title, summary, severity, status, source
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      'INC_FORBIDDEN',
      'inc-forbidden',
      'dddddddd-dddd-dddd-dddd-ddddddddddd3',
      'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee3',
      'Forbidden cross tenant incident',
      'should fail',
      'high',
      'open',
      'manual'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant incident insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant incident insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ mission control super-admin incident visibility works'
         ELSE 'HATA ❌ mission control super-admin incident visibility broken'
       END AS mission_control_incident_super_admin_result
FROM runtime.mission_control_incidents;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ mission control super-admin action visibility works'
         ELSE 'HATA ❌ mission control super-admin action visibility broken'
       END AS mission_control_action_super_admin_result
FROM runtime.mission_control_actions;

ROLLBACK;
