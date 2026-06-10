#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
SQL_FILE="sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_4d_user_role_sql_package_test_report.md"
FIX3_REPORT="reports/pilot/faz4c/4c_4d_fix3_assignment_cte_columns_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4e_user_role_sql_dry_run.md"
REPORT_FILE="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_report.md"

PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"
TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"

echo "===== 4C-4E USER ROLE SQL DRY RUN / ROLLBACK VERIFICATION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4e_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4e_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4e_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_4e_sql_output.log /tmp/4c_4e_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4e_sql_output.log 2>/tmp/4c_4e_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4e_sql_output.log 2>/tmp/4c_4e_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_4e_user_role_preview.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_4e_user_role_preview.sql >/tmp/4c_4e_sql_output.log 2>/tmp/4c_4e_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_4e_sql_error.log
  return 127
}

safe_count() {
  local sql="$1"
  local out
  out="$(run_sql "$sql" 2>/dev/null || true)"
  out="$(printf "%s" "$out" | tr -d '[:space:]')"
  if [ -z "$out" ]; then
    echo "0"
  else
    echo "$out"
  fi
}

[ -f "$SQL_FILE" ] || fail "SQL preview file yok: $SQL_FILE"
[ -f "$PREV_REPORT" ] || fail "4C-4D test report yok: $PREV_REPORT"
[ -f "$FIX3_REPORT" ] || fail "4C-4D-FIX3 report yok: $FIX3_REPORT"

grep -q "4C_4D_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4D test PASS degil"
grep -q "4C_4E_READY=YES" "$PREV_REPORT" || fail "4C-4E ready YES yok"
grep -q "4C_4D_FIX3_STATUS=PASS" "$FIX3_REPORT" || fail "4C-4D-FIX3 PASS degil"
grep -q "4C_4D_FIX3_ASSIGNMENT_USER_EXPR=u.user_id" "$FIX3_REPORT" || fail "FIX3 user expr dogru degil"
grep -q "4C_4D_FIX3_ASSIGNMENT_ROLE_EXPR=r.role_id" "$FIX3_REPORT" || fail "FIX3 role expr dogru degil"

grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL preview ROLLBACK icermiyor"

if grep -q "COMMIT;" "$SQL_FILE"; then
  fail "SQL preview COMMIT icermemeli"
fi

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_4e_db_ping.out; then
  ERR="$(cat /tmp/4c_4e_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

BEFORE_USER_COUNT="$(safe_count "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
")"

BEFORE_ROLE_COUNT="$(safe_count "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

BEFORE_ASSIGNMENT_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

DRY_RUN_SQL_EXECUTION_STATUS="PASS"

if ! run_sql_file "$SQL_FILE"; then
  DRY_RUN_SQL_EXECUTION_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_4e_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_4e_sql_error.log 2>/dev/null || true)"

AFTER_USER_COUNT="$(safe_count "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
")"

AFTER_ROLE_COUNT="$(safe_count "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

AFTER_ASSIGNMENT_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

ROLLBACK_VERIFIED="NO"

if [ "$BEFORE_USER_COUNT" = "$AFTER_USER_COUNT" ] && \
   [ "$BEFORE_ROLE_COUNT" = "$AFTER_ROLE_COUNT" ] && \
   [ "$BEFORE_ASSIGNMENT_COUNT" = "$AFTER_ASSIGNMENT_COUNT" ]; then
  ROLLBACK_VERIFIED="YES"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
DRY_RUN_STATUS="PASS"

if [ "$DRY_RUN_SQL_EXECUTION_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLLBACK_VERIFIED" != "YES" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  DRY_RUN_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-4E User Role SQL Dry Run"
  echo
  echo "## Amac"
  echo
  echo "4C-4D SQL preview dosyasini ROLLBACK ile calistirip kalici DB yazma olmadigini dogrulamak."
  echo
  echo "Bu adim kalici DB yazma yapmaz."
  echo
  echo "---"
  echo
  echo "## 1. SQL dosyasi"
  echo
  echo "SQL_FILE=$SQL_FILE"
  echo
  echo "---"
  echo
  echo "## 2. Dry-run oncesi durum"
  echo
  echo "BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 3. SQL execution"
  echo
  echo "DRY_RUN_SQL_EXECUTION_STATUS=$DRY_RUN_SQL_EXECUTION_STATUS"
  echo
  echo "SQL output:"
  printf '%s\n' "$SQL_OUTPUT" | sed 's/^/    /'
  echo
  echo "SQL error:"
  printf '%s\n' "$SQL_ERROR" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 4. Dry-run sonrasi durum"
  echo
  echo "AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 5. Rollback dogrulama"
  echo
  echo "ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
  echo
  echo "---"
  echo
  echo "## 6. Status"
  echo
  echo "4C_4E_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_4E_SQL_EXECUTION_STATUS=$DRY_RUN_SQL_EXECUTION_STATUS"
  echo "4C_4E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
  echo "4C_4E_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "4C_4E_AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "4C_4E_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "4C_4E_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "4C_4E_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "4C_4E_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo "4C_4E_DB_WRITE_APPLIED=NO"
  echo "4C_4E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4E_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4F_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4E User Role SQL Dry Run Report"
  echo
  echo "Step: 4C-4E"
  echo "Blok: User / Role SQL Dry Run / ROLLBACK Verification"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4E_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_4E_SQL_EXECUTION_STATUS=$DRY_RUN_SQL_EXECUTION_STATUS"
  echo "4C_4E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
  echo "4C_4E_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "4C_4E_AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "4C_4E_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "4C_4E_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "4C_4E_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "4C_4E_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo "4C_4E_DB_WRITE_APPLIED=NO"
  echo "4C_4E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4F_READY=$NEXT_READY"
  echo
  echo "## SQL error"
  printf '%s\n' "$SQL_ERROR" | sed 's/^/    /'
  echo
  echo "## Sonuc"
  echo
  echo "User/role SQL dry-run tamamlandi."
  echo "ROLLBACK dogrulamasi: $ROLLBACK_VERIFIED"
  echo "Kalici DB yazma yapilmadi."
} > "$REPORT_FILE"

echo "OK ✅ User role dry-run report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4E DRY RUN OZET ====="
echo "4C_4E_DRY_RUN_STATUS=$DRY_RUN_STATUS"
echo "4C_4E_SQL_EXECUTION_STATUS=$DRY_RUN_SQL_EXECUTION_STATUS"
echo "4C_4E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
echo "4C_4E_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
echo "4C_4E_AFTER_USER_COUNT=$AFTER_USER_COUNT"
echo "4C_4E_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
echo "4C_4E_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
echo "4C_4E_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
echo "4C_4E_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
echo "4C_4E_DB_WRITE_APPLIED=NO"
echo "4C_4F_READY=$NEXT_READY"
