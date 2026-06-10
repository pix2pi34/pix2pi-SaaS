#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_test_report.md"

DOC_FILE="docs/pilot/faz4c/4c_5i_sample_data_verification.md"
REPORT_FILE="reports/pilot/faz4c/4c_5i_sample_data_verification_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
STAGING_SCHEMA="tenant_uzmanparcaci"
STAGING_TABLE_NAME="pilot_product_import_staging"
STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"
IMPORT_BATCH_CODE="UZMANPARCACI_SAMPLE_4C5E"

echo "===== 4C-5I SAMPLE DATA VERIFICATION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_5i_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_5i_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_5i_psql_error.log
    return $?
  fi

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

safe_text() {
  local sql="$1"
  run_sql "$sql" 2>/dev/null || true
}

[ -f "$PREV_REPORT" ] || fail "4C-5H test report yok: $PREV_REPORT"

grep -q "4C_5H_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5H test PASS degil"
grep -q "4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS" "$PREV_REPORT" || fail "4C-5H apply PASS degil"
grep -q "4C_5H_AFTER_TABLE_EXISTS=1" "$PREV_REPORT" || fail "4C-5H after table exists 1 degil"
grep -q "4C_5H_AFTER_ROW_COUNT=5" "$PREV_REPORT" || fail "4C-5H after row count 5 degil"
grep -q "4C_5H_DB_WRITE_APPLIED=YES" "$PREV_REPORT" || fail "4C-5H DB write YES degil"
grep -q "4C_5I_READY=YES" "$PREV_REPORT" || fail "4C-5I ready YES yok"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_5i_db_ping.out; then
  ERR="$(cat /tmp/4c_5i_psql_error.log 2>/dev/null || true)"
  fail "DB baglantisi yok: $ERR"
fi

TABLE_EXISTS="$(safe_value "
select count(*)
from information_schema.tables
where table_schema='${STAGING_SCHEMA}'
  and table_name='${STAGING_TABLE_NAME}'
  and table_type='BASE TABLE';
")"

ROW_COUNT="0"
DUPLICATE_SKU_COUNT="0"
TENANT_MISMATCH_COUNT="0"
BATCH_MISMATCH_COUNT="0"
REQUIRED_TEXT_BLANK_COUNT="0"
NUMERIC_INVALID_COUNT="0"
SALE_LT_PURCHASE_COUNT="0"
INVALID_CURRENCY_COUNT="0"
VALIDATION_STATUS_COUNT="0"
BARCODE_BLANK_COUNT="0"
DISTINCT_SKU_COUNT="0"
DISTINCT_CATEGORY_COUNT="0"
DISTINCT_PART_GROUP_COUNT="0"
DISTINCT_UNIT_COUNT="0"
SOURCE_ROW_COUNT="0"
EXPECTED_SKU_MATCH_COUNT="0"
SAMPLE_ROWS=""

if [ "$TABLE_EXISTS" = "1" ]; then
  ROW_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  DUPLICATE_SKU_COUNT="$(safe_value "
select count(*)
from (
  select sku
  from ${STAGING_TABLE}
  where tenant_id='${TENANT_ID}'::uuid
    and import_batch_code='${IMPORT_BATCH_CODE}'
  group by sku
  having count(*) > 1
) d;
")"

  TENANT_MISMATCH_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id <> '${TENANT_ID}'::uuid;
")"

  BATCH_MISMATCH_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code <> '${IMPORT_BATCH_CODE}';
")"

  REQUIRED_TEXT_BLANK_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and (
    trim(coalesce(product_name,''))=''
    or trim(coalesce(sku,''))=''
    or trim(coalesce(category,''))=''
    or trim(coalesce(unit,''))=''
    or trim(coalesce(currency,''))=''
    or trim(coalesce(oem_code,''))=''
    or trim(coalesce(equivalent_code,''))=''
    or trim(coalesce(vehicle_fitment_note,''))=''
    or trim(coalesce(brand,''))=''
    or trim(coalesce(part_group,''))=''
  );
")"

  NUMERIC_INVALID_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and (
    initial_stock_qty < 0
    or sale_price < 0
    or purchase_price < 0
  );
