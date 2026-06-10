#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
USER_ROLE_ENV="docs/pilot/faz4c/4c_4a_user_role_identity_plan.env"
STRATEGY_REPORT="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_report.md"

SQL_FILE="sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_4d_user_role_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_4d_user_role_sql_package_report.md"

echo "===== 4C-4D USER ROLE SQL PACKAGE / DRY RUN PLAN ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_4d_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_4d_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_4d_psql_error.log
    return $?
  fi

  return 127
}

safe_run_sql() {
  local sql="$1"
  run_sql "$sql" || true
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

sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

column_exists() {
  local full_table="$1"
  local col="$2"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_run_sql "
select count(*)
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name='${col}';
" | tr -d '[:space:]'
}

choose_existing_column() {
  local full_table="$1"
  shift

  local col
  for col in "$@"; do
    if [ "$(column_exists "$full_table" "$col")" != "0" ]; then
      echo "$col"
      return 0
    fi
  done

  echo "NONE"
}

join_by_comma() {
  local IFS=", "
  echo "$*"
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
[ -f "$STRATEGY_REPORT" ] || fail "4C-4C strategy report yok: $STRATEGY_REPORT"

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

STRATEGY_STATUS="$(get_report_value 4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS "$STRATEGY_REPORT")"
USER_TABLE="$(get_report_value 4C_4C_SELECTED_USER_TABLE "$STRATEGY_REPORT")"
ROLE_TABLE="$(get_report_value 4C_4C_SELECTED_ROLE_TABLE "$STRATEGY_REPORT")"
MAPPING_TABLE="$(get_report_value 4C_4C_SELECTED_MAPPING_TABLE "$STRATEGY_REPORT")"
TENANT_ID="$(get_report_value 4C_4C_TENANT_ID "$STRATEGY_REPORT")"

[ "$STRATEGY_STATUS" = "PASS" ] || fail "4C-4C strategy PASS degil"
[ "$USER_TABLE" = "auth.users" ] || fail "Selected user table auth.users degil: $USER_TABLE"
[ "$ROLE_TABLE" = "auth.roles" ] || fail "Selected role table auth.roles degil: $ROLE_TABLE"
[ "$MAPPING_TABLE" = "auth.user_role_assignments" ] || fail "Selected mapping table auth.user_role_assignments degil: $MAPPING_TABLE"
[ -n "$TENANT_ID" ] && [ "$TENANT_ID" != "UNKNOWN" ] || fail "Tenant id yok"

if ! run_sql "select 1;" >/tmp/4c_4d_db_ping.out; then
  ERR="$(cat /tmp/4c_4d_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

USER_EMAIL_COL="$(choose_existing_column "$USER_TABLE" email mail username)"
USER_ID_COL="$(choose_existing_column "$USER_TABLE" id user_id)"
ROLE_CODE_COL="$(choose_existing_column "$ROLE_TABLE" code role_code slug name)"
ROLE_ID_COL="$(choose_existing_column "$ROLE_TABLE" id role_id)"
ASSIGN_USER_ID_COL="$(choose_existing_column "$MAPPING_TABLE" user_id)"
ASSIGN_ROLE_ID_COL="$(choose_existing_column "$MAPPING_TABLE" role_id)"
ASSIGN_TENANT_ID_COL="$(choose_existing_column "$MAPPING_TABLE" tenant_id)"

EXISTING_USER_COUNT="0"
if [ "$USER_EMAIL_COL" != "NONE" ]; then
  EXISTING_USER_COUNT="$(safe_run_sql "
select count(*)
from auth.users
where lower(${USER_EMAIL_COL}::text)=lower('$(sql_escape "$PILOT_USER_EMAIL")');
" | tr -d '[:space:]')"
  [ -z "$EXISTING_USER_COUNT" ] && EXISTING_USER_COUNT="0"
fi

EXISTING_ROLE_COUNT="0"
if [ "$ROLE_CODE_COL" != "NONE" ]; then
  EXISTING_ROLE_COUNT="$(safe_run_sql "
select count(*)
from auth.roles
where upper(${ROLE_CODE_COL}::text)=upper('$(sql_escape "$PILOT_ROLE_CODE")');
" | tr -d '[:space:]')"
  [ -z "$EXISTING_ROLE_COUNT" ] && EXISTING_ROLE_COUNT="0"
fi

USER_COLUMNS=()
USER_VALUES=()
USER_MAPPING_LINES=""

add_user_col() {
  local col="$1"
  local expr="$2"
  if [ "$(column_exists "$USER_TABLE" "$col")" != "0" ]; then
    USER_COLUMNS+=("$col")
    USER_VALUES+=("$expr")
    USER_MAPPING_LINES="${USER_MAPPING_LINES}- ${col} <= ${expr}"$'\n'
  fi
}

ROLE_COLUMNS=()
ROLE_VALUES=()
ROLE_MAPPING_LINES=""

add_role_col() {
  local col="$1"
  local expr="$2"
  if [ "$(column_exists "$ROLE_TABLE" "$col")" != "0" ]; then
    ROLE_COLUMNS+=("$col")
    ROLE_VALUES+=("$expr")
    ROLE_MAPPING_LINES="${ROLE_MAPPING_LINES}- ${col} <= ${expr}"$'\n'
  fi
}

ASSIGN_COLUMNS=()
ASSIGN_VALUES=()
ASSIGN_MAPPING_LINES=""

add_assign_col() {
  local col="$1"
  local expr="$2"
  if [ "$(column_exists "$MAPPING_TABLE" "$col")" != "0" ]; then
    ASSIGN_COLUMNS+=("$col")
    ASSIGN_VALUES+=("$expr")
    ASSIGN_MAPPING_LINES="${ASSIGN_MAPPING_LINES}- ${col} <= ${expr}"$'\n'
  fi
}

# auth.users mapping
add_user_col "tenant_id" "'${TENANT_ID}'::uuid"
add_user_col "email" "'$(sql_escape "$PILOT_USER_EMAIL")'"
add_user_col "mail" "'$(sql_escape "$PILOT_USER_EMAIL")'"
add_user_col "username" "'$(sql_escape "$PILOT_USER_EMAIL")'"
add_user_col "full_name" "'$(sql_escape "$PILOT_USER_FULL_NAME")'"
add_user_col "password_hash" "'PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED'"
add_user_col "display_name" "'$(sql_escape "$PILOT_USER_DISPLAY_NAME")'"
add_user_col "name" "'$(sql_escape "$PILOT_USER_DISPLAY_NAME")'"
add_user_col "phone" "'$(sql_escape "$PILOT_USER_PHONE")'"
add_user_col "phone_number" "'$(sql_escape "$PILOT_USER_PHONE")'"
add_user_col "status" "'active'"
add_user_col "is_active" "true"
add_user_col "active" "true"
add_user_col "is_test_user" "false"
add_user_col "is_owner" "true"
add_user_col "created_at" "now()"
add_user_col "updated_at" "now()"

# auth.roles mapping
add_role_col "tenant_id" "'${TENANT_ID}'::uuid"
add_role_col "code" "'$(sql_escape "$PILOT_ROLE_CODE")'"
add_role_col "role_code" "'$(sql_escape "$PILOT_ROLE_CODE")'"
add_role_col "role_name" "'$(sql_escape "$PILOT_ROLE_NAME")'"
add_role_col "slug" "'pilot_admin'"
add_role_col "name" "'$(sql_escape "$PILOT_ROLE_NAME")'"
add_role_col "display_name" "'$(sql_escape "$PILOT_ROLE_NAME")'"
add_role_col "scope" "'TENANT'"
add_role_col "status" "'active'"
add_role_col "is_active" "true"
add_role_col "created_at" "now()"
add_role_col "updated_at" "now()"

# auth.user_role_assignments mapping
add_assign_col "tenant_id" "'${TENANT_ID}'::uuid"
add_assign_col "user_id" "u.user_id"
add_assign_col "role_id" "r.role_id"
add_assign_col "status" "'active'"
add_assign_col "is_active" "true"
add_assign_col "assigned_at" "now()"
add_assign_col "created_at" "now()"
add_assign_col "updated_at" "now()"

USER_COLUMN_COUNT="${#USER_COLUMNS[@]}"
ROLE_COLUMN_COUNT="${#ROLE_COLUMNS[@]}"
ASSIGN_COLUMN_COUNT="${#ASSIGN_COLUMNS[@]}"

USER_COLUMNS_SQL="$(join_by_comma "${USER_COLUMNS[@]}")"
USER_VALUES_SQL="$(join_by_comma "${USER_VALUES[@]}")"
ROLE_COLUMNS_SQL="$(join_by_comma "${ROLE_COLUMNS[@]}")"
ROLE_VALUES_SQL="$(join_by_comma "${ROLE_VALUES[@]}")"
ASSIGN_COLUMNS_SQL="$(join_by_comma "${ASSIGN_COLUMNS[@]}")"
ASSIGN_VALUES_SQL="$(join_by_comma "${ASSIGN_VALUES[@]}")"

USER_REQUIRED_COLUMNS="$(safe_run_sql "
select column_name
from information_schema.columns
where table_schema='auth'
  and table_name='users'
  and is_nullable='NO'
  and column_default is null
order by ordinal_position;
")"

ROLE_REQUIRED_COLUMNS="$(safe_run_sql "
select column_name
from information_schema.columns
where table_schema='auth'
  and table_name='roles'
  and is_nullable='NO'
  and column_default is null
order by ordinal_position;
")"

ASSIGN_REQUIRED_COLUMNS="$(safe_run_sql "
select column_name
from information_schema.columns
where table_schema='auth'
  and table_name='user_role_assignments'
  and is_nullable='NO'
  and column_default is null
order by ordinal_position;
")"

USER_REQUIRED_COUNT="$(count_lines "$USER_REQUIRED_COLUMNS")"
ROLE_REQUIRED_COUNT="$(count_lines "$ROLE_REQUIRED_COLUMNS")"
ASSIGN_REQUIRED_COUNT="$(count_lines "$ASSIGN_REQUIRED_COLUMNS")"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
SQL_PACKAGE_STATUS="PASS"

[ "$USER_EMAIL_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$USER_ID_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ROLE_CODE_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ROLE_ID_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ASSIGN_USER_ID_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ASSIGN_ROLE_ID_COL" = "NONE" ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))

[ "$USER_COLUMN_COUNT" -eq 0 ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ROLE_COLUMN_COUNT" -eq 0 ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
[ "$ASSIGN_COLUMN_COUNT" -eq 0 ] && CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))

