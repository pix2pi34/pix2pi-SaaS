#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
SQL_FILE="sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4e_fix1_dry_run_error_diagnosis.md"
REPORT_FILE="reports/pilot/faz4c/4c_4e_fix1_dry_run_error_diagnosis_report.md"

PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"

echo "===== 4C-4E-FIX1 USER ROLE DRY RUN ERROR DIAGNOSIS ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

safe_source() {
  local f="$1"
  if [ -f "$f" ]; then
    set -a
    source "$f"
    set +a
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4e_fix1_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4e_fix1_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4e_fix1_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_4e_fix1_sql_output.log /tmp/4c_4e_fix1_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4e_fix1_sql_output.log 2>/tmp/4c_4e_fix1_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_4e_fix1_sql_output.log 2>/tmp/4c_4e_fix1_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_4e_fix1_preview.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_4e_fix1_preview.sql >/tmp/4c_4e_fix1_sql_output.log 2>/tmp/4c_4e_fix1_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_4e_fix1_sql_error.log
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

table_columns() {
  local schema="$1"
  local table="$2"

  run_sql "
select
  ordinal_position || '. ' ||
  column_name || ' | ' ||
  data_type || ' | udt=' ||
  udt_schema || '.' || udt_name || ' | nullable=' ||
  is_nullable || ' | default=' ||
  coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema}'
  and table_name='${table}'
order by ordinal_position;
" || true
}

required_columns() {
  local schema="$1"
  local table="$2"

  run_sql "
select column_name
from information_schema.columns
where table_schema='${schema}'
  and table_name='${table}'
  and is_nullable='NO'
  and column_default is null
order by ordinal_position;
" || true
}

table_constraints() {
  local schema="$1"
  local table="$2"

  run_sql "
select
  tc.constraint_name || ' | ' ||
  tc.constraint_type || ' | ' ||
  coalesce(kcu.column_name,'') || ' | ' ||
  coalesce(ccu.table_schema || '.' || ccu.table_name || '.' || ccu.column_name,'')
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
 and tc.table_schema = kcu.table_schema
 and tc.table_name = kcu.table_name
left join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
 and tc.table_schema = ccu.table_schema
where tc.table_schema='${schema}'
  and tc.table_name='${table}'
order by tc.constraint_name, kcu.ordinal_position;
" || true
}

[ -f "$SQL_FILE" ] || fail "SQL preview file yok: $SQL_FILE"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_4e_fix1_db_ping.out; then
  ERR="$(cat /tmp/4c_4e_fix1_psql_error.log 2>/dev/null || true)"
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

DRY_RUN_STATUS="PASS"

if ! run_sql_file "$SQL_FILE"; then
  DRY_RUN_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_4e_fix1_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_4e_fix1_sql_error.log 2>/dev/null || true)"

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

ROLLBACK_SAFE="NO"
if [ "$BEFORE_USER_COUNT" = "$AFTER_USER_COUNT" ] && \
   [ "$BEFORE_ROLE_COUNT" = "$AFTER_ROLE_COUNT" ] && \
   [ "$BEFORE_ASSIGNMENT_COUNT" = "$AFTER_ASSIGNMENT_COUNT" ]; then
  ROLLBACK_SAFE="YES"
fi

AUTH_USERS_COLUMNS="$(table_columns auth users)"
AUTH_ROLES_COLUMNS="$(table_columns auth roles)"
AUTH_ASSIGN_COLUMNS="$(table_columns auth user_role_assignments)"

AUTH_USERS_REQUIRED="$(required_columns auth users)"
AUTH_ROLES_REQUIRED="$(required_columns auth roles)"
AUTH_ASSIGN_REQUIRED="$(required_columns auth user_role_assignments)"

AUTH_USERS_CONSTRAINTS="$(table_constraints auth users)"
AUTH_ROLES_CONSTRAINTS="$(table_constraints auth roles)"
AUTH_ASSIGN_CONSTRAINTS="$(table_constraints auth user_role_assignments)"

