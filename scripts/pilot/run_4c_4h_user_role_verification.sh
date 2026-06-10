#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_4g_user_role_apply_execution_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4h_user_role_verification.md"
REPORT_FILE="reports/pilot/faz4c/4c_4h_user_role_verification_report.md"

PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"
TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
TENANT_BUSINESS_CODE="UZMANPARCACI"
TENANT_SLUG="uzmanparcaci"

echo "===== 4C-4H USER ROLE VERIFICATION / ACCESS SMOKE ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4h_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4h_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4h_psql_error.log
    return $?
  fi

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

safe_value() {
  local sql="$1"
  local out
  out="$(run_sql "$sql" 2>/dev/null || true)"
  out="$(printf "%s" "$out" | tr -d '\r')"
  if [ -z "$out" ]; then
    echo "NONE"
  else
    echo "$out"
  fi
}

[ -f "$PREV_REPORT" ] || fail "4C-4G test report yok: $PREV_REPORT"

grep -q "4C_4G_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4G test PASS degil"
grep -q "4C_4G_USER_ROLE_APPLY_STATUS=PASS" "$PREV_REPORT" || fail "4C-4G apply PASS degil"
grep -q "4C_4G_DB_WRITE_APPLIED=YES" "$PREV_REPORT" || fail "4C-4G DB write YES degil"
grep -q "4C_4H_READY=YES" "$PREV_REPORT" || fail "4C-4H ready YES degil"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_4h_db_ping.out; then
  ERR="$(cat /tmp/4c_4h_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

TENANT_COUNT="$(safe_count "
select count(*)
from platform.tenants
where id='${TENANT_ID}'::uuid
  and business_code='${TENANT_BUSINESS_CODE}'::core.code_text
  and slug='${TENANT_SLUG}';
")"

USER_COUNT="$(safe_count "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
")"

USER_TENANT_MATCH_COUNT="$(safe_count "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
  and tenant_id='${TENANT_ID}'::uuid;
")"

ROLE_COUNT="$(safe_count "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

ROLE_TENANT_MATCH_COUNT="$(safe_count "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}')
  and tenant_id='${TENANT_ID}'::uuid;
")"

ASSIGNMENT_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

ASSIGNMENT_TENANT_MATCH_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}')
  and a.tenant_id='${TENANT_ID}'::uuid
  and u.tenant_id='${TENANT_ID}'::uuid
  and r.tenant_id='${TENANT_ID}'::uuid;
")"

PASSWORD_HASH_STATUS="$(safe_value "
select
  case
    when password_hash='PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED' then 'TEMP_PASSWORD_HASH_RESET_REQUIRED'
    when password_hash is null then 'PASSWORD_HASH_NULL'
    else 'CUSTOM_PASSWORD_HASH_SET'
  end
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
limit 1;
")"

USER_IS_ACTIVE="$(safe_value "
select is_active::text
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
limit 1;
")"

ROLE_NAME="$(safe_value "
select role_name::text
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}')
limit 1;
")"

SUPER_ADMIN_ASSIGNMENT_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text) in ('SUPER_ADMIN','PLATFORM_ADMIN','GLOBAL_ADMIN','ROOT_ADMIN');
")"

CROSS_TENANT_ASSIGNMENT_COUNT="$(safe_count "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and (
    a.tenant_id <> '${TENANT_ID}'::uuid
    or u.tenant_id <> '${TENANT_ID}'::uuid
    or r.tenant_id <> '${TENANT_ID}'::uuid
  );
")"

USER_ROW="$(safe_value "
select
  id::text || ' | ' ||
  tenant_id::text || ' | ' ||
  email::text || ' | ' ||
  full_name::text || ' | ' ||
  is_active::text || ' | ' ||
  case
    when password_hash='PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED' then 'TEMP_PASSWORD_HASH'
    else 'OTHER_PASSWORD_HASH'
  end
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
limit 1;
")"

ROLE_ROW="$(safe_value "
select
  id::text || ' | ' ||
  tenant_id::text || ' | ' ||
  role_code::text || ' | ' ||
  role_name::text
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}')
limit 1;
")"

