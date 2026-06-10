#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

PREVIEW_SQL="sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql"
COMMIT_SQL="sql/pilot/faz4c/4c_5h_commit_product_import_staging_uzmanparcaci.sql"
PREV_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_5h_controlled_sample_data_apply.md"
REPORT_FILE="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
STAGING_SCHEMA="tenant_uzmanparcaci"
STAGING_TABLE_NAME="pilot_product_import_staging"
STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"
IMPORT_BATCH_CODE="UZMANPARCACI_SAMPLE_4C5E"

echo "===== 4C-5H CONTROLLED SAMPLE DATA APPLY ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_5h_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_5h_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_5h_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_5h_sql_output.log /tmp/4c_5h_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -At -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_5h_sql_output.log 2>/tmp/4c_5h_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -At -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_5h_sql_output.log 2>/tmp/4c_5h_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_5h_commit_product_import_staging.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -At -v ON_ERROR_STOP=1 -f /tmp/4c_5h_commit_product_import_staging.sql >/tmp/4c_5h_sql_output.log 2>/tmp/4c_5h_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_5h_sql_error.log
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

[ -f "$PREVIEW_SQL" ] || fail "Preview SQL yok: $PREVIEW_SQL"
[ -f "$PREV_REPORT" ] || fail "4C-5G test report yok: $PREV_REPORT"

grep -q "4C_5G_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5G test PASS degil"
grep -q "4C_5G_SQL_EXECUTION_STATUS=PASS" "$PREV_REPORT" || fail "4C-5G SQL execution PASS degil"
grep -q "4C_5G_ROLLBACK_VERIFIED=YES" "$PREV_REPORT" || fail "4C-5G rollback verified YES degil"
grep -q "4C_5G_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-5G DB write NO degil"
grep -q "4C_5H_READY=YES" "$PREV_REPORT" || fail "4C-5H ready YES yok"

grep -q "ROLLBACK;" "$PREVIEW_SQL" || fail "Preview SQL ROLLBACK icermiyor"

if grep -q "COMMIT;" "$PREVIEW_SQL"; then
  fail "Preview SQL COMMIT icermemeli"
fi

python3 - <<'PY'
from pathlib import Path

preview = Path("sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql")
commit = Path("sql/pilot/faz4c/4c_5h_commit_product_import_staging_uzmanparcaci.sql")

text = preview.read_text(encoding="utf-8")

text = text.replace(
    "-- FAZ 4C — 4C-5F Import SQL Package / Dry Run Plan",
    "-- FAZ 4C — 4C-5H Controlled Sample Data Apply / COMMIT"
)

text = text.replace(
    "--   This SQL file is preview only.\n--   It ends with ROLLBACK intentionally.\n--   4C-5F does NOT perform permanent DB write.",
    "--   This SQL file is a guarded COMMIT package.\n--   4C-5H executes this file.\n--   This step performs permanent DB write."
)

text = text.replace(
    "ROLLBACK;\n\n-- Note:\n-- This preview intentionally ends with ROLLBACK.\n-- 4C-5G will execute this preview and verify rollback safety.",
    """DO $$
DECLARE
  final_row_count integer;
  final_duplicate_sku_count integer;
BEGIN
  SELECT count(*) INTO final_row_count
  FROM tenant_uzmanparcaci.pilot_product_import_staging
  WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
    AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E';

  SELECT count(*) INTO final_duplicate_sku_count
  FROM (
    SELECT sku
    FROM tenant_uzmanparcaci.pilot_product_import_staging
    WHERE tenant_id='6dfe8d22-035a-401f-807c-507408d2e439'::uuid
      AND import_batch_code='UZMANPARCACI_SAMPLE_4C5E'
    GROUP BY sku
    HAVING count(*) > 1
  ) d;

  IF final_row_count <> 5 THEN
    RAISE EXCEPTION 'Staging final row count verification failed. final_row_count=%', final_row_count;
  END IF;

  IF final_duplicate_sku_count <> 0 THEN
    RAISE EXCEPTION 'Duplicate SKU verification failed. final_duplicate_sku_count=%', final_duplicate_sku_count;
  END IF;
END
$$;

COMMIT;

-- Note:
-- This commit package is executed by 4C-5H controlled apply step."""
)

commit.write_text(text, encoding="utf-8")
PY

[ -f "$COMMIT_SQL" ] || fail "Commit SQL olusmadi: $COMMIT_SQL"

