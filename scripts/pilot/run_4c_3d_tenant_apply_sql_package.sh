#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TENANT_ENV="docs/pilot/faz4c/4c_3a_tenant_identity_setup_plan.env"
STRATEGY_REPORT="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_report.md"
SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_3d_tenant_apply_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_3d_tenant_apply_sql_package_report.md"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

echo "===== 4C-3D TENANT APPLY SQL PACKAGE / DRY RUN PLAN ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3d_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3d_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3d_psql_error.log
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

sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

has_column() {
  local col="$1"
  printf "%s\n" "$TABLE_COLUMNS_ONLY" | grep -qx "$col"
}

add_mapping_literal() {
  local col="$1"
  local val="$2"
  if has_column "$col"; then
    INSERT_COLUMNS+=("$col")
    INSERT_VALUES+=("'$(sql_escape "$val")'")
    MAPPING_LINES="${MAPPING_LINES}- ${col} <= ${val}"$'\n'
  fi
}

add_mapping_bool() {
  local col="$1"
  local val="$2"
  if has_column "$col"; then
    INSERT_COLUMNS+=("$col")
    INSERT_VALUES+=("$val")
    MAPPING_LINES="${MAPPING_LINES}- ${col} <= ${val}"$'\n'
  fi
}

add_mapping_now() {
  local col="$1"
  if has_column "$col"; then
    INSERT_COLUMNS+=("$col")
    INSERT_VALUES+=("now()")
    MAPPING_LINES="${MAPPING_LINES}- ${col} <= now()"$'\n'
  fi
}

add_mapping_json() {
  local col="$1"
  local json="$2"
  if has_column "$col"; then
    INSERT_COLUMNS+=("$col")
    INSERT_VALUES+=("'$(sql_escape "$json")'::jsonb")
    MAPPING_LINES="${MAPPING_LINES}- ${col} <= metadata jsonb"$'\n'
  fi
}

[ -f "$TENANT_ENV" ] || fail "Tenant env yok: $TENANT_ENV"
[ -f "$STRATEGY_REPORT" ] || fail "4C-3C strategy report yok: $STRATEGY_REPORT"

safe_source "$COMMON_ENV"
safe_source "$TENANT_ENV"

SELECTED_TABLE="$(get_report_value 4C_3C_SELECTED_TENANT_TABLE "$STRATEGY_REPORT")"
STRATEGY_STATUS="$(get_report_value 4C_3C_TENANT_APPLY_STRATEGY_STATUS "$STRATEGY_REPORT")"
SCHEMA_CREATE_NEEDED="$(get_report_value 4C_3C_TENANT_SCHEMA_CREATE_NEEDED "$STRATEGY_REPORT")"

if [ "$STRATEGY_STATUS" != "PASS" ]; then
  fail "4C-3C strategy PASS degil"
fi

if [ "$SELECTED_TABLE" != "platform.tenants" ]; then
  fail "Beklenen selected table platform.tenants degil: $SELECTED_TABLE"
fi

TABLE_SCHEMA="${SELECTED_TABLE%%.*}"
TABLE_NAME="${SELECTED_TABLE#*.}"

TENANT_CODE="${TENANT_CODE:-uzmanparcaci}"
TENANT_SLUG="${TENANT_SLUG:-uzmanparcaci}"
TENANT_DISPLAY_NAME="${TENANT_DISPLAY_NAME:-uzmanparcaci}"
TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"
TENANT_SECTOR="${TENANT_SECTOR:-OTO_YEDEK_PARCA}"
TENANT_CITY="${TENANT_CITY:-istanbul}"
TENANT_DISTRICT="${TENANT_DISTRICT:-bahcelievler}"
TENANT_OWNER_NAME="${TENANT_OWNER_NAME:-mert_omur}"
TENANT_OWNER_EMAIL="${TENANT_OWNER_EMAIL:-uzmanparcaci1@gmail.com}"
TENANT_OWNER_PHONE="${TENANT_OWNER_PHONE:-5377457536}"

if ! run_sql "select 1;" >/tmp/4c_3d_db_ping.out; then
  ERR="$(cat /tmp/4c_3d_psql_error.log 2>/dev/null || true)"
  cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3D Tenant Apply SQL Package Report

