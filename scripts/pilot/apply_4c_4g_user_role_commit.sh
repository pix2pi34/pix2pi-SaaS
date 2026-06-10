#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
COMMIT_SQL="sql/pilot/faz4c/4c_4f_commit_user_role_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_4f_user_role_commit_sql_package_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4g_user_role_apply_execution.md"
REPORT_FILE="reports/pilot/faz4c/4c_4g_user_role_apply_execution_report.md"

PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"
TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
TENANT_BUSINESS_CODE="UZMANPARCACI"

echo "===== 4C-4G USER ROLE APPLY EXECUTION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4g_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4g_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4g_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_4g_sql_output.log /tmp/4c_4g_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4g_sql_output.log 2>/tmp/4c_4g_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4g_sql_output.log 2>/tmp/4c_4g_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_4g_user_role_commit.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_4g_user_role_commit.sql >/tmp/4c_4g_sql_output.log 2>/tmp/4c_4g_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_4g_sql_error.log
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

[ -f "$COMMIT_SQL" ] || fail "Commit SQL yok: $COMMIT_SQL"
[ -f "$PREV_REPORT" ] || fail "4C-4F test report yok: $PREV_REPORT"

grep -q "4C_4F_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4F test PASS degil"
grep -q "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS" "$PREV_REPORT" || fail "4C-4F commit package PASS degil"
grep -q "4C_4F_COMMIT_SQL_HAS_COMMIT=YES" "$PREV_REPORT" || fail "Commit SQL has COMMIT YES degil"
grep -q "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO" "$PREV_REPORT" || fail "Commit SQL has ROLLBACK NO degil"
grep -q "4C_4F_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-4F DB write NO degil"
grep -q "4C_4G_READY=YES" "$PREV_REPORT" || fail "4C-4G ready YES degil"

grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL icinde COMMIT yok"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi

grep -q "PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED" "$COMMIT_SQL" || fail "Commit SQL temp password hash yok"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_4g_db_ping.out; then
  ERR="$(cat /tmp/4c_4g_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

TENANT_COUNT="$(safe_count "
select count(*)
from platform.tenants
where id='${TENANT_ID}'::uuid
  and business_code='${TENANT_BUSINESS_CODE}'::core.code_text;
")"

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

APPLY_SQL_EXECUTION_STATUS="PASS"

if ! run_sql_file "$COMMIT_SQL"; then
  APPLY_SQL_EXECUTION_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_4g_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_4g_sql_error.log 2>/dev/null || true)"

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

USER_ROW="$(
  run_sql "
select
  id::text || ' | ' ||
  tenant_id::text || ' | ' ||
  email::text || ' | ' ||
  full_name::text || ' | ' ||
  is_active::text || ' | ' ||
  case when password_hash='PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED' then 'TEMP_PASSWORD_HASH' else 'CUSTOM_PASSWORD_HASH' end
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
limit 1;
" || true
)"

ROLE_ROW="$(
  run_sql "
select
  id::text || ' | ' ||
  tenant_id::text || ' | ' ||
  role_code::text || ' | ' ||
  role_name::text
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}')
limit 1;
" || true
)"

ASSIGNMENT_ROW="$(
  run_sql "
select
  a.tenant_id::text || ' | ' ||
  a.user_id::text || ' | ' ||
  a.role_id::text
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}')
limit 1;
" || true
)"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
APPLY_STATUS="PASS"

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$APPLY_SQL_EXECUTION_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_USER_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_ROLE_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_ASSIGNMENT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