[ "$USER_REQUIRED_COUNT" != "0" ] && WARNING_COUNT=$((WARNING_COUNT + 1))
[ "$ROLE_REQUIRED_COUNT" != "0" ] && WARNING_COUNT=$((WARNING_COUNT + 1))
[ "$ASSIGN_REQUIRED_COUNT" != "0" ] && WARNING_COUNT=$((WARNING_COUNT + 1))

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  SQL_PACKAGE_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

if [ "$SQL_PACKAGE_STATUS" = "PASS" ]; then
cat <<SQL_EOF > "$SQL_FILE"
-- FAZ 4C — 4C-4D User / Role SQL Package Preview
-- Purpose: uzmanparcaci pilot admin user and role assignment
-- IMPORTANT:
--   This SQL file is preview only.
--   It ends with ROLLBACK intentionally.
--   4C-4D does NOT perform permanent DB write.
--
-- Generated at: $(date '+%Y-%m-%d %H:%M:%S')
-- Tenant ID: ${TENANT_ID}
-- Tenant business_code: ${TENANT_BUSINESS_CODE}
-- Pilot user: ${PILOT_USER_EMAIL}
-- Pilot role: ${PILOT_ROLE_CODE}

BEGIN;

DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='users'
  ) THEN
    RAISE EXCEPTION 'Required table auth.users does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='roles'
  ) THEN
    RAISE EXCEPTION 'Required table auth.roles does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='auth' AND table_name='user_role_assignments'
  ) THEN
    RAISE EXCEPTION 'Required table auth.user_role_assignments does not exist';
  END IF;
