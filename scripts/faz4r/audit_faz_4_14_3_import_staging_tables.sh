#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
ROLLBACK_GLOB="backups/faz4r/faz_4_14_3_import_staging_tables_*/rollback/*_faz_4_14_3_import_staging_tables_rollback.sql"
DOC_FILE="docs/faz4r/FAZ_4_14_3_IMPORT_STAGING_TABLES.md"
CONFIG_FILE="configs/faz4r/faz_4_14_3_import_staging_tables.v1.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_14_3_IMPORT_STAGING_TABLES_REAL_IMPLEMENTATION_AUDIT.md"

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

latest_migration_file() {
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

run_db_metadata_test() {
  local migration_file="$1"
  local dsn="$2"
  local test_schema="faz_4_14_3_import_test_$(date +%Y%m%d_%H%M%S)_$$"
  local tmp_sql="/tmp/faz_4_14_3_metadata_test_${test_schema}.sql"
  local tmp_out="/tmp/faz_4_14_3_metadata_test_${test_schema}.out"

  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
    return 1
  fi
  record_pass "psql command availability"

  cat > "$tmp_sql" <<SQL_TEST_EOF
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
      ('import_batches'),
      ('import_source_files'),
      ('import_staging_rows'),
      ('import_staging_customers'),
      ('import_staging_products'),
      ('import_staging_stock_entries'),
      ('import_staging_finance_documents'),
      ('import_validation_errors'),
      ('import_audit_events')
  ) AS required(table_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = '${test_schema}'
      AND t.table_name = required.table_name
  );

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'missing required import staging tables: %', missing_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM (
    VALUES
      ('tenant_id'),
      ('import_batch_id'),
      ('import_type'),
      ('status'),
      ('dry_run'),
      ('correlation_id')
  ) AS required(column_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = '${test_schema}'
      AND c.table_name = 'import_batches'
      AND c.column_name = required.column_name
  );

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'missing required import_batches columns: %', missing_count;
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
      'import_source_files',
      'import_staging_rows',
      'import_staging_customers',
      'import_staging_products',
      'import_staging_stock_entries',
      'import_staging_finance_documents',
      'import_validation_errors',
      'import_audit_events'
    );

  IF fk_count < 8 THEN
    RAISE EXCEPTION 'expected at least 8 foreign keys, found %', fk_count;
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
    AND indexname LIKE 'import_%';

  IF index_count < 20 THEN
    RAISE EXCEPTION 'expected at least 20 import indexes, found %', index_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  jsonb_column_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO jsonb_column_count
  FROM information_schema.columns
  WHERE table_schema = '${test_schema}'
    AND table_name LIKE 'import_%'
    AND udt_name = 'jsonb';

  IF jsonb_column_count < 8 THEN
    RAISE EXCEPTION 'expected at least 8 jsonb columns, found %', jsonb_column_count;
  END IF;
END
\$\$;

ROLLBACK;
SQL_TEST_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
    record_pass "PostgreSQL temporary schema migration apply"
    record_pass "PostgreSQL required table metadata verification"
    record_pass "PostgreSQL required column metadata verification"
    record_pass "PostgreSQL foreign key metadata verification"
    record_pass "PostgreSQL index metadata verification"
    record_pass "PostgreSQL jsonb metadata verification"
    return 0
  else
    record_fail "PostgreSQL temporary schema migration apply"
    echo "----- PostgreSQL metadata test output start -----"
    cat "$tmp_out" || true
    echo "----- PostgreSQL metadata test output end -----"
    return 1
  fi
}

{
  echo "===== 180 — FAZ 4-14.3 IMPORT / STAGING TABLES REAL IMPLEMENTATION AUDIT START ====="

  MIGRATION_FILE="$(latest_migration_file)"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    record_pass "migration file exists"
  else
    record_fail "migration file exists"
  fi

  ROLLBACK_FILE="$(find backups/faz4r -path "*faz_4_14_3_import_staging_tables_*/rollback/*_faz_4_14_3_import_staging_tables_rollback.sql" -type f 2>/dev/null | sort | tail -n 1 || true)"

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    record_pass "rollback file exists"
  else
    record_fail "rollback file exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    check_contains "migration import_batches table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_batches"
    check_contains "migration import_source_files table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_source_files"
    check_contains "migration import_staging_rows table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_staging_rows"
    check_contains "migration import_staging_customers table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_staging_customers"
    check_contains "migration import_staging_products table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_staging_products"
    check_contains "migration import_staging_stock_entries table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_staging_stock_entries"
    check_contains "migration import_staging_finance_documents table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_staging_finance_documents"
    check_contains "migration import_validation_errors table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_validation_errors"
    check_contains "migration import_audit_events table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.import_audit_events"
    check_contains "migration tenant_id required" "$MIGRATION_FILE" "tenant_id              TEXT NOT NULL"
    check_contains "migration jsonb raw data support" "$MIGRATION_FILE" "JSONB NOT NULL DEFAULT"
    check_contains "migration cascade foreign keys" "$MIGRATION_FILE" "ON DELETE CASCADE"
    check_contains "migration import completion marker" "$MIGRATION_FILE" "IMPORT_STAGING_TABLES_IMPLEMENTED"
    check_contains "migration closed policy marker" "$MIGRATION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"
  fi

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    check_contains "rollback drops import_audit_events" "$ROLLBACK_FILE" "DROP TABLE IF EXISTS public.import_audit_events"
    check_contains "rollback drops import_batches" "$ROLLBACK_FILE" "DROP TABLE IF EXISTS public.import_batches"
  fi

  check_contains "doc scope marker" "$DOC_FILE" "FAZ 4-14.3 Import / Staging Tabloları"
  check_contains "doc tenant security marker" "$DOC_FILE" "Tüm staging tablolarında tenant_id zorunludur."
  check_contains "doc policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"
  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 180"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"
    run_db_metadata_test "$MIGRATION_FILE" "$DB_DSN"
  fi

  echo "===== 180 — FAZ 4-14.3 IMPORT / STAGING TABLES COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_DOC_STATUS=READY"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_CONFIG_STATUS=READY"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_MIGRATION_STATUS=READY"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_ROLLBACK_STATUS=READY"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_DB_METADATA_TEST_STATUS=PASS"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_FINAL_STATUS=PASS"
    echo "FAZ_4_14_7_READY=YES"
    exit 0
  else
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_DB_METADATA_TEST_STATUS=FAIL"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_14_3_IMPORT_STAGING_TABLES_FINAL_STATUS=FAIL"
    echo "FAZ_4_14_7_READY=NO"
    exit 1
  fi
} | tee "$EVIDENCE_FILE"
