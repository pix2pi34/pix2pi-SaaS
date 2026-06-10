#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
DOC_FILE="docs/faz4r/FAZ_4_15_7_READMODEL_REPORTING_TEST_SET.md"
CONFIG_FILE="configs/faz4r/faz_4_15_7_readmodel_reporting_test_set.v1.json"
SQL_TEST_FILE="tests/faz4r/faz_4_15_7_readmodel_reporting_test_set.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
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

latest_migration_file_by_suffix() {
  local suffix="$1"
  find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*_${suffix}.sql" | sort | tail -n 1
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

run_readmodel_reporting_test_set() {
  local m185="$1"
  local m186="$2"
  local m187="$3"
  local m188="$4"
  local m189="$5"
  local test_file="$6"
  local dsn="$7"

  local test_schema="faz_4_15_7_readmodel_test_$(date +%Y%m%d_%H%M%S)_$$"
  local tmp_sql="/tmp/faz_4_15_7_readmodel_test_${test_schema}.sql"
  local tmp_out="/tmp/faz_4_15_7_readmodel_test_${test_schema}.out"

  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
    return 1
  fi
  record_pass "psql command availability"

  {
    echo "\\set ON_ERROR_STOP on"
    echo "BEGIN;"
    echo "CREATE SCHEMA ${test_schema};"
    echo "SET search_path TO ${test_schema}, public;"
    echo ""
    echo "-- APPLY 185"
    sed 's/public\./'"${test_schema}"'./g' "$m185"
    echo ""
    echo "-- APPLY 186"
    sed 's/public\./'"${test_schema}"'./g' "$m186"
    echo ""
    echo "-- APPLY 187"
    sed 's/public\./'"${test_schema}"'./g' "$m187"
    echo ""
    echo "-- APPLY 188"
    sed 's/public\./'"${test_schema}"'./g' "$m188"
    echo ""
    echo "-- APPLY 189"
    sed 's/public\./'"${test_schema}"'./g' "$m189"
    cat <<SQL_VERIFY_EOF

DO \$\$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM (
    VALUES
      ('search_index_documents'),
      ('finance_account_balances_mart'),
      ('payment_reconciliation_mart'),
      ('e_document_documents_mart'),
      ('projection_cache_entries')
  ) AS required(table_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = '${test_schema}'
      AND t.table_name = required.table_name
  );

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'missing cross readmodel tables: %', missing_count;
  END IF;
END
\$\$;

SQL_VERIFY_EOF
    cat "$test_file"
    echo "ROLLBACK;"
  } > "$tmp_sql"

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
    record_pass "PostgreSQL temporary schema migration chain apply"
    record_pass "PostgreSQL cross readmodel required table verification"
    record_pass "search readmodel cross behavior test"
    record_pass "finance reporting cross behavior test"
    record_pass "payment reporting cross behavior test"
    record_pass "e-document reporting cross behavior test"
    record_pass "materialized cache cross behavior test"
    record_pass "cross readmodel consistency behavior test"
    record_pass "cross readmodel FK guard behavior test"
    record_pass "rollback safety behavior test"
    return 0
  else
    record_fail "PostgreSQL readmodel/reporting test set behavior"
    echo "----- PostgreSQL readmodel/reporting test set output start -----"
    cat "$tmp_out" || true
    echo "----- PostgreSQL readmodel/reporting test set output end -----"
    return 1
  fi
}

{
  echo "===== 190 — FAZ 4-15.7 READMODEL / REPORTING TEST SET REAL IMPLEMENTATION AUDIT START ====="

  M185="$(latest_migration_file_by_suffix "faz_4_15_5_search_index_projection_tables")"
  M186="$(latest_migration_file_by_suffix "faz_4_15_2_finance_reporting_mart")"
  M187="$(latest_migration_file_by_suffix "faz_4_15_4_payment_reconciliation_reporting_mart")"
  M188="$(latest_migration_file_by_suffix "faz_4_15_3_e_document_export_reporting_mart")"
  M189="$(latest_migration_file_by_suffix "faz_4_15_6_materialized_view_cache_projection_standard")"

  [ -n "$M185" ] && [ -f "$M185" ] && record_pass "185 migration dependency exists" || record_fail "185 migration dependency exists"
  [ -n "$M186" ] && [ -f "$M186" ] && record_pass "186 migration dependency exists" || record_fail "186 migration dependency exists"
  [ -n "$M187" ] && [ -f "$M187" ] && record_pass "187 migration dependency exists" || record_fail "187 migration dependency exists"
  [ -n "$M188" ] && [ -f "$M188" ] && record_pass "188 migration dependency exists" || record_fail "188 migration dependency exists"
  [ -n "$M189" ] && [ -f "$M189" ] && record_pass "189 migration dependency exists" || record_fail "189 migration dependency exists"

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "sql test file exists" "$SQL_TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-15.7 Readmodel / Reporting Test Seti"
  check_contains "doc migration range marker" "$DOC_FILE" "185–189"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 190"
  check_contains "config dependency 185 marker" "$CONFIG_FILE" "185_FAZ_4_15_5_SEARCH_INDEX_PROJECTION_TABLES"
  check_contains "config dependency 186 marker" "$CONFIG_FILE" "186_FAZ_4_15_2_FINANCE_REPORTING_MART"
  check_contains "config dependency 187 marker" "$CONFIG_FILE" "187_FAZ_4_15_4_PAYMENT_RECONCILIATION_REPORTING_MART"
  check_contains "config dependency 188 marker" "$CONFIG_FILE" "188_FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART"
  check_contains "config dependency 189 marker" "$CONFIG_FILE" "189_FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "sql test search marker" "$SQL_TEST_FILE" "INSERT INTO search_index_documents"
  check_contains "sql test finance marker" "$SQL_TEST_FILE" "INSERT INTO finance_account_balances_mart"
  check_contains "sql test payment marker" "$SQL_TEST_FILE" "INSERT INTO payment_reconciliation_mart"
  check_contains "sql test edoc marker" "$SQL_TEST_FILE" "INSERT INTO e_document_documents_mart"
  check_contains "sql test cache marker" "$SQL_TEST_FILE" "INSERT INTO projection_cache_entries"
  check_contains "sql test materialized refresh marker" "$SQL_TEST_FILE" "REFRESH MATERIALIZED VIEW mv_projection_cache_health"
  check_contains "sql test FK guard marker" "$SQL_TEST_FILE" "foreign_key_violation"
  check_contains "sql test completion marker" "$SQL_TEST_FILE" "READMODEL_REPORTING_TEST_SET_SQL_TEST_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -f "$M185" ] && [ -f "$M186" ] && [ -f "$M187" ] && [ -f "$M188" ] && [ -f "$M189" ] && [ -f "$SQL_TEST_FILE" ]; then
      run_readmodel_reporting_test_set "$M185" "$M186" "$M187" "$M188" "$M189" "$SQL_TEST_FILE" "$DB_DSN"
    else
      record_fail "readmodel/reporting test set prerequisites"
    fi
  fi

  echo "===== 190 — FAZ 4-15.7 READMODEL / REPORTING TEST SET COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=0"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=0"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_DOC_STATUS=READY"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_CONFIG_STATUS=READY"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_SQL_TEST_STATUS=READY"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_DB_BEHAVIOR_STATUS=PASS"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_FINAL_STATUS=PASS"
    echo "FAZ_4_15_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_DB_BEHAVIOR_STATUS=FAIL"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_15_7_READMODEL_REPORTING_TEST_SET_FINAL_STATUS=FAIL"
    echo "FAZ_4_15_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
