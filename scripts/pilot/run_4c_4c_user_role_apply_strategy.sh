#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
USER_ROLE_ENV="docs/pilot/faz4c/4c_4a_user_role_identity_plan.env"
PRECHECK_REPORT="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4c_user_role_apply_strategy.md"
REPORT_FILE="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_report.md"

echo "===== 4C-4C USER ROLE APPLY STRATEGY DECISION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4c_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4c_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4c_psql_error.log
    return $?
  fi

  return 127
}

get_report_value() {
  local key="$1"
  local file="$2"
  local value
  value="$(grep "^${key}=" "$file" | tail -n 1 | cut -d'=' -f2- | tr -d '\r' || true)"
  if [ -z "$value" ]; then
    echo "UNKNOWN"
  else
    echo "$value"
  fi
}

count_lines() {
  local value="$1"
  if [ -z "$value" ]; then
    echo "0"
  else
    printf '%s\n' "$value" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
  fi
}

has_column() {
  local full_table="$1"
  local col="$2"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  run_sql "
select count(*)
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name='${col}';
" | tr -d '[:space:]'
}

column_list() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  run_sql "
select column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
" || true
}

not_null_no_default_list() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  run_sql "
select column_name
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and is_nullable='NO'
  and column_default is null
order by ordinal_position;
" || true
}

[ -f "$USER_ROLE_ENV" ] || fail "User role env yok: $USER_ROLE_ENV"
[ -f "$PRECHECK_REPORT" ] || fail "4C-4B precheck report yok: $PRECHECK_REPORT"

safe_source "$COMMON_ENV"
safe_source "$USER_ROLE_ENV"

PILOT_USER_EMAIL="${PILOT_USER_EMAIL:-uzmanparcaci1@gmail.com}"
PILOT_USER_FULL_NAME="${PILOT_USER_FULL_NAME:-mert_omur}"
PILOT_USER_DISPLAY_NAME="${PILOT_USER_DISPLAY_NAME:-mert omur}"
PILOT_USER_PHONE="${PILOT_USER_PHONE:-5377457536}"
PILOT_ROLE_CODE="${PILOT_ROLE_CODE:-PILOT_ADMIN}"
PILOT_ROLE_NAME="${PILOT_ROLE_NAME:-Pilot Admin}"
TENANT_BUSINESS_CODE="${TENANT_BUSINESS_CODE:-UZMANPARCACI}"
TENANT_SLUG="${TENANT_SLUG:-uzmanparcaci}"
TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"

PRECHECK_STATUS="$(get_report_value 4C_4B_DB_PRECHECK_STATUS "$PRECHECK_REPORT")"
DB_CONNECT_PREV="$(get_report_value 4C_4B_DB_CONNECT_STATUS "$PRECHECK_REPORT")"
TENANT_COUNT_PREV="$(get_report_value 4C_4B_TENANT_COUNT "$PRECHECK_REPORT")"
USER_TABLE_COUNT_PREV="$(get_report_value 4C_4B_USER_TABLE_COUNT "$PRECHECK_REPORT")"
ROLE_TABLE_COUNT_PREV="$(get_report_value 4C_4B_ROLE_TABLE_COUNT "$PRECHECK_REPORT")"
MAPPING_TABLE_COUNT_PREV="$(get_report_value 4C_4B_MAPPING_TABLE_COUNT "$PRECHECK_REPORT")"
EXISTING_USER_COUNT_PREV="$(get_report_value 4C_4B_EXISTING_USER_COUNT "$PRECHECK_REPORT")"
EXISTING_ROLE_COUNT_PREV="$(get_report_value 4C_4B_EXISTING_ROLE_COUNT "$PRECHECK_REPORT")"

[ "$PRECHECK_STATUS" = "PASS" ] || fail "4C-4B precheck PASS degil"
[ "$DB_CONNECT_PREV" = "PASS" ] || fail "4C-4B DB connect PASS degil"
[ "$TENANT_COUNT_PREV" = "1" ] || fail "Tenant count 1 degil"

if ! run_sql "select 1;" >/tmp/4c_4c_db_ping.out; then
  ERR="$(cat /tmp/4c_4c_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

TENANT_ID="$(
  run_sql "
select id::text
from platform.tenants
where slug='${TENANT_SLUG}'
   or business_code='${TENANT_BUSINESS_CODE}'::core.code_text
limit 1;
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

