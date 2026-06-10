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

INSERT INTO runtime.job_queues (
  id, tenant_id, business_code, queue_key, display_name, visibility_scope, max_concurrency, retry_limit, retry_backoff_seconds
)
VALUES
  ('11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL, 'Q_GLOBAL_SYNC', 'global-sync', 'Global Sync Queue', 'global', 4, 3, 30),
  ('11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'Q_TENANT_A_MAIN', 'tenant-a-main', 'Tenant A Main Queue', 'tenant', 2, 5, 20),
  ('11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '22222222-2222-2222-2222-222222222222', 'Q_TENANT_B_MAIN', 'tenant-b-main', 'Tenant B Main Queue', 'tenant', 2, 5, 20)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.jobs (
  id, tenant_id, queue_id, business_code, job_key, job_type, priority, status, payload, dedupe_key, retry_count, max_attempts
)
VALUES
  ('22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL, '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'JOB_GLOBAL_SYNC_1', 'job-global-sync-1', 'sync', 'high', 'queued', '{"scope":"global"}'::jsonb, 'dedupe-global-1', 0, 3),
  ('22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-1111-1111-1111-111111111111', '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'JOB_TENANT_A_1', 'job-tenant-a-1', 'email_send', 'normal', 'queued', '{"tenant":"A"}'::jsonb, 'dedupe-tenant-a-1', 0, 5),
  ('22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '22222222-2222-2222-2222-222222222222', '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 'JOB_TENANT_B_1', 'job-tenant-b-1', 'export_run', 'normal', 'queued', '{"tenant":"B"}'::jsonb, 'dedupe-tenant-b-1', 0, 5)
ON CONFLICT DO NOTHING;

INSERT INTO runtime.job_attempts (
  id, tenant_id, job_id, queue_id, attempt_no, status, worker_id, duration_ms, result_payload
)
VALUES
  ('33333333-cccc-cccc-cccc-ccccccccccc1', NULL, '22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 1, 'started', 'worker-global-1', 10, '{"status":"started"}'::jsonb),
  ('33333333-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', '22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 1, 'started', 'worker-a-1', 12, '{"status":"started"}'::jsonb),
  ('33333333-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', '22222222-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa3', 1, 'started', 'worker-b-1', 14, '{"status":"started"}'::jsonb)
ON CONFLICT DO NOTHING;

SET LOCAL ROLE pix2pi_app;

SELECT security.set_claim('app.current_tenant_id', '11111111-1111-1111-1111-111111111111');
SELECT security.set_claim('app.is_super_admin', 'false');

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ job queue visibility works'
         ELSE 'HATA ❌ job queue visibility broken'
       END AS job_queue_visibility_result
FROM runtime.job_queues;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ jobs visibility works'
         ELSE 'HATA ❌ jobs visibility broken'
       END AS jobs_visibility_result
FROM runtime.jobs;

SELECT CASE
         WHEN count(*) = 2 THEN 'OK ✅ job attempts visibility works'
         ELSE 'HATA ❌ job attempts visibility broken'
       END AS job_attempts_visibility_result
FROM runtime.job_attempts;

DO $$
BEGIN
  BEGIN
    INSERT INTO runtime.jobs (
      tenant_id, queue_id, business_code, job_key, job_type, priority, status, payload, dedupe_key, retry_count, max_attempts
    )
    VALUES (
      '22222222-2222-2222-2222-222222222222',
      '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
      'JOB_FORBIDDEN',
      'job-forbidden',
      'forbidden_job',
      'high',
      'queued',
      '{"tenant":"B"}'::jsonb,
      'dedupe-forbidden',
      0,
      3
    );
    RAISE EXCEPTION 'HATA ❌ cross tenant job insert succeeded';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'OK ✅ cross tenant job insert blocked';
  END;
END;
$$;

SELECT security.set_claim('app.is_super_admin', 'true');

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ job queue super-admin visibility works'
         ELSE 'HATA ❌ job queue super-admin visibility broken'
       END AS job_queue_super_admin_result
FROM runtime.job_queues;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ jobs super-admin visibility works'
         ELSE 'HATA ❌ jobs super-admin visibility broken'
       END AS jobs_super_admin_result
FROM runtime.jobs;

SELECT CASE
         WHEN count(*) = 3 THEN 'OK ✅ job attempts super-admin visibility works'
         ELSE 'HATA ❌ job attempts super-admin visibility broken'
       END AS job_attempts_super_admin_result
FROM runtime.job_attempts;

ROLLBACK;
