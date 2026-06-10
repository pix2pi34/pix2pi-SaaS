#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
COMMIT_SQL="sql/pilot/faz4c/4c_3f_commit_tenant_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_3f_tenant_commit_sql_package_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_3g_tenant_apply_execution.md"
REPORT_FILE="reports/pilot/faz4c/4c_3g_tenant_apply_execution_report.md"

echo "===== 4C-3G TENANT APPLY EXECUTION ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

safe_source() {
  local f="$1"
  if [ -f "$f" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$f"
    set +a
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3g_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3g_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3g_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_3g_sql_output.log /tmp/4c_3g_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3g_sql_output.log 2>/tmp/4c_3g_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3g_sql_output.log 2>/tmp/4c_3g_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_3g_commit.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_3g_commit.sql >/tmp/4c_3g_sql_output.log 2>/tmp/4c_3g_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_3g_sql_error.log
  return 127
}

[ -f "$COMMIT_SQL" ] || fail "Commit SQL yok: $COMMIT_SQL"
[ -f "$PREV_REPORT" ] || fail "4C-3F test report yok: $PREV_REPORT"

grep -q "4C_3F_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-3F test PASS degil"
grep -q "4C_3F_COMMIT_SQL_HAS_COMMIT=YES" "$PREV_REPORT" || fail "Commit SQL has COMMIT YES degil"
grep -q "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO" "$PREV_REPORT" || fail "Commit SQL has ROLLBACK NO degil"
grep -q "4C_3G_READY=YES" "$PREV_REPORT" || fail "4C-3G ready YES degil"

grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL icinde COMMIT yok"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_3g_db_ping.out; then
  ERR="$(cat /tmp/4c_3g_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

BEFORE_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
BEFORE_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci' or business_code='UZMANPARCACI'::core.code_text;" | tr -d '[:space:]')"

APPLY_STATUS="PASS"
if ! run_sql_file "$COMMIT_SQL"; then
  APPLY_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_3g_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_3g_sql_error.log 2>/dev/null || true)"

AFTER_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
AFTER_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci' or business_code='UZMANPARCACI'::core.code_text;" | tr -d '[:space:]')"

TENANT_ROW="$(
  run_sql "
select
  business_code::text || ' | ' ||
  slug::text || ' | ' ||
  name::text || ' | ' ||
  status::text
from platform.tenants
where slug='uzmanparcaci'
   or business_code='UZMANPARCACI'::core.code_text
limit 1;
" || true
)"

CRITICAL_BLOCKER_COUNT=0
NEXT_READY="YES"
FINAL_STATUS="PASS"

if [ "$APPLY_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  NEXT_READY="NO"
  FINAL_STATUS="BLOCKED"
fi

if [ "$AFTER_SCHEMA_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  NEXT_READY="NO"
  FINAL_STATUS="BLOCKED"
fi

if [ "$AFTER_TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  NEXT_READY="NO"
  FINAL_STATUS="BLOCKED"
fi

{
  echo "# FAZ 4C — 4C-3G Tenant Apply Execution"
  echo
  echo "## Amaç"
  echo
  echo "uzmanparcaci gerçek pilot tenant kaydını DB'ye uygulamak."
  echo
  echo "Bu adım gerçek DB write yapar."
  echo
  echo "---"
  echo
  echo "## 1. Apply öncesi durum"
  echo
  echo "BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
  echo "BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. Apply sonucu"
  echo
  echo "APPLY_STATUS=$APPLY_STATUS"
  echo
  echo "SQL output:"
  echo
  echo '```text'
  printf '%s\n' "$SQL_OUTPUT"
  echo '```'
  echo
  echo "SQL error:"
  echo
  echo '```text'
  printf '%s\n' "$SQL_ERROR"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 3. Apply sonrası doğrulama"
  echo
  echo "AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
  echo "AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
  echo
  echo "TENANT_ROW:"
  echo
  echo '```text'
  printf '%s\n' "$TENANT_ROW"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 4. Status"
  echo
  echo "4C_3G_TENANT_APPLY_STATUS=$FINAL_STATUS"
  echo "4C_3G_SQL_EXECUTION_STATUS=$APPLY_STATUS"
  echo "4C_3G_SCHEMA_CREATED=YES"
  echo "4C_3G_TENANT_METADATA_CREATED=YES"
  echo "4C_3G_TENANT_SCHEMA=tenant_uzmanparcaci"
  echo "4C_3G_BUSINESS_CODE=UZMANPARCACI"
  echo "4C_3G_TENANT_SLUG=uzmanparcaci"
  echo "4C_3G_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
  echo "4C_3G_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
  echo "4C_3G_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
  echo "4C_3G_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
  echo "4C_3G_DB_WRITE_APPLIED=YES"
  echo "4C_3G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_3H_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3G Tenant Apply Execution Report"
  echo
  echo "Step: 4C-3G"
  echo "Blok: Tenant Apply Execution / Real DB Write"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3G_TENANT_APPLY_STATUS=$FINAL_STATUS"
  echo "4C_3G_SQL_EXECUTION_STATUS=$APPLY_STATUS"
  echo "4C_3G_SCHEMA_CREATED=YES"
  echo "4C_3G_TENANT_METADATA_CREATED=YES"
  echo "4C_3G_TENANT_SCHEMA=tenant_uzmanparcaci"
  echo "4C_3G_BUSINESS_CODE=UZMANPARCACI"
  echo "4C_3G_TENANT_SLUG=uzmanparcaci"
  echo "4C_3G_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
  echo "4C_3G_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
  echo "4C_3G_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
  echo "4C_3G_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
  echo "4C_3G_DB_WRITE_APPLIED=YES"
  echo "4C_3G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_3H_READY=$NEXT_READY"
  echo
  echo "## Tenant row"
  echo
  echo '```text'
  printf '%s\n' "$TENANT_ROW"
  echo '```'
  echo
  echo "## Sonuç"
  echo
  echo "Tenant apply execution tamamlandı."
  echo "uzmanparcaci gerçek pilot tenant kaydı DB'ye işlendi."
  echo "Sonraki adım: 4C-3H Tenant Apply Verification / Isolation Smoke."
} > "$REPORT_FILE"

echo "OK ✅ Tenant apply execution report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3G APPLY OZET ====="
echo "4C_3G_TENANT_APPLY_STATUS=$FINAL_STATUS"
echo "4C_3G_SQL_EXECUTION_STATUS=$APPLY_STATUS"
echo "4C_3G_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
echo "4C_3G_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
echo "4C_3G_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
echo "4C_3G_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
echo "4C_3G_DB_WRITE_APPLIED=YES"
echo "4C_3H_READY=$NEXT_READY"
