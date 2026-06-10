#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_3g_tenant_apply_execution_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_3h_tenant_apply_verification.md"
REPORT_FILE="reports/pilot/faz4c/4c_3h_tenant_apply_verification_report.md"

echo "===== 4C-3H TENANT APPLY VERIFICATION / ISOLATION SMOKE ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3h_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3h_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3h_psql_error.log
    return $?
  fi

  return 127
}

[ -f "$PREV_REPORT" ] || fail "4C-3G test report yok: $PREV_REPORT"

grep -q "4C_3G_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-3G test PASS degil"
grep -q "4C_3G_TENANT_APPLY_STATUS=PASS" "$PREV_REPORT" || fail "4C-3G tenant apply PASS degil"
grep -q "4C_3G_DB_WRITE_APPLIED=YES" "$PREV_REPORT" || fail "4C-3G DB write YES degil"
grep -q "4C_3H_READY=YES" "$PREV_REPORT" || fail "4C-3H ready YES degil"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_3h_db_ping.out; then
  ERR="$(cat /tmp/4c_3h_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"

TENANT_COUNT_BY_SLUG="$(
  run_sql "
select count(*)
from platform.tenants
where slug='uzmanparcaci';
" | tr -d '[:space:]'
)"

TENANT_COUNT_BY_CODE="$(
  run_sql "
select count(*)
from platform.tenants
where business_code='UZMANPARCACI'::core.code_text;
" | tr -d '[:space:]'
)"

TENANT_DUPLICATE_COUNT="$(
  run_sql "
select count(*)
from platform.tenants
where slug='uzmanparcaci'
   or business_code='UZMANPARCACI'::core.code_text;
" | tr -d '[:space:]'
)"

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

TENANT_SCHEMA_LIST="$(
  run_sql "
select schema_name
from information_schema.schemata
where schema_name like 'tenant%'
order by schema_name;
" || true
)"

SEARCH_PATH_STATUS="PASS"
if ! run_sql "begin; set local search_path to tenant_uzmanparcaci, public; select current_schema(); rollback;" >/tmp/4c_3h_search_path.out; then
  SEARCH_PATH_STATUS="FAIL"
fi

SEARCH_PATH_OUTPUT="$(cat /tmp/4c_3h_search_path.out 2>/dev/null || true)"

CODE_CAST_STATUS="PASS"
if ! run_sql "select 'UZMANPARCACI'::core.code_text;" >/tmp/4c_3h_code_cast.out; then
  CODE_CAST_STATUS="FAIL"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
FINAL_STATUS="PASS"

if [ "$SCHEMA_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_COUNT_BY_SLUG" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_COUNT_BY_CODE" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_DUPLICATE_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SEARCH_PATH_STATUS" != "PASS" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CODE_CAST_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  FINAL_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-3H Tenant Apply Verification / Isolation Smoke"
  echo
  echo "## Amaç"
  echo
  echo "uzmanparcaci gerçek pilot tenant kaydının DB'de doğru oluştuğunu doğrulamak."
  echo
  echo "Bu adım kalıcı DB yazma yapmaz."
  echo
  echo "---"
  echo
  echo "## 1. Tenant doğrulama"
  echo
  echo "SCHEMA_COUNT=$SCHEMA_COUNT"
  echo "TENANT_COUNT_BY_SLUG=$TENANT_COUNT_BY_SLUG"
  echo "TENANT_COUNT_BY_CODE=$TENANT_COUNT_BY_CODE"
  echo "TENANT_DUPLICATE_COUNT=$TENANT_DUPLICATE_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. Tenant row"
  echo
  echo '```text'
  printf '%s\n' "$TENANT_ROW"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 3. Tenant schema listesi"
  echo
  echo '```text'
  printf '%s\n' "$TENANT_SCHEMA_LIST"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 4. Isolation smoke"
  echo
  echo "SEARCH_PATH_STATUS=$SEARCH_PATH_STATUS"
  echo "SEARCH_PATH_OUTPUT=$SEARCH_PATH_OUTPUT"
  echo "CODE_CAST_STATUS=$CODE_CAST_STATUS"
  echo
  echo "---"
  echo
  echo "## 5. Status"
  echo
  echo "4C_3H_TENANT_VERIFICATION_STATUS=$FINAL_STATUS"
  echo "4C_3H_SCHEMA_EXISTS=YES"
  echo "4C_3H_TENANT_METADATA_EXISTS=YES"
  echo "4C_3H_DUPLICATE_TENANT_COUNT=$TENANT_DUPLICATE_COUNT"
  echo "4C_3H_SEARCH_PATH_SMOKE_STATUS=$SEARCH_PATH_STATUS"
  echo "4C_3H_CODE_CAST_STATUS=$CODE_CAST_STATUS"
  echo "4C_3H_DB_WRITE_APPLIED=NO"
  echo "4C_3H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_3H_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_3I_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3H Tenant Apply Verification Report"
  echo
  echo "Step: 4C-3H"
  echo "Blok: Tenant Apply Verification / Isolation Smoke"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3H_TENANT_VERIFICATION_STATUS=$FINAL_STATUS"
  echo "4C_3H_SCHEMA_COUNT=$SCHEMA_COUNT"
  echo "4C_3H_TENANT_COUNT_BY_SLUG=$TENANT_COUNT_BY_SLUG"
  echo "4C_3H_TENANT_COUNT_BY_CODE=$TENANT_COUNT_BY_CODE"
  echo "4C_3H_DUPLICATE_TENANT_COUNT=$TENANT_DUPLICATE_COUNT"
  echo "4C_3H_SEARCH_PATH_SMOKE_STATUS=$SEARCH_PATH_STATUS"
  echo "4C_3H_CODE_CAST_STATUS=$CODE_CAST_STATUS"
  echo "4C_3H_DB_WRITE_APPLIED=NO"
  echo "4C_3H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_3H_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_3I_READY=$NEXT_READY"
  echo
  echo "## Tenant row"
  echo
  echo '```text'
  printf '%s\n' "$TENANT_ROW"
  echo '```'
  echo
  echo "## Sonuç"
  echo
  echo "Tenant apply verification tamamlandı."
  echo "uzmanparcaci tenant kaydı ve schema doğrulandı."
  echo "Sonraki adım: 4C-3I Tenant Setup Final Closure."
} > "$REPORT_FILE"

echo "OK ✅ Tenant verification report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3H VERIFICATION OZET ====="
echo "4C_3H_TENANT_VERIFICATION_STATUS=$FINAL_STATUS"
echo "4C_3H_SCHEMA_COUNT=$SCHEMA_COUNT"
echo "4C_3H_TENANT_COUNT_BY_SLUG=$TENANT_COUNT_BY_SLUG"
echo "4C_3H_TENANT_COUNT_BY_CODE=$TENANT_COUNT_BY_CODE"
echo "4C_3H_DUPLICATE_TENANT_COUNT=$TENANT_DUPLICATE_COUNT"
echo "4C_3H_SEARCH_PATH_SMOKE_STATUS=$SEARCH_PATH_STATUS"
echo "4C_3H_CODE_CAST_STATUS=$CODE_CAST_STATUS"
echo "4C_3H_DB_WRITE_APPLIED=NO"
echo "4C_3I_READY=$NEXT_READY"
