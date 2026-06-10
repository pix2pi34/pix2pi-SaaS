#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_report.md"

DOC_FILE="docs/pilot/faz4c/4c_5d_import_mapping_strategy.md"
ENV_FILE="docs/pilot/faz4c/4c_5d_import_mapping_strategy.env"
REPORT_FILE="reports/pilot/faz4c/4c_5d_import_mapping_strategy_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
TENANT_BUSINESS_CODE="UZMANPARCACI"
TENANT_SCHEMA="tenant_uzmanparcaci"

PRODUCT_TABLE="public.erp_items"
STOCK_TABLE="public.erp_stock_movements"
CATEGORY_TABLE="public.erp_product_categories"
UNIT_TABLE="public.erp_units"
STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"

echo "===== 4C-5D IMPORT MAPPING STRATEGY DECISION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_5d_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_5d_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_5d_psql_error.log
    return $?
  fi

  return 127
}

safe_sql() {
  local sql="$1"
  run_sql "$sql" || true
}

table_exists() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_sql "
select count(*)
from information_schema.tables
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and table_type='BASE TABLE';
" | tr -d '[:space:]'
}

column_exists() {
  local full_table="$1"
  local col="$2"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_sql "
select count(*)
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
  and column_name='${col}';
" | tr -d '[:space:]'
}

choose_col() {
  local full_table="$1"
  shift

  local col
  for col in "$@"; do
    if [ "$(column_exists "$full_table" "$col")" != "0" ]; then
      echo "$col"
      return 0
    fi
  done

  echo "STAGING_ONLY"
}

table_columns() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_sql "
select
  column_name || ':' || data_type || ':nullable=' || is_nullable || ':default=' || coalesce(column_default,'')
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
"
}

[ -f "$PREV_REPORT" ] || fail "4C-5C report yok: $PREV_REPORT"

grep -q "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=PASS" "$PREV_REPORT" || fail "4C-5C PASS degil"
grep -q "4C_5D_READY=YES" "$PREV_REPORT" || fail "4C-5D ready YES yok"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_5d_db_ping.out; then
  ERR="$(cat /tmp/4c_5d_psql_error.log 2>/dev/null || true)"

  cat > "$REPORT_FILE" <<EOF
# FAZ 4C — 4C-5D Import Mapping Strategy Report

Step: 4C-5D
Blok: Import Mapping Strategy Decision
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=BLOCKED
4C_5D_DB_CONNECT_STATUS=FAIL
4C_5D_CRITICAL_BLOCKER_COUNT=1
4C_5D_BLOCKER_REASON=DB_CONNECTION_FAILED
4C_5D_DB_WRITE_APPLIED=NO
4C_5E_READY=NO

## Hata

$ERR
EOF

  echo "HATA ❌ DB baglantisi kurulamadi"
  exit 0
fi

TENANT_COUNT="$(safe_sql "
select count(*)
from platform.tenants
where id='${TENANT_ID}'::uuid
  and business_code='${TENANT_BUSINESS_CODE}'::core.code_text;
" | tr -d '[:space:]')"

PRODUCT_TABLE_EXISTS="$(table_exists "$PRODUCT_TABLE")"
STOCK_TABLE_EXISTS="$(table_exists "$STOCK_TABLE")"
CATEGORY_TABLE_EXISTS="$(table_exists "$CATEGORY_TABLE")"
UNIT_TABLE_EXISTS="$(table_exists "$UNIT_TABLE")"
TENANT_SCHEMA_EXISTS="$(safe_sql "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
" | tr -d '[:space:]')"

