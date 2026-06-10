#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_report.md"

DOC_FILE="docs/pilot/faz4c/4c_5c_product_stock_table_discovery.md"
REPORT_FILE="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
TENANT_BUSINESS_CODE="UZMANPARCACI"
TENANT_SCHEMA="tenant_uzmanparcaci"

echo "===== 4C-5C PRODUCT / STOCK TABLE DISCOVERY ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_5c_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_5c_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_5c_psql_error.log
    return $?
  fi

  return 127
}

safe_sql() {
  local sql="$1"
  run_sql "$sql" || true
}

count_lines() {
  local value="$1"
  if [ -z "$value" ]; then
    echo "0"
  else
    printf '%s\n' "$value" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
  fi
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

score_product_table() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_sql "
with cols as (
  select column_name
  from information_schema.columns
  where table_schema='${schema_name}'
    and table_name='${table_name}'
)
select
  0
  + case when '${schema_name}' in ('inventory','erp','public','product','catalog','tenant_uzmanparcaci') then 20 else 0 end
  + case when lower('${table_name}') in ('products','product','items','item','stock_items','inventory_items') then 60 else 0 end
  + case when lower('${table_name}') like '%product%' then 25 else 0 end
  + case when lower('${table_name}') like '%item%' then 20 else 0 end
  + case when exists (select 1 from cols where column_name in ('id','product_id','item_id')) then 15 else 0 end
  + case when exists (select 1 from cols where column_name in ('sku','code','product_code','item_code')) then 25 else 0 end
  + case when exists (select 1 from cols where column_name in ('name','product_name','item_name')) then 25 else 0 end
  + case when exists (select 1 from cols where column_name in ('category_id','category','group_id','part_group')) then 10 else 0 end
  + case when exists (select 1 from cols where column_name in ('unit','unit_id','uom')) then 10 else 0 end
  + case when exists (select 1 from cols where column_name in ('tenant_id','business_id')) then 20 else 0 end
;"
}

score_stock_table() {
  local full_table="$1"
  local schema_name="${full_table%%.*}"
  local table_name="${full_table#*.}"

  safe_sql "
with cols as (
  select column_name
  from information_schema.columns
  where table_schema='${schema_name}'
    and table_name='${table_name}'
)
select
  0
  + case when '${schema_name}' in ('inventory','erp','public','stock','tenant_uzmanparcaci') then 20 else 0 end
  + case when lower('${table_name}') in ('stocks','stock','inventory_stock','stock_balances','product_stock') then 60 else 0 end
  + case when lower('${table_name}') like '%stock%' then 30 else 0 end
  + case when lower('${table_name}') like '%inventory%' then 20 else 0 end
  + case when exists (select 1 from cols where column_name in ('product_id','item_id','stock_item_id')) then 25 else 0 end
  + case when exists (select 1 from cols where column_name in ('quantity','qty','stock_qty','available_qty','on_hand_qty')) then 25 else 0 end
  + case when exists (select 1 from cols where column_name in ('tenant_id','business_id')) then 20 else 0 end
;"
}

[ -f "$PREV_REPORT" ] || fail "4C-5B report yok: $PREV_REPORT"

grep -q "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=PASS" "$PREV_REPORT" || fail "4C-5B PASS degil"
grep -q "4C_5C_READY=YES" "$PREV_REPORT" || fail "4C-5C ready YES degil"

safe_source "$COMMON_ENV"

if ! run_sql "select 1;" >/tmp/4c_5c_db_ping.out; then
  ERR="$(cat /tmp/4c_5c_psql_error.log 2>/dev/null || true)"

  cat > "$REPORT_FILE" <<EOF
# FAZ 4C — 4C-5C Product / Stock Table Discovery Report

Step: 4C-5C
Blok: Product / Stock Table Discovery
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=BLOCKED
4C_5C_DB_CONNECT_STATUS=FAIL
4C_5C_CRITICAL_BLOCKER_COUNT=1
4C_5C_BLOCKER_REASON=DB_CONNECTION_FAILED
4C_5C_DB_WRITE_APPLIED=NO
4C_5D_READY=NO

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

