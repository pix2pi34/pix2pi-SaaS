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

INSERT INTO runtime.workflow_definitions (
  id, tenant_id, business_code, workflow_key, display_name, version_no, visibility_scope, definition_status, trigger_event
)
VALUES
  ('12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'WF_GLOBAL_APPROVAL', 'global-approval', 'Global Approval', 1, 'global', 'active', 'system.event'),
  ('12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'WF_TENANT_A_ORDER', 'tenant-a-order-approval', 'Tenant A Order Approval', 1, 'tenant', 'active', 'order.created'),
  ('12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'WF_TENANT_B_ORDER', 'tenant-b-order-approval', 'Tenant B Order Approval', 1, 'tenant', 'active', 'order.created')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.workflow_instances (
  id, tenant_id, definition_id, business_code, instance_key, workflow_status, subject_ref_type, subject_ref_id, current_step_key
)
VALUES
  ('13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'WFI_GLOBAL_1', 'wfi-global-1', 'running', 'sync_run', 'sync-1', 'review'),
  ('13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'WFI_TENANT_A_1', 'wfi-tenant-a-1', 'waiting_approval', 'sales_order', 'so-a-1', 'manager-approval'),
  ('13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'WFI_TENANT_B_1', 'wfi-tenant-b-1', 'waiting_approval', 'sales_order', 'so-b-1', 'manager-approval')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.workflow_steps (
  id, tenant_id, instance_id, definition_id, business_code, step_key, step_order, step_type, step_status, assigned_to
)
VALUES
  ('14141414-cccc-cccc-cccc-ccccccccccc1', NULL, '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'WFS_GLOBAL_1', 'review', 1, 'manual_review', 'running', 'system'),
  ('14141414-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'WFS_TENANT_A_1', 'manager-approval', 1, 'approval', 'waiting_approval', 'manager-a'),
  ('14141414-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'WFS_TENANT_B_1', 'manager-approval', 1, 'approval', 'waiting_approval', 'manager-b')
ON CONFLICT DO NOTHING;

INSERT INTO runtime.workflow_approvals (
  id, tenant_id, instance_id, step_id, business_code, approval_key, approver_ref, approval_status
)
VALUES
  ('15151515-dddd-dddd-dddd-ddddddddddd1', NULL, '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '14141414-cccc-cccc-cccc-ccccccccccc1', 'WFA_GLOBAL_1', 'approval-global-1', 'ops-global', 'pending'),
  ('15151515-dddd-dddd-dddd-ddddddddddd2', '11111111-1111-1111-1111-111111111111', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '14141414-cccc-cccc-cccc-ccccccccccc2', 'WFA_TENANT_A_1', 'approval-tenant-a-1', 'manager-a', 'pending'),
  ('15151515-dddd-dddd-dddd-ddddddddddd3', '22222222-2222-2222-2222-222222222222', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '14141414-cccc-cccc-cccc-ccccccccccc3', 'WFA_TENANT_B_1', 'approval-tenant-b-1', 'manager-b', 'pending')
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ workflow definitions visibility works'
         ELSE 'HATA ❌ workflow definitions visibility broken'
       END AS workflow_definitions_visibility_result
FROM runtime.workflow_definitions;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ workflow instances visibility works'
         ELSE 'HATA ❌ workflow instances visibility broken'
       END AS workflow_instances_visibility_result
FROM runtime.workflow_instances;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ workflow steps visibility works'
         ELSE 'HATA ❌ workflow steps visibility broken'
       END AS workflow_steps_visibility_result
FROM runtime.workflow_steps;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ workflow approvals visibility works'
         ELSE 'HATA ❌ workflow approvals visibility broken'
       END AS workflow_approvals_visibility_result
FROM runtime.workflow_approvals;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.workflow_instances (
      tenant_id, definition_id, business_code, instance_key, workflow_status, subject_ref_type, subject_ref_id, current_step_key
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      '12121212-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
      'WFI_FORBIDDEN',
      'wfi-forbidden',
      'running',
      'sales_order',
      'so-forbidden',
      'manager-approval'
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant workflow instance insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant workflow instance insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ workflow definitions super-admin visibility works'
         ELSE 'HATA ❌ workflow definitions super-admin visibility broken'
       END AS workflow_definitions_super_admin_result
FROM runtime.workflow_definitions;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ workflow instances super-admin visibility works'
         ELSE 'HATA ❌ workflow instances super-admin visibility broken'
       END AS workflow_instances_super_admin_result
FROM runtime.workflow_instances;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ workflow steps super-admin visibility works'
         ELSE 'HATA ❌ workflow steps super-admin visibility broken'
       END AS workflow_steps_super_admin_result
FROM runtime.workflow_steps;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ workflow approvals super-admin visibility works'
         ELSE 'HATA ❌ workflow approvals super-admin visibility broken'
       END AS workflow_approvals_super_admin_result
FROM runtime.workflow_approvals;

ROLLBACK;
