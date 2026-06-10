#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD.md"
CONFIG_FILE="configs/faz4r/faz_4_14_2_reference_data_seed_standard.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/apply_reference_data_seed.sh"
SQL_TEST_FILE="tests/faz4r/faz_4_14_2_reference_data_seed_standard.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
SEED_DIR="db/seeds/faz4"

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

latest_seed_file() {
  find "$SEED_DIR" -maxdepth 1 -type f -name "*_faz_4_14_2_reference_data_seed_standard.sql" | sort | tail -n 1
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

run_seed_behavior_test() {
  local seed_file="$1"
  local dsn="$2"

  local test_schema="faz_4_14_2_seed_test_$(date +%Y%m%d_%H%M%S)_$$"
  local setup_sql="/tmp/faz_4_14_2_seed_setup_${test_schema}.sql"
  local verify_dry_sql="/tmp/faz_4_14_2_seed_verify_dry_${test_schema}.sql"
  local verify_apply_sql="/tmp/faz_4_14_2_seed_verify_apply_${test_schema}.sql"
  local verify_idempotent_sql="/tmp/faz_4_14_2_seed_verify_idempotent_${test_schema}.sql"
  local cleanup_sql="/tmp/faz_4_14_2_seed_cleanup_${test_schema}.sql"
  local out_file="/tmp/faz_4_14_2_seed_behavior_${test_schema}.out"

  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
    return 1
  fi
  record_pass "psql command availability"

  cat > "$setup_sql" <<SQL_SETUP_EOF
\\set ON_ERROR_STOP on
DROP SCHEMA IF EXISTS ${test_schema} CASCADE;
CREATE SCHEMA ${test_schema};
SQL_SETUP_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$setup_sql" > "$out_file" 2>&1; then
    record_pass "PostgreSQL seed test schema setup"
  else
    record_fail "PostgreSQL seed test schema setup"
    cat "$out_file" || true
    return 1
  fi

  if SCHEMA="$test_schema" APPLY=0 SEED_SCOPE="FAZ4_IMPORT_CORE" SEED_VERSION="v1" SEED_SQL_FILE="$seed_file" "$RUNTIME_SCRIPT" >> "$out_file" 2>&1; then
    record_pass "reference seed dry-run execution"
  else
    record_fail "reference seed dry-run execution"
    cat "$out_file" || true
    return 1
  fi

  cat > "$verify_dry_sql" <<SQL_DRY_EOF
\\set ON_ERROR_STOP on

DO \$\$
DECLARE
  v_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = '${test_schema}'
      AND table_name = 'reference_seed_sets'
  ) INTO v_exists;

  IF v_exists IS TRUE THEN
    RAISE EXCEPTION 'dry-run created reference_seed_sets table';
  END IF;
END
\$\$;
SQL_DRY_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$verify_dry_sql" >> "$out_file" 2>&1; then
    record_pass "reference seed dry-run no mutation verification"
  else
    record_fail "reference seed dry-run no mutation verification"
    cat "$out_file" || true
    return 1
  fi

  if SCHEMA="$test_schema" APPLY=1 SEED_SCOPE="FAZ4_IMPORT_CORE" SEED_VERSION="v1" SEED_SQL_FILE="$seed_file" "$RUNTIME_SCRIPT" >> "$out_file" 2>&1; then
    record_pass "reference seed apply execution"
  else
    record_fail "reference seed apply execution"
    cat "$out_file" || true
    return 1
  fi

  cat > "$verify_apply_sql" <<SQL_VERIFY_EOF
\\set ON_ERROR_STOP on

DO \$\$
DECLARE
  v_set_count INTEGER;
  v_item_count INTEGER;
  v_import_type_count INTEGER;
  v_vat20_count INTEGER;
  v_try_count INTEGER;
  v_unit_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_set_count
  FROM ${test_schema}.reference_seed_sets
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1'
    AND status = 'APPLIED';

  IF v_set_count <> 1 THEN
    RAISE EXCEPTION 'seed set count mismatch: %', v_set_count;
  END IF;

  SELECT COUNT(*) INTO v_item_count
  FROM ${test_schema}.reference_seed_items
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1';

  IF v_item_count < 50 THEN
    RAISE EXCEPTION 'seed item count too low: %', v_item_count;
  END IF;

  SELECT COUNT(*) INTO v_import_type_count
  FROM ${test_schema}.reference_seed_items
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1'
    AND item_type = 'IMPORT_TYPE';

  IF v_import_type_count <> 5 THEN
    RAISE EXCEPTION 'import type seed count mismatch: %', v_import_type_count;
  END IF;

  SELECT COUNT(*) INTO v_vat20_count
  FROM ${test_schema}.reference_seed_items
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1'
    AND item_type = 'VAT_RATE'
    AND item_code = 'VAT_20'
    AND item_payload->>'rate' = '20';

  IF v_vat20_count <> 1 THEN
    RAISE EXCEPTION 'VAT_20 seed missing';
  END IF;

  SELECT COUNT(*) INTO v_try_count
  FROM ${test_schema}.reference_seed_items
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1'
    AND item_type = 'CURRENCY'
    AND item_code = 'TRY';

  IF v_try_count <> 1 THEN
    RAISE EXCEPTION 'TRY seed missing';
  END IF;

  SELECT COUNT(*) INTO v_unit_count
  FROM ${test_schema}.reference_seed_items
  WHERE seed_scope = 'FAZ4_IMPORT_CORE'
    AND seed_version = 'v1'
    AND item_type = 'UNIT'
    AND item_code = 'ADET';

  IF v_unit_count <> 1 THEN
    RAISE EXCEPTION 'ADET seed missing';
  END IF;
END
\$\$;
SQL_VERIFY_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$verify_apply_sql" >> "$out_file" 2>&1; then
    record_pass "reference seed table creation verification"
    record_pass "reference seed item count verification"
    record_pass "reference seed import type verification"
    record_pass "reference seed VAT verification"
    record_pass "reference seed currency verification"
    record_pass "reference seed unit verification"
  else
    record_fail "reference seed apply verification"
    cat "$out_file" || true
    return 1
  fi

  if SCHEMA="$test_schema" APPLY=1 SEED_SCOPE="FAZ4_IMPORT_CORE" SEED_VERSION="v1" SEED_SQL_FILE="$seed_file" "$RUNTIME_SCRIPT" >> "$out_file" 2>&1; then
    record_pass "reference seed second apply execution"
  else
    record_fail "reference seed second apply execution"
    cat "$out_file" || true
    return 1
  fi

  cat > "$verify_idempotent_sql" <<SQL_IDEMPOTENT_EOF
\\set ON_ERROR_STOP on

DO \$\$
DECLARE
  v_duplicate_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_duplicate_count
  FROM (
    SELECT seed_scope, seed_version, item_type, item_code, COUNT(*) AS c
    FROM ${test_schema}.reference_seed_items
    GROUP BY seed_scope, seed_version, item_type, item_code
    HAVING COUNT(*) > 1
  ) duplicates;

  IF v_duplicate_count <> 0 THEN
    RAISE EXCEPTION 'seed duplicate count mismatch: %', v_duplicate_count;
  END IF;
END
\$\$;
SQL_IDEMPOTENT_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$verify_idempotent_sql" >> "$out_file" 2>&1; then
    record_pass "reference seed idempotency verification"
  else
    record_fail "reference seed idempotency verification"
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
  echo "===== 184 — FAZ 4-14.2 REFERENCE DATA / SEED STANDARD REAL IMPLEMENTATION AUDIT START ====="

  SEED_FILE="$(latest_seed_file)"

  if [ -d "$SEED_DIR" ]; then
    record_pass "seed directory exists"
  else
    record_fail "seed directory exists"
  fi

  if [ -n "$SEED_FILE" ] && [ -f "$SEED_FILE" ]; then
    record_pass "seed SQL file exists"
  else
    record_fail "seed SQL file exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "runtime seed script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime seed script executable" "$RUNTIME_SCRIPT"
  check_file "sql test artifact exists" "$SQL_TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-14.2 Reference Data / Seed Standardı"
  check_contains "doc dry-run marker" "$DOC_FILE" "Varsayılan mod dry-run"
  check_contains "doc idempotent marker" "$DOC_FILE" "duplicate üretmez"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 184"
  check_contains "config dependency 180 marker" "$CONFIG_FILE" "180_FAZ_4_14_3_IMPORT_STAGING_TABLES"
  check_contains "config dependency 181 marker" "$CONFIG_FILE" "181_FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS"
  check_contains "config dependency 182 marker" "$CONFIG_FILE" "182_FAZ_4_14_4_BACKFILL_REBUILD_SCRIPT_STANDARD"
  check_contains "config dependency 183 marker" "$CONFIG_FILE" "183_FAZ_4_14_1_MIGRATION_CHAIN_STANDARD"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  if [ -n "$SEED_FILE" ] && [ -f "$SEED_FILE" ]; then
    check_contains "seed table reference_seed_sets marker" "$SEED_FILE" "CREATE TABLE IF NOT EXISTS :\"schema_name\".reference_seed_sets"
    check_contains "seed table reference_seed_items marker" "$SEED_FILE" "CREATE TABLE IF NOT EXISTS :\"schema_name\".reference_seed_items"
    check_contains "seed idempotent conflict marker" "$SEED_FILE" "ON CONFLICT"
    check_contains "seed import type marker" "$SEED_FILE" "'IMPORT_TYPE'"
    check_contains "seed VAT marker" "$SEED_FILE" "'VAT_RATE'"
    check_contains "seed completion marker" "$SEED_FILE" "REFERENCE_DATA_SEED_STANDARD_IMPLEMENTED"
  fi

  check_contains "runtime schema guard marker" "$RUNTIME_SCRIPT" "INVALID_SCHEMA_NAME"
  check_contains "runtime apply guard marker" "$RUNTIME_SCRIPT" "APPLY_MUST_BE_0_OR_1"
  check_contains "runtime dry-run marker" "$RUNTIME_SCRIPT" "REFERENCE_SEED_STATUS=DRY_RUN_ONLY"
  check_contains "runtime apply marker" "$RUNTIME_SCRIPT" "REFERENCE_SEED_STATUS=APPLIED"
  check_contains "runtime seed scope marker" "$RUNTIME_SCRIPT" "SEED_SCOPE"
  check_contains "runtime seed version marker" "$RUNTIME_SCRIPT" "SEED_VERSION"

  check_contains "sql test artifact marker" "$SQL_TEST_FILE" "REFERENCE_DATA_SEED_STANDARD_SQL_TEST_ARTIFACT_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -n "$SEED_FILE" ] && [ -f "$SEED_FILE" ]; then
      run_seed_behavior_test "$SEED_FILE" "$DB_DSN"
    else
      record_fail "reference seed behavior test prerequisites"
    fi
  fi

  echo "===== 184 — FAZ 4-14.2 REFERENCE DATA / SEED STANDARD COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_DOC_STATUS=READY"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_CONFIG_STATUS=READY"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_SEED_SQL_STATUS=READY"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_RUNTIME_STATUS=READY"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_DB_BEHAVIOR_STATUS=PASS"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_FINAL_STATUS=PASS"
    echo "FAZ_4_15_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_DB_BEHAVIOR_STATUS=FAIL"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_14_2_REFERENCE_DATA_SEED_STANDARD_FINAL_STATUS=FAIL"
    echo "FAZ_4_15_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