PRODUCT_NAME_COL="$(choose_col "$PRODUCT_TABLE" product_name name item_name title)"
PRODUCT_SKU_COL="$(choose_col "$PRODUCT_TABLE" sku code item_code product_code)"
PRODUCT_CATEGORY_COL="$(choose_col "$PRODUCT_TABLE" category_id category product_category_id)"
PRODUCT_UNIT_COL="$(choose_col "$PRODUCT_TABLE" unit_id unit uom_id)"
PRODUCT_SALE_PRICE_COL="$(choose_col "$PRODUCT_TABLE" sale_price sales_price price list_price)"
PRODUCT_PURCHASE_PRICE_COL="$(choose_col "$PRODUCT_TABLE" purchase_price cost_price buy_price)"
PRODUCT_CURRENCY_COL="$(choose_col "$PRODUCT_TABLE" currency currency_code)"
PRODUCT_TENANT_COL="$(choose_col "$PRODUCT_TABLE" tenant_id business_id)"
PRODUCT_OEM_COL="$(choose_col "$PRODUCT_TABLE" oem_code oem)"
PRODUCT_EQUIV_COL="$(choose_col "$PRODUCT_TABLE" equivalent_code equivalent_sku cross_code)"
PRODUCT_FITMENT_COL="$(choose_col "$PRODUCT_TABLE" vehicle_fitment_note fitment_note compatibility_note)"

STOCK_PRODUCT_COL="$(choose_col "$STOCK_TABLE" product_id item_id stock_item_id)"
STOCK_QTY_COL="$(choose_col "$STOCK_TABLE" quantity qty stock_qty movement_qty)"
STOCK_TENANT_COL="$(choose_col "$STOCK_TABLE" tenant_id business_id)"
STOCK_TYPE_COL="$(choose_col "$STOCK_TABLE" movement_type type direction)"
STOCK_REASON_COL="$(choose_col "$STOCK_TABLE" reason note description)"

PRODUCT_COLUMNS="$(table_columns "$PRODUCT_TABLE")"
STOCK_COLUMNS="$(table_columns "$STOCK_TABLE")"

CORE_DIRECT_REQUIRED_OK="YES"

for v in \
  "$PRODUCT_NAME_COL" \
  "$PRODUCT_SKU_COL" \
  "$PRODUCT_CATEGORY_COL" \
  "$PRODUCT_UNIT_COL" \
  "$PRODUCT_SALE_PRICE_COL" \
  "$PRODUCT_PURCHASE_PRICE_COL" \
  "$PRODUCT_CURRENCY_COL" \
  "$PRODUCT_TENANT_COL" \
  "$STOCK_PRODUCT_COL" \
  "$STOCK_QTY_COL" \
  "$STOCK_TENANT_COL"
do
  if [ "$v" = "STAGING_ONLY" ]; then
    CORE_DIRECT_REQUIRED_OK="NO"
  fi
done

AUTO_PART_SPECIAL_DIRECT_OK="YES"

for v in \
  "$PRODUCT_OEM_COL" \
  "$PRODUCT_EQUIV_COL" \
  "$PRODUCT_FITMENT_COL"
do
  if [ "$v" = "STAGING_ONLY" ]; then
    AUTO_PART_SPECIAL_DIRECT_OK="NO"
  fi
done

SELECTED_STRATEGY="STAGING_FIRST_THEN_CORE_MAPPING"
CORE_DIRECT_APPLY_NOW="NO"
STAGING_TABLE_CREATE_NEEDED="YES"
STAGING_TABLE_EXISTS="$(table_exists "$STAGING_TABLE")"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
STRATEGY_STATUS="PASS"

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_SCHEMA_EXISTS" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$PRODUCT_TABLE_EXISTS" != "1" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$STOCK_TABLE_EXISTS" != "1" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CORE_DIRECT_REQUIRED_OK" = "NO" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$AUTO_PART_SPECIAL_DIRECT_OK" = "NO" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  STRATEGY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat <<ENV_EOF > "$ENV_FILE"
# FAZ 4C — 4C-5D Import Mapping Strategy Decision
# Bu dosya import mapping kararini dondurur.
# Bu adimda DB write yapilmaz.

TENANT_ID="${TENANT_ID}"
TENANT_BUSINESS_CODE="${TENANT_BUSINESS_CODE}"
TENANT_SCHEMA="${TENANT_SCHEMA}"

