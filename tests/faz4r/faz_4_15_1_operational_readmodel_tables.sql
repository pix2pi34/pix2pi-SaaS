-- 191 — FAZ 4-15.1 Operational Readmodel Tabloları behavior test body
-- Audit script injects temporary schema and latest 191 migration before this block.

DO $$
DECLARE
  v_snapshot_count INTEGER;
  v_tenant_health_count INTEGER;
  v_user_activity_count INTEGER;
  v_import_queue_count INTEGER;
  v_task_queue_count INTEGER;
  v_service_health_count INTEGER;
  v_offset_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_critical_count INTEGER;
BEGIN
  INSERT INTO operational_readmodel_snapshots (
    tenant_id,
    snapshot_id,
    snapshot_type,
    snapshot_status,
    generated_by,
    correlation_id,
    snapshot_at,
    source_event_id,
    projection_version,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'PILOT_DASHBOARD',
    'ACTIVE',
    'system_test',
    'corr_191_001',
    now(),
    'evt_191_001',
    1,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_tenant_health_readmodel (
    tenant_id,
    snapshot_id,
    tenant_status,
    health_status,
    open_issue_count,
    critical_issue_count,
    active_user_count,
    import_batch_count,
    failed_import_count,
    pending_uat_count,
    last_activity_at,
    last_import_at,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'ACTIVE',
    'WARN',
    3,
    1,
    5,
    2,
    1,
    4,
    now(),
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_user_activity_readmodel (
    tenant_id,
    snapshot_id,
    user_id,
    user_role,
    user_status,
    last_login_at,
    last_action_at,
    action_count,
    failed_login_count,
    device_count,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'user_191_001',
    'TENANT_ADMIN',
    'ACTIVE',
    now(),
    now(),
    12,
    0,
    2,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_import_queue_readmodel (
    tenant_id,
    snapshot_id,
    import_batch_id,
    import_type,
    import_status,
    total_rows,
    valid_rows,
    invalid_rows,
    committed_rows,
    failed_rows,
    owner_user_id,
    created_by,
    started_at,
    completed_at,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'import_batch_191_001',
    'CUSTOMER',
    'VALIDATED',
    100,
    98,
    2,
    0,
    0,
    'user_191_001',
    'user_191_001',
    now(),
    NULL,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_task_queue_readmodel (
    tenant_id,
    snapshot_id,
    task_id,
    task_type,
    task_status,
    priority,
    assigned_to,
    due_at,
    source_ref,
    correlation_id,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'task_191_001',
    'UAT',
    'OPEN',
    'CRITICAL',
    'user_191_001',
    now() + interval '1 day',
    'uat_case_001',
    'corr_191_001',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_service_health_readmodel (
    tenant_id,
    snapshot_id,
    service_name,
    service_status,
    health_endpoint,
    last_check_at,
    response_time_ms,
    error_count,
    warning_count,
    metadata
  ) VALUES (
    'tenant_test_191',
    'snapshot_191_001',
    'api-gateway',
    'UP',
    '/health',
    now(),
    35,
    0,
    0,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_readmodel_projection_offsets (
    tenant_id,
    projection_name,
    stream_name,
    consumer_name,
    last_event_id,
    last_sequence,
    status,
    lag_count,
    last_projected_at,
    metadata
  ) VALUES (
    'tenant_test_191',
    'operational_readmodel_projection',
    'OPERATIONAL_EVENTS',
    'operational_readmodel_consumer',
    'evt_191_001',
    500,
    'ACTIVE',
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO operational_readmodel_audit_events (
    tenant_id,
    audit_event_id,
    snapshot_id,
    projection_name,
    event_type,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES (
    'tenant_test_191',
    'audit_191_001',
    'snapshot_191_001',
    'operational_readmodel_projection',
    'OPERATIONAL_SNAPSHOT_CREATED',
    'system_test',
    'corr_191_001',
    '{"snapshot_id":"snapshot_191_001"}'::jsonb
  );

  UPDATE operational_task_queue_readmodel
  SET task_status = 'IN_PROGRESS',
      updated_at = now()
  WHERE tenant_id = 'tenant_test_191'
    AND snapshot_id = 'snapshot_191_001'
    AND task_id = 'task_191_001';

  SELECT COUNT(*) INTO v_snapshot_count
  FROM operational_readmodel_snapshots
  WHERE tenant_id = 'tenant_test_191'
    AND snapshot_id = 'snapshot_191_001'
    AND snapshot_status = 'ACTIVE';

  IF v_snapshot_count <> 1 THEN
    RAISE EXCEPTION 'operational snapshot count mismatch: %', v_snapshot_count;
  END IF;

  SELECT COUNT(*) INTO v_tenant_health_count
  FROM operational_tenant_health_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND snapshot_id = 'snapshot_191_001'
    AND health_status = 'WARN';

  IF v_tenant_health_count <> 1 THEN
    RAISE EXCEPTION 'tenant health count mismatch: %', v_tenant_health_count;
  END IF;

  SELECT critical_issue_count INTO v_critical_count
  FROM operational_tenant_health_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND snapshot_id = 'snapshot_191_001';

  IF v_critical_count <> 1 THEN
    RAISE EXCEPTION 'critical issue count mismatch: %', v_critical_count;
  END IF;

  SELECT COUNT(*) INTO v_user_activity_count
  FROM operational_user_activity_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND user_id = 'user_191_001'
    AND action_count = 12;

  IF v_user_activity_count <> 1 THEN
    RAISE EXCEPTION 'user activity count mismatch: %', v_user_activity_count;
  END IF;

  SELECT COUNT(*) INTO v_import_queue_count
  FROM operational_import_queue_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND import_batch_id = 'import_batch_191_001'
    AND import_status = 'VALIDATED';

  IF v_import_queue_count <> 1 THEN
    RAISE EXCEPTION 'import queue count mismatch: %', v_import_queue_count;
  END IF;

  SELECT COUNT(*) INTO v_task_queue_count
  FROM operational_task_queue_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND task_id = 'task_191_001'
    AND task_status = 'IN_PROGRESS'
    AND priority = 'CRITICAL';

  IF v_task_queue_count <> 1 THEN
    RAISE EXCEPTION 'task queue count mismatch: %', v_task_queue_count;
  END IF;

  SELECT COUNT(*) INTO v_service_health_count
  FROM operational_service_health_readmodel
  WHERE tenant_id = 'tenant_test_191'
    AND service_name = 'api-gateway'
    AND service_status = 'UP';

  IF v_service_health_count <> 1 THEN
    RAISE EXCEPTION 'service health count mismatch: %', v_service_health_count;
  END IF;

  SELECT COUNT(*) INTO v_offset_count
  FROM operational_readmodel_projection_offsets
  WHERE tenant_id = 'tenant_test_191'
    AND projection_name = 'operational_readmodel_projection'
    AND last_sequence = 500;

  IF v_offset_count <> 1 THEN
    RAISE EXCEPTION 'projection offset count mismatch: %', v_offset_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM operational_readmodel_audit_events
  WHERE tenant_id = 'tenant_test_191'
    AND event_type = 'OPERATIONAL_SNAPSHOT_CREATED';

  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'audit event count mismatch: %', v_audit_count;
  END IF;

  BEGIN
    INSERT INTO operational_task_queue_readmodel (
      tenant_id,
      snapshot_id,
      task_id,
      task_type,
      task_status,
      correlation_id
    ) VALUES (
      'tenant_test_191',
      'missing_snapshot',
      'task_orphan_191',
      'UAT',
      'OPEN',
      'corr_orphan_191'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'operational readmodel FK guard did not work';
  END IF;
END
$$;

-- OPERATIONAL_READMODEL_TABLES_SQL_TEST_IMPLEMENTED
