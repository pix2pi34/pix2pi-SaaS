-- 190 — FAZ 4-15.7 Readmodel / Reporting Test Seti
-- Audit script injects temporary schema and latest 185-189 migrations before this block.

DO $$
DECLARE
  v_search_count INTEGER;
  v_finance_balance_count INTEGER;
  v_payment_count INTEGER;
  v_edoc_count INTEGER;
  v_cache_health_count INTEGER;
  v_total_cache_hit BIGINT;
  v_cross_gross_finance NUMERIC(18,2);
  v_cross_gross_payment NUMERIC(18,2);
  v_cross_gross_edoc NUMERIC(18,2);
  v_fk_guard_ok BOOLEAN := FALSE;
BEGIN
  INSERT INTO search_index_documents (
    tenant_id,
    search_document_id,
    entity_type,
    entity_id,
    entity_ref,
    title,
    subtitle,
    searchable_text,
    search_vector,
    status,
    source_event_id,
    source_updated_at,
    projection_version,
    ranking_score,
    payload
  ) VALUES (
    'tenant_test_190',
    'doc_190_invoice_001',
    'FINANCE_DOCUMENT',
    'invoice_190_001',
    'FAT-190-001',
    'FAT-190-001 Acme Ltd',
    'Toplam 1200 TRY',
    'FAT-190-001 Acme Ltd 1200 TRY KDV 20',
    to_tsvector('simple', 'FAT-190-001 Acme Ltd 1200 TRY KDV 20'),
    'ACTIVE',
    'evt_190_001',
    now(),
    1,
    10.0000,
    '{"document_no":"FAT-190-001","gross_amount":1200}'::jsonb
  );

  INSERT INTO search_index_terms (
    tenant_id,
    term_id,
    search_document_id,
    entity_type,
    term,
    normalized_term,
    term_type,
    weight
  ) VALUES (
    'tenant_test_190',
    'term_190_001',
    'doc_190_invoice_001',
    'FINANCE_DOCUMENT',
    'FAT-190-001',
    'fat-190-001',
    'DOCUMENT_NO',
    8.0000
  );

  INSERT INTO finance_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN'
  );

  INSERT INTO finance_account_balances_mart (
    tenant_id,
    period_id,
    account_code,
    account_name,
    account_type,
    currency_code,
    period_debit,
    period_credit,
    closing_debit,
    closing_credit,
    source_event_id
  ) VALUES
    (
      'tenant_test_190',
      'period_2026_05',
      '120',
      'Alıcılar',
      'RECEIVABLE',
      'TRY',
      1200.00,
      0.00,
      1200.00,
      0.00,
      'evt_190_001'
    ),
    (
      'tenant_test_190',
      'period_2026_05',
      '600',
      'Yurtiçi Satışlar',
      'REVENUE',
      'TRY',
      0.00,
      1000.00,
      0.00,
      1000.00,
      'evt_190_001'
    ),
    (
      'tenant_test_190',
      'period_2026_05',
      '391.01.20',
      'Hesaplanan KDV %20',
      'TAX',
      'TRY',
      0.00,
      200.00,
      0.00,
      200.00,
      'evt_190_001'
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
    source_document_count
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    'tax_190_kdv_20',
    'KDV',
    20.00,
    1000.00,
    200.00,
    'OUTPUT',
    'TRY',
    1
  );

  INSERT INTO payment_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN'
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
    source_event_id
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    'pay_190_001',
    'SIMULATION',
    'CARD',
    'CAPTURE',
    'CAPTURED',
    1200.00,
    'TRY',
    'prov_190_001',
    'idem_190_001',
    'corr_190_001',
    'evt_190_001'
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
    matched_at
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    'recon_190_001',
    'SIMULATION',
    'pay_190_001',
    'prov_190_001',
    1200.00,
    1200.00,
    0.00,
    'TRY',
    'MATCHED',
    now()
  );

  INSERT INTO e_document_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN'
  );

  INSERT INTO e_document_documents_mart (
    tenant_id,
    period_id,
    e_document_id,
    document_type,
    document_no,
    document_uuid,
    scenario_type,
    direction,
    document_status,
    issue_date,
    party_id,
    party_name,
    tax_no,
    currency_code,
    net_amount,
    tax_amount,
    gross_amount,
    source_event_id,
    source_document_ref
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    'edoc_190_001',
    'E_FATURA',
    'EF190000000001',
    'uuid-190-001',
    'COMMERCIAL',
    'OUTBOUND',
    'ACCEPTED',
    DATE '2026-05-08',
    'customer_190_001',
    'Acme Ltd',
    '1234567890',
    'TRY',
    1000.00,
    200.00,
    1200.00,
    'evt_190_001',
    'FAT-190-001'
  );

  INSERT INTO e_document_status_summary_mart (
    tenant_id,
    period_id,
    summary_id,
    document_type,
    document_status,
    direction,
    document_count,
    total_net_amount,
    total_tax_amount,
    total_gross_amount,
    currency_code
  ) VALUES (
    'tenant_test_190',
    'period_2026_05',
    'summary_190_001',
    'E_FATURA',
    'ACCEPTED',
    'OUTBOUND',
    1,
    1000.00,
    200.00,
    1200.00,
    'TRY'
  );

  INSERT INTO materialized_projection_definitions (
    tenant_id,
    projection_name,
    projection_type,
    source_domain,
    refresh_strategy,
    cache_strategy,
    ttl_seconds,
    stale_after_seconds,
    owner_team,
    metadata
  ) VALUES (
    'tenant_test_190',
    'pilot_reporting_dashboard_projection',
    'HYBRID',
    'REPORTING',
    'EVENT_DRIVEN',
    'POSTGRES',
    600,
    120,
    'platform',
    '{"test":"FAZ_4_15_7"}'::jsonb
  );

  INSERT INTO projection_cache_profiles (
    tenant_id,
    cache_profile_id,
    projection_name,
    cache_backend,
    ttl_seconds,
    stale_after_seconds,
    max_entries,
    invalidation_strategy
  ) VALUES (
    'tenant_test_190',
    'cache_profile_190_001',
    'pilot_reporting_dashboard_projection',
    'POSTGRES',
    600,
    120,
    10000,
    'EVENT_DRIVEN'
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
    projection_version
  ) VALUES (
    'tenant_test_190',
    'cache:pilot_reporting_dashboard:tenant_test_190:period_2026_05',
    'pilot_reporting_dashboard_projection',
    'cache_profile_190_001',
    'REPORTING_DASHBOARD',
    'period_2026_05',
    'ACTIVE',
    '{"finance_gross":1200,"payment_gross":1200,"edoc_gross":1200}'::jsonb,
    'payload_hash_190_001',
    now() + interval '10 minutes',
    4,
    'evt_190_001',
    1
  );

  REFRESH MATERIALIZED VIEW mv_projection_cache_health;

  SELECT COUNT(*) INTO v_search_count
  FROM search_index_documents
  WHERE tenant_id = 'tenant_test_190'
    AND search_vector @@ to_tsquery('simple', 'Acme');

  IF v_search_count <> 1 THEN
    RAISE EXCEPTION 'search readmodel count mismatch: %', v_search_count;
  END IF;

  SELECT COUNT(*) INTO v_finance_balance_count
  FROM finance_account_balances_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05';

  IF v_finance_balance_count <> 3 THEN
    RAISE EXCEPTION 'finance balance count mismatch: %', v_finance_balance_count;
  END IF;

  SELECT COUNT(*) INTO v_payment_count
  FROM payment_reconciliation_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05'
    AND reconciliation_status = 'MATCHED';

  IF v_payment_count <> 1 THEN
    RAISE EXCEPTION 'payment reconciliation count mismatch: %', v_payment_count;
  END IF;

  SELECT COUNT(*) INTO v_edoc_count
  FROM e_document_documents_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05'
    AND document_status = 'ACCEPTED';

  IF v_edoc_count <> 1 THEN
    RAISE EXCEPTION 'e-document count mismatch: %', v_edoc_count;
  END IF;

  SELECT COUNT(*), COALESCE(SUM(total_hit_count), 0)
  INTO v_cache_health_count, v_total_cache_hit
  FROM mv_projection_cache_health
  WHERE tenant_id = 'tenant_test_190'
    AND projection_name = 'pilot_reporting_dashboard_projection';

  IF v_cache_health_count <> 1 THEN
    RAISE EXCEPTION 'cache health count mismatch: %', v_cache_health_count;
  END IF;

  IF v_total_cache_hit <> 4 THEN
    RAISE EXCEPTION 'cache health hit mismatch: %', v_total_cache_hit;
  END IF;

  SELECT closing_debit INTO v_cross_gross_finance
  FROM finance_account_balances_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05'
    AND account_code = '120';

  SELECT internal_amount INTO v_cross_gross_payment
  FROM payment_reconciliation_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05'
    AND reconciliation_id = 'recon_190_001';

  SELECT gross_amount INTO v_cross_gross_edoc
  FROM e_document_documents_mart
  WHERE tenant_id = 'tenant_test_190'
    AND period_id = 'period_2026_05'
    AND e_document_id = 'edoc_190_001';

  IF v_cross_gross_finance <> 1200.00
     OR v_cross_gross_payment <> 1200.00
     OR v_cross_gross_edoc <> 1200.00 THEN
    RAISE EXCEPTION 'cross readmodel gross mismatch: finance %, payment %, edoc %',
      v_cross_gross_finance,
      v_cross_gross_payment,
      v_cross_gross_edoc;
  END IF;

  BEGIN
    INSERT INTO projection_cache_entries (
      tenant_id,
      cache_key,
      projection_name,
      entity_type,
      entity_id
    ) VALUES (
      'tenant_test_190',
      'cache:orphan:190',
      'missing_projection_190',
      'REPORTING_DASHBOARD',
      'orphan'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'cross readmodel FK guard did not work';
  END IF;
END
$$;

-- READMODEL_REPORTING_TEST_SET_SQL_TEST_IMPLEMENTED
