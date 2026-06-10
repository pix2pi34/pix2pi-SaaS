#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

MIGRATION_DIR="db/migrations/faz4"
DOC_FILE="docs/faz4r/FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD.md"
CONFIG_FILE="configs/faz4r/faz_4_15_6_materialized_view_cache_projection_standard.v1.json"
SQL_TEST_FILE="tests/faz4r/faz_4_15_6_materialized_view_cache_projection_standard.sql"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"

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

latest_189_migration_file() {
  find "$MIGRATION_DIR" -maxdepth 1 -type f -name "*_faz_4_15_6_materialized_view_cache_projection_standard.sql" | sort | tail -n 1
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

run_materialized_cache_db_test() {
  local migration_file="$1"
  local test_file="$2"
  local dsn="$3"

  local test_schema="faz_4_15_6_mv_cache_test_$(date +%Y%m%d_%H%M%S)_$$"
  local tmp_sql="/tmp/faz_4_15_6_mv_cache_test_${test_schema}.sql"
  local tmp_out="/tmp/faz_4_15_6_mv_cache_test_${test_schema}.out"

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
      ('materialized_projection_definitions'),
      ('projection_cache_profiles'),
      ('projection_cache_entries'),
      ('materialized_projection_dependencies'),
      ('materialized_projection_refresh_jobs'),
      ('materialized_projection_audit_events')
  ) AS required(table_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.tables t
    WHERE t.table_schema = '${test_schema}'
      AND t.table_name = required.table_name
  );

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'missing required materialized/cache projection tables: %', missing_count;
  END IF;
END
\$\$;

DO \$\$
DECLARE
  v_mv_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_mv_count
  FROM pg_matviews
  WHERE schemaname = '${test_schema}'
    AND matviewname = 'mv_projection_cache_health';

  IF v_mv_count <> 1 THEN
    RAISE EXCEPTION 'materialized view missing: %', v_mv_count;
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
      'projection_cache_profiles',
      'projection_cache_entries',
      'materialized_projection_dependencies',
      'materialized_projection_refresh_jobs',
      'materialized_projection_audit_events'
    );

  IF fk_count < 5 THEN
    RAISE EXCEPTION 'expected at least 5 materialized/cache FKs, found %', fk_count;
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
    AND tc.table_name = 'projection_cache_entries';

  IF unique_count < 1 THEN
    RAISE EXCEPTION 'expected projection_cache_entries unique constraint, found %', unique_count;
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
    AND (
      indexname LIKE 'materialized_projection_%'
      OR indexname LIKE 'projection_cache_%'
      OR indexname LIKE 'mv_projection_cache_%'
    );

  IF index_count < 15 THEN
    RAISE EXCEPTION 'expected at least 15 materialized/cache indexes, found %', index_count;
  END IF;
END
\$\$;

$(cat "$test_file")

ROLLBACK;
SQL_RUN_EOF

  if psql "$dsn" -v ON_ERROR_STOP=1 -f "$tmp_sql" > "$tmp_out" 2>&1; then
    record_pass "PostgreSQL temporary schema migration apply"
    record_pass "PostgreSQL required materialized/cache table metadata verification"
    record_pass "PostgreSQL materialized view metadata verification"
    record_pass "PostgreSQL materialized/cache FK metadata verification"
    record_pass "PostgreSQL materialized/cache unique constraint metadata verification"
    record_pass "PostgreSQL materialized/cache index metadata verification"
    record_pass "projection definition behavior test"
    record_pass "cache profile behavior test"
    record_pass "cache entry behavior test"
    record_pass "projection dependency behavior test"
    record_pass "refresh job behavior test"
    record_pass "projection audit event behavior test"
    record_pass "materialized view refresh behavior test"
    record_pass "projection FK guard behavior test"
    record_pass "rollback safety behavior test"
    return 0
  else
    record_fail "PostgreSQL materialized/cache projection DB behavior test"
    echo "----- PostgreSQL materialized/cache projection test output start -----"
    cat "$tmp_out" || true
    echo "----- PostgreSQL materialized/cache projection test output end -----"
    return 1
  fi
}