TENANT_SCHEMA_COUNT="$(safe_sql "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
" | tr -d '[:space:]')"

PRODUCT_TABLES="$(safe_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('products','product','items','item','stock_items','inventory_items','catalog_items')
    or lower(table_name) like '%product%'
    or lower(table_name) like '%item%'
    or lower(table_name) like '%catalog%'
    or lower(table_name) like '%part%'
  )
order by table_schema, table_name;
")"

STOCK_TABLES="$(safe_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('stocks','stock','inventory_stock','stock_balances','product_stock')
    or lower(table_name) like '%stock%'
    or lower(table_name) like '%inventory%'
    or lower(table_name) like '%movement%'
  )
order by table_schema, table_name;
")"

CATEGORY_TABLES="$(safe_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) like '%category%'
    or lower(table_name) like '%categories%'
    or lower(table_name) like '%group%'
  )
order by table_schema, table_name;
")"

UNIT_TABLES="$(safe_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('units','unit','uom','uoms')
    or lower(table_name) like '%unit%'
    or lower(table_name) like '%uom%'
  )
order by table_schema, table_name;
")"

PRODUCT_TABLE_COUNT="$(count_lines "$PRODUCT_TABLES")"
STOCK_TABLE_COUNT="$(count_lines "$STOCK_TABLES")"
CATEGORY_TABLE_COUNT="$(count_lines "$CATEGORY_TABLES")"
UNIT_TABLE_COUNT="$(count_lines "$UNIT_TABLES")"

BEST_PRODUCT_TABLE="NONE"
BEST_PRODUCT_SCORE="-1"
PRODUCT_SCORE_DETAILS=""

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  score="$(score_product_table "$full_table" | tr -d '[:space:]')"
  [ -z "$score" ] && score="0"
  PRODUCT_SCORE_DETAILS="${PRODUCT_SCORE_DETAILS}${full_table}=score:${score}"$'\n'
  if [ "$score" -gt "$BEST_PRODUCT_SCORE" ]; then
    BEST_PRODUCT_SCORE="$score"
    BEST_PRODUCT_TABLE="$full_table"
  fi
done <<< "$PRODUCT_TABLES"

BEST_STOCK_TABLE="NONE"
BEST_STOCK_SCORE="-1"
STOCK_SCORE_DETAILS=""

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue
  score="$(score_stock_table "$full_table" | tr -d '[:space:]')"
  [ -z "$score" ] && score="0"
  STOCK_SCORE_DETAILS="${STOCK_SCORE_DETAILS}${full_table}=score:${score}"$'\n'
  if [ "$score" -gt "$BEST_STOCK_SCORE" ]; then
    BEST_STOCK_SCORE="$score"
    BEST_STOCK_TABLE="$full_table"
  fi
done <<< "$STOCK_TABLES"

BEST_PRODUCT_COLUMNS=""
if [ "$BEST_PRODUCT_TABLE" != "NONE" ]; then
  BEST_PRODUCT_COLUMNS="$(table_columns "$BEST_PRODUCT_TABLE")"
fi

BEST_STOCK_COLUMNS=""
if [ "$BEST_STOCK_TABLE" != "NONE" ]; then
  BEST_STOCK_COLUMNS="$(table_columns "$BEST_STOCK_TABLE")"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