BEST_USER_TABLE="NONE"
BEST_USER_SCORE="-1"
USER_SCORE_DETAILS=""

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue

  score=0
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  [ "$schema_name" = "auth" ] && score=$((score + 40))
  [ "$table_name" = "users" ] && score=$((score + 60))
  [ "$table_name" = "identity_users" ] && score=$((score + 45))
  [ "$(has_column "$full_table" "email")" != "0" ] && score=$((score + 30))
  [ "$(has_column "$full_table" "id")" != "0" ] && score=$((score + 20))
  [ "$(has_column "$full_table" "tenant_id")" != "0" ] && score=$((score + 20))
  [ "$(has_column "$full_table" "full_name")" != "0" ] && score=$((score + 10))
  [ "$(has_column "$full_table" "display_name")" != "0" ] && score=$((score + 10))
  [ "$(has_column "$full_table" "phone")" != "0" ] && score=$((score + 8))
  [ "$(has_column "$full_table" "status")" != "0" ] && score=$((score + 8))
  [ "$(has_column "$full_table" "created_at")" != "0" ] && score=$((score + 5))

  USER_SCORE_DETAILS="${USER_SCORE_DETAILS}${full_table}=score:${score}"$'\n'

  if [ "$score" -gt "$BEST_USER_SCORE" ]; then
    BEST_USER_SCORE="$score"
    BEST_USER_TABLE="$full_table"
  fi
done <<< "$USER_TABLES"

BEST_ROLE_TABLE="NONE"
BEST_ROLE_SCORE="-1"
ROLE_SCORE_DETAILS=""

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue

  score=0
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  [ "$schema_name" = "auth" ] && score=$((score + 40))
  [ "$table_name" = "roles" ] && score=$((score + 60))
  [ "$(has_column "$full_table" "code")" != "0" ] && score=$((score + 30))
  [ "$(has_column "$full_table" "role_code")" != "0" ] && score=$((score + 25))
  [ "$(has_column "$full_table" "name")" != "0" ] && score=$((score + 20))
  [ "$(has_column "$full_table" "id")" != "0" ] && score=$((score + 20))
  [ "$(has_column "$full_table" "tenant_id")" != "0" ] && score=$((score + 15))
  [ "$(has_column "$full_table" "scope")" != "0" ] && score=$((score + 10))
  [ "$(has_column "$full_table" "status")" != "0" ] && score=$((score + 8))

  ROLE_SCORE_DETAILS="${ROLE_SCORE_DETAILS}${full_table}=score:${score}"$'\n'

  if [ "$score" -gt "$BEST_ROLE_SCORE" ]; then
    BEST_ROLE_SCORE="$score"
    BEST_ROLE_TABLE="$full_table"
  fi
done <<< "$ROLE_TABLES"

BEST_MAPPING_TABLE="NONE"
BEST_MAPPING_SCORE="-1"
MAPPING_SCORE_DETAILS=""

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue

  score=0
  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  [ "$schema_name" = "auth" ] && score=$((score + 40))
  [ "$table_name" = "user_role_assignments" ] && score=$((score + 80))
  [ "$(has_column "$full_table" "user_id")" != "0" ] && score=$((score + 30))
  [ "$(has_column "$full_table" "role_id")" != "0" ] && score=$((score + 30))
  [ "$(has_column "$full_table" "tenant_id")" != "0" ] && score=$((score + 20))
  [ "$(has_column "$full_table" "created_at")" != "0" ] && score=$((score + 5))

  MAPPING_SCORE_DETAILS="${MAPPING_SCORE_DETAILS}${full_table}=score:${score}"$'\n'

  if [ "$score" -gt "$BEST_MAPPING_SCORE" ]; then
    BEST_MAPPING_SCORE="$score"
    BEST_MAPPING_TABLE="$full_table"
  fi
done <<< "$MAPPING_TABLES"

USER_COLUMNS="$(column_list "$BEST_USER_TABLE")"
ROLE_COLUMNS="$(column_list "$BEST_ROLE_TABLE")"
MAPPING_COLUMNS="$(column_list "$BEST_MAPPING_TABLE")"

USER_REQUIRED_COLUMNS="$(not_null_no_default_list "$BEST_USER_TABLE")"
ROLE_REQUIRED_COLUMNS="$(not_null_no_default_list "$BEST_ROLE_TABLE")"
MAPPING_REQUIRED_COLUMNS="$(not_null_no_default_list "$BEST_MAPPING_TABLE")"