END
\$\$;

DO \$\$
DECLARE
  tenant_count integer;
BEGIN
  SELECT count(*) INTO tenant_count
  FROM platform.tenants
  WHERE id='${TENANT_ID}'::uuid
    AND (
      slug='${TENANT_SLUG}'
      OR business_code='${TENANT_BUSINESS_CODE}'::core.code_text
    );

  IF tenant_count <> 1 THEN
    RAISE EXCEPTION 'Tenant verification failed. tenant_count=%', tenant_count;
  END IF;
END
\$\$;

WITH inserted_user AS (
  INSERT INTO auth.users (${USER_COLUMNS_SQL})
  SELECT ${USER_VALUES_SQL}
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.users
    WHERE lower(${USER_EMAIL_COL}::text)=lower('$(sql_escape "$PILOT_USER_EMAIL")')
  )
  RETURNING ${USER_ID_COL} AS user_id
),
selected_user AS (
  SELECT user_id FROM inserted_user
  UNION ALL
  SELECT ${USER_ID_COL} AS user_id
  FROM auth.users
  WHERE lower(${USER_EMAIL_COL}::text)=lower('$(sql_escape "$PILOT_USER_EMAIL")')
  LIMIT 1
),
inserted_role AS (
  INSERT INTO auth.roles (${ROLE_COLUMNS_SQL})
  SELECT ${ROLE_VALUES_SQL}
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.roles
    WHERE upper(${ROLE_CODE_COL}::text)=upper('$(sql_escape "$PILOT_ROLE_CODE")')
  )
  RETURNING ${ROLE_ID_COL} AS role_id
),
selected_role AS (
  SELECT role_id FROM inserted_role
  UNION ALL
  SELECT ${ROLE_ID_COL} AS role_id
  FROM auth.roles
  WHERE upper(${ROLE_CODE_COL}::text)=upper('$(sql_escape "$PILOT_ROLE_CODE")')
  LIMIT 1
),
inserted_assignment AS (
  INSERT INTO auth.user_role_assignments (${ASSIGN_COLUMNS_SQL})
  SELECT ${ASSIGN_VALUES_SQL}
  FROM selected_user u
  CROSS JOIN selected_role r
  WHERE NOT EXISTS (
    SELECT 1
    FROM auth.user_role_assignments a
    WHERE a.${ASSIGN_USER_ID_COL} = u.user_id
      AND a.${ASSIGN_ROLE_ID_COL} = r.role_id
  )
  RETURNING ${ASSIGN_USER_ID_COL}, ${ASSIGN_ROLE_ID_COL}
)
SELECT
  'preview_user_count' AS check_name,
  count(*)::text AS check_value
