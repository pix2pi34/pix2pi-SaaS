#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
DOC_FILE="docs/faz4r/FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD.md"
CONFIG_FILE="configs/faz4r/faz_4_14_4_backfill_rebuild_script_standard.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/run_import_batch_backfill_rebuild.sh"
SQL_TEST_FILE="tests/faz4r/faz_4_14_4_backfill_rebuild_script_standard.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

record_warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "$1 OPTIONAL_WARN / WARN ⚠️"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_executable() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

latest_180_migration_file() {
  find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*_faz_4_14_3_import_staging_tables.sql" | sort | tail -n 1
}

load_env_files() {
  set +u
  if [ -f ".env" ]; then
    source ".env"
  fi
  if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
    source "/opt/pix2pi/orchestrator/env/common.env"
  fi
  if [ -f "/etc/pix2pi/ports.env" ]; then
    source "/etc/pix2pi/ports.env"
  fi
  set -u
}

resolve_db_dsn() {
  load_env_files

  if [ -n "${DB_WRITE_DSN:-}" ]; then
    echo "$DB_WRITE_DSN"
    return 0
  fi

  if [ -n "${DATABASE_URL:-}" ]; then
    echo "$DATABASE_URL"
    return 0
  fi

  if [ -n "${POSTGRES_DSN:-}" ]; then
    echo "$POSTGRES_DSN"
    return 0
  fi

  if [ -n "${PIX2PI_DB_DSN:-}" ]; then
    echo "$PIX2PI_DB_DSN"
    return 0
  fi

  echo ""
  return 1
}

