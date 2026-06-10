#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
DOC_FILE="docs/faz4r/FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART.md"
CONFIG_FILE="configs/faz4r/faz_4_15_3_e_document_export_reporting_mart.v1.json"
SQL_TEST_FILE="tests/faz4r/faz_4_15_3_e_document_export_reporting_mart.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_REAL_IMPLEMENTATION_AUDIT.md"

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

latest_188_migration_file() {
  find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*_faz_4_15_3_e_document_export_reporting_mart.sql" | sort | tail -n 1
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

run_e_document_reporting_db_test() {
  local migration_file="$1"
  local test_file="$2"
  local dsn="$3"

  local test_schema="faz_4_15_3_edoc_test_$(date +%Y%m%d_%H%M%S)_$$"
  local tmp_sql="/tmp/faz_4_15_3_edoc_test_${test_schema}.sql"
  local tmp_out="/tmp/faz_4_15_3_edoc_test_${test_schema}.out"

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

DO \$\$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM (
    VALUES
      ('e_document_report_periods'),
      ('e_document_documents_mart'),
      ('e_document_export_batches_mart'),
      ('e_document_export_files_mart'),
      ('e_document_status_summary_mart'),
      ('e_document_reporting_projection_offsets'),
      ('e_document_reporting_audit_events')
  ) AS required(table_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = '${test_schema}'
      AND t.table_name = required.table_name
  );

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'missing required e-document reporting mart tables: %', missing_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  fk_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO fk_count
  FROM information_schema.table_constraints tc
  WHERE tc.table_schema = '${test_schema}'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN (
      'e_document_documents_mart',
      'e_document_export_batches_mart',
      'e_document_export_files_mart',
      'e_document_status_summary_mart'
    );

  IF fk_count < 4 THEN
    RAISE EXCEPTION 'expected at least 4 e-document mart FKs, found %', fk_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  unique_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unique_count
  FROM information_schema.table_constraints tc
  WHERE tc.table_schema = '${test_schema}'
    AND tc.constraint_type = 'UNIQUE'
    AND tc.table_name IN (
      'e_document_report_periods',
      'e_document_documents_mart'
    );

  IF unique_count < 2 THEN
    RAISE EXCEPTION 'expected e-document unique constraints, found %', unique_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = '${test_schema}'
    AND indexname LIKE 'e_document_%';

  IF index_count < 15 THEN
    RAISE EXCEPTION 'expected at least 15 e-document indexes, found %', index_count;
  END IF;
END
\$\$;

$(cat "$test_file")

ROLLBACK;
SQL_RUN_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
    record_pass "PostgreSQL temporary schema migration apply"
    record_pass "PostgreSQL required e-document table metadata verification"
    record_pass "PostgreSQL e-document FK metadata verification"
    record_pass "PostgreSQL e-document unique constraint metadata verification"
    record_pass "PostgreSQL e-document index metadata verification"
    record_pass "e-document period behavior test"
    record_pass "e-document document behavior test"
    record_pass "e-document export batch behavior test"
    record_pass "e-document export file behavior test"
    record_pass "e-document status summary behavior test"
    record_pass "e-document projection offset behavior test"
    record_pass "e-document reporting audit event behavior test"
    record_pass "e-document FK guard behavior test"
    record_pass "rollback safety behavior test"
    return 0
  else
    record_fail "PostgreSQL e-document reporting DB behavior test"
    echo "----- PostgreSQL e-document reporting test output start -----"
    cat "$tmp_out" || true
    echo "----- PostgreSQL e-document reporting test output end -----"
    return 1
  fi
}

{
  echo "===== 188 — FAZ 4-15.3 E-DOCUMENT / EXPORT REPORTING MART REAL IMPLEMENTATION AUDIT START ====="

  MIGRATION_FILE="$(latest_188_migration_file)"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    record_pass "migration file exists"
  else
    record_fail "migration file exists"
  fi

  ROLLBACK_FILE="$(find backups/faz4r -path "*faz_4_15_3_e_document_export_reporting_mart_*/rollback/*_faz_4_15_3_e_document_export_reporting_mart_rollback.sql" -type f 2>/dev/null | sort | tail -n 1 || true)"

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    record_pass "rollback file exists"
  else
    record_fail "rollback file exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "sql behavior test file exists" "$SQL_TEST_FILE"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    check_contains "migration e_document_report_periods table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_report_periods"
    check_contains "migration e_document_documents_mart table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_documents_mart"
    check_contains "migration e_document_export_batches_mart table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_export_batches_mart"
    check_contains "migration e_document_export_files_mart table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_export_files_mart"
    check_contains "migration e_document_status_summary_mart table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_status_summary_mart"
    check_contains "migration e_document_reporting_projection_offsets table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_reporting_projection_offsets"
    check_contains "migration e_document_reporting_audit_events table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.e_document_reporting_audit_events"
    check_contains "migration tenant_id required" "$MIGRATION_FILE" "tenant_id              TEXT NOT NULL"
    check_contains "migration FK cascade support" "$MIGRATION_FILE" "ON DELETE CASCADE"
    check_contains "migration numeric amount support" "$MIGRATION_FILE" "NUMERIC(18,2)"
    check_contains "migration export target support" "$MIGRATION_FILE" "'LOGO'"
    check_contains "migration completion marker" "$MIGRATION_FILE" "E_DOCUMENT_EXPORT_REPORTING_MART_IMPLEMENTED"
    check_contains "migration closed policy marker" "$MIGRATION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"
  fi

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    check_contains "rollback drops audit table" "$ROLLBACK_FILE" "DROP TABLE IF EXISTS public.e_document_reporting_audit_events"
    check_contains "rollback drops period table" "$ROLLBACK_FILE" "DROP TABLE IF EXISTS public.e_document_report_periods"
  fi

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-15.3 e-Belge / Export Reporting Mart"
  check_contains "doc tenant security marker" "$DOC_FILE" "Tüm tablolarda tenant_id zorunludur."
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 188"
  check_contains "config priority group marker" "$CONFIG_FILE" "DB-L6 Reporting / Readmodel"
  check_contains "config dependency 187 marker" "$CONFIG_FILE" "187_FAZ_4_15_4_PAYMENT_RECONCILIATION_REPORTING_MART"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "sql test period insert marker" "$SQL_TEST_FILE" "INSERT INTO e_document_report_periods"
  check_contains "sql test document insert marker" "$SQL_TEST_FILE" "INSERT INTO e_document_documents_mart"
  check_contains "sql test export batch marker" "$SQL_TEST_FILE" "INSERT INTO e_document_export_batches_mart"
  check_contains "sql test export file marker" "$SQL_TEST_FILE" "INSERT INTO e_document_export_files_mart"
  check_contains "sql test status summary marker" "$SQL_TEST_FILE" "INSERT INTO e_document_status_summary_mart"
  check_contains "sql test offset marker" "$SQL_TEST_FILE" "INSERT INTO e_document_reporting_projection_offsets"
  check_contains "sql test audit marker" "$SQL_TEST_FILE" "INSERT INTO e_document_reporting_audit_events"
  check_contains "sql test FK guard marker" "$SQL_TEST_FILE" "foreign_key_violation"
  check_contains "sql test completion marker" "$SQL_TEST_FILE" "E_DOCUMENT_EXPORT_REPORTING_MART_SQL_TEST_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ] && [ -f "$SQL_TEST_FILE" ]; then
      run_e_document_reporting_db_test "$MIGRATION_FILE" "$SQL_TEST_FILE" "$DB_DSN"
    else
      record_fail "e-document reporting DB behavior test prerequisites"
    fi
  fi

  echo "===== 188 — FAZ 4-15.3 E-DOCUMENT / EXPORT REPORTING MART COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_DOC_STATUS=READY"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_CONFIG_STATUS=READY"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_MIGRATION_STATUS=READY"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_ROLLBACK_STATUS=READY"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_DB_BEHAVIOR_STATUS=PASS"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_FINAL_STATUS=PASS"
    echo "FAZ_4_15_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_DB_BEHAVIOR_STATUS=FAIL"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART_FINAL_STATUS=FAIL"
    echo "FAZ_4_15_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