")"

  SALE_LT_PURCHASE_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and sale_price < purchase_price;
")"

  INVALID_CURRENCY_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and currency not in ('TRY','USD','EUR');
")"

  VALIDATION_STATUS_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and validation_status='VALIDATED';
")"

  BARCODE_BLANK_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and (barcode is null or trim(coalesce(barcode,''))='');
")"

  DISTINCT_SKU_COUNT="$(safe_value "
select count(distinct sku)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  DISTINCT_CATEGORY_COUNT="$(safe_value "
select count(distinct category)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  DISTINCT_PART_GROUP_COUNT="$(safe_value "
select count(distinct part_group)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  DISTINCT_UNIT_COUNT="$(safe_value "
select count(distinct unit)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  SOURCE_ROW_COUNT="$(safe_value "
select count(distinct source_row_number)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

  EXPECTED_SKU_MATCH_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and sku in (
    'UZP-FREN-0001',
    'UZP-FILTRE-0002',
    'UZP-FILTRE-0003',
    'UZP-SUSP-0004',
    'UZP-MOTOR-0005'
  );
")"

  SAMPLE_ROWS="$(safe_text "
select
  source_row_number::text || ' | ' ||
  sku || ' | ' ||
  product_name || ' | ' ||
  category || ' | ' ||
  unit || ' | ' ||
  initial_stock_qty::text || ' | ' ||
  sale_price::text || ' | ' ||
  purchase_price::text || ' | ' ||
  currency || ' | ' ||
  oem_code || ' | ' ||
  equivalent_code
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
order by source_row_number;
")"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
VERIFY_STATUS="PASS"