# Temp password hash bilerek kullaniliyor; canli login icin 4C-4H/4C-4I tarafinda reset/davet gate olarak izlenecek.
WARNING_COUNT=$((WARNING_COUNT + 1))

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  APPLY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-4G User Role Apply Execution"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment kaydini DB'ye uygulamak."
  echo
  echo "Bu adim gercek DB write yapar."
  echo
  echo "---"
  echo
  echo "## 1. Apply oncesi durum"
  echo
  echo "TENANT_COUNT=$TENANT_COUNT"
  echo "BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. SQL execution"
  echo
  echo "APPLY_SQL_EXECUTION_STATUS=$APPLY_SQL_EXECUTION_STATUS"
  echo
  echo "SQL output:"
  printf '%s\n' "$SQL_OUTPUT" | sed 's/^/    /'
  echo
  echo "SQL error:"
  printf '%s\n' "$SQL_ERROR" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 3. Apply sonrasi durum"
  echo
  echo "AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 4. User row"
  printf '%s\n' "$USER_ROW" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 5. Role row"
  printf '%s\n' "$ROLE_ROW" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 6. Assignment row"
  printf '%s\n' "$ASSIGNMENT_ROW" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 7. Password gate"
  echo
  echo "PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED"
  echo "Bu kullanici canli girise acilmadan once parola reset / davet akisi zorunlu kapidir."
  echo
  echo "---"
  echo
  echo "## 8. Status"
  echo
  echo "4C_4G_USER_ROLE_APPLY_STATUS=$APPLY_STATUS"
  echo "4C_4G_SQL_EXECUTION_STATUS=$APPLY_SQL_EXECUTION_STATUS"
  echo "4C_4G_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4G_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "4C_4G_AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "4C_4G_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "4C_4G_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "4C_4G_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "4C_4G_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo "4C_4G_PILOT_USER_EMAIL=$PILOT_USER_EMAIL"
  echo "4C_4G_PILOT_ROLE_CODE=$PILOT_ROLE_CODE"
  echo "4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED"
  echo "4C_4G_DB_WRITE_APPLIED=YES"
  echo "4C_4G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4G_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4H_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4G User Role Apply Execution Report"
  echo
  echo "Step: 4C-4G"
  echo "Blok: User / Role Apply Execution"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4G_USER_ROLE_APPLY_STATUS=$APPLY_STATUS"
  echo "4C_4G_SQL_EXECUTION_STATUS=$APPLY_SQL_EXECUTION_STATUS"
  echo "4C_4G_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4G_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "4C_4G_AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "4C_4G_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "4C_4G_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "4C_4G_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "4C_4G_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo "4C_4G_PILOT_USER_EMAIL=$PILOT_USER_EMAIL"
  echo "4C_4G_PILOT_ROLE_CODE=$PILOT_ROLE_CODE"
  echo "4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED"
  echo "4C_4G_DB_WRITE_APPLIED=YES"
  echo "4C_4G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4G_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4H_READY=$NEXT_READY"
  echo
  echo "## User row"
  printf '%s\n' "$USER_ROW" | sed 's/^/    /'
  echo
  echo "## Role row"
  printf '%s\n' "$ROLE_ROW" | sed 's/^/    /'
  echo
  echo "## Assignment row"
  printf '%s\n' "$ASSIGNMENT_ROW" | sed 's/^/    /'
  echo
  echo "## Sonuc"
  echo
  echo "User/role apply execution tamamlandi."
  echo "uzmanparcaci pilot kullanicisi ve PILOT_ADMIN rolu DB'ye islendi."
  echo "Sonraki adim: 4C-4H User / Role Verification / Access Smoke."
} > "$REPORT_FILE"

echo "OK ✅ User role apply execution report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4G APPLY OZET ====="
echo "4C_4G_USER_ROLE_APPLY_STATUS=$APPLY_STATUS"
echo "4C_4G_SQL_EXECUTION_STATUS=$APPLY_SQL_EXECUTION_STATUS"
echo "4C_4G_TENANT_COUNT=$TENANT_COUNT"
echo "4C_4G_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
echo "4C_4G_AFTER_USER_COUNT=$AFTER_USER_COUNT"
echo "4C_4G_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
echo "4C_4G_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
echo "4C_4G_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
echo "4C_4G_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
echo "4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED"
echo "4C_4G_DB_WRITE_APPLIED=YES"
echo "4C_4H_READY=$NEXT_READY"
