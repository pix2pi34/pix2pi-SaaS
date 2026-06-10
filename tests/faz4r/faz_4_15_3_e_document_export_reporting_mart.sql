-- 188 — FAZ 4-15.3 e-Belge / Export Reporting Mart behavior test body
-- Audit script injects temporary schema and latest 188 migration before this block.

DO $$
DECLARE
  v_period_count INTEGER;
  v_document_count INTEGER;
  v_export_batch_count INTEGER;
  v_export_file_count INTEGER;
  v_summary_count INTEGER;
  v_offset_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_total_gross NUMERIC(18,2);
  v_file_count INTEGER;
BEGIN
  INSERT INTO e_document_report_periods (
    tenant_id,
    period_id,
    fiscal_year,
    fiscal_month,
    period_start,
    period_end,
    status,
    metadata
  ) VALUES (
    'tenant_test_188',
    'period_2026_05',
    2026,
    5,
    DATE '2026-05-01',
    DATE '2026-05-31',
    'OPEN',
    '{"fixture":true}'::jsonb
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
    source_document_ref,
    metadata
  ) VALUES (
    'tenant_test_188',
    'period_2026_05',
    'edoc_188_001',
    'E_FATURA',
    'EF2026000000001',
    'uuid-188-001',
    'COMMERCIAL',
    'OUTBOUND',
    'ACCEPTED',
    DATE '2026-05-08',
    'customer_001',
    'Acme Ltd',
    '1234567890',
    'TRY',
    1000.00,
    200.00,
    1200.00,
    'evt_edoc_188_001',
    'FAT-001',
    '{"fixture":true,"vat_rate":20}'::jsonb
  );

  INSERT INTO e_document_export_batches_mart (
    tenant_id,
    period_id,
    export_batch_id,
    export_type,
    target_system,
    export_status,
    file_count,
    document_count,
    total_net_amount,
    total_tax_amount,
    total_gross_amount,
    requested_by,
    correlation_id,
    started_at,
    completed_at,
    metadata
  ) VALUES (
    'tenant_test_188',
    'period_2026_05',
    'export_batch_188_001',
    'LOGO',
    'LOGO',
    'COMPLETED',
    1,
    1,
    1000.00,
    200.00,
    1200.00,
    'system_test',
    'corr_188_001',
    now(),
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO e_document_export_files_mart (
    tenant_id,
    period_id,
    export_batch_id,
    export_file_id,
    file_name,
    file_type,
    file_size_bytes,
    file_checksum,
    storage_reference,
    document_count,
    export_status,
    metadata
  ) VALUES (
    'tenant_test_188',
    'period_2026_05',
    'export_batch_188_001',
    'export_file_188_001',
    'logo_export_2026_05.xml',
    'XML',
    2048,
    'checksum_188_001',
    'local://exports/logo_export_2026_05.xml',
    1,
    'VERIFIED',
    '{"fixture":true}'::jsonb
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
    currency_code,
    metadata
  ) VALUES (
    'tenant_test_188',
    'period_2026_05',
    'summary_188_001',
    'E_FATURA',
    'ACCEPTED',
    'OUTBOUND',
    1,
    1000.00,
    200.00,
    1200.00,
    'TRY',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO e_document_reporting_projection_offsets (
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
    'tenant_test_188',
    'e_document_reporting_projection',
    'E_DOCUMENT_EVENTS',
    'e_document_reporting_consumer',
    'evt_edoc_188_001',
    400,
    'ACTIVE',
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO e_document_reporting_audit_events (
    tenant_id,
    audit_event_id,
    projection_name,
    event_type,
    period_id,
    document_type,
    e_document_id,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES (
    'tenant_test_188',
    'audit_edoc_188_001',
    'e_document_reporting_projection',
    'E_DOCUMENT_PROJECTED',
    'period_2026_05',
    'E_FATURA',
    'edoc_188_001',
    'system_test',
    'corr_188_001',
    '{"document_no":"EF2026000000001"}'::jsonb
  );

  UPDATE e_document_report_periods
  SET status = 'LOCKED',
      locked_at = now(),
      locked_by = 'system_test',
      updated_at = now()
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05';

  SELECT COUNT(*) INTO v_period_count
  FROM e_document_report_periods
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND status = 'LOCKED';

  IF v_period_count <> 1 THEN
    RAISE EXCEPTION 'e-document period count mismatch: %', v_period_count;
  END IF;

  SELECT COUNT(*) INTO v_document_count
  FROM e_document_documents_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND document_type = 'E_FATURA'
    AND document_status = 'ACCEPTED';

  IF v_document_count <> 1 THEN
    RAISE EXCEPTION 'e-document count mismatch: %', v_document_count;
  END IF;

  SELECT total_gross_amount INTO v_total_gross
  FROM e_document_export_batches_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND export_batch_id = 'export_batch_188_001';

  IF v_total_gross <> 1200.00 THEN
    RAISE EXCEPTION 'export batch gross amount mismatch: %', v_total_gross;
  END IF;

  SELECT file_count INTO v_file_count
  FROM e_document_export_batches_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND export_batch_id = 'export_batch_188_001';

  IF v_file_count <> 1 THEN
    RAISE EXCEPTION 'export batch file count mismatch: %', v_file_count;
  END IF;

  SELECT COUNT(*) INTO v_export_batch_count
  FROM e_document_export_batches_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND export_status = 'COMPLETED';

  IF v_export_batch_count <> 1 THEN
    RAISE EXCEPTION 'export batch count mismatch: %', v_export_batch_count;
  END IF;

  SELECT COUNT(*) INTO v_export_file_count
  FROM e_document_export_files_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND export_batch_id = 'export_batch_188_001'
    AND export_status = 'VERIFIED';

  IF v_export_file_count <> 1 THEN
    RAISE EXCEPTION 'export file count mismatch: %', v_export_file_count;
  END IF;

  SELECT COUNT(*) INTO v_summary_count
  FROM e_document_status_summary_mart
  WHERE tenant_id = 'tenant_test_188'
    AND period_id = 'period_2026_05'
    AND document_type = 'E_FATURA'
    AND document_status = 'ACCEPTED'
    AND total_gross_amount = 1200.00;

  IF v_summary_count <> 1 THEN
    RAISE EXCEPTION 'status summary count mismatch: %', v_summary_count;
  END IF;

  SELECT COUNT(*) INTO v_offset_count
  FROM e_document_reporting_projection_offsets
  WHERE tenant_id = 'tenant_test_188'
    AND projection_name = 'e_document_reporting_projection'
    AND last_sequence = 400;

  IF v_offset_count <> 1 THEN
    RAISE EXCEPTION 'e-document reporting offset count mismatch: %', v_offset_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM e_document_reporting_audit_events
  WHERE tenant_id = 'tenant_test_188'
    AND event_type = 'E_DOCUMENT_PROJECTED';

  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'e-document reporting audit count mismatch: %', v_audit_count;
  END IF;

  BEGIN
    INSERT INTO e_document_documents_mart (
      tenant_id,
      period_id,
      e_document_id,
      document_type,
      document_no,
      direction,
      issue_date
    ) VALUES (
      'tenant_test_188',
      'missing_period',
      'edoc_orphan_188',
      'E_FATURA',
      'ORPHAN-188',
      'OUTBOUND',
      DATE '2026-05-08'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'e-document reporting mart FK guard did not work';
  END IF;
END
$$;

-- E_DOCUMENT_EXPORT_REPORTING_MART_SQL_TEST_IMPLEMENTED