FROM auth.users
WHERE lower(${USER_EMAIL_COL}::text)=lower('$(sql_escape "$PILOT_USER_EMAIL")');

SELECT
  'preview_role_count' AS check_name,
  count(*)::text AS check_value
FROM auth.roles
WHERE upper(${ROLE_CODE_COL}::text)=upper('$(sql_escape "$PILOT_ROLE_CODE")');

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- Later commit/apply steps will be generated only after successful dry-run.
SQL_EOF
else
  rm -f "$SQL_FILE"
fi

SQL_FILE_CREATED="NO"
[ -f "$SQL_FILE" ] && SQL_FILE_CREATED="YES"

{
  echo "# FAZ 4C — 4C-4D User Role SQL Package / Dry Run Plan"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment icin SQL preview paketi uretmek."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo "SQL dosyasi ROLLBACK ile biter."
  echo
  echo "---"
  echo
  echo "## 1. Secilen tablolar"
  echo
  echo "SELECTED_USER_TABLE=$USER_TABLE"
  echo "SELECTED_ROLE_TABLE=$ROLE_TABLE"
  echo "SELECTED_MAPPING_TABLE=$MAPPING_TABLE"
  echo
  echo "---"
  echo
  echo "## 2. Kolon secimleri"
  echo
  echo "USER_ID_COL=$USER_ID_COL"
  echo "USER_EMAIL_COL=$USER_EMAIL_COL"
  echo "ROLE_ID_COL=$ROLE_ID_COL"
  echo "ROLE_CODE_COL=$ROLE_CODE_COL"
  echo "ASSIGN_USER_ID_COL=$ASSIGN_USER_ID_COL"
  echo "ASSIGN_ROLE_ID_COL=$ASSIGN_ROLE_ID_COL"
  echo "ASSIGN_TENANT_ID_COL=$ASSIGN_TENANT_ID_COL"
  echo
  echo "---"
  echo
  echo "## 3. Tenant ve kullanici"
  echo
  echo "TENANT_ID=$TENANT_ID"
  echo "TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE"
  echo "PILOT_USER_EMAIL=$PILOT_USER_EMAIL"
  echo "PILOT_ROLE_CODE=$PILOT_ROLE_CODE"
  echo
  echo "---"
  echo
  echo "## 4. Existing kontrol"
  echo
  echo "EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo
  echo "---"
  echo
  echo "## 5. Insert mapping"
  echo
  echo "USER_COLUMN_COUNT=$USER_COLUMN_COUNT"
  printf '%s\n' "$USER_MAPPING_LINES"
  echo
  echo "ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT"
  printf '%s\n' "$ROLE_MAPPING_LINES"
  echo
  echo "ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT"
  printf '%s\n' "$ASSIGN_MAPPING_LINES"
  echo
  echo "---"
  echo
  echo "## 6. Zorunlu default olmayan kolonlar"
  echo
  echo "USER_REQUIRED_COUNT=$USER_REQUIRED_COUNT"
  printf '%s\n' "$USER_REQUIRED_COLUMNS"
  echo
  echo "ROLE_REQUIRED_COUNT=$ROLE_REQUIRED_COUNT"
  printf '%s\n' "$ROLE_REQUIRED_COLUMNS"
  echo
  echo "ASSIGN_REQUIRED_COUNT=$ASSIGN_REQUIRED_COUNT"
  printf '%s\n' "$ASSIGN_REQUIRED_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 7. SQL dosyasi"
  echo
  echo "SQL_FILE=$SQL_FILE"
  echo
  echo "---"
  echo
  echo "## 8. Status"
  echo
  echo "4C_4D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS"
  echo "4C_4D_SELECTED_USER_TABLE=$USER_TABLE"
  echo "4C_4D_SELECTED_ROLE_TABLE=$ROLE_TABLE"
  echo "4C_4D_SELECTED_MAPPING_TABLE=$MAPPING_TABLE"
  echo "4C_4D_USER_ID_COL=$USER_ID_COL"
  echo "4C_4D_USER_EMAIL_COL=$USER_EMAIL_COL"
  echo "4C_4D_ROLE_ID_COL=$ROLE_ID_COL"
  echo "4C_4D_ROLE_CODE_COL=$ROLE_CODE_COL"
  echo "4C_4D_ASSIGN_USER_ID_COL=$ASSIGN_USER_ID_COL"
  echo "4C_4D_ASSIGN_ROLE_ID_COL=$ASSIGN_ROLE_ID_COL"
  echo "4C_4D_SQL_FILE_CREATED=$SQL_FILE_CREATED"
  echo "4C_4D_USER_COLUMN_COUNT=$USER_COLUMN_COUNT"
  echo "4C_4D_ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT"
  echo "4C_4D_ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT"
  echo "4C_4D_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4D_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4D_USER_REQUIRED_COLUMN_COUNT=$USER_REQUIRED_COUNT"
  echo "4C_4D_ROLE_REQUIRED_COLUMN_COUNT=$ROLE_REQUIRED_COUNT"
  echo "4C_4D_ASSIGN_REQUIRED_COLUMN_COUNT=$ASSIGN_REQUIRED_COUNT"
  echo "4C_4D_DB_WRITE_APPLIED=NO"
  echo "4C_4D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4D_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4E_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4D User Role SQL Package Report"
  echo
  echo "Step: 4C-4D-FIX2"
  echo "Blok: User / Role SQL Package / Dry Run Plan"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS"
  echo "4C_4D_SELECTED_USER_TABLE=$USER_TABLE"
  echo "4C_4D_SELECTED_ROLE_TABLE=$ROLE_TABLE"
  echo "4C_4D_SELECTED_MAPPING_TABLE=$MAPPING_TABLE"
  echo "4C_4D_USER_ID_COL=$USER_ID_COL"
  echo "4C_4D_USER_EMAIL_COL=$USER_EMAIL_COL"
  echo "4C_4D_ROLE_ID_COL=$ROLE_ID_COL"
  echo "4C_4D_ROLE_CODE_COL=$ROLE_CODE_COL"
  echo "4C_4D_ASSIGN_USER_ID_COL=$ASSIGN_USER_ID_COL"
  echo "4C_4D_ASSIGN_ROLE_ID_COL=$ASSIGN_ROLE_ID_COL"
  echo "4C_4D_TENANT_ID=$TENANT_ID"
  echo "4C_4D_SQL_FILE_CREATED=$SQL_FILE_CREATED"
  echo "4C_4D_SQL_FILE=$SQL_FILE"
  echo "4C_4D_USER_COLUMN_COUNT=$USER_COLUMN_COUNT"
  echo "4C_4D_ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT"
  echo "4C_4D_ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT"
  echo "4C_4D_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
  echo "4C_4D_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
  echo "4C_4D_USER_REQUIRED_COLUMN_COUNT=$USER_REQUIRED_COUNT"
  echo "4C_4D_ROLE_REQUIRED_COLUMN_COUNT=$ROLE_REQUIRED_COUNT"
  echo "4C_4D_ASSIGN_REQUIRED_COLUMN_COUNT=$ASSIGN_REQUIRED_COUNT"
  echo "4C_4D_DB_WRITE_APPLIED=NO"
  echo "4C_4D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_4D_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_4E_READY=$NEXT_READY"
  echo
  echo "## Sonuc"
  echo
  echo "User/role SQL preview paketi hazirlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-4E User / Role SQL Dry Run / ROLLBACK Verification."
} > "$REPORT_FILE"