if [ "$TABLE_EXISTS" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROW_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$DUPLICATE_SKU_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_MISMATCH_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BATCH_MISMATCH_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$REQUIRED_TEXT_BLANK_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$NUMERIC_INVALID_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SALE_LT_PURCHASE_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$INVALID_CURRENCY_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$VALIDATION_STATUS_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$DISTINCT_SKU_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$SOURCE_ROW_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$EXPECTED_SKU_MATCH_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$BARCODE_BLANK_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  VERIFY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat > "$DOC_FILE" <<DOC_EOF
# FAZ 4C — 4C-5I Sample Data Verification

## Amaç

4C-5H ile staging tabloya kalıcı yazılan uzmanparcaci sample ürün verisini doğrulamak.

Bu adım DB'ye yazmaz.

---

## 1. Staging tablo

STAGING_TABLE=$STAGING_TABLE
IMPORT_BATCH_CODE=$IMPORT_BATCH_CODE
TABLE_EXISTS=$TABLE_EXISTS

---

## 2. Ana veri kontrolleri

ROW_COUNT=$ROW_COUNT
DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
BATCH_MISMATCH_COUNT=$BATCH_MISMATCH_COUNT
REQUIRED_TEXT_BLANK_COUNT=$REQUIRED_TEXT_BLANK_COUNT
NUMERIC_INVALID_COUNT=$NUMERIC_INVALID_COUNT
SALE_LT_PURCHASE_COUNT=$SALE_LT_PURCHASE_COUNT
INVALID_CURRENCY_COUNT=$INVALID_CURRENCY_COUNT
VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT
EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT

---

## 3. İş veri dağılımı

DISTINCT_SKU_COUNT=$DISTINCT_SKU_COUNT
DISTINCT_CATEGORY_COUNT=$DISTINCT_CATEGORY_COUNT
DISTINCT_PART_GROUP_COUNT=$DISTINCT_PART_GROUP_COUNT
DISTINCT_UNIT_COUNT=$DISTINCT_UNIT_COUNT
SOURCE_ROW_COUNT=$SOURCE_ROW_COUNT
BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT

Not:
BARCODE_BLANK_COUNT uyarıdır, blocker değildir. Pilot işletme barkod kullanmadığını bildirmiştir.

---

## 4. Sample rows

\`\`\`text
$SAMPLE_ROWS
\`\`\`

---

## 5. Status

4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=$VERIFY_STATUS
4C_5I_STAGING_TABLE_EXISTS=$TABLE_EXISTS
4C_5I_ROW_COUNT=$ROW_COUNT
4C_5I_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
4C_5I_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
4C_5I_BATCH_MISMATCH_COUNT=$BATCH_MISMATCH_COUNT
4C_5I_REQUIRED_TEXT_BLANK_COUNT=$REQUIRED_TEXT_BLANK_COUNT
4C_5I_NUMERIC_INVALID_COUNT=$NUMERIC_INVALID_COUNT
4C_5I_SALE_LT_PURCHASE_COUNT=$SALE_LT_PURCHASE_COUNT
4C_5I_INVALID_CURRENCY_COUNT=$INVALID_CURRENCY_COUNT
4C_5I_VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT
4C_5I_EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT
4C_5I_DISTINCT_CATEGORY_COUNT=$DISTINCT_CATEGORY_COUNT
4C_5I_DISTINCT_PART_GROUP_COUNT=$DISTINCT_PART_GROUP_COUNT
4C_5I_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_5I_DB_WRITE_APPLIED=NO
4C_5I_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5I_WARNING_COUNT=$WARNING_COUNT
4C_5J_READY=$NEXT_READY
DOC_EOF

cat > "$REPORT_FILE" <<REPORT_EOF
# FAZ 4C — 4C-5I Sample Data Verification Report

Step: 4C-5I
Blok: Sample Data Verification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=$VERIFY_STATUS
4C_5I_STAGING_TABLE=$STAGING_TABLE
4C_5I_STAGING_TABLE_EXISTS=$TABLE_EXISTS
4C_5I_ROW_COUNT=$ROW_COUNT
4C_5I_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
4C_5I_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
4C_5I_BATCH_MISMATCH_COUNT=$BATCH_MISMATCH_COUNT
4C_5I_REQUIRED_TEXT_BLANK_COUNT=$REQUIRED_TEXT_BLANK_COUNT
4C_5I_NUMERIC_INVALID_COUNT=$NUMERIC_INVALID_COUNT
4C_5I_SALE_LT_PURCHASE_COUNT=$SALE_LT_PURCHASE_COUNT
4C_5I_INVALID_CURRENCY_COUNT=$INVALID_CURRENCY_COUNT
4C_5I_VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT
4C_5I_EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT
4C_5I_DISTINCT_SKU_COUNT=$DISTINCT_SKU_COUNT
4C_5I_DISTINCT_CATEGORY_COUNT=$DISTINCT_CATEGORY_COUNT
4C_5I_DISTINCT_PART_GROUP_COUNT=$DISTINCT_PART_GROUP_COUNT
4C_5I_DISTINCT_UNIT_COUNT=$DISTINCT_UNIT_COUNT
4C_5I_SOURCE_ROW_COUNT=$SOURCE_ROW_COUNT
4C_5I_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_5I_DB_WRITE_APPLIED=NO
4C_5I_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5I_WARNING_COUNT=$WARNING_COUNT
4C_5J_READY=$NEXT_READY

## Sample rows

\`\`\`text
$SAMPLE_ROWS
\`\`\`

## Sonuc

Sample data verification tamamlandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-5J Real Pilot Data Entry / Import Final Closure.
REPORT_EOF

echo "OK ✅ Sample data verification report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5I VERIFICATION OZET ====="
echo "4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=$VERIFY_STATUS"
echo "4C_5I_STAGING_TABLE_EXISTS=$TABLE_EXISTS"
echo "4C_5I_ROW_COUNT=$ROW_COUNT"
echo "4C_5I_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
echo "4C_5I_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT"
echo "4C_5I_REQUIRED_TEXT_BLANK_COUNT=$REQUIRED_TEXT_BLANK_COUNT"
echo "4C_5I_NUMERIC_INVALID_COUNT=$NUMERIC_INVALID_COUNT"
echo "4C_5I_SALE_LT_PURCHASE_COUNT=$SALE_LT_PURCHASE_COUNT"
echo "4C_5I_INVALID_CURRENCY_COUNT=$INVALID_CURRENCY_COUNT"
echo "4C_5I_VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT"
echo "4C_5I_EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT"
echo "4C_5I_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT"
echo "4C_5I_DB_WRITE_APPLIED=NO"
echo "4C_5J_READY=$NEXT_READY"