USER_REQUIRED_COUNT="$(count_lines "$USER_REQUIRED_COLUMNS")"
ROLE_REQUIRED_COUNT="$(count_lines "$ROLE_REQUIRED_COLUMNS")"
MAPPING_REQUIRED_COUNT="$(count_lines "$MAPPING_REQUIRED_COLUMNS")"

EXISTING_USER_COUNT="0"
if [ "$BEST_USER_TABLE" != "NONE" ] && [ "$(has_column "$BEST_USER_TABLE" "email")" != "0" ]; then
  EXISTING_USER_COUNT="$(
    run_sql "
select count(*)
from ${BEST_USER_TABLE}
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
" | tr -d '[:space:]'
  )"
fi

EXISTING_ROLE_COUNT="0"
ROLE_CODE_COLUMN="NONE"

if [ "$BEST_ROLE_TABLE" != "NONE" ]; then
  if [ "$(has_column "$BEST_ROLE_TABLE" "code")" != "0" ]; then
    ROLE_CODE_COLUMN="code"
  elif [ "$(has_column "$BEST_ROLE_TABLE" "role_code")" != "0" ]; then
    ROLE_CODE_COLUMN="role_code"
  fi

  if [ "$ROLE_CODE_COLUMN" != "NONE" ]; then
    EXISTING_ROLE_COUNT="$(
      run_sql "
select count(*)
from ${BEST_ROLE_TABLE}
where upper(${ROLE_CODE_COLUMN}::text)=upper('${PILOT_ROLE_CODE}');
" | tr -d '[:space:]'
    )"
  fi
fi

USER_CREATE_NEEDED="YES"
ROLE_CREATE_NEEDED="YES"
ASSIGNMENT_CREATE_NEEDED="YES"

[ "$EXISTING_USER_COUNT" != "0" ] && USER_CREATE_NEEDED="NO"
[ "$EXISTING_ROLE_COUNT" != "0" ] && ROLE_CREATE_NEEDED="NO"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
STRATEGY_STATUS="PASS"
NEXT_READY="YES"