echo "OK ✅ User role SQL package report olusturuldu: $REPORT_FILE"

if [ "$SQL_FILE_CREATED" = "YES" ]; then
  echo "OK ✅ User role SQL preview paketi olusturuldu: $SQL_FILE"
else
  echo "HATA ❌ User role SQL preview paketi olusturulamadi"
fi

echo
echo "===== 4C-4D-FIX2 SQL PACKAGE OZET ====="
echo "4C_4D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS"
echo "4C_4D_SELECTED_USER_TABLE=$USER_TABLE"
echo "4C_4D_SELECTED_ROLE_TABLE=$ROLE_TABLE"
echo "4C_4D_SELECTED_MAPPING_TABLE=$MAPPING_TABLE"
echo "4C_4D_USER_ID_COL=$USER_ID_COL"
echo "4C_4D_USER_EMAIL_COL=$USER_EMAIL_COL"
echo "4C_4D_ROLE_ID_COL=$ROLE_ID_COL"
echo "4C_4D_ROLE_CODE_COL=$ROLE_CODE_COL"
echo "4C_4D_ASSIGN_USER_ID_COL=$ASSIGN_USER_ID_COL"
echo "4C_4D_ASSIGN_ROLE_ID_COL=$ASSIGN_ROLE_ID_COL"
echo "4C_4D_SQL_FILE_CREATED=$SQL_FILE_CREATED"
echo "4C_4D_USER_COLUMN_COUNT=$USER_COLUMN_COUNT"
echo "4C_4D_ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT"
echo "4C_4D_ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT"
echo "4C_4D_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
echo "4C_4D_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
echo "4C_4D_DB_WRITE_APPLIED=NO"
echo "4C_4E_READY=$NEXT_READY"

if [ "$SQL_PACKAGE_STATUS" != "PASS" ]; then
  exit 1
fi