ASSIGNMENT_ROW="$(safe_value "
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
")"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
VERIFY_STATUS="PASS"

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLE_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLE_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ASSIGNMENT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ASSIGNMENT_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SUPER_ADMIN_ASSIGNMENT_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$CROSS_TENANT_ASSIGNMENT_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$PASSWORD_HASH_STATUS" = "TEMP_PASSWORD_HASH_RESET_REQUIRED" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$USER_IS_ACTIVE" != "true" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  VERIFY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-4H User Role Verification / Access Smoke"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve assignment kaydini dogrulamak."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Tenant verification"
  echo
  echo "TENANT_COUNT=$TENANT_COUNT"
  echo "TENANT_ID=$TENANT_ID"
  echo "TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE"
  echo
  echo "---"
  echo
  echo "## 2. User verification"
  echo
  echo "USER_COUNT=$USER_COUNT"
  echo "USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT"
  echo "USER_IS_ACTIVE=$USER_IS_ACTIVE"
  echo "PASSWORD_HASH_STATUS=$PASSWORD_HASH_STATUS"
  echo
  echo "USER_ROW:"
  echo "    $USER_ROW"
  echo
  echo "---"
  echo
  echo "## 3. Role verification"
  echo
  echo "ROLE_COUNT=$ROLE_COUNT"
  echo "ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT"
  echo "ROLE_NAME=$ROLE_NAME"
  echo
  echo "ROLE_ROW:"
  echo "    $ROLE_ROW"
  echo
  echo "---"
  echo
  echo "## 4. Assignment verification"
  echo
  echo "ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT"
  echo "ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT"
  echo
  echo "ASSIGNMENT_ROW:"
  echo "    $ASSIGNMENT_ROW"
  echo
  echo "---"
  echo
  echo "## 5. Access smoke"
  echo
  echo "SUPER_ADMIN_ASSIGNMENT_COUNT=$SUPER_ADMIN_ASSIGNMENT_COUNT"
  echo "CROSS_TENANT_ASSIGNMENT_COUNT=$CROSS_TENANT_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 6. Password gate"
  echo
  echo "PASSWORD_HASH_STATUS=$PASSWORD_HASH_STATUS"
  echo "PASSWORD_RESET_OR_INVITE_REQUIRED=YES"
  echo "Bu uyari bilincli olarak korunur. Canli giris acilmadan once parola reset/davet akisi calistirilmalidir."
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_4H_USER_ROLE_VERIFICATION_STATUS=$VERIFY_STATUS"
  echo "4C_4H_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4H_USER_COUNT=$USER_COUNT"
  echo "4C_4H_USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT"
  echo "4C_4H_ROLE_COUNT=$ROLE_COUNT"
  echo "4C_4H_ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT"
  echo "4C_4H_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT"
  echo "4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT"
  echo "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=$SUPER_ADMIN_ASSIGNMENT_COUNT"
  echo "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=$CROSS_TENANT_ASSIGNMENT_COUNT"
  echo "4C_4H_PASSWORD_HASH_STATUS=$PASSWORD_HASH_STATUS"
  echo "4C_4H_PASSWORD_RESET_OR_INVITE_REQUIRED=YES"
  echo "4C_4H_DB_WRITE_APPLIED=NO"
  echo "4C_4H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4H_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4I_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4H User Role Verification Report"
  echo
  echo "Step: 4C-4H"
  echo "Blok: User / Role Verification / Access Smoke"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4H_USER_ROLE_VERIFICATION_STATUS=$VERIFY_STATUS"
  echo "4C_4H_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4H_USER_COUNT=$USER_COUNT"
  echo "4C_4H_USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT"
  echo "4C_4H_ROLE_COUNT=$ROLE_COUNT"
  echo "4C_4H_ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT"
  echo "4C_4H_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT"
  echo "4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT"
  echo "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=$SUPER_ADMIN_ASSIGNMENT_COUNT"
  echo "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=$CROSS_TENANT_ASSIGNMENT_COUNT"
  echo "4C_4H_PASSWORD_HASH_STATUS=$PASSWORD_HASH_STATUS"
  echo "4C_4H_PASSWORD_RESET_OR_INVITE_REQUIRED=YES"
  echo "4C_4H_DB_WRITE_APPLIED=NO"
  echo "4C_4H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4H_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4I_READY=$NEXT_READY"
  echo
  echo "## User row"
  echo "    $USER_ROW"
  echo
  echo "## Role row"
  echo "    $ROLE_ROW"
  echo
  echo "## Assignment row"
  echo "    $ASSIGNMENT_ROW"
  echo
  echo "## Sonuc"
  echo "User/role verification smoke tamamlandi."
  echo "Kalici DB yazma yapilmadi."
  echo "Sonraki adim: 4C-4I User / Role Assignment Final Closure."
} > "$REPORT_FILE"

echo "OK ✅ User role verification report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4H VERIFICATION OZET ====="
echo "4C_4H_USER_ROLE_VERIFICATION_STATUS=$VERIFY_STATUS"
echo "4C_4H_TENANT_COUNT=$TENANT_COUNT"
echo "4C_4H_USER_COUNT=$USER_COUNT"
echo "4C_4H_USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT"
echo "4C_4H_ROLE_COUNT=$ROLE_COUNT"
echo "4C_4H_ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT"
echo "4C_4H_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT"
echo "4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT"
echo "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=$SUPER_ADMIN_ASSIGNMENT_COUNT"
echo "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=$CROSS_TENANT_ASSIGNMENT_COUNT"
echo "4C_4H_PASSWORD_HASH_STATUS=$PASSWORD_HASH_STATUS"
echo "4C_4H_DB_WRITE_APPLIED=NO"
echo "4C_4I_READY=$NEXT_READY"
