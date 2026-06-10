-- 185 — FAZ 4-15.5 Search / Index Projection Tabloları behavior test body
-- Audit script injects temporary schema and latest 185 migration before this block.

DO $$
DECLARE
  v_doc_count INTEGER;
  v_term_count INTEGER;
  v_offset_count INTEGER;
  v_job_count INTEGER;
  v_audit_count INTEGER;
  v_fk_guard_ok BOOLEAN := FALSE;
  v_status TEXT;
BEGIN
  INSERT INTO search_projection_sources (
    tenant_id,
    projection_source_id,
    source_type,
    source_name,
    source_version,
    is_active,
    last_event_id,
    metadata
  ) VALUES (
    'tenant_test_185',
    'source_customer_001',
    'CUSTOMER',
    'customer_projection',
    'v1',
    TRUE,
    'evt_185_001',
    '{"fixture":true}'::jsonb
  );

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
    'tenant_test_185',
    'doc_customer_001',
    'CUSTOMER',
    'customer_001',
    'CARI001',
    'Acme Ltd',
    'Vergi No 1234567890',
    'Acme Ltd CARI001 1234567890 Istanbul Kadikoy',
    to_tsvector('simple', 'Acme Ltd CARI001 1234567890 Istanbul Kadikoy'),
    'ACTIVE',
    'evt_185_001',
    now(),
    1,
    10.5000,
    '{"customer_code":"CARI001","tax_no":"1234567890","city":"Istanbul"}'::jsonb
  );

  INSERT INTO search_index_terms (
    tenant_id,
    term_id,
    search_document_id,
    entity_type,
    term,
    normalized_term,
    term_type,
    weight,
    metadata
  ) VALUES
    (
      'tenant_test_185',
      'term_185_001',
      'doc_customer_001',
      'CUSTOMER',
      'Acme Ltd',
      'acme ltd',
      'TEXT',
      1.0000,
      '{"fixture":true}'::jsonb
    ),
    (
      'tenant_test_185',
      'term_185_002',
      'doc_customer_001',
      'CUSTOMER',
      'CARI001',
      'cari001',
      'CODE',
      5.0000,
      '{"fixture":true}'::jsonb
    ),
    (
      'tenant_test_185',
      'term_185_003',
      'doc_customer_001',
      'CUSTOMER',
      '1234567890',
      '1234567890',
      'TAX_NO',
      8.0000,
      '{"fixture":true}'::jsonb
    );

  INSERT INTO search_projection_offsets (
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
    'tenant_test_185',
    'search_customer_projection',
    'ERP_EVENTS',
    'search_projection_consumer',
    'evt_185_001',
    100,
    'ACTIVE',
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  INSERT INTO search_projection_rebuild_jobs (
    tenant_id,
    rebuild_job_id,
    projection_name,
    scope_type,
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
    'tenant_test_185',
    'rebuild_185_001',
    'search_customer_projection',
    'ENTITY_TYPE',
    'CUSTOMER',
    'RUNNING',
    'system_test',
    'corr_185_001',
    1,
    0,
    0,
    now(),
    '{"fixture":true}'::jsonb
  );

  UPDATE search_projection_rebuild_jobs
  SET
    status = 'COMPLETED',
    processed_items = 1,
    completed_at = now(),
    updated_at = now()
  WHERE tenant_id = 'tenant_test_185'
    AND rebuild_job_id = 'rebuild_185_001';

  INSERT INTO search_projection_audit_events (
    tenant_id,
    audit_event_id,
    projection_name,
    event_type,
    entity_type,
    entity_id,
    actor_id,
    correlation_id,
    event_payload
  ) VALUES (
    'tenant_test_185',
    'audit_185_001',
    'search_customer_projection',
    'SEARCH_DOCUMENT_INDEXED',
    'CUSTOMER',
    'customer_001',
    'system_test',
    'corr_185_001',
    '{"document_id":"doc_customer_001"}'::jsonb
  );

  SELECT COUNT(*) INTO v_doc_count
  FROM search_index_documents
  WHERE tenant_id = 'tenant_test_185'
    AND entity_type = 'CUSTOMER'
    AND status = 'ACTIVE'
    AND search_vector @@ to_tsquery('simple', 'acme');

  IF v_doc_count <> 1 THEN
    RAISE EXCEPTION 'search document count mismatch: %', v_doc_count;
  END IF;

  SELECT COUNT(*) INTO v_term_count
  FROM search_index_terms
  WHERE tenant_id = 'tenant_test_185'
    AND search_document_id = 'doc_customer_001';

  IF v_term_count <> 3 THEN
    RAISE EXCEPTION 'search term count mismatch: %', v_term_count;
  END IF;

  SELECT COUNT(*) INTO v_offset_count
  FROM search_projection_offsets
  WHERE tenant_id = 'tenant_test_185'
    AND projection_name = 'search_customer_projection'
    AND last_sequence = 100;

  IF v_offset_count <> 1 THEN
    RAISE EXCEPTION 'projection offset count mismatch: %', v_offset_count;
  END IF;

  SELECT status INTO v_status
  FROM search_projection_rebuild_jobs
  WHERE tenant_id = 'tenant_test_185'
    AND rebuild_job_id = 'rebuild_185_001';

  IF v_status <> 'COMPLETED' THEN
    RAISE EXCEPTION 'rebuild job status mismatch: %', v_status;
  END IF;

  SELECT COUNT(*) INTO v_audit_count
  FROM search_projection_audit_events
  WHERE tenant_id = 'tenant_test_185'
    AND event_type = 'SEARCH_DOCUMENT_INDEXED';

  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'search audit count mismatch: %', v_audit_count;
  END IF;

  BEGIN
    INSERT INTO search_index_terms (
      tenant_id,
      term_id,
      search_document_id,
      entity_type,
      term,
      normalized_term
    ) VALUES (
      'tenant_test_185',
      'term_orphan_185',
      'missing_doc_185',
      'CUSTOMER',
      'orphan',
      'orphan'
    );
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_guard_ok := TRUE;
  END;

  IF v_fk_guard_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'search term foreign key guard did not work';
  END IF;
END
$$;

-- SEARCH_INDEX_PROJECTION_TABLES_SQL_TEST_IMPLEMENTED