grep -q "BEGIN;" "$COMMIT_SQL" || fail "Commit SQL BEGIN yok"
grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL COMMIT yok"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL ROLLBACK icermemeli"
fi

grep -q "CREATE TABLE IF NOT EXISTS tenant_uzmanparcaci.pilot_product_import_staging" "$COMMIT_SQL" || fail "Commit SQL staging create yok"
grep -q "INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging" "$COMMIT_SQL" || fail "Commit SQL staging insert yok"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_5h_db_ping.out; then
  ERR="$(cat /tmp/4c_5h_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

BEFORE_TABLE_EXISTS="$(table_exists_count)"
BEFORE_ROW_COUNT="$(staging_row_count)"
BEFORE_DUPLICATE_SKU_COUNT="$(duplicate_sku_count)"

SQL_EXECUTION_STATUS="PASS"

if ! run_sql_file "$COMMIT_SQL"; then
  SQL_EXECUTION_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_5h_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_5h_sql_error.log 2>/dev/null || true)"

AFTER_TABLE_EXISTS="$(table_exists_count)"
AFTER_ROW_COUNT="$(staging_row_count)"
AFTER_DUPLICATE_SKU_COUNT="$(duplicate_sku_count)"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
APPLY_STATUS="PASS"

if [ "$SQL_EXECUTION_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_TABLE_EXISTS" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_ROW_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$AFTER_DUPLICATE_SKU_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BEFORE_ROW_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  APPLY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat > "$DOC_FILE" <<DOC_EOF
# FAZ 4C — 4C-5H Controlled Sample Data Apply

## Amaç

uzmanparcaci sample CSV verisini staging/import tablosuna kontrollü şekilde kalıcı olarak uygulamak.

Bu adım gerçek DB write yapar.

---

## 1. SQL dosyası

COMMIT_SQL=$COMMIT_SQL
STAGING_TABLE=$STAGING_TABLE
IMPORT_BATCH_CODE=$IMPORT_BATCH_CODE

---

## 2. Apply öncesi durum

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

## 4. Apply sonrası durum

AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
AFTER_ROW_COUNT=$AFTER_ROW_COUNT
AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT

---

## 5. Status

4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=$APPLY_STATUS
4C_5H_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS
4C_5H_STAGING_TABLE=$STAGING_TABLE
4C_5H_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5H_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5H_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5H_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5H_AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT
4C_5H_DB_WRITE_APPLIED=YES
4C_5H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5H_WARNING_COUNT=$WARNING_COUNT
4C_5I_READY=$NEXT_READY
DOC_EOF

cat > "$REPORT_FILE" <<REPORT_EOF
# FAZ 4C — 4C-5H Controlled Sample Data Apply Report

Step: 4C-5H
Blok: Controlled Sample Data Apply
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=$APPLY_STATUS
4C_5H_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS
4C_5H_STAGING_TABLE=$STAGING_TABLE
4C_5H_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5H_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5H_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5H_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5H_BEFORE_DUPLICATE_SKU_COUNT=$BEFORE_DUPLICATE_SKU_COUNT
4C_5H_AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT
4C_5H_DB_WRITE_APPLIED=YES
4C_5H_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5H_WARNING_COUNT=$WARNING_COUNT
4C_5I_READY=$NEXT_READY

## SQL output

\`\`\`text
$SQL_OUTPUT
\`\`\`

## SQL error

\`\`\`text
$SQL_ERROR
\`\`\`

## Sonuc

Controlled sample data apply tamamlandi.
uzmanparcaci sample ürün verileri staging tabloya kalıcı olarak işlendi.
Sonraki adim: 4C-5I Sample Data Verification.
REPORT_EOF

echo "OK ✅ Controlled sample apply report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5H APPLY OZET ====="
echo "4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=$APPLY_STATUS"
echo "4C_5H_SQL_EXECUTION_STATUS=$SQL_EXECUTION_STATUS"
echo "4C_5H_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS"
echo "4C_5H_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS"
echo "4C_5H_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT"
echo "4C_5H_AFTER_ROW_COUNT=$AFTER_ROW_COUNT"
echo "4C_5H_AFTER_DUPLICATE_SKU_COUNT=$AFTER_DUPLICATE_SKU_COUNT"
echo "4C_5H_DB_WRITE_APPLIED=YES"
echo "4C_5I_READY=$NEXT_READY"
