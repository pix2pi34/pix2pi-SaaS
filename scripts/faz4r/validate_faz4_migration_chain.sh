#!/usr/bin/env bash
set -euo pipefail

MIGRATION_DIR="${MIGRATION_DIR:-db/migrations/faz4}"
APPLY_DB_TEST="${APPLY_DB_TEST:-0}"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

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

echo "===== FAZ 4 MIGRATION CHAIN VALIDATION START ====="
echo "MIGRATION_DIR=${MIGRATION_DIR}"
echo "APPLY_DB_TEST=${APPLY_DB_TEST}"

if [ -d "$MIGRATION_DIR" ]; then
  record_pass "migration directory exists"
else
  record_fail "migration directory exists"
fi

mapfile -t migration_files < <(find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*.sql" | sort)

if [ "${#migration_files[@]}" -gt 0 ]; then
  record_pass "migration sql files exist"
else
  record_fail "migration sql files exist"
fi

if find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*_faz_4_14_3_import_staging_tables.sql" | grep -q .; then
  record_pass "180 import staging migration exists in chain"
else
  record_fail "180 import staging migration exists in chain"
fi

bad_name_count=0
empty_file_count=0
missing_marker_count=0

tmp_timestamps="$(mktemp)"
: > "$tmp_timestamps"

for file in "${migration_files[@]}"; do
  base="$(basename "$file")"

  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}_[a-z0-9_]+\.sql$ ]]; then
    :
  else
    bad_name_count=$((bad_name_count + 1))
  fi

  if [ ! -s "$file" ]; then
    empty_file_count=$((empty_file_count + 1))
  fi

  echo "$base" | awk -F_ '{print $1"_"$2}' >> "$tmp_timestamps"

  if ! grep -Eq "(CREATE|ALTER|INSERT|UPDATE|COMMENT|DROP|IMPORT_STAGING_TABLES_IMPLEMENTED)" "$file"; then
    missing_marker_count=$((missing_marker_count + 1))
  fi
done

if [ "$bad_name_count" -eq 0 ]; then
  record_pass "migration filename pattern validation"
else
  record_fail "migration filename pattern validation"
fi

if [ "$empty_file_count" -eq 0 ]; then
  record_pass "migration empty file guard"
else
  record_fail "migration empty file guard"
fi

duplicate_timestamp_count="$(sort "$tmp_timestamps" | uniq -d | wc -l | tr -d ' ')"
rm -f "$tmp_timestamps"

if [ "$duplicate_timestamp_count" -eq 0 ]; then
  record_pass "migration duplicate timestamp guard"
else
  record_fail "migration duplicate timestamp guard"
fi

if [ "$missing_marker_count" -eq 0 ]; then
  record_pass "migration SQL content marker validation"
else
  record_fail "migration SQL content marker validation"
fi

if [ "$APPLY_DB_TEST" = "1" ]; then
  if ! command -v psql >/dev/null 2>&1; then
    record_fail "psql command availability"
  else
    record_pass "psql command availability"

    DB_DSN="$(resolve_db_dsn || true)"

    if [ -z "$DB_DSN" ]; then
      record_fail "DB_WRITE_DSN or DATABASE_URL availability"
    else
      record_pass "DB_WRITE_DSN or DATABASE_URL availability"

      test_schema="faz_4_14_1_chain_test_$(date +%Y%m%d_%H%M%S)_$$"
      tmp_sql="/tmp/faz_4_14_1_chain_apply_${test_schema}.sql"
      tmp_out="/tmp/faz_4_14_1_chain_apply_${test_schema}.out"

      {
        echo "\\set ON_ERROR_STOP on"
        echo "BEGIN;"
        echo "CREATE SCHEMA ${test_schema};"
        echo "SET search_path TO ${test_schema}, public;"
        for file in "${migration_files[@]}"; do
          echo ""
          echo "-- APPLY_CHAIN_FILE: $(basename "$file")"
          sed 's/public\./'"${test_schema}"'./g' "$file"
        done
        cat <<SQL_VERIFY_EOF

DO \$\$
DECLARE
  required_table_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO required_table_count
  FROM information_schema.tables
  WHERE table_schema = '${test_schema}'
    AND table_name IN (
      'import_batches',
      'import_source_files',
      'import_staging_rows',
      'import_staging_customers',
      'import_staging_products',
      'import_staging_stock_entries',
      'import_staging_finance_documents',
      'import_validation_errors',
      'import_audit_events'
    );

  IF required_table_count < 9 THEN
    RAISE EXCEPTION 'migration chain required table count mismatch: %', required_table_count;
  END IF;
END
\$\$;

ROLLBACK;
SQL_VERIFY_EOF
      } > "$tmp_sql"

      if psql "$DB_DSN" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
        record_pass "migration chain temporary schema apply"
        record_pass "migration chain required table verification"
        record_pass "migration chain rollback safety"
      else
        record_fail "migration chain temporary schema apply"
        echo "----- migration chain apply output start -----"
        cat "$tmp_out" || true
        echo "----- migration chain apply output end -----"
      fi
    fi
  fi
else
  record_warn "migration chain DB apply test skipped"
fi

echo "===== FAZ 4 MIGRATION CHAIN VALIDATION RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ4_MIGRATION_CHAIN_VALIDATION_STATUS=PASS"
  exit 0
else
  echo "FAZ4_MIGRATION_CHAIN_VALIDATION_STATUS=FAIL"
  exit 1
fi
