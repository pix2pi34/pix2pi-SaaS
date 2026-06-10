-- 186 — FAZ 4-15.2 Finance Reporting Mart behavior test body
-- Audit script injects temporary schema and latest 186 migration before this block.

DO $$
DECLARE
  v_period_count INTEGER;
  v_balance_count INTEGER;
  v_income_count INTEGER;
  v_tax_count INTEGER;
  v_aging_count INTEGER;
  v_offset_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_net_profit NUMERIC(18,2);
  v_total_tax NUMERIC(18,2);
BEGIN
  INSERT INTO finance_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status,
    metadata
  ) VALUES (
    'tenant_test_186',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO finance_account_balances_mart (
    tenant_id,
    period_id,
    account_code,
    account_name,
    account_type,
    currency_code,
    opening_debit,
    opening_credit,
    period_debit,
    period_credit,
    closing_debit,
    closing_credit,
    source_event_id,
    projection_version,
    metadata
  ) VALUES
    (
      'tenant_test_186',
      'period_2026_05',
      '120',
      'Alıcılar',
      'RECEIVABLE',
      'TRY',
      0,
      0,
      1200.00,
      0,
      1200.00,
      0,
      'evt_fin_186_001',
      1,
      '{"tdhp":true}'::jsonb
    ),
    (
      'tenant_test_186',
      'period_2026_05',
      '600',
      'Yurtiçi Satışlar',
      'REVENUE',
      'TRY',
      0,
      0,
      0,
      1000.00,
      0,
      1000.00,
      'evt_fin_186_001',
      1,
      '{"tdhp":true}'::jsonb
    ),
    (
      'tenant_test_186',
      'period_2026_05',
      '391.01.20',
      'Hesaplanan KDV %20',
      'TAX',
      'TRY',
      0,
      0,
      0,
      200.00,
      0,
      200.00,
      'evt_fin_186_001',
      1,
      '{"tdhp":true,"vat_rate":20}'::jsonb
    );

  INSERT INTO finance_income_expense_mart (
    tenant_id,
    period_id,
    report_line_id,
    line_type,
    line_code,
    line_name,
    amount,
    currency_code,
    source_account_codes,
    metadata
  ) VALUES
    (
      'tenant_test_186',
      'period_2026_05',
      'line_revenue_001',
      'REVENUE',
      'REV_TOTAL',
      'Toplam Gelir',
      1000.00,
      'TRY',
      '["600"]'::jsonb,
      '{"fixture":true}'::jsonb
    ),
    (
      'tenant_test_186',
      'period_2026_05',
      'line_tax_001',
      'TAX',
      'VAT_OUTPUT',
      'Hesaplanan KDV',
      200.00,
      'TRY',
      '["391.01.20"]'::jsonb,
      '{"fixture":true}'::jsonb
    ),
    (
      'tenant_test_186',
      'period_2026_05',
      'line_net_profit_001',
      'NET_PROFIT',
      'NET_PROFIT',
      'Net Kar',
      1000.00,
      'TRY',
      '["600"]'::jsonb,
      '{"fixture":true}'::jsonb
    );

  INSERT INTO finance_tax_summary_mart (
    tenant_id,
    period_id,
    tax_summary_id,
    tax_type,
    tax_rate,
    taxable_amount,
    tax_amount,
    direction,
    currency_code,
    source_document_count,
    metadata
  ) VALUES (
    'tenant_test_186',
    'period_2026_05',
    'tax_kdv_20_output',
    'KDV',
    20.00,
    1000.00,
    200.00,
    'OUTPUT',
    'TRY',
    1,
    '{"vat_account":"391.01.20"}'::jsonb
  );

  INSERT INTO finance_ar_ap_aging_mart (
    tenant_id,
    aging_id,
    period_id,
    party_id,
    party_type,
    party_name,
    account_code,
    document_ref,
    due_date,
    bucket,
    outstanding_amount,
    currency_code,
    metadata
  ) VALUES (
    'tenant_test_186',
    'aging_186_001',
    'period_2026_05',
    'customer_001',
    'CUSTOMER',
    'Acme Ltd',
    '120',
    'FAT-001',
    DATE '2026-05-20',
    'CURRENT',
    1200.00,
    'TRY',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO finance_reporting_projection_offsets (
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
    'tenant_test_186',
    'finance_reporting_projection',
    'ERP_FINANCE_EVENTS',
    'finance_reporting_consumer',
    'evt_fin_186_001',
    200,
    'ACTIVE',
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO finance_reporting_audit_events (
    tenant_id,
    audit_event_id,
    projection_name,
    event_type,
    period_id,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES (
    'tenant_test_186',
    'audit_fin_186_001',
    'finance_reporting_projection',
    'FINANCE_ACCOUNT_BALANCE_PROJECTED',
    'period_2026_05',
    'system_test',
    'corr_186_001',
    '{"account_count":3}'::jsonb
  );

  UPDATE finance_report_periods
  SET status = 'LOCKED',
      locked_at = now(),
      locked_by = 'system_test',
      updated_at = now()
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05';

  SELECT COUNT(*) INTO v_period_count
  FROM finance_report_periods
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05'
    AND status = 'LOCKED';

  IF v_period_count <> 1 THEN
    RAISE EXCEPTION 'finance period count mismatch: %', v_period_count;
  END IF;

  SELECT COUNT(*) INTO v_balance_count
  FROM finance_account_balances_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05';

  IF v_balance_count <> 3 THEN
    RAISE EXCEPTION 'finance account balance count mismatch: %', v_balance_count;
  END IF;

  SELECT amount INTO v_net_profit
  FROM finance_income_expense_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05'
    AND line_type = 'NET_PROFIT';

  IF v_net_profit <> 1000.00 THEN
    RAISE EXCEPTION 'net profit mismatch: %', v_net_profit;
  END IF;

  SELECT COUNT(*) INTO v_income_count
  FROM finance_income_expense_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05';

  IF v_income_count <> 3 THEN
    RAISE EXCEPTION 'income expense count mismatch: %', v_income_count;
  END IF;

  SELECT SUM(tax_amount) INTO v_total_tax
  FROM finance_tax_summary_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05'
    AND tax_type = 'KDV'
    AND direction = 'OUTPUT';

  IF v_total_tax <> 200.00 THEN
    RAISE EXCEPTION 'tax summary mismatch: %', v_total_tax;
  END IF;

  SELECT COUNT(*) INTO v_tax_count
  FROM finance_tax_summary_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05';

  IF v_tax_count <> 1 THEN
    RAISE EXCEPTION 'tax count mismatch: %', v_tax_count;
  END IF;

  SELECT COUNT(*) INTO v_aging_count
  FROM finance_ar_ap_aging_mart
  WHERE tenant_id = 'tenant_test_186'
    AND period_id = 'period_2026_05'
    AND bucket = 'CURRENT'
    AND outstanding_amount = 1200.00;

  IF v_aging_count <> 1 THEN
    RAISE EXCEPTION 'ar/ap aging count mismatch: %', v_aging_count;
  END IF;

  SELECT COUNT(*) INTO v_offset_count
  FROM finance_reporting_projection_offsets
  WHERE tenant_id = 'tenant_test_186'
    AND projection_name = 'finance_reporting_projection'
    AND last_sequence = 200;

  IF v_offset_count <> 1 THEN
    RAISE EXCEPTION 'finance reporting offset count mismatch: %', v_offset_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM finance_reporting_audit_events
  WHERE tenant_id = 'tenant_test_186'
    AND event_type = 'FINANCE_ACCOUNT_BALANCE_PROJECTED';

  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'finance reporting audit count mismatch: %', v_audit_count;
  END IF;

  BEGIN
    INSERT INTO finance_account_balances_mart (
      tenant_id,
      period_id,
      account_code,
      account_name
    ) VALUES (
      'tenant_test_186',
      'missing_period',
      '120',
      'FK Guard Must Fail'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'finance reporting mart FK guard did not work';
  END IF;
END
$$;

-- FINANCE_REPORTING_MART_SQL_TEST_IMPLEMENTED