SELECTED_IMPORT_MAPPING_STRATEGY="${SELECTED_STRATEGY}"
CORE_DIRECT_APPLY_NOW="${CORE_DIRECT_APPLY_NOW}"
STAGING_TABLE_CREATE_NEEDED="${STAGING_TABLE_CREATE_NEEDED}"
STAGING_TABLE="${STAGING_TABLE}"
STAGING_TABLE_EXISTS="${STAGING_TABLE_EXISTS}"

PRODUCT_TABLE="${PRODUCT_TABLE}"
STOCK_TABLE="${STOCK_TABLE}"
CATEGORY_TABLE="${CATEGORY_TABLE}"
UNIT_TABLE="${UNIT_TABLE}"

PRODUCT_NAME_COL="${PRODUCT_NAME_COL}"
PRODUCT_SKU_COL="${PRODUCT_SKU_COL}"
PRODUCT_CATEGORY_COL="${PRODUCT_CATEGORY_COL}"
PRODUCT_UNIT_COL="${PRODUCT_UNIT_COL}"
PRODUCT_SALE_PRICE_COL="${PRODUCT_SALE_PRICE_COL}"
PRODUCT_PURCHASE_PRICE_COL="${PRODUCT_PURCHASE_PRICE_COL}"
PRODUCT_CURRENCY_COL="${PRODUCT_CURRENCY_COL}"
PRODUCT_TENANT_COL="${PRODUCT_TENANT_COL}"
PRODUCT_OEM_COL="${PRODUCT_OEM_COL}"
PRODUCT_EQUIV_COL="${PRODUCT_EQUIV_COL}"
PRODUCT_FITMENT_COL="${PRODUCT_FITMENT_COL}"

STOCK_PRODUCT_COL="${STOCK_PRODUCT_COL}"
STOCK_QTY_COL="${STOCK_QTY_COL}"
STOCK_TENANT_COL="${STOCK_TENANT_COL}"
STOCK_TYPE_COL="${STOCK_TYPE_COL}"
STOCK_REASON_COL="${STOCK_REASON_COL}"

CORE_DIRECT_REQUIRED_OK="${CORE_DIRECT_REQUIRED_OK}"
AUTO_PART_SPECIAL_DIRECT_OK="${AUTO_PART_SPECIAL_DIRECT_OK}"

IMPORT_MAPPING_DB_WRITE_APPLIED="NO"
IMPORT_MAPPING_STATUS="${STRATEGY_STATUS}"
IMPORT_MAPPING_NEXT_STEP="4C_5E_SAMPLE_CSV_GENERATION_VALIDATION"
ENV_EOF