if [ -z "$TENANT_ID" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BEST_USER_TABLE" = "NONE" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BEST_ROLE_TABLE" = "NONE" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BEST_MAPPING_TABLE" = "NONE" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_REQUIRED_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$ROLE_REQUIRED_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$MAPPING_REQUIRED_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  STRATEGY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-4C User / Role Apply Strategy Decision"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci pilot kullanicisi ve rol atamasi icin DB apply stratejisini belirlemek."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Onceki precheck"
  echo
  echo "4C_4B_DB_PRECHECK_STATUS=$PRECHECK_STATUS"
  echo "4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT_PREV"
  echo "4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT_PREV"
  echo "4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT_PREV"
  echo "4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT_PREV"
  echo "4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT_PREV"
  echo
  echo "---"
  echo
  echo "## 2. Tenant"
  echo
  echo "TENANT_ID=$TENANT_ID"
  echo "TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE"
  echo "TENANT_SCHEMA=$TENANT_SCHEMA"
  echo
  echo "---"
  echo
  echo "## 3. Secilen user table"
  echo
  echo "SELECTED_USER_TABLE=$BEST_USER_TABLE"
  echo "SELECTED_USER_TABLE_SCORE=$BEST_USER_SCORE"
  echo
  echo "User score details:"
  printf '%s\n' "$USER_SCORE_DETAILS"
  echo
  echo "User columns:"
  printf '%s\n' "$USER_COLUMNS"
  echo
  echo "User required no default columns:"
  printf '%s\n' "$USER_REQUIRED_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 4. Secilen role table"
  echo
  echo "SELECTED_ROLE_TABLE=$BEST_ROLE_TABLE"
  echo "SELECTED_ROLE_TABLE_SCORE=$BEST_ROLE_SCORE"
  echo "ROLE_CODE_COLUMN=$ROLE_CODE_COLUMN"
  echo
  echo "Role score details:"
  printf '%s\n' "$ROLE_SCORE_DETAILS"
  echo
  echo "Role columns:"
  printf '%s\n' "$ROLE_COLUMNS"
  echo
  echo "Role required no default columns:"
  printf '%s\n' "$ROLE_REQUIRED_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 5. Secilen mapping table"
  echo
  echo "SELECTED_MAPPING_TABLE=$BEST_MAPPING_TABLE"
  echo "SELECTED_MAPPING_TABLE_SCORE=$BEST_MAPPING_SCORE"
  echo
  echo "Mapping score details:"
  printf '%s\n' "$MAPPING_SCORE_DETAILS"
  echo
  echo "Mapping columns:"
  printf '%s\n' "$MAPPING_COLUMNS"
  echo
  echo "Mapping required no default columns:"
  printf '%s\n' "$MAPPING_REQUIRED_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 6. Apply karari"
  echo
  echo "PILOT_USER_EMAIL=$PILOT_USER_EMAIL"
  echo "PILOT_ROLE_CODE=$PILOT_ROLE_CODE"
  echo "EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "USER_CREATE_NEEDED=$USER_CREATE_NEEDED"
  echo "ROLE_CREATE_NEEDED=$ROLE_CREATE_NEEDED"
  echo "ASSIGNMENT_CREATE_NEEDED=$ASSIGNMENT_CREATE_NEEDED"
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS"
  echo "4C_4C_SELECTED_USER_TABLE=$BEST_USER_TABLE"
  echo "4C_4C_SELECTED_ROLE_TABLE=$BEST_ROLE_TABLE"
  echo "4C_4C_SELECTED_MAPPING_TABLE=$BEST_MAPPING_TABLE"
  echo "4C_4C_TENANT_ID=$TENANT_ID"
  echo "4C_4C_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4C_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4C_USER_CREATE_NEEDED=$USER_CREATE_NEEDED"
  echo "4C_4C_ROLE_CREATE_NEEDED=$ROLE_CREATE_NEEDED"
  echo "4C_4C_ASSIGNMENT_CREATE_NEEDED=$ASSIGNMENT_CREATE_NEEDED"
  echo "4C_4C_USER_REQUIRED_COLUMN_COUNT=$USER_REQUIRED_COUNT"
  echo "4C_4C_ROLE_REQUIRED_COLUMN_COUNT=$ROLE_REQUIRED_COUNT"
  echo "4C_4C_MAPPING_REQUIRED_COLUMN_COUNT=$MAPPING_REQUIRED_COUNT"
  echo "4C_4C_DB_WRITE_APPLIED=NO"
  echo "4C_4C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4C_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4D_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4C User Role Apply Strategy Decision Report"
  echo
  echo "Step: 4C-4C"
  echo "Blok: User / Role Apply Strategy Decision"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS"
  echo "4C_4C_SELECTED_USER_TABLE=$BEST_USER_TABLE"
  echo "4C_4C_SELECTED_ROLE_TABLE=$BEST_ROLE_TABLE"
  echo "4C_4C_SELECTED_MAPPING_TABLE=$BEST_MAPPING_TABLE"
  echo "4C_4C_TENANT_ID=$TENANT_ID"
  echo "4C_4C_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4C_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4C_USER_CREATE_NEEDED=$USER_CREATE_NEEDED"
  echo "4C_4C_ROLE_CREATE_NEEDED=$ROLE_CREATE_NEEDED"
  echo "4C_4C_ASSIGNMENT_CREATE_NEEDED=$ASSIGNMENT_CREATE_NEEDED"
  echo "4C_4C_USER_REQUIRED_COLUMN_COUNT=$USER_REQUIRED_COUNT"
  echo "4C_4C_ROLE_REQUIRED_COLUMN_COUNT=$ROLE_REQUIRED_COUNT"
  echo "4C_4C_MAPPING_REQUIRED_COLUMN_COUNT=$MAPPING_REQUIRED_COUNT"
  echo "4C_4C_DB_WRITE_APPLIED=NO"
  echo "4C_4C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4C_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4D_READY=$NEXT_READY"
  echo
  echo "## Sonuc"
  echo
  echo "User/role apply stratejisi belirlendi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-4D User / Role SQL Package / Dry Run Plan."
} > "$REPORT_FILE"

echo "OK ✅ User role apply strategy dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ User role apply strategy report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4C STRATEGY OZET ====="
echo "4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS"
echo "4C_4C_SELECTED_USER_TABLE=$BEST_USER_TABLE"
echo "4C_4C_SELECTED_ROLE_TABLE=$BEST_ROLE_TABLE"
echo "4C_4C_SELECTED_MAPPING_TABLE=$BEST_MAPPING_TABLE"
echo "4C_4C_TENANT_ID=$TENANT_ID"
echo "4C_4C_USER_CREATE_NEEDED=$USER_CREATE_NEEDED"
echo "4C_4C_ROLE_CREATE_NEEDED=$ROLE_CREATE_NEEDED"
echo "4C_4C_ASSIGNMENT_CREATE_NEEDED=$ASSIGNMENT_CREATE_NEEDED"
echo "4C_4C_DB_WRITE_APPLIED=NO"
echo "4C_4D_READY=$NEXT_READY"