Step: 4C-3D
Blok: Tenant Apply SQL Package / Dry Run Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3D_SQL_PACKAGE_STATUS=BLOCKED
4C_3D_DB_CONNECT_STATUS=FAIL
4C_3D_CRITICAL_BLOCKER_COUNT=1
4C_3D_DB_WRITE_APPLIED=NO
4C_3E_READY=NO

## Hata

\`\`\`text
$ERR
\`\`\`
REPORT_EOF
  echo "HATA ❌ DB baglantisi yok"
  exit 0
fi

TABLE_EXISTS="$(run_sql "
select count(*)
from information_schema.tables
where table_schema='${TABLE_SCHEMA}'
  and table_name='${TABLE_NAME}';
" | tr -d '[:space:]')"

if [ "$TABLE_EXISTS" != "1" ]; then
  fail "Selected tenant table bulunamadi: $SELECTED_TABLE"
fi

TABLE_COLUMNS="$(run_sql "
select column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${TABLE_SCHEMA}'
  and table_name='${TABLE_NAME}'
order by ordinal_position;
")"

TABLE_COLUMNS_ONLY="$(run_sql "
select column_name
from information_schema.columns
where table_schema='${TABLE_SCHEMA}'
  and table_name='${TABLE_NAME}'
order by ordinal_position;
")"

EXISTING_TENANT_COUNT_BY_CODE="0"
if has_column "code"; then
  EXISTING_TENANT_COUNT_BY_CODE="$(run_sql "select count(*) from ${SELECTED_TABLE} where code='$(sql_escape "$TENANT_CODE")';" | tr -d '[:space:]')"
elif has_column "slug"; then
  EXISTING_TENANT_COUNT_BY_CODE="$(run_sql "select count(*) from ${SELECTED_TABLE} where slug='$(sql_escape "$TENANT_SLUG")';" | tr -d '[:space:]')"
elif has_column "name"; then
  EXISTING_TENANT_COUNT_BY_CODE="$(run_sql "select count(*) from ${SELECTED_TABLE} where name='$(sql_escape "$TENANT_DISPLAY_NAME")';" | tr -d '[:space:]')"
fi

SCHEMA_EXISTS="$(run_sql "select count(*) from information_schema.schemata where schema_name='${TENANT_SCHEMA}';" | tr -d '[:space:]')"

INSERT_COLUMNS=()
INSERT_VALUES=()
MAPPING_LINES=""

add_mapping_literal "code" "$TENANT_CODE"
add_mapping_literal "slug" "$TENANT_SLUG"
add_mapping_literal "name" "$TENANT_DISPLAY_NAME"
add_mapping_literal "display_name" "$TENANT_DISPLAY_NAME"
add_mapping_literal "legal_name" "$TENANT_DISPLAY_NAME"
add_mapping_literal "schema_name" "$TENANT_SCHEMA"
add_mapping_literal "tenant_schema" "$TENANT_SCHEMA"
add_mapping_literal "sector" "$TENANT_SECTOR"
add_mapping_literal "status" "active"
add_mapping_bool "is_active" "true"
add_mapping_bool "active" "true"
add_mapping_bool "is_test" "false"
add_mapping_bool "is_test_tenant" "false"
add_mapping_bool "is_pilot" "true"
add_mapping_bool "is_real_pilot" "true"
add_mapping_literal "city" "$TENANT_CITY"
add_mapping_literal "district" "$TENANT_DISTRICT"
add_mapping_literal "owner_name" "$TENANT_OWNER_NAME"
add_mapping_literal "owner_email" "$TENANT_OWNER_EMAIL"
add_mapping_literal "owner_phone" "$TENANT_OWNER_PHONE"
add_mapping_now "created_at"
add_mapping_now "updated_at"

METADATA_JSON="{\"pilot_phase\":\"FAZ_4C\",\"business\":\"uzmanparcaci\",\"sector\":\"OTO_YEDEK_PARCA\",\"marketplace_live_integration\":\"NO\",\"marketplace_phase\":\"FAZ_4D\",\"source\":\"4C-3D\"}"
add_mapping_json "metadata" "$METADATA_JSON"
add_mapping_json "meta" "$METADATA_JSON"

INSERT_COLUMN_COUNT="${#INSERT_COLUMNS[@]}"

INSERT_COLUMNS_SQL="$(IFS=', '; echo "${INSERT_COLUMNS[*]}")"
INSERT_VALUES_SQL="$(IFS=', '; echo "${INSERT_VALUES[*]}")"

if [ "$INSERT_COLUMN_COUNT" -eq 0 ]; then
  SQL_PACKAGE_STATUS="BLOCKED"
  CRITICAL_BLOCKER_COUNT=1
  NEXT_READY="NO"
else
  SQL_PACKAGE_STATUS="PASS"
  CRITICAL_BLOCKER_COUNT=0
  NEXT_READY="YES"
fi

WARNING_COUNT=0

if [ "$EXISTING_TENANT_COUNT_BY_CODE" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$SCHEMA_EXISTS" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

cat <<SQL_EOF > "$SQL_FILE"
-- FAZ 4C — 4C-3D Tenant Apply SQL Package / Preview
-- Purpose: uzmanparcaci tenant setup SQL preview
-- IMPORTANT:
--   This SQL file was generated as a package.
--   It is NOT executed by 4C-3D.
--   Apply will be controlled in a later guarded step.
--
-- Generated at: $(date '+%Y-%m-%d %H:%M:%S')
-- Selected tenant table: $SELECTED_TABLE
-- Tenant schema: $TENANT_SCHEMA
-- Tenant code: $TENANT_CODE

BEGIN;

-- 1. Safety check: selected tenant table must exist
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = '$TABLE_SCHEMA'
      AND table_name = '$TABLE_NAME'
  ) THEN
    RAISE EXCEPTION 'Selected tenant table %.% does not exist', '$TABLE_SCHEMA', '$TABLE_NAME';
  END IF;
END
\$\$;

-- 2. Create schema guarded
CREATE SCHEMA IF NOT EXISTS $TENANT_SCHEMA;

-- 3. Insert tenant metadata guarded
-- Existing count detected during generation: $EXISTING_TENANT_COUNT_BY_CODE
INSERT INTO $SELECTED_TABLE ($INSERT_COLUMNS_SQL)
SELECT $INSERT_VALUES_SQL
WHERE NOT EXISTS (
SQL_EOF

if has_column "code"; then
  cat <<SQL_EOF >> "$SQL_FILE"
  SELECT 1 FROM $SELECTED_TABLE WHERE code = '$(sql_escape "$TENANT_CODE")'
SQL_EOF
elif has_column "slug"; then
  cat <<SQL_EOF >> "$SQL_FILE"
  SELECT 1 FROM $SELECTED_TABLE WHERE slug = '$(sql_escape "$TENANT_SLUG")'
SQL_EOF
else
  cat <<SQL_EOF >> "$SQL_FILE"
  SELECT 1 FROM $SELECTED_TABLE WHERE name = '$(sql_escape "$TENANT_DISPLAY_NAME")'
SQL_EOF
fi

cat <<SQL_EOF >> "$SQL_FILE"
);

-- 4. Verification
SELECT 'tenant_schema_exists' AS check_name, count(*)::text AS check_value
FROM information_schema.schemata
WHERE schema_name = '$TENANT_SCHEMA';

SELECT 'tenant_metadata_exists' AS check_name, count(*)::text AS check_value
FROM $SELECTED_TABLE
WHERE
SQL_EOF

if has_column "code"; then
  cat <<SQL_EOF >> "$SQL_FILE"
  code = '$(sql_escape "$TENANT_CODE")';
SQL_EOF
elif has_column "slug"; then
  cat <<SQL_EOF >> "$SQL_FILE"
  slug = '$(sql_escape "$TENANT_SLUG")';
SQL_EOF
else
  cat <<SQL_EOF >> "$SQL_FILE"
  name = '$(sql_escape "$TENANT_DISPLAY_NAME")';
SQL_EOF
fi

cat <<SQL_EOF >> "$SQL_FILE"

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- Later apply step will generate/execute a guarded COMMIT version only after approval.
SQL_EOF

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-3D Tenant Apply SQL Package / Dry Run Plan

## Blok

4C-3D — Tenant Apply SQL Package / Dry Run Plan

## Amac

Bu adim uzmanparcaci tenant kurulumu icin SQL paketini hazirlar.

Bu adim DB'ye yazmaz.
Bu adim schema olusturmaz.
Bu adim tenant kaydi olusturmaz.
Bu adim sadece SQL preview paketi uretir.

---

## 1. Onceki karar

4C_3C_SELECTED_TENANT_TABLE=platform.tenants
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=YES
4C_3C_TENANT_METADATA_INSERT_NEEDED=YES

---

## 2. Selected tenant table

SELECTED_TENANT_TABLE=$SELECTED_TABLE
TABLE_EXISTS=$TABLE_EXISTS

Kolonlar:

\`\`\`text
$TABLE_COLUMNS
\`\`\`

---

## 3. Tenant identity

TENANT_CODE=$TENANT_CODE
TENANT_SLUG=$TENANT_SLUG
TENANT_DISPLAY_NAME=$TENANT_DISPLAY_NAME
TENANT_SCHEMA=$TENANT_SCHEMA
TENANT_SECTOR=$TENANT_SECTOR
TENANT_OWNER_EMAIL=$TENANT_OWNER_EMAIL
TENANT_OWNER_PHONE=$TENANT_OWNER_PHONE

---

## 4. Existing kontrol

EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_TENANT_COUNT_BY_CODE
TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS

---

## 5. Insert mapping

INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT

Mapping:

$MAPPING_LINES

---

## 6. SQL package

SQL preview dosyasi:

$SQL_FILE

Bu dosya ROLLBACK ile biter.
Bu adimda apply yoktur.

---

## 7. Karar

4C_3D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS
4C_3D_SELECTED_TENANT_TABLE=$SELECTED_TABLE
4C_3D_TENANT_SCHEMA=$TENANT_SCHEMA
4C_3D_INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT
4C_3D_EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_TENANT_COUNT_BY_CODE
4C_3D_TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS
4C_3D_SQL_FILE_CREATED=YES
4C_3D_DB_WRITE_APPLIED=NO
4C_3D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3D_WARNING_COUNT=$WARNING_COUNT
4C_3D_NEXT_STEP_READY=$NEXT_READY
4C_3E_READY=$NEXT_READY

---

## 8. Sonraki adim

Sonraki adim:

4C-3E — Tenant SQL Dry Run Execution / ROLLBACK Verification

Bu adimda SQL preview ROLLBACK ile calistirilacak, kalici yazma yapilmadan dogrulanacak.
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3D Tenant Apply SQL Package Report

Step: 4C-3D
Blok: Tenant Apply SQL Package / Dry Run Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS
4C_3D_DB_CONNECT_STATUS=PASS
4C_3D_SELECTED_TENANT_TABLE=$SELECTED_TABLE
4C_3D_TENANT_SCHEMA=$TENANT_SCHEMA
4C_3D_TABLE_EXISTS=$TABLE_EXISTS
4C_3D_INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT
4C_3D_EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_TENANT_COUNT_BY_CODE
4C_3D_TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS
4C_3D_SQL_FILE_CREATED=YES
4C_3D_SQL_FILE=$SQL_FILE
4C_3D_DB_WRITE_APPLIED=NO
4C_3D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3D_WARNING_COUNT=$WARNING_COUNT
4C_3E_READY=$NEXT_READY

## Sonuc

Tenant apply SQL preview paketi hazirlandi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-3E Tenant SQL Dry Run Execution / ROLLBACK Verification.
REPORT_EOF

echo "OK ✅ SQL preview package olusturuldu: $SQL_FILE"
echo "OK ✅ Tenant SQL package dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Tenant SQL package report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-3D SQL PACKAGE OZETI ====="
echo "4C_3D_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS"
echo "4C_3D_SELECTED_TENANT_TABLE=$SELECTED_TABLE"
echo "4C_3D_INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT"
echo "4C_3D_EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_TENANT_COUNT_BY_CODE"
echo "4C_3D_TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
echo "4C_3D_DB_WRITE_APPLIED=NO"
echo "4C_3E_READY=$NEXT_READY"
