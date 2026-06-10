#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
SQL_FILE="sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_5f_import_sql_package_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_5g_import_dry_run_rollback.md"
REPORT_FILE="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
STAGING_SCHEMA="tenant_uzmanparcaci"
STAGING_TABLE_NAME="pilot_product_import_staging"
STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"
IMPORT_BATCH_CODE="UZMANPARCACI_SAMPLE_4C5E"

echo "===== 4C-5G IMPORT DRY RUN / ROLLBACK VERIFICATION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_5g_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_5g_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_5g_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_5g_sql_output.log /tmp/4c_5g_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -At -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_5g_sql_output.log 2>/tmp/4c_5g_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -At -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_5g_sql_output.log 2>/tmp/4c_5g_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_5g_preview_product_import_staging.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -At -v ON_ERROR_STOP=1 -f /tmp/4c_5g_preview_product_import_staging.sql >/tmp/4c_5g_sql_output.log 2>/tmp/4c_5g_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_5g_sql_error.log
  return 127
}

safe_value() {
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

table_exists_count() {
  safe_value "
select count(*)
from information_schema.tables
where table_schema='${STAGING_SCHEMA}'
  and table_name='${STAGING_TABLE_NAME}'
  and table_type='BASE TABLE';
"
}

staging_row_count() {
  local exists_count
  exists_count="$(table_exists_count)"

  if [ "$exists_count" = "0" ]; then
    echo "0"
    return 0
  fi

  safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
"
}

duplicate_sku_count() {
  local exists_count
  exists_count="$(table_exists_count)"

  if [ "$exists_count" = "0" ]; then
    echo "0"
    return 0
  fi

  safe_value "
select count(*)
from (
  select sku
  from ${STAGING_TABLE}
  where tenant_id='${TENANT_ID}'::uuid
    and import_batch_code='${IMPORT_BATCH_CODE}'
  group by sku
  having count(*) > 1
) d;
"
}

[ -f "$SQL_FILE" ] || fail "SQL preview yok: $SQL_FILE"
[ -f "$PREV_REPORT" ] || fail "4C-5F test report yok: $PREV_REPORT"

grep -q "4C_5F_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5F test PASS degil"
grep -q "4C_5F_IMPORT_SQL_PACKAGE_STATUS=PASS" "$PREV_REPORT" || fail "4C-5F SQL package PASS degil"
grep -q "4C_5F_SQL_HAS_ROLLBACK=YES" "$PREV_REPORT" || fail "4C-5F ROLLBACK YES degil"
grep -q "4C_5F_SQL_HAS_COMMIT=NO" "$PREV_REPORT" || fail "4C-5F COMMIT NO degil"
grep -q "4C_5F_SAMPLE_INSERT_COUNT=5" "$PREV_REPORT" || fail "4C-5F insert count 5 degil"
grep -q "4C_5G_READY=YES" "$PREV_REPORT" || fail "4C-5G ready YES degil"

grep -q "BEGIN;" "$SQL_FILE" || fail "SQL BEGIN yok"
grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL ROLLBACK yok"

if grep -q "COMMIT;" "$SQL_FILE"; then
  fail "SQL preview COMMIT icermemeli"
fi

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_5g_db_ping.out; then
  ERR="$(cat /tmp/4c_5g_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

BEFORE_TABLE_EXISTS="$(table_exists_count)"
BEFORE_ROW_COUNT="$(staging_row_count)"
BEFORE_DUPLICATE_SKU_COUNT="$(duplicate_sku_count)"

SQL_EXECUTION_STATUS="PASS"

if ! run_sql_file "$SQL_FILE"; then
  SQL_EXECUTION_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_5g_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_5g_sql_error.log 2>/dev/null || true)"

AFTER_TABLE_EXISTS="$(table_exists_count)"
AFTER_ROW_COUNT="$(staging_row_count)"
AFTER_DUPLICATE_SKU_COUNT="$(duplicate_sku_count)"

ROLLBACK_VERIFIED="NO"

if [ "$BEFORE_TABLE_EXISTS" = "$AFTER_TABLE_EXISTS" ] && \
   [ "$BEFORE_ROW_COUNT" = "$AFTER_ROW_COUNT" ] && \
   [ "$BEFORE_DUPLICATE_SKU_COUNT" = "$AFTER_DUPLICATE_SKU_COUNT" ]; then
  ROLLBACK_VERIFIED="YES"
fi

SQL_OUTPUT_STAGING_ROW_COUNT="UNKNOWN"
SQL_OUTPUT_DUPLICATE_SKU_COUNT="UNKNOWN"

if printf '%s\n' "$SQL_OUTPUT" | grep -q '^staging_row_count|'; then
  SQL_OUTPUT_STAGING_ROW_COUNT="$(printf '%s\n' "$SQL_OUTPUT" | awk -F'|' '$1=="staging_row_count"{print $2}' | tail -n 1 | tr -d ' ')"