{
  echo "# FAZ 4C — 4C-5D Import Mapping Strategy Decision"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci ürün/stok import verisinin hangi strateji ile sisteme alınacağını belirlemek."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Tenant kontrolu"
  echo
  echo "TENANT_ID=$TENANT_ID"
  echo "TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE"
  echo "TENANT_COUNT=$TENANT_COUNT"
  echo "TENANT_SCHEMA=$TENANT_SCHEMA"
  echo "TENANT_SCHEMA_EXISTS=$TENANT_SCHEMA_EXISTS"
  echo
  echo "---"
  echo
  echo "## 2. Seçilen strateji"
  echo
  echo "SELECTED_IMPORT_MAPPING_STRATEGY=$SELECTED_STRATEGY"
  echo "CORE_DIRECT_APPLY_NOW=$CORE_DIRECT_APPLY_NOW"
  echo "STAGING_TABLE_CREATE_NEEDED=$STAGING_TABLE_CREATE_NEEDED"
  echo "STAGING_TABLE=$STAGING_TABLE"
  echo "STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS"
  echo
  echo "Karar:"
  echo "Oto yedek parça özel alanları ve veri kalite riski sebebiyle önce staging/import tablosu kullanılacaktır."
  echo "ERP core tablolarına doğrudan yazma bu adımda yapılmayacaktır."
  echo
  echo "---"
  echo
  echo "## 3. Core tablo hedefleri"
  echo
  echo "PRODUCT_TABLE=$PRODUCT_TABLE"
  echo "PRODUCT_TABLE_EXISTS=$PRODUCT_TABLE_EXISTS"
  echo "STOCK_TABLE=$STOCK_TABLE"
  echo "STOCK_TABLE_EXISTS=$STOCK_TABLE_EXISTS"
  echo "CATEGORY_TABLE=$CATEGORY_TABLE"
  echo "CATEGORY_TABLE_EXISTS=$CATEGORY_TABLE_EXISTS"
  echo "UNIT_TABLE=$UNIT_TABLE"
  echo "UNIT_TABLE_EXISTS=$UNIT_TABLE_EXISTS"
  echo
  echo "---"
  echo
  echo "## 4. CSV -> Product mapping"
  echo
  echo "product_name -> $PRODUCT_TABLE.$PRODUCT_NAME_COL"
  echo "sku -> $PRODUCT_TABLE.$PRODUCT_SKU_COL"
  echo "category -> $PRODUCT_TABLE.$PRODUCT_CATEGORY_COL"
  echo "unit -> $PRODUCT_TABLE.$PRODUCT_UNIT_COL"
  echo "sale_price -> $PRODUCT_TABLE.$PRODUCT_SALE_PRICE_COL"
  echo "purchase_price -> $PRODUCT_TABLE.$PRODUCT_PURCHASE_PRICE_COL"
  echo "currency -> $PRODUCT_TABLE.$PRODUCT_CURRENCY_COL"
  echo "tenant_id -> $PRODUCT_TABLE.$PRODUCT_TENANT_COL"
  echo "oem_code -> $PRODUCT_TABLE.$PRODUCT_OEM_COL"
  echo "equivalent_code -> $PRODUCT_TABLE.$PRODUCT_EQUIV_COL"
  echo "vehicle_fitment_note -> $PRODUCT_TABLE.$PRODUCT_FITMENT_COL"
  echo
  echo "---"
  echo
  echo "## 5. CSV -> Stock mapping"
  echo
  echo "initial_stock_qty -> $STOCK_TABLE.$STOCK_QTY_COL"
  echo "product_ref -> $STOCK_TABLE.$STOCK_PRODUCT_COL"
  echo "tenant_id -> $STOCK_TABLE.$STOCK_TENANT_COL"
  echo "movement_type -> $STOCK_TABLE.$STOCK_TYPE_COL"
  echo "reason -> $STOCK_TABLE.$STOCK_REASON_COL"
  echo
  echo "---"
  echo
  echo "## 6. Fit sonucu"
  echo
  echo "CORE_DIRECT_REQUIRED_OK=$CORE_DIRECT_REQUIRED_OK"
  echo "AUTO_PART_SPECIAL_DIRECT_OK=$AUTO_PART_SPECIAL_DIRECT_OK"
  echo
  echo "Product columns:"
  printf '%s\n' "$PRODUCT_COLUMNS" | sed 's/^/    /'
  echo
  echo "Stock columns:"
  printf '%s\n' "$STOCK_COLUMNS" | sed 's/^/    /'
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=$STRATEGY_STATUS"
  echo "4C_5D_SELECTED_STRATEGY=$SELECTED_STRATEGY"
  echo "4C_5D_CORE_DIRECT_APPLY_NOW=$CORE_DIRECT_APPLY_NOW"
  echo "4C_5D_STAGING_TABLE_CREATE_NEEDED=$STAGING_TABLE_CREATE_NEEDED"
  echo "4C_5D_STAGING_TABLE=$STAGING_TABLE"
  echo "4C_5D_STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS"
  echo "4C_5D_PRODUCT_TABLE=$PRODUCT_TABLE"
  echo "4C_5D_STOCK_TABLE=$STOCK_TABLE"
  echo "4C_5D_CORE_DIRECT_REQUIRED_OK=$CORE_DIRECT_REQUIRED_OK"
  echo "4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=$AUTO_PART_SPECIAL_DIRECT_OK"
  echo "4C_5D_DB_WRITE_APPLIED=NO"
  echo "4C_5D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5D_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5E_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-5D Import Mapping Strategy Report"
  echo
  echo "Step: 4C-5D"
  echo "Blok: Import Mapping Strategy Decision"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=$STRATEGY_STATUS"
  echo "4C_5D_DB_CONNECT_STATUS=PASS"
  echo "4C_5D_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_5D_TENANT_SCHEMA_EXISTS=$TENANT_SCHEMA_EXISTS"
  echo "4C_5D_SELECTED_STRATEGY=$SELECTED_STRATEGY"
  echo "4C_5D_CORE_DIRECT_APPLY_NOW=$CORE_DIRECT_APPLY_NOW"
  echo "4C_5D_STAGING_TABLE_CREATE_NEEDED=$STAGING_TABLE_CREATE_NEEDED"
  echo "4C_5D_STAGING_TABLE=$STAGING_TABLE"
  echo "4C_5D_STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS"
  echo "4C_5D_PRODUCT_TABLE=$PRODUCT_TABLE"
  echo "4C_5D_STOCK_TABLE=$STOCK_TABLE"
  echo "4C_5D_CATEGORY_TABLE=$CATEGORY_TABLE"
  echo "4C_5D_UNIT_TABLE=$UNIT_TABLE"
  echo "4C_5D_CORE_DIRECT_REQUIRED_OK=$CORE_DIRECT_REQUIRED_OK"
  echo "4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=$AUTO_PART_SPECIAL_DIRECT_OK"
  echo "4C_5D_DB_WRITE_APPLIED=NO"
  echo "4C_5D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5D_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5E_READY=$NEXT_READY"
  echo
  echo "## Mapping"
  echo "product_name=$PRODUCT_NAME_COL"
  echo "sku=$PRODUCT_SKU_COL"
  echo "category=$PRODUCT_CATEGORY_COL"
  echo "unit=$PRODUCT_UNIT_COL"
  echo "sale_price=$PRODUCT_SALE_PRICE_COL"
  echo "purchase_price=$PRODUCT_PURCHASE_PRICE_COL"
  echo "currency=$PRODUCT_CURRENCY_COL"
  echo "oem_code=$PRODUCT_OEM_COL"
  echo "equivalent_code=$PRODUCT_EQUIV_COL"
  echo "vehicle_fitment_note=$PRODUCT_FITMENT_COL"
  echo "stock_qty=$STOCK_QTY_COL"
  echo
  echo "## Sonuc"
  echo "Import mapping strategy decision tamamlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-5E Sample CSV Generation / Validation."
} > "$REPORT_FILE"

echo "OK ✅ Import mapping strategy dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Import mapping strategy env olusturuldu: $ENV_FILE"
echo "OK ✅ Import mapping strategy report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5D STRATEGY OZET ====="
echo "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=$STRATEGY_STATUS"
echo "4C_5D_SELECTED_STRATEGY=$SELECTED_STRATEGY"
echo "4C_5D_CORE_DIRECT_APPLY_NOW=$CORE_DIRECT_APPLY_NOW"
echo "4C_5D_STAGING_TABLE_CREATE_NEEDED=$STAGING_TABLE_CREATE_NEEDED"
echo "4C_5D_STAGING_TABLE=$STAGING_TABLE"
echo "4C_5D_PRODUCT_TABLE=$PRODUCT_TABLE"
echo "4C_5D_STOCK_TABLE=$STOCK_TABLE"
echo "4C_5D_CORE_DIRECT_REQUIRED_OK=$CORE_DIRECT_REQUIRED_OK"
echo "4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=$AUTO_PART_SPECIAL_DIRECT_OK"
echo "4C_5D_DB_WRITE_APPLIED=NO"
echo "4C_5E_READY=$NEXT_READY"