{
  echo "===== 189 — FAZ 4-15.6 MATERIALIZED VIEW / CACHE PROJECTION STANDARD REAL IMPLEMENTATION AUDIT START ====="

  MIGRATION_FILE="$(latest_189_migration_file)"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    record_pass "migration file exists"
  else
    record_fail "migration file exists"
  fi

  ROLLBACK_FILE="$(find backups/faz4r -path "*faz_4_15_6_materialized_view_cache_projection_standard_*/rollback/*_faz_4_15_6_materialized_view_cache_projection_standard_rollback.sql" -type f 2>/dev/null | sort | tail -n 1 || true)"

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    record_pass "rollback file exists"
  else
    record_fail "rollback file exists"
  fi

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "sql behavior test file exists" "$SQL_TEST_FILE"

  if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    check_contains "migration materialized_projection_definitions table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.materialized_projection_definitions"
    check_contains "migration projection_cache_profiles table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.projection_cache_profiles"
    check_contains "migration projection_cache_entries table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.projection_cache_entries"
    check_contains "migration materialized_projection_dependencies table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.materialized_projection_dependencies"
    check_contains "migration materialized_projection_refresh_jobs table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.materialized_projection_refresh_jobs"
    check_contains "migration materialized_projection_audit_events table" "$MIGRATION_FILE" "CREATE TABLE IF NOT EXISTS public.materialized_projection_audit_events"
    check_contains "migration materialized view marker" "$MIGRATION_FILE" "CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_projection_cache_health"
    check_contains "migration tenant_id required" "$MIGRATION_FILE" "tenant_id              TEXT NOT NULL"
    check_contains "migration FK cascade support" "$MIGRATION_FILE" "ON DELETE CASCADE"
    check_contains "migration cache status support" "$MIGRATION_FILE" "cache_status"
    check_contains "migration refresh job support" "$MIGRATION_FILE" "refresh_job_id"
    check_contains "migration completion marker" "$MIGRATION_FILE" "MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_IMPLEMENTED"
    check_contains "migration closed policy marker" "$MIGRATION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"
  fi

  if [ -n "$ROLLBACK_FILE" ] && [ -f "$ROLLBACK_FILE" ]; then
    check_contains "rollback drops materialized view" "$ROLLBACK_FILE" "DROP MATERIALIZED VIEW IF EXISTS public.mv_projection_cache_health"
    check_contains "rollback drops definitions table" "$ROLLBACK_FILE" "DROP TABLE IF EXISTS public.materialized_projection_definitions"
  fi

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-15.6 Materialized View / Cache Projection Standardı"
  check_contains "doc tenant security marker" "$DOC_FILE" "Tüm tablolarda tenant_id zorunludur."
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 189"
  check_contains "config priority group marker" "$CONFIG_FILE" "DB-L6 Reporting / Readmodel"
  check_contains "config dependency 188 marker" "$CONFIG_FILE" "188_FAZ_4_15_3_E_DOCUMENT_EXPORT_REPORTING_MART"
  check_contains "config materialized view marker" "$CONFIG_FILE" "mv_projection_cache_health"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "sql test definition insert marker" "$SQL_TEST_FILE" "INSERT INTO materialized_projection_definitions"
  check_contains "sql test cache profile marker" "$SQL_TEST_FILE" "INSERT INTO projection_cache_profiles"
  check_contains "sql test cache entry marker" "$SQL_TEST_FILE" "INSERT INTO projection_cache_entries"
  check_contains "sql test dependency marker" "$SQL_TEST_FILE" "INSERT INTO materialized_projection_dependencies"
  check_contains "sql test refresh job marker" "$SQL_TEST_FILE" "INSERT INTO materialized_projection_refresh_jobs"
  check_contains "sql test audit marker" "$SQL_TEST_FILE" "INSERT INTO materialized_projection_audit_events"
  check_contains "sql test refresh materialized view marker" "$SQL_TEST_FILE" "REFRESH MATERIALIZED VIEW mv_projection_cache_health"
  check_contains "sql test FK guard marker" "$SQL_TEST_FILE" "foreign_key_violation"
  check_contains "sql test completion marker" "$SQL_TEST_FILE" "MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_SQL_TEST_IMPLEMENTED"

  DB_DSN="$(resolve_db_dsn || true)"

  if [ -z "$DB_DSN" ]; then
    record_fail "DB_WRITE_DSN or DATABASE_URL availability"
  else
    record_pass "DB_WRITE_DSN or DATABASE_URL availability"

    if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ] && [ -f "$SQL_TEST_FILE" ]; then
      run_materialized_cache_db_test "$MIGRATION_FILE" "$SQL_TEST_FILE" "$DB_DSN"
    else
      record_fail "materialized/cache projection DB behavior test prerequisites"
    fi
  fi

  echo "===== 189 — FAZ 4-15.6 MATERIALIZED VIEW / CACHE PROJECTION STANDARD COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_DOC_STATUS=READY"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_CONFIG_STATUS=READY"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_MIGRATION_STATUS=READY"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_ROLLBACK_STATUS=READY"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_DB_BEHAVIOR_STATUS=PASS"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_FINAL_STATUS=PASS"
    echo "FAZ_4_15_7_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_DB_BEHAVIOR_STATUS=FAIL"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_15_6_MATERIALIZED_VIEW_CACHE_PROJECTION_STANDARD_FINAL_STATUS=FAIL"
    echo "FAZ_4_15_7_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