DISCOVERY_STATUS="PASS"
NEXT_READY="YES"

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$PRODUCT_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$STOCK_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CATEGORY_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$UNIT_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  DISCOVERY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-5C Product / Stock Table Discovery"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci import akisi icin mevcut urun, stok, kategori ve birim tablolarini kesfetmek."
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
  echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo
  echo "---"
  echo
  echo "## 2. Product tablo adaylari"
  echo
  echo "PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT"
  printf '%s\n' "$PRODUCT_TABLES"
  echo
  echo "Product score details:"
  printf '%s\n' "$PRODUCT_SCORE_DETAILS"
  echo
  echo "BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE"
  echo "BEST_PRODUCT_SCORE=$BEST_PRODUCT_SCORE"
  echo
  echo "Best product columns:"
  printf '%s\n' "$BEST_PRODUCT_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 3. Stock tablo adaylari"
  echo
  echo "STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT"
  printf '%s\n' "$STOCK_TABLES"
  echo
  echo "Stock score details:"
  printf '%s\n' "$STOCK_SCORE_DETAILS"
  echo
  echo "BEST_STOCK_TABLE=$BEST_STOCK_TABLE"
  echo "BEST_STOCK_SCORE=$BEST_STOCK_SCORE"
  echo
  echo "Best stock columns:"
  printf '%s\n' "$BEST_STOCK_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 4. Category tablo adaylari"
  echo
  echo "CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT"
  printf '%s\n' "$CATEGORY_TABLES"
  echo
  echo "---"
  echo
  echo "## 5. Unit tablo adaylari"
  echo
  echo "UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT"
  printf '%s\n' "$UNIT_TABLES"
  echo
  echo "---"
  echo
  echo "## 6. Karar notu"
  echo
  echo "Bu adim sadece discovery yapar."
  echo "Eger tablo adayi yoksa bu adim fail olmaz; 4C-5D mapping strategy icinde create-vs-use-existing karari verilir."
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=$DISCOVERY_STATUS"
  echo "4C_5C_DB_CONNECT_STATUS=PASS"
  echo "4C_5C_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_5C_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "4C_5C_PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT"
  echo "4C_5C_STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT"
  echo "4C_5C_CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT"
  echo "4C_5C_UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT"
  echo "4C_5C_BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE"
  echo "4C_5C_BEST_PRODUCT_SCORE=$BEST_PRODUCT_SCORE"
  echo "4C_5C_BEST_STOCK_TABLE=$BEST_STOCK_TABLE"
  echo "4C_5C_BEST_STOCK_SCORE=$BEST_STOCK_SCORE"
  echo "4C_5C_DB_WRITE_APPLIED=NO"
  echo "4C_5C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5C_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5D_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-5C Product Stock Table Discovery Report"
  echo
  echo "Step: 4C-5C"
  echo "Blok: Product / Stock Table Discovery"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=$DISCOVERY_STATUS"
  echo "4C_5C_DB_CONNECT_STATUS=PASS"
  echo "4C_5C_TENANT_COUNT=$TENANT_COUNT"
  echo "4C_5C_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "4C_5C_PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT"
  echo "4C_5C_STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT"
  echo "4C_5C_CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT"
  echo "4C_5C_UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT"
  echo "4C_5C_BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE"
  echo "4C_5C_BEST_PRODUCT_SCORE=$BEST_PRODUCT_SCORE"
  echo "4C_5C_BEST_STOCK_TABLE=$BEST_STOCK_TABLE"
  echo "4C_5C_BEST_STOCK_SCORE=$BEST_STOCK_SCORE"
  echo "4C_5C_DB_WRITE_APPLIED=NO"
  echo "4C_5C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5C_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5D_READY=$NEXT_READY"
  echo
  echo "## Product candidates"
  printf '%s\n' "$PRODUCT_TABLES"
  echo
  echo "## Stock candidates"
  printf '%s\n' "$STOCK_TABLES"
  echo
  echo "## Category candidates"
  printf '%s\n' "$CATEGORY_TABLES"
  echo
  echo "## Unit candidates"
  printf '%s\n' "$UNIT_TABLES"
  echo
  echo "## Sonuc"
  echo "Product / stock table discovery tamamlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-5D Import Mapping Strategy Decision."
} > "$REPORT_FILE"

echo "OK ✅ Product / stock discovery dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Product / stock discovery report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5C DISCOVERY OZET ====="
echo "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=$DISCOVERY_STATUS"
echo "4C_5C_DB_CONNECT_STATUS=PASS"
echo "4C_5C_TENANT_COUNT=$TENANT_COUNT"
echo "4C_5C_PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT"
echo "4C_5C_STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT"
echo "4C_5C_CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT"
echo "4C_5C_UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT"
echo "4C_5C_BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE"
echo "4C_5C_BEST_STOCK_TABLE=$BEST_STOCK_TABLE"
echo "4C_5C_DB_WRITE_APPLIED=NO"
echo "4C_5D_READY=$NEXT_READY"