run_backfill_rebuild_behavior_test() {
  local migration_file="$1"
  local dsn="$2"

  local test_schema="faz_4_14_4_rebuild_test_$(date +%Y%m%d_%H%M%S)_$$"
  local setup_sql="/tmp/faz_4_14_4_setup_${test_schema}.sql"
  local verify_dry_sql="/tmp/faz_4_14_4_verify_dry_${test_schema}.sql"
  local verify_apply_sql="/tmp/faz_4_14_4_verify_apply_${test_schema}.sql"
  local cleanup_sql="/tmp/faz_4_14_4_cleanup_${test_schema}.sql"
  local out_file="/tmp/faz_4_14_4_rebuild_test_${test_schema}.out"

  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
    return 1
  fi
  record_pass "psql command availability"

  cat > "$setup_sql" <<SQL_SETUP_EOF
\\set ON_ERROR_STOP on

DROP SCHEMA IF EXISTS ${test_schema} CASCADE;
CREATE SCHEMA ${test_schema};
SET search_path TO ${test_schema}, public;

$(sed 's/public\./'"${test_schema}"'./g' "$migration_file")

INSERT INTO ${test_schema}.import_batches (
  tenant_id,
  import_batch_id,
  import_type,
  source_name,
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
  metadata
) VALUES (
  'tenant_test_182',
  'batch_182_001',
  'MIXED',
  'backfill_fixture.xlsx',
  TRUE,
  'CREATED',
  0,
  0,
  0,
  0,
  0,
  0,
  'system_test',
  'corr_182_001',
  '{"phase":"FAZ_4_14_4"}'::jsonb
);

INSERT INTO ${test_schema}.import_staging_rows (
  tenant_id,
  import_batch_id,
  row_number,
  entity_type,
  source_row,
  normalized_row,
  row_hash,
  validation_status,
  transform_status,
  commit_status
) VALUES
  (
    'tenant_test_182',
    'batch_182_001',
    1,
    'CUSTOMER',
    '{"customer_name":"Valid Customer"}'::jsonb,
    '{"customer_name":"Valid Customer"}'::jsonb,
    'hash_182_001',
    'PENDING',
    'TRANSFORMED',
    'COMMITTED'
  ),
  (
    'tenant_test_182',
    'batch_182_001',
    2,
    'PRODUCT',
    '{"product_name":""}'::jsonb,
    '{"product_name":""}'::jsonb,
    'hash_182_002',
    'PENDING',
    'TRANSFORM_FAILED',
    'COMMIT_FAILED'
  ),
  (
    'tenant_test_182',
    'batch_182_001',
    3,
    'STOCK',
    '{"product_code":"PRD001","quantity":5}'::jsonb,
    '{"product_code":"PRD001","quantity":5}'::jsonb,
    'hash_182_003',
    'DUPLICATE',
    'TRANSFORMED',
    'SKIPPED'
  );

INSERT INTO ${test_schema}.import_validation_errors (
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
  'tenant_test_182',
  'batch_182_001',
  2,
  'err_182_001',
  'PRODUCT',
  'product_name',
  'PRODUCT_NAME_REQUIRED',
  'Ürün adı zorunludur.',
  'BLOCKER',
  '',
  '{"fixture":true}'::jsonb
);
SQL_SETUP_EOF

  if ! psql "$dsn" -v ON_ERROR_STOP=1 -f "$setup_sql" > "$out_file" 2>&1; then
    record_fail "PostgreSQL rebuild fixture setup"
    cat "$out_file" || true
    return 1
  fi
  record_pass "PostgreSQL rebuild fixture setup"

  if TENANT_ID="tenant_test_182" IMPORT_BATCH_ID="batch_182_001" SCHEMA="$test_schema" APPLY=0 "$RUNTIME_SCRIPT" >> "$out_file" 2>&1; then
    record_pass "backfill rebuild dry-run execution"
  else
    record_fail "backfill rebuild dry-run execution"
    cat "$out_file" || true
    return 1
  fi

  cat > "$verify_dry_sql" <<SQL_DRY_EOF
\\set ON_ERROR_STOP on

DO \$\$
DECLARE
  v_total INTEGER;
  v_valid INTEGER;
  v_invalid INTEGER;
BEGIN
  SELECT total_rows, valid_rows, invalid_rows
  INTO v_total, v_valid, v_invalid
  FROM ${test_schema}.import_batches
  WHERE tenant_id = 'tenant_test_182'
    AND import_batch_id = 'batch_182_001';

  IF v_total <> 0 OR v_valid <> 0 OR v_invalid <> 0 THEN
    RAISE EXCEPTION 'dry-run mutated counters: total %, valid %, invalid %', v_total, v_valid, v_invalid;
  END IF;
END
\$\$;
SQL_DRY_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$verify_dry_sql" >> "$out_file" 2>&1; then
    record_pass "dry-run no mutation verification"
  else
    record_fail "dry-run no mutation verification"
    cat "$out_file" || true
    return 1
  fi

  if TENANT_ID="tenant_test_182" IMPORT_BATCH_ID="batch_182_001" SCHEMA="$test_schema" APPLY=1 "$RUNTIME_SCRIPT" >> "$out_file" 2>&1; then
    record_pass "backfill rebuild apply execution"
  else
    record_fail "backfill rebuild apply execution"
    cat "$out_file" || true
    return 1
  fi

  cat > "$verify_apply_sql" <<SQL_APPLY_VERIFY_EOF
\\set ON_ERROR_STOP on

DO \$\$
DECLARE
  v_total INTEGER;
  v_valid INTEGER;
  v_invalid INTEGER;
  v_duplicate INTEGER;
  v_committed INTEGER;
  v_failed INTEGER;
  v_row1_status TEXT;
  v_row2_status TEXT;
  v_row2_error_count INTEGER;
BEGIN
  SELECT
    total_rows,
    valid_rows,
    invalid_rows,
    duplicate_rows,
    committed_rows,
    failed_rows
  INTO
    v_total,
    v_valid,
    v_invalid,
    v_duplicate,
    v_committed,
    v_failed
  FROM ${test_schema}.import_batches
  WHERE tenant_id = 'tenant_test_182'
    AND import_batch_id = 'batch_182_001';

  IF v_total <> 3 THEN
    RAISE EXCEPTION 'total_rows mismatch: %', v_total;
  END IF;

  IF v_valid <> 1 THEN
    RAISE EXCEPTION 'valid_rows mismatch: %', v_valid;
  END IF;

  IF v_invalid <> 1 THEN
    RAISE EXCEPTION 'invalid_rows mismatch: %', v_invalid;
  END IF;

  IF v_duplicate <> 1 THEN
    RAISE EXCEPTION 'duplicate_rows mismatch: %', v_duplicate;
  END IF;

  IF v_committed <> 1 THEN
    RAISE EXCEPTION 'committed_rows mismatch: %', v_committed;
  END IF;

  IF v_failed <> 1 THEN
    RAISE EXCEPTION 'failed_rows mismatch: %', v_failed;
  END IF;

  SELECT validation_status
  INTO v_row1_status
  FROM ${test_schema}.import_staging_rows
  WHERE tenant_id = 'tenant_test_182'
    AND import_batch_id = 'batch_182_001'
    AND row_number = 1;

  IF v_row1_status <> 'VALID' THEN
    RAISE EXCEPTION 'row1 validation_status mismatch: %', v_row1_status;
  END IF;

  SELECT validation_status, jsonb_array_length(validation_errors)
  INTO v_row2_status, v_row2_error_count
  FROM ${test_schema}.import_staging_rows
  WHERE tenant_id = 'tenant_test_182'
    AND import_batch_id = 'batch_182_001'
    AND row_number = 2;

  IF v_row2_status <> 'INVALID' THEN
    RAISE EXCEPTION 'row2 validation_status mismatch: %', v_row2_status;
  END IF;

  IF v_row2_error_count <> 1 THEN
    RAISE EXCEPTION 'row2 validation_errors count mismatch: %', v_row2_error_count;
  END IF;
END
\$\$;
SQL_APPLY_VERIFY_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$verify_apply_sql" >> "$out_file" 2>&1; then
    record_pass "apply counter rebuild verification"
    record_pass "apply validation status rebuild verification"
    record_pass "apply validation error aggregate verification"
  else
    record_fail "apply rebuild verification"
    cat "$out_file" || true
    return 1
  fi

  cat > "$cleanup_sql" <<SQL_CLEAN_EOF
\\set ON_ERROR_STOP on
DROP SCHEMA IF EXISTS ${test_schema} CASCADE;
SQL_CLEAN_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$cleanup_sql" >> "$out_file" 2>&1; then
    record_pass "temporary schema cleanup"
  else
    record_warn "temporary schema cleanup"
  fi

  return 0
}

