-- 181 — FAZ 4-14.7 Migration / Lifecycle / Import Testleri
-- This SQL body is executed by the audit script inside a generated temporary schema.
-- The audit script injects:
--   1. temp schema creation
--   2. latest FAZ 4-14.3 migration SQL
--   3. this lifecycle test SQL
--   4. rollback

DO $$
DECLARE
  v_batch_count INTEGER;
  v_file_count INTEGER;
  v_row_count INTEGER;
  v_customer_count INTEGER;
  v_product_count INTEGER;
  v_stock_count INTEGER;
  v_finance_count INTEGER;
  v_error_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_status TEXT;
  v_commit_status TEXT;
BEGIN
  INSERT INTO import_batches (
    tenant_id,
    import_batch_id,
    import_type,
    source_name,
    source_checksum,
    dry_run,
    status,
    total_rows,
    valid_rows,
    invalid_rows,
    duplicate_rows,
    committed_rows,
    failed_rows,
    created_by,
    correlation_id,
    metadata,
    started_at
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    'MIXED',
    'pilot_import_fixture.xlsx',
    'checksum_181_001',
    TRUE,
    'CREATED',
    5,
    0,
    0,
    0,
    0,
    0,
    'system_test',
    'corr_181_001',
    '{"phase":"FAZ_4_14_7","test":"lifecycle"}'::jsonb,
    now()
  );

  INSERT INTO import_source_files (
    tenant_id,
    import_batch_id,
    file_id,
    file_name,
    file_mime_type,
    file_size_bytes,
    source_checksum,
    storage_reference,
    parse_status,
    metadata
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    'file_181_001',
    'pilot_import_fixture.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    2048,
    'checksum_181_001',
    'local://tests/faz4r/pilot_import_fixture.xlsx',
    'PARSED',
    '{"sheet_count":4}'::jsonb
  );

  INSERT INTO import_staging_rows (
    tenant_id,
    import_batch_id,
    row_number,
    entity_type,
    source_file_id,
    source_row,
    normalized_row,
    row_hash,
    validation_status,
    transform_status,
    commit_status
  ) VALUES
    (
      'tenant_test_181',
      'batch_181_001',
      1,
      'CUSTOMER',
      'file_181_001',
      '{"customer_name":"Acme Ltd","tax_no":"1234567890"}'::jsonb,
      '{"customer_name":"Acme Ltd","tax_no":"1234567890"}'::jsonb,
      'hash_customer_001',
      'VALID',
      'TRANSFORMED',
      'COMMIT_READY'
    ),
    (
      'tenant_test_181',
      'batch_181_001',
      2,
      'PRODUCT',
      'file_181_001',
      '{"product_name":"Yag Filtresi","barcode":"869000000001"}'::jsonb,
      '{"product_name":"Yag Filtresi","barcode":"869000000001"}'::jsonb,
      'hash_product_001',
      'VALID',
      'TRANSFORMED',
      'COMMIT_READY'
    ),
    (
      'tenant_test_181',
      'batch_181_001',
      3,
      'STOCK',
      'file_181_001',
      '{"product_code":"PRD001","quantity":10}'::jsonb,
      '{"product_code":"PRD001","quantity":10}'::jsonb,
      'hash_stock_001',
      'VALID',
      'TRANSFORMED',
      'COMMIT_READY'
    ),
    (
      'tenant_test_181',
      'batch_181_001',
      4,
      'FINANCE_DOCUMENT',
      'file_181_001',
      '{"document_no":"FAT-001","total_amount":1200}'::jsonb,
      '{"document_no":"FAT-001","total_amount":1200}'::jsonb,
      'hash_finance_001',
      'VALID',
      'TRANSFORMED',
      'COMMIT_READY'
    ),
    (
      'tenant_test_181',
      'batch_181_001',
      5,
      'CUSTOMER',
      'file_181_001',
      '{"customer_name":"","tax_no":""}'::jsonb,
      '{"customer_name":"","tax_no":""}'::jsonb,
      'hash_customer_invalid_001',
      'INVALID',
      'TRANSFORM_FAILED',
      'SKIPPED'
    );

  INSERT INTO import_staging_customers (
    tenant_id,
    import_batch_id,
    row_number,
    customer_code,
    customer_name,
    customer_type,
    tax_no,
    tax_office,
    phone,
    email,
    address_line,
    city,
    district,
    raw_data,
    validation_status
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    1,
    'CARI001',
    'Acme Ltd',
    'COMMERCIAL',
    '1234567890',
    'Kadikoy',
    '+902120000000',
    'test@example.com',
    'Test Mahallesi',
    'Istanbul',
    'Kadikoy',
    '{"fixture":true}'::jsonb,
    'VALID'
  );

  INSERT INTO import_staging_products (
    tenant_id,
    import_batch_id,
    row_number,
    product_code,
    barcode,
    product_name,
    product_type,
    unit_code,
    vat_rate,
    category_code,
    brand,
    oem_code,
    equivalent_code,
    raw_data,
    validation_status
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    2,
    'PRD001',
    '869000000001',
    'Yag Filtresi',
    'STOCK_ITEM',
    'ADET',
    20.00,
    'OTO',
    'PIX',
    'OEM001',
    'EQ001',
    '{"fixture":true}'::jsonb,
    'VALID'
  );

  INSERT INTO import_staging_stock_entries (
    tenant_id,
    import_batch_id,
    row_number,
    product_code,
    warehouse_code,
    movement_type,
    quantity,
    unit_code,
    document_no,
    document_date,
    source_reference,
    raw_data,
    validation_status
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    3,
    'PRD001',
    'MAIN',
    'OPENING',
    10.0000,
    'ADET',
    'STK-OPEN-001',
    CURRENT_DATE,
    'fixture_stock_opening',
    '{"fixture":true}'::jsonb,
    'VALID'
  );

  INSERT INTO import_staging_finance_documents (
    tenant_id,
    import_batch_id,
    row_number,
    document_type,
    document_no,
    document_date,
    customer_code,
    tax_no,
    currency_code,
    net_amount,
    vat_amount,
    total_amount,
    source_reference,
    raw_data,
    validation_status
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    4,
    'SALES_INVOICE',
    'FAT-001',
    CURRENT_DATE,
    'CARI001',
    '1234567890',
    'TRY',
    1000.00,
    200.00,
    1200.00,
    'fixture_invoice',
    '{"fixture":true}'::jsonb,
    'VALID'
  );

  INSERT INTO import_validation_errors (
    tenant_id,
    import_batch_id,
    row_number,
    error_id,
    entity_type,
    field_name,
    error_code,
    error_message,
    severity,
    raw_value,
    metadata
  ) VALUES (
    'tenant_test_181',
    'batch_181_001',
    5,
    'err_181_001',
    'CUSTOMER',
    'customer_name',
    'CUSTOMER_NAME_REQUIRED',
    'Cari adı zorunludur.',
    'BLOCKER',
    '',
    '{"fixture":true}'::jsonb
  );

  INSERT INTO import_audit_events (
    tenant_id,
    import_batch_id,
    audit_event_id,
    event_type,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES
    (
      'tenant_test_181',
      'batch_181_001',
      'audit_181_001',
      'IMPORT_BATCH_CREATED',
      'system_test',
      'corr_181_001',
      '{"status":"CREATED"}'::jsonb
    ),
    (
      'tenant_test_181',
      'batch_181_001',
      'audit_181_002',
      'IMPORT_VALIDATION_COMPLETED',
      'system_test',
      'corr_181_001',
      '{"valid_rows":4,"invalid_rows":1}'::jsonb
    );

  UPDATE import_batches
  SET
    status = 'VALIDATED',
    valid_rows = 4,
    invalid_rows = 1,
    updated_at = now()
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  UPDATE import_staging_rows
  SET commit_status = 'COMMITTED'
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001'
    AND validation_status = 'VALID';

  UPDATE import_batches
  SET
    status = 'COMMITTED',
    committed_rows = 4,
    completed_at = now(),
    updated_at = now()
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  SELECT COUNT(*) INTO v_batch_count
  FROM import_batches
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_batch_count <> 1 THEN
    RAISE EXCEPTION 'import batch count mismatch: %', v_batch_count;
  END IF;

  SELECT COUNT(*) INTO v_file_count
  FROM import_source_files
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_file_count <> 1 THEN
    RAISE EXCEPTION 'import source file count mismatch: %', v_file_count;
  END IF;

  SELECT COUNT(*) INTO v_row_count
  FROM import_staging_rows
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_row_count <> 5 THEN
    RAISE EXCEPTION 'import staging row count mismatch: %', v_row_count;
  END IF;

  SELECT COUNT(*) INTO v_customer_count
  FROM import_staging_customers
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_customer_count <> 1 THEN
    RAISE EXCEPTION 'customer staging count mismatch: %', v_customer_count;
  END IF;

  SELECT COUNT(*) INTO v_product_count
  FROM import_staging_products
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_product_count <> 1 THEN
    RAISE EXCEPTION 'product staging count mismatch: %', v_product_count;
  END IF;

  SELECT COUNT(*) INTO v_stock_count
  FROM import_staging_stock_entries
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_stock_count <> 1 THEN
    RAISE EXCEPTION 'stock staging count mismatch: %', v_stock_count;
  END IF;

  SELECT COUNT(*) INTO v_finance_count
  FROM import_staging_finance_documents
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_finance_count <> 1 THEN
    RAISE EXCEPTION 'finance staging count mismatch: %', v_finance_count;
  END IF;

  SELECT COUNT(*) INTO v_error_count
  FROM import_validation_errors
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001'
    AND severity = 'BLOCKER';

  IF v_error_count <> 1 THEN
    RAISE EXCEPTION 'validation error count mismatch: %', v_error_count;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM import_audit_events
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_audit_count <> 2 THEN
    RAISE EXCEPTION 'audit event count mismatch: %', v_audit_count;
  END IF;

  SELECT status INTO v_status
  FROM import_batches
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001';

  IF v_status <> 'COMMITTED' THEN
    RAISE EXCEPTION 'batch lifecycle final status mismatch: %', v_status;
  END IF;

  SELECT commit_status INTO v_commit_status
  FROM import_staging_rows
  WHERE tenant_id = 'tenant_test_181'
    AND import_batch_id = 'batch_181_001'
    AND row_number = 1;

  IF v_commit_status <> 'COMMITTED' THEN
    RAISE EXCEPTION 'row commit status mismatch: %', v_commit_status;
  END IF;

  BEGIN
    INSERT INTO import_staging_customers (
      tenant_id,
      import_batch_id,
      row_number,
      customer_name
    ) VALUES (
      'tenant_test_181',
      'batch_181_001',
      999,
      'FK Guard Must Fail'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'foreign key guard did not block orphan customer staging row';
  END IF;
END
$$;

-- LIFECYCLE_IMPORT_TESTS_IMPLEMENTED
