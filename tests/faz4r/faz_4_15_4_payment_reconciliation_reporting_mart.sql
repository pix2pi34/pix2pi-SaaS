-- 187 — FAZ 4-15.4 Payment / Reconciliation Reporting Mart behavior test body
-- Audit script injects temporary schema and latest 187 migration before this block.

DO $$
DECLARE
  v_period_count INTEGER;
  v_attempt_count INTEGER;
  v_reconciliation_count INTEGER;
  v_settlement_count INTEGER;
  v_fee_count INTEGER;
  v_offset_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_net_amount NUMERIC(18,2);
  v_difference NUMERIC(18,2);
BEGIN
  INSERT INTO payment_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status,
    metadata
  ) VALUES (
    'tenant_test_187',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO payment_attempts_mart (
    tenant_id,
    period_id,
    payment_attempt_id,
    provider_code,
    payment_channel,
    operation_type,
    status,
    amount,
    currency_code,
    provider_transaction_id,
    idempotency_key,
    correlation_id,
    source_event_id,
    attempted_at,
    completed_at,
    metadata
  ) VALUES (
    'tenant_test_187',
    'period_2026_05',
    'pay_attempt_187_001',
    'SIMULATION',
    'CARD',
    'CAPTURE',
    'CAPTURED',
    1200.00,
    'TRY',
    'prov_txn_187_001',
    'idem_187_001',
    'corr_187_001',
    'evt_pay_187_001',
    now(),
    now(),
    '{"fixture":true,"invoice_no":"FAT-001"}'::jsonb
  );

  INSERT INTO payment_reconciliation_mart (
    tenant_id,
    period_id,
    reconciliation_id,
    provider_code,
    payment_attempt_id,
    provider_transaction_id,
    internal_amount,
    provider_amount,
    difference_amount,
    currency_code,
    reconciliation_status,
    matched_at,
    metadata
  ) VALUES (
    'tenant_test_187',
    'period_2026_05',
    'recon_187_001',
    'SIMULATION',
    'pay_attempt_187_001',
    'prov_txn_187_001',
    1200.00,
    1200.00,
    0.00,
    'TRY',
    'MATCHED',
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO payment_settlement_summary_mart (
    tenant_id,
    period_id,
    settlement_summary_id,
    provider_code,
    settlement_date,
    gross_amount,
    fee_amount,
    net_amount,
    refund_amount,
    chargeback_amount,
    transaction_count,
    currency_code,
    status,
    metadata
  ) VALUES (
    'tenant_test_187',
    'period_2026_05',
    'settlement_187_001',
    'SIMULATION',
    DATE '2026-05-08',
    1200.00,
    24.00,
    1176.00,
    0.00,
    0.00,
    1,
    'TRY',
    'RECONCILED',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO payment_fee_summary_mart (
    tenant_id,
    period_id,
    fee_summary_id,
    provider_code,
    fee_type,
    fee_amount,
    base_amount,
    effective_rate,
    currency_code,
    transaction_count,
    metadata
  ) VALUES (
    'tenant_test_187',
    'period_2026_05',
    'fee_187_001',
    'SIMULATION',
    'PROVIDER_COMMISSION',
    24.00,
    1200.00,
    2.0000,
    'TRY',
    1,
    '{"fixture":true}'::jsonb
  );

  INSERT INTO payment_reporting_projection_offsets (
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
    'tenant_test_187',
    'payment_reporting_projection',
    'PAYMENT_EVENTS',
    'payment_reporting_consumer',
    'evt_pay_187_001',
    300,
    'ACTIVE',
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO payment_reporting_audit_events (
    tenant_id,
    audit_event_id,
    projection_name,
    event_type,
    period_id,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES (
    'tenant_test_187',
    'audit_pay_187_001',
    'payment_reporting_projection',
    'PAYMENT_ATTEMPT_PROJECTED',
    'period_2026_05',
    'system_test',
    'corr_187_001',
    '{"payment_attempt_id":"pay_attempt_187_001"}'::jsonb
  );

  UPDATE payment_report_periods
  SET status = 'LOCKED',
      locked_at = now(),
      locked_by = 'system_test',
      updated_at = now()
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05';

  SELECT COUNT(*) INTO v_period_count
  FROM payment_report_periods
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05'
    AND status = 'LOCKED';

  IF v_period_count <> 1 THEN
    RAISE EXCEPTION 'payment period count mismatch: %', v_period_count;
  END IF;

  SELECT COUNT(*) INTO v_attempt_count
  FROM payment_attempts_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05'
    AND status = 'CAPTURED';

  IF v_attempt_count <> 1 THEN
    RAISE EXCEPTION 'payment attempt count mismatch: %', v_attempt_count;
  END IF;

  SELECT difference_amount INTO v_difference
  FROM payment_reconciliation_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05'
    AND reconciliation_status = 'MATCHED';

  IF v_difference <> 0.00 THEN
    RAISE EXCEPTION 'reconciliation difference mismatch: %', v_difference;
  END IF;

  SELECT COUNT(*) INTO v_reconciliation_count
  FROM payment_reconciliation_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05';

  IF v_reconciliation_count <> 1 THEN
    RAISE EXCEPTION 'reconciliation count mismatch: %', v_reconciliation_count;
  END IF;

  SELECT net_amount INTO v_net_amount
  FROM payment_settlement_summary_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05'
    AND status = 'RECONCILED';

  IF v_net_amount <> 1176.00 THEN
    RAISE EXCEPTION 'settlement net amount mismatch: %', v_net_amount;
  END IF;

  SELECT COUNT(*) INTO v_settlement_count
  FROM payment_settlement_summary_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05';

  IF v_settlement_count <> 1 THEN
    RAISE EXCEPTION 'settlement count mismatch: %', v_settlement_count;
  END IF;

  SELECT COUNT(*) INTO v_fee_count
  FROM payment_fee_summary_mart
  WHERE tenant_id = 'tenant_test_187'
    AND period_id = 'period_2026_05'
    AND fee_type = 'PROVIDER_COMMISSION';

  IF v_fee_count <> 1 THEN
    RAISE EXCEPTION 'fee count mismatch: %', v_fee_count;
  END IF;

  SELECT COUNT(*) INTO v_offset_count
  FROM payment_reporting_projection_offsets
  WHERE tenant_id = 'tenant_test_187'
    AND projection_name = 'payment_reporting_projection'
    AND last_sequence = 300;

  IF v_offset_count <> 1 THEN
    RAISE EXCEPTION 'payment reporting offset count mismatch: %', v_offset_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM payment_reporting_audit_events
  WHERE tenant_id = 'tenant_test_187'
    AND event_type = 'PAYMENT_ATTEMPT_PROJECTED';

  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'payment reporting audit count mismatch: %', v_audit_count;
  END IF;

  BEGIN
    INSERT INTO payment_attempts_mart (
      tenant_id,
      period_id,
      payment_attempt_id,
      provider_code,
      payment_channel,
      operation_type,
      status,
      amount,
      correlation_id
    ) VALUES (
      'tenant_test_187',
      'missing_period',
      'pay_attempt_orphan_187',
      'SIMULATION',
      'CARD',
      'CAPTURE',
      'CAPTURED',
      100.00,
      'corr_orphan_187'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'payment reporting mart FK guard did not work';
  END IF;
END
$$;

-- PAYMENT_RECONCILIATION_REPORTING_MART_SQL_TEST_IMPLEMENTED
