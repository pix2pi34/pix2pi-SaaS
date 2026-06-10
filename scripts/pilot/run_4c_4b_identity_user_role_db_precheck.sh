#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
USER_ROLE_ENV="docs/pilot/faz4c/4c_4a_user_role_identity_plan.env"

DOC_FILE="docs/pilot/faz4c/4c_4b_identity_user_role_db_precheck.md"
REPORT_FILE="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_report.md"

echo "===== 4C-4B IDENTITY USER ROLE DB PRECHECK ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4b_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4b_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4b_psql_error.log
    return $?
  fi

  return 127
}

count_lines() {
  local value="$1"
  if [ -z "$value" ]; then
    echo "0"
  else
    printf '%s\n' "$value" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
  fi
}

[ -f "$USER_ROLE_ENV" ] || fail "User role env yok: $USER_ROLE_ENV"

safe_source "$COMMON_ENV"
safe_source "$USER_ROLE_ENV"

PILOT_USER_EMAIL="${PILOT_USER_EMAIL:-uzmanparcaci1@gmail.com}"
PILOT_ROLE_CODE="${PILOT_ROLE_CODE:-PILOT_ADMIN}"
TENANT_BUSINESS_CODE="${TENANT_BUSINESS_CODE:-UZMANPARCACI}"
TENANT_SLUG="${TENANT_SLUG:-uzmanparcaci}"
TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"

DB_CONNECT_STATUS="FAIL"
if run_sql "select 1;" >/tmp/4c_4b_db_ping.out; then
  DB_CONNECT_STATUS="PASS"
fi

if [ "$DB_CONNECT_STATUS" != "PASS" ]; then
  ERR="$(cat /tmp/4c_4b_psql_error.log 2>/dev/null || true)"

  {
    echo "# FAZ 4C — 4C-4B Identity User Role DB Precheck Report"
    echo
    echo "Step: 4C-4B"
    echo "Blok: Identity User / Role DB Precheck"
    echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "## Test sonucu"
    echo
    echo "4C_4B_DB_PRECHECK_STATUS=BLOCKED"
    echo "4C_4B_DB_CONNECT_STATUS=FAIL"
    echo "4C_4B_CRITICAL_BLOCKER_COUNT=1"
    echo "4C_4B_BLOCKER_REASON=DB_CONNECTION_FAILED"
    echo "4C_4B_DB_WRITE_APPLIED=NO"
    echo "4C_4C_READY=NO"
    echo
    echo "## Hata"
    echo
    printf '%s\n' "$ERR"
  } > "$REPORT_FILE"

  echo "HATA ❌ DB baglantisi kurulamadi"
  echo "4C_4B_DB_CONNECT_STATUS=FAIL"
  exit 0
fi

TENANT_COUNT="$(
  run_sql "
select count(*)
from platform.tenants
where slug='${TENANT_SLUG}'
   or business_code='${TENANT_BUSINESS_CODE}'::core.code_text;
" | tr -d '[:space:]'
)"

TENANT_SCHEMA_COUNT="$(
  run_sql "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
" | tr -d '[:space:]'
)"

USER_TABLES="$(
  run_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('users','user','accounts','account','identities','identity_users','app_users')
    or lower(table_name) like '%user%'
    or lower(table_name) like '%account%'
    or lower(table_name) like '%identity%'
  )
order by table_schema, table_name;
" || true
)"

ROLE_TABLES="$(
  run_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('roles','role','permissions','permission')
    or lower(table_name) like '%role%'
    or lower(table_name) like '%permission%'
  )
order by table_schema, table_name;
" || true
)"

MAPPING_TABLES="$(
  run_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) like '%user%role%'
    or lower(table_name) like '%role%user%'
    or lower(table_name) like '%tenant%user%'
    or lower(table_name) like '%user%tenant%'
    or lower(table_name) like '%membership%'
    or lower(table_name) like '%assignment%'
  )
order by table_schema, table_name;
" || true
)"

USER_TABLE_COUNT="$(count_lines "$USER_TABLES")"
ROLE_TABLE_COUNT="$(count_lines "$ROLE_TABLES")"
MAPPING_TABLE_COUNT="$(count_lines "$MAPPING_TABLES")"

USER_TABLE_DETAILS=""
while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  columns="$(
    run_sql "
select column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
" || true
  )"

  USER_TABLE_DETAILS="${USER_TABLE_DETAILS}
### ${full_table}

${columns}
"
done <<< "$USER_TABLES"

ROLE_TABLE_DETAILS=""
while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  columns="$(
    run_sql "
select column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
" || true
  )"

  ROLE_TABLE_DETAILS="${ROLE_TABLE_DETAILS}
### ${full_table}

${columns}
"
done <<< "$ROLE_TABLES"

MAPPING_TABLE_DETAILS=""
while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  columns="$(
    run_sql "
select column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
" || true
  )"

  MAPPING_TABLE_DETAILS="${MAPPING_TABLE_DETAILS}
### ${full_table}

${columns}
"
done <<< "$MAPPING_TABLES"

EXISTING_USER_MATCHES=""
EXISTING_USER_COUNT=0

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  HAS_EMAIL="$(
    run_sql "
select count(*)
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name='email';
" | tr -d '[:space:]'
  )"

  if [ "$HAS_EMAIL" = "1" ]; then
    cnt="$(
      run_sql "