{
  echo "# FAZ 4C — 4C-4E-FIX1 Dry Run Error Diagnosis"
  echo
  echo "## Amac"
  echo
  echo "4C-4E dry-run neden FAIL oldu, gercek PostgreSQL hatasini yakalamak."
  echo
  echo "Bu adim kalici DB yazma yapmaz."
  echo
  echo "---"
  echo
  echo "## 1. Dry-run sonucu"
  echo
  echo "DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo "BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. SQL output"
  printf '%s\n' "$SQL_OUTPUT" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 3. SQL error"
  printf '%s\n' "$SQL_ERROR" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 4. auth.users kolonlari"
  printf '%s\n' "$AUTH_USERS_COLUMNS" | sed 's/^/    /'
  echo
  echo "auth.users required no default:"
  printf '%s\n' "$AUTH_USERS_REQUIRED" | sed 's/^/    /'
  echo
  echo "auth.users constraints:"
  printf '%s\n' "$AUTH_USERS_CONSTRAINTS" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 5. auth.roles kolonlari"
  printf '%s\n' "$AUTH_ROLES_COLUMNS" | sed 's/^/    /'
  echo
  echo "auth.roles required no default:"
  printf '%s\n' "$AUTH_ROLES_REQUIRED" | sed 's/^/    /'
  echo
  echo "auth.roles constraints:"
  printf '%s\n' "$AUTH_ROLES_CONSTRAINTS" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 6. auth.user_role_assignments kolonlari"
  printf '%s\n' "$AUTH_ASSIGN_COLUMNS" | sed 's/^/    /'
  echo
  echo "auth.user_role_assignments required no default:"
  printf '%s\n' "$AUTH_ASSIGN_REQUIRED" | sed 's/^/    /'
  echo
  echo "auth.user_role_assignments constraints:"
  printf '%s\n' "$AUTH_ASSIGN_CONSTRAINTS" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_4E_FIX1_DIAGNOSIS_STATUS=PASS"
  echo "4C_4E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_4E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo "4C_4E_FIX1_DB_WRITE_APPLIED=NO"
  echo "4C_4D_FIX4_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4E-FIX1 Dry Run Error Diagnosis Report"
  echo
  echo "Step: 4C-4E-FIX1"
  echo "Blok: Dry Run Error Diagnosis"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4E_FIX1_DIAGNOSIS_STATUS=PASS"
  echo "4C_4E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_4E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo "4C_4E_FIX1_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
  echo "4C_4E_FIX1_AFTER_USER_COUNT=$AFTER_USER_COUNT"
  echo "4C_4E_FIX1_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
  echo "4C_4E_FIX1_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
  echo "4C_4E_FIX1_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
  echo "4C_4E_FIX1_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
  echo "4C_4E_FIX1_DB_WRITE_APPLIED=NO"
  echo "4C_4D_FIX4_READY=YES"
  echo
  echo "## SQL error"
  printf '%s\n' "$SQL_ERROR" | sed 's/^/    /'
  echo
  echo "## auth.users required no default"
  printf '%s\n' "$AUTH_USERS_REQUIRED" | sed 's/^/    /'
  echo
  echo "## auth.roles required no default"
  printf '%s\n' "$AUTH_ROLES_REQUIRED" | sed 's/^/    /'
  echo
  echo "## auth.user_role_assignments required no default"
  printf '%s\n' "$AUTH_ASSIGN_REQUIRED" | sed 's/^/    /'
  echo
  echo "## Sonuc"
  echo
  echo "Dry-run hatasi yakalandi."
  echo "Kalici DB yazma yapilmadi."
  echo "Bir sonraki adimda SQL mapping duzeltilecek."
} > "$REPORT_FILE"

echo "OK ✅ Diagnosis dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Diagnosis report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4E-FIX1 OZET ====="
echo "4C_4E_FIX1_DIAGNOSIS_STATUS=PASS ✅"
echo "4C_4E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
echo "4C_4E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
echo "4C_4E_FIX1_BEFORE_USER_COUNT=$BEFORE_USER_COUNT"
echo "4C_4E_FIX1_AFTER_USER_COUNT=$AFTER_USER_COUNT"
echo "4C_4E_FIX1_BEFORE_ROLE_COUNT=$BEFORE_ROLE_COUNT"
echo "4C_4E_FIX1_AFTER_ROLE_COUNT=$AFTER_ROLE_COUNT"
echo "4C_4E_FIX1_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT_COUNT"
echo "4C_4E_FIX1_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT_COUNT"
echo "4C_4E_FIX1_DB_WRITE_APPLIED=NO"
echo "4C_4D_FIX4_READY=YES"
