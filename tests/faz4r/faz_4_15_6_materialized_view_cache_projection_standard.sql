-- 189 — FAZ 4-15.6 Materialized View / Cache Projection Standard behavior test body
-- Audit script injects temporary schema and latest 189 migration before this block.

DO $$
DECLARE
  v_definition_count INTEGER;
  v_profile_count INTEGER;
  v_cache_count INTEGER;
  v_dependency_count INTEGER;
  v_job_count INTEGER;
  v_audit_count INTEGER;
  v_health_count INTEGER;
  v_total_hit_count BIGINT;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_job_status TEXT;
BEGIN
  INSERT INTO materialized_projection_definitions (
    tenant_id,
    projection_name,
    projection_type,
    source_domain,
    refresh_strategy,
    cache_strategy,
    ttl_seconds,
    stale_after_seconds,
    rebuild_required,
    is_active,
    source_query_hash,
    owner_team,
    metadata
  ) VALUES (
    'tenant_test_189',
    'finance_dashboard_projection',
    'HYBRID',
    'FINANCE',
    'EVENT_DRIVEN',
    'POSTGRES',
    600,
    120,
    FALSE,
    TRUE,
    'hash_189_001',
    'platform',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO projection_cache_profiles (
    tenant_id,
    cache_profile_id,
    projection_name,
    cache_backend,
    ttl_seconds,
    stale_after_seconds,
    max_entries,
    invalidation_strategy,
    is_active,
    metadata
  ) VALUES (
    'tenant_test_189',
    'cache_profile_189_001',
    'finance_dashboard_projection',
    'POSTGRES',
    600,
    120,
    10000,
    'EVENT_DRIVEN',
    TRUE,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO projection_cache_entries (
    tenant_id,
    cache_key,
    projection_name,
    cache_profile_id,
    entity_type,
    entity_id,
    cache_status,
    payload,
    payload_hash,
    expires_at,
    hit_count,
    source_event_id,
    projection_version,
    metadata
  ) VALUES
    (
      'tenant_test_189',
      'cache:finance_dashboard:tenant_test_189:summary',
      'finance_dashboard_projection',
      'cache_profile_189_001',
      'FINANCE_REPORT',
      'summary_2026_05',
      'ACTIVE',
      '{"period":"2026-05","gross":1200,"net":1000}'::jsonb,
      'payload_hash_189_001',
      now() + interval '10 minutes',
      2,
      'evt_189_001',
      1,
      '{"fixture":true}'::jsonb
    ),
    (
      'tenant_test_189',
      'cache:finance_dashboard:tenant_test_189:stale',
      'finance_dashboard_projection',
      'cache_profile_189_001',
      'FINANCE_REPORT',
      'stale_2026_05',
      'STALE',
      '{"period":"2026-05","stale":true}'::jsonb,
      'payload_hash_189_002',
      now() - interval '1 minute',
      3,
      'evt_189_002',
      1,
      '{"fixture":true}'::jsonb
    );

  UPDATE projection_cache_entries
  SET hit_count = hit_count + 1,
      last_hit_at = now(),
      updated_at = now()
  WHERE tenant_id = 'tenant_test_189'
    AND cache_key = 'cache:finance_dashboard:tenant_test_189:summary';

  INSERT INTO materialized_projection_dependencies (
    tenant_id,
    dependency_id,
    projection_name,
    source_table,
    source_entity_type,
    dependency_type,
    is_required,
    metadata
  ) VALUES (
    'tenant_test_189',
    'dep_189_001',
    'finance_dashboard_projection',
    'finance_account_balances_mart',
    'FINANCE_REPORT',
    'AGGREGATE',
    TRUE,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO materialized_projection_refresh_jobs (
    tenant_id,
    refresh_job_id,
    projection_name,
    refresh_scope,
    scope_ref,
    status,
    requested_by,
    correlation_id,
    total_items,
    processed_items,
    failed_items,
    started_at,
    metadata
  ) VALUES (
    'tenant_test_189',
    'refresh_189_001',
    'finance_dashboard_projection',
    'FULL',
    NULL,
    'RUNNING',
    'system_test',
    'corr_189_001',
    2,
    0,
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  UPDATE materialized_projection_refresh_jobs
  SET status = 'COMPLETED',
      processed_items = 2,
      completed_at = now(),
      updated_at = now()
  WHERE tenant_id = 'tenant_test_189'
    AND refresh_job_id = 'refresh_189_001';

  INSERT INTO materialized_projection_audit_events (
    tenant_id,
    audit_event_id,
    projection_name,
    event_type,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES
    (
      'tenant_test_189',
      'audit_189_001',
      'finance_dashboard_projection',
      'PROJECTION_DEFINED',
      'system_test',
      'corr_189_001',
      '{"projection_name":"finance_dashboard_projection"}'::jsonb
    ),
    (
      'tenant_test_189',
      'audit_189_002',
      'finance_dashboard_projection',
      'REFRESH_JOB_COMPLETED',
      'system_test',
      'corr_189_001',
      '{"refresh_job_id":"refresh_189_001"}'::jsonb
    );

  REFRESH MATERIALIZED VIEW mv_projection_cache_health;

  SELECT COUNT(*) INTO v_definition_count
  FROM materialized_projection_definitions
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection'
    AND is_active = TRUE;

  IF v_definition_count <> 1 THEN
    RAISE EXCEPTION 'projection definition count mismatch: %', v_definition_count;
  END IF;

  SELECT COUNT(*) INTO v_profile_count
  FROM projection_cache_profiles
  WHERE tenant_id = 'tenant_test_189'
    AND cache_profile_id = 'cache_profile_189_001'
    AND is_active = TRUE;

  IF v_profile_count <> 1 THEN
    RAISE EXCEPTION 'cache profile count mismatch: %', v_profile_count;
  END IF;

  SELECT COUNT(*) INTO v_cache_count
  FROM projection_cache_entries
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection';

  IF v_cache_count <> 2 THEN
    RAISE EXCEPTION 'cache entry count mismatch: %', v_cache_count;
  END IF;

  SELECT COUNT(*) INTO v_dependency_count
  FROM materialized_projection_dependencies
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection';

  IF v_dependency_count <> 1 THEN
    RAISE EXCEPTION 'dependency count mismatch: %', v_dependency_count;
  END IF;

  SELECT status INTO v_job_status
  FROM materialized_projection_refresh_jobs
  WHERE tenant_id = 'tenant_test_189'
    AND refresh_job_id = 'refresh_189_001';

  IF v_job_status <> 'COMPLETED' THEN
    RAISE EXCEPTION 'refresh job status mismatch: %', v_job_status;
  END IF;

  SELECT COUNT(*) INTO v_job_count
  FROM materialized_projection_refresh_jobs
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection';

  IF v_job_count <> 1 THEN
    RAISE EXCEPTION 'refresh job count mismatch: %', v_job_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM materialized_projection_audit_events
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection';

  IF v_audit_count <> 2 THEN
    RAISE EXCEPTION 'audit event count mismatch: %', v_audit_count;
  END IF;

  SELECT COUNT(*), COALESCE(SUM(total_hit_count), 0)
  INTO v_health_count, v_total_hit_count
  FROM mv_projection_cache_health
  WHERE tenant_id = 'tenant_test_189'
    AND projection_name = 'finance_dashboard_projection';

  IF v_health_count <> 1 THEN
    RAISE EXCEPTION 'materialized cache health count mismatch: %', v_health_count;
  END IF;

  IF v_total_hit_count <> 6 THEN
    RAISE EXCEPTION 'materialized cache health hit count mismatch: %', v_total_hit_count;
  END IF;

  BEGIN
    INSERT INTO projection_cache_entries (
      tenant_id,
      cache_key,
      projection_name,
      entity_type,
      entity_id
    ) VALUES (
      'tenant_test_189',
      'cache:orphan',
      'missing_projection',
      'GENERIC',
      'orphan'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'projection cache FK guard did not work';
  END IF;
END
$$;

-- MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_SQL_TEST_IMPLEMENTED
