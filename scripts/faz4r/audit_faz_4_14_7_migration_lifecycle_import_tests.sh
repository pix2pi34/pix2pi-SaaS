#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
DOC_FILE="docs/faz4r/FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS.md"
CONFIG_FILE="configs/faz4r/faz_4_14_7_migration_lifecycle_import_tests.v1.json"
SQL_TEST_FILE="tests/faz4r/faz_4_14_7_migration_lifecycle_import_tests.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

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

run_lifecycle_import_test() {
  local migration_file="$1"
  local test_file="$2"
  local dsn="$3"

  local test_schema="faz_4_14_7_import_lifecycle_test_$(date +%Y%m%d_%H%M%S)_$$"
  local tmp_sql="/tmp/faz_4_14_7_lifecycle_test_${test_schema}.sql"
  local tmp_out="/tmp/faz_4_14_7_lifecycle_test_${test_schema}.out"

  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
    return 1
  fi
  record_pass "psql command availability"

  cat > "$tmp_sql" <<SQL_RUN_EOF
\\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA ${test_schema};
SET search_path TO ${test_schema}, public;

$(sed 's/public\./'"${test_schema}"'./g' "$migration_file")

$(cat "$test_file")

ROLLBACK;
SQL_RUN_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
    record_pass "PostgreSQL temporary schema migration apply"
    record_pass "import batch lifecycle insert/update test"
    record_pass "import source file lifecycle test"
    record_pass "raw staging rows lifecycle test"
    record_pass "customer staging lifecycle test"
    record_pass "product staging lifecycle test"
    record_pass "stock staging lifecycle test"
    record_pass "finance document staging lifecycle test"
    record_pass "validation error lifecycle test"
    record_pass "audit event lifecycle test"
    record_pass "foreign key guard lifecycle test"
    record_pass "commit status lifecycle test"
    record_pass "rollback safety lifecycle test"
    return 0
  else
    record_fail "PostgreSQL lifecycle import SQL test"
    echo "----- PostgreSQL lifecycle test output start -----"
    cat "$tmp_out" || true
    echo "----- PostgreSQL lifecycle test output end -----"
    return 1
  fi
}

{
  echo "===== 181 — FAZ 4-14.7 MIGRATION / LIFECYCLE / IMPORT TESTS REAL IMPLEMENTATION AUDIT START ====="

  MIGRATION_FILE="$(latest_180_migration_file)"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    record_pass "180 import staging migration dependency exists"
  else
    record_fail "180 import staging migration dependency exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "sql lifecycle test file exists" "$SQL_TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-14.7 Migration / Lifecycle / Import Testleri"
  check_contains "doc temporary schema marker" "$DOC_FILE" "temporary schema"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 181"
  check_contains "config dependency marker" "$CONFIG_FILE" "180_FAZ_4_14_3_IMPORT_STAGING_TABLES"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "sql test batch insert marker" "$SQL_TEST_FILE" "INSERT INTO import_batches"
  check_contains "sql test source file insert marker" "$SQL_TEST_FILE" "INSERT INTO import_source_files"
  check_contains "sql test staging rows insert marker" "$SQL_TEST_FILE" "INSERT INTO import_staging_rows"
  check_contains "sql test customer staging marker" "$SQL_TEST_FILE" "INSERT INTO import_staging_customers"
  check_contains "sql test product staging marker" "$SQL_TEST_FILE" "INSERT INTO import_staging_products"
  check_contains "sql test stock staging marker" "$SQL_TEST_FILE" "INSERT INTO import_staging_stock_entries"
  check_contains "sql test finance staging marker" "$SQL_TEST_FILE" "INSERT INTO import_staging_finance_documents"
  check_contains "sql test validation error marker" "$SQL_TEST_FILE" "INSERT INTO import_validation_errors"
  check_contains "sql test audit event marker" "$SQL_TEST_FILE" "INSERT INTO import_audit_events"
  check_contains "sql test FK guard marker" "$SQL_TEST_FILE" "foreign_key_violation"
  check_contains "sql test completion marker" "$SQL_TEST_FILE" "LIFECYCLE_IMPORT_TESTS_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ] && [ -f "$SQL_TEST_FILE" ]; then
      run_lifecycle_import_test "$MIGRATION_FILE" "$SQL_TEST_FILE" "$DB_DSN"
    else
      record_fail "lifecycle import test prerequisites"
    fi
  fi

  echo "===== 181 — FAZ 4-14.7 MIGRATION / LIFECYCLE / IMPORT TESTS COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_DOC_STATUS=READY"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_CONFIG_STATUS=READY"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_SQL_TEST_STATUS=READY"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_DB_LIFECYCLE_STATUS=PASS"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_FINAL_STATUS=PASS"
    echo "FAZ_4_14_4_READY=YES"
    exit 0
  else
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_DB_LIFECYCLE_STATUS=FAIL"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_14_7_MIGRATION_LIFECYCLE_IMPORT_TESTS_FINAL_STATUS=FAIL"
    echo "FAZ_4_14_4_READY=NO"
    exit 1
  fi
} | tee "$EVIDENCE_FILE"