{
  echo "===== 182 — FAZ 4-14.4 BACKFILL / REBUILD SCRIPT STANDARD REAL IMPLEMENTATION AUDIT START ====="

  MIGRATION_FILE="$(latest_180_migration_file)"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    record_pass "180 import staging migration dependency exists"
  else
    record_fail "180 import staging migration dependency exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "runtime rebuild script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime rebuild script executable" "$RUNTIME_SCRIPT"
  check_file "sql behavior test file exists" "$SQL_TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-14.4 Backfill / Rebuild Script Standardı"
  check_contains "doc dry-run marker" "$DOC_FILE" "Varsayılan mod dry-run"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 182"
  check_contains "config dependency 180 marker" "$CONFIG_FILE" "180_FAZ_4_14_3_IMPORT_STAGING_TABLES"
  check_contains "config dependency 181 marker" "$CONFIG_FILE" "181_FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "runtime tenant guard marker" "$RUNTIME_SCRIPT" "TENANT_ID_REQUIRED"
  check_contains "runtime batch guard marker" "$RUNTIME_SCRIPT" "IMPORT_BATCH_ID_REQUIRED"
  check_contains "runtime schema guard marker" "$RUNTIME_SCRIPT" "INVALID_SCHEMA_NAME"
  check_contains "runtime dry-run marker" "$RUNTIME_SCRIPT" "BACKFILL_REBUILD_STATUS=DRY_RUN_ONLY"
  check_contains "runtime apply marker" "$RUNTIME_SCRIPT" "BACKFILL_REBUILD_STATUS=APPLIED"
  check_contains "runtime validation errors rebuild marker" "$RUNTIME_SCRIPT" "validation_errors = COALESCE"
  check_contains "runtime counter rebuild marker" "$RUNTIME_SCRIPT" "counter_rebuild AS"
  check_contains "runtime import batch update marker" "$RUNTIME_SCRIPT" "UPDATE :\"schema_name\".import_batches"

  check_contains "sql fixture completion marker" "$SQL_TEST_FILE" "BACKFILL_REBUILD_SQL_FIXTURE_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
      run_backfill_rebuild_behavior_test "$MIGRATION_FILE" "$DB_DSN"
    else
      record_fail "backfill rebuild behavior test prerequisites"
    fi
  fi

  echo "===== 182 — FAZ 4-14.4 BACKFILL / REBUILD SCRIPT STANDARD COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_DOC_STATUS=READY"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_CONFIG_STATUS=READY"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_RUNTIME_STATUS=READY"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_TEST_STATUS=PASS"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_FINAL_STATUS=PASS"
    echo "FAZ_4_14_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_TEST_STATUS=FAIL"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD_FINAL_STATUS=FAIL"
    echo "FAZ_4_14_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