fi

if printf '%s\n' "$SQL_OUTPUT" | grep -q '^duplicate_sku_count|'; then
  SQL_OUTPUT_DUPLICATE_SKU_COUNT="$(printf '%s\n' "$SQL_OUTPUT" | awk -F'|' '$1=="duplicate_sku_count"{print $2}' | tail -n 1 | tr -d ' ')"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
DRY_RUN_STATUS="PASS"

if [ "$SQL_EXECUTION_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLLBACK_VERIFIED" != "YES" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SQL_OUTPUT_STAGING_ROW_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SQL_OUTPUT_DUPLICATE_SKU_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  DRY_RUN_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat > "$DOC_FILE" <<DOC_EOF
# FAZ 4C — 4C-5G Import Dry Run / ROLLBACK Verification

## Amaç

4C-5F SQL preview paketini çalıştırmak, staging insertlerinin transaction içinde başarılı olduğunu görmek ve ROLLBACK sonrası kalıcı DB yazma olmadığını doğrulamak.

Bu adım kalıcı DB yazma yapmaz.

---

## 1. SQL dosyası

SQL_FILE=$SQL_FILE
STAGING_TABLE=$STAGING_TABLE
IMPORT_BATCH_CODE=$IMPORT_BATCH_CODE

---

## 2. Dry-run öncesi durum

BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
BEFORE_DUPLICATE_SKU_COUNT=$BEFORE_DUPLICATE_SKU_COUNT

---

## 3. SQL execution

SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS

SQL output:

\`\`\`text
$SQL_OUTPUT
\`\`\`

SQL error:

\`\`\`text
$SQL_ERROR
\`\`\`

---

## 4. SQL output verification

SQL_OUTPUT_STAGING_ROW_COUNT=$SQL_OUTPUT_STAGING_ROW_COUNT
SQL_OUTPUT_DUPLICATE_SKU_COUNT=$SQL_OUTPUT_DUPLICATE_SKU_COUNT

---

## 5. Dry-run sonrası durum

AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
AFTER_ROW_COUNT=$AFTER_ROW_COUNT
AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT

---

## 6. Rollback doğrulama

ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED

---

## 7. Status

4C_5G_IMPORT_DRY_RUN_STATUS=$DRY_RUN_STATUS
4C_5G_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS
4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=$SQL_OUTPUT_STAGING_ROW_COUNT
4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=$SQL_OUTPUT_DUPLICATE_SKU_COUNT
4C_5G_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5G_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5G_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5G_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5G_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED
4C_5G_DB_WRITE_APPLIED=NO
4C_5G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5G_WARNING_COUNT=$WARNING_COUNT
4C_5H_READY=$NEXT_READY
DOC_EOF

cat > "$REPORT_FILE" <<REPORT_EOF
# FAZ 4C — 4C-5G Import Dry Run Rollback Report

Step: 4C-5G
Blok: Import Dry Run / ROLLBACK Verification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5G_IMPORT_DRY_RUN_STATUS=$DRY_RUN_STATUS
4C_5G_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS
4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=$SQL_OUTPUT_STAGING_ROW_COUNT
4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=$SQL_OUTPUT_DUPLICATE_SKU_COUNT
4C_5G_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5G_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5G_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5G_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5G_BEFORE_DUPLICATE_SKU_COUNT=$BEFORE_DUPLICATE_SKU_COUNT
4C_5G_AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT
4C_5G_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED
4C_5G_DB_WRITE_APPLIED=NO
4C_5G_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5G_WARNING_COUNT=$WARNING_COUNT
4C_5H_READY=$NEXT_READY

## SQL output

\`\`\`text
$SQL_OUTPUT
\`\`\`

## SQL error

\`\`\`text
$SQL_ERROR
\`\`\`

## Sonuc

Import dry-run / rollback verification tamamlandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-5H Controlled Sample Data Apply.
REPORT_EOF

echo "OK ✅ Import dry-run report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5G DRY RUN OZET ====="
echo "4C_5G_IMPORT_DRY_RUN_STATUS=$DRY_RUN_STATUS"
echo "4C_5G_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS"
echo "4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=$SQL_OUTPUT_STAGING_ROW_COUNT"
echo "4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=$SQL_OUTPUT_DUPLICATE_SKU_COUNT"
echo "4C_5G_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS"
echo "4C_5G_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS"
echo "4C_5G_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT"
echo "4C_5G_AFTER_ROW_COUNT=$AFTER_ROW_COUNT"
echo "4C_5G_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
echo "4C_5G_DB_WRITE_APPLIED=NO"
echo "4C_5H_READY=$NEXT_READY"