select count(*)
from ${full_table}
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
" | tr -d '[:space:]' || echo "0"
    )"

    if [ "$cnt" != "0" ]; then
      EXISTING_USER_MATCHES="${EXISTING_USER_MATCHES}${full_table}=${cnt}"$'\n'
      EXISTING_USER_COUNT=$((EXISTING_USER_COUNT + cnt))
    fi
  fi
done <<< "$USER_TABLES"

EXISTING_ROLE_MATCHES=""
EXISTING_ROLE_COUNT=0

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  HAS_CODE="$(
    run_sql "
select count(*)
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name in ('code','role_code');
" | tr -d '[:space:]'
  )"

  if [ "$HAS_CODE" != "0" ]; then
    CODE_COL="$(
      run_sql "
select column_name
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name in ('code','role_code')
order by case when column_name='code' then 1 else 2 end
limit 1;
" | tr -d '[:space:]'
    )"

    cnt="$(
      run_sql "
select count(*)
from ${full_table}
where upper(${CODE_COL}::text)=upper('${PILOT_ROLE_CODE}');
" | tr -d '[:space:]' || echo "0"
    )"

    if [ "$cnt" != "0" ]; then
      EXISTING_ROLE_MATCHES="${EXISTING_ROLE_MATCHES}${full_table}.${CODE_COL}=${cnt}"$'\n'
      EXISTING_ROLE_COUNT=$((EXISTING_ROLE_COUNT + cnt))
    fi
  fi
done <<< "$ROLE_TABLES"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
PRECHECK_STATUS="PASS"

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_SCHEMA_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$ROLE_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$MAPPING_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  PRECHECK_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-4B Identity User / Role DB Precheck"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci tenant icin kullanici, rol ve user-role mapping tablolarini kesfetmek."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Tenant kontrolu"
  echo
  echo "TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE"
  echo "TENANT_SCHEMA=$TENANT_SCHEMA"
  echo "TENANT_COUNT=$TENANT_COUNT"
  echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. Pilot kullanici / rol"
  echo
  echo "PILOT_USER_EMAIL=$PILOT_USER_EMAIL"
  echo "PILOT_ROLE_CODE=$PILOT_ROLE_CODE"
  echo
  echo "---"
  echo
  echo "## 3. User tablo adaylari"
  echo
  echo "USER_TABLE_COUNT=$USER_TABLE_COUNT"
  echo
  printf '%s\n' "$USER_TABLES"
  echo
  echo "---"
  echo
  echo "## 4. User tablo detaylari"
  printf '%s\n' "$USER_TABLE_DETAILS"
  echo
  echo "---"
  echo
  echo "## 5. Role tablo adaylari"
  echo
  echo "ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT"
  echo
  printf '%s\n' "$ROLE_TABLES"
  echo
  echo "---"
  echo
  echo "## 6. Role tablo detaylari"
  printf '%s\n' "$ROLE_TABLE_DETAILS"
  echo
  echo "---"
  echo
  echo "## 7. Mapping tablo adaylari"
  echo
  echo "MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT"
  echo
  printf '%s\n' "$MAPPING_TABLES"
  echo
  echo "---"
  echo
  echo "## 8. Mapping tablo detaylari"
  printf '%s\n' "$MAPPING_TABLE_DETAILS"
  echo
  echo "---"
  echo
  echo "## 9. Existing user / role kontrolu"
  echo
  echo "EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "EXISTING_USER_MATCHES:"
  printf '%s\n' "$EXISTING_USER_MATCHES"
  echo
  echo "EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "EXISTING_ROLE_MATCHES:"
  printf '%s\n' "$EXISTING_ROLE_MATCHES"
  echo
  echo "---"
  echo
  echo "## 10. Status"
  echo
  echo "4C_4B_DB_PRECHECK_STATUS=$PRECHECK_STATUS"
  echo "4C_4B_DB_CONNECT_STATUS=PASS"
  echo "4C_4B_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT"
  echo "4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT"
  echo "4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT"
  echo "4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4B_DB_WRITE_APPLIED=NO"
  echo "4C_4B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4B_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4C_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4B Identity User Role DB Precheck Report"
  echo
  echo "Step: 4C-4B"
  echo "Blok: Identity User / Role DB Precheck"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4B_DB_PRECHECK_STATUS=$PRECHECK_STATUS"
  echo "4C_4B_DB_CONNECT_STATUS=PASS"
  echo "4C_4B_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_4B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT"
  echo "4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT"
  echo "4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT"
  echo "4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4B_DB_WRITE_APPLIED=NO"
  echo "4C_4B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4B_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4C_READY=$NEXT_READY"
  echo
  echo "## User table candidates"
  printf '%s\n' "$USER_TABLES"
  echo
  echo "## Role table candidates"
  printf '%s\n' "$ROLE_TABLES"
  echo
  echo "## Mapping table candidates"
  printf '%s\n' "$MAPPING_TABLES"
  echo
  echo "## Sonuc"
  echo
  echo "Identity user/role DB precheck tamamlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-4C User / Role Apply Strategy Decision."
} > "$REPORT_FILE"

echo "OK ✅ Identity user role precheck dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Identity user role precheck report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4B PRECHECK OZET ====="
echo "4C_4B_DB_PRECHECK_STATUS=$PRECHECK_STATUS"
echo "4C_4B_DB_CONNECT_STATUS=PASS"
echo "4C_4B_TENANT_COUNT=$TENANT_COUNT"
echo "4C_4B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
echo "4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT"
echo "4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT"
echo "4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT"
echo "4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
echo "4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
echo "4C_4B_DB_WRITE_APPLIED=NO"
echo "4C_4C_READY=$NEXT_READY"
