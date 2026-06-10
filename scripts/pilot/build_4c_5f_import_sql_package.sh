#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_report.md"
PREV_TEST_REPORT="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_test_report.md"
STRATEGY_ENV="docs/pilot/faz4c/4c_5d_import_mapping_strategy.env"
SAMPLE_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv"

SQL_FILE="sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_5f_import_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_5f_import_sql_package_report.md"

echo "===== 4C-5F IMPORT SQL PACKAGE / DRY RUN PLAN ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$PREV_REPORT" ] || fail "4C-5E report yok: $PREV_REPORT"
[ -f "$PREV_TEST_REPORT" ] || fail "4C-5E test report yok: $PREV_TEST_REPORT"
[ -f "$STRATEGY_ENV" ] || fail "4C-5D strategy env yok: $STRATEGY_ENV"
[ -f "$SAMPLE_CSV" ] || fail "Sample CSV yok: $SAMPLE_CSV"

grep -q "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS" "$PREV_REPORT" || fail "4C-5E validation PASS degil"
grep -q "4C_5E_SAMPLE_CSV_CREATED=YES" "$PREV_REPORT" || fail "Sample CSV created YES degil"
grep -q "4C_5E_ROW_ERROR_COUNT=0" "$PREV_REPORT" || fail "4C-5E row error 0 degil"
grep -q "4C_5E_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-5E DB write NO degil"
grep -q "4C_5F_READY=YES" "$PREV_REPORT" || fail "4C-5F ready YES yok"

# shellcheck disable=SC1090
source "$STRATEGY_ENV"

[ "${SELECTED_IMPORT_MAPPING_STRATEGY:-}" = "STAGING_FIRST_THEN_CORE_MAPPING" ] || fail "Strategy staging-first degil"
[ "${CORE_DIRECT_APPLY_NOW:-}" = "NO" ] || fail "Core direct apply NO degil"
[ "${STAGING_TABLE_CREATE_NEEDED:-}" = "YES" ] || fail "Staging table create needed YES degil"
[ -n "${STAGING_TABLE:-}" ] || fail "STAGING_TABLE bos"

python3 - <<'PY'
import csv
from pathlib import Path
from datetime import datetime, timezone

sample_csv = Path("imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv")
sql_file = Path("sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql")
sql_file.parent.mkdir(parents=True, exist_ok=True)

tenant_id = "6dfe8d22-035a-401f-807c-507408d2e439"
tenant_business_code = "UZMANPARCACI"
tenant_schema = "tenant_uzmanparcaci"
staging_table = "tenant_uzmanparcaci.pilot_product_import_staging"
import_batch_code = "UZMANPARCACI_SAMPLE_4C5E"

def esc(value: str) -> str:
    return (value or "").replace("'", "''")

with sample_csv.open("r", encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

lines = []
lines.append("-- FAZ 4C — 4C-5F Import SQL Package / Dry Run Plan")
lines.append("-- Purpose: uzmanparcaci product import staging preview")
lines.append("-- IMPORTANT:")
lines.append("--   This SQL file is preview only.")
lines.append("--   It ends with ROLLBACK intentionally.")
lines.append("--   4C-5F does NOT perform permanent DB write.")
lines.append("--")
lines.append(f"-- Generated at: {datetime.now(timezone.utc).isoformat()}")
lines.append(f"-- Tenant business_code: {tenant_business_code}")
lines.append(f"-- Tenant schema: {tenant_schema}")
lines.append(f"-- Staging table: {staging_table}")
lines.append(f"-- Sample row count: {len(rows)}")
lines.append("")
lines.append("BEGIN;")
lines.append("")
lines.append("-- 1. Safety check: tenant must exist")
lines.append("DO $$")
lines.append("DECLARE")
lines.append("  tenant_count integer;")
lines.append("BEGIN")
lines.append("  SELECT count(*) INTO tenant_count")
lines.append("  FROM platform.tenants")
lines.append(f"  WHERE id='{tenant_id}'::uuid")
lines.append(f"    AND business_code='{tenant_business_code}'::core.code_text;")
lines.append("")
lines.append("  IF tenant_count <> 1 THEN")
lines.append("    RAISE EXCEPTION 'Tenant verification failed. tenant_count=%', tenant_count;")
lines.append("  END IF;")
lines.append("END")
lines.append("$$;")
lines.append("")
lines.append("-- 2. Safety check: tenant schema must exist")
lines.append("DO $$")
lines.append("BEGIN")
lines.append("  IF NOT EXISTS (")
lines.append("    SELECT 1 FROM information_schema.schemata")
lines.append(f"    WHERE schema_name='{tenant_schema}'")
lines.append("  ) THEN")
lines.append(f"    RAISE EXCEPTION 'Tenant schema {tenant_schema} does not exist';")
lines.append("  END IF;")
lines.append("END")
lines.append("$$;")
lines.append("")
lines.append("-- 3. Create staging table guarded")
lines.append(f"CREATE TABLE IF NOT EXISTS {staging_table} (")
lines.append("  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),")
lines.append("  tenant_id uuid NOT NULL,")
lines.append("  import_batch_code text NOT NULL,")
lines.append("  source_file text NOT NULL,")
lines.append("  source_row_number integer NOT NULL,")
lines.append("  product_name text NOT NULL,")
lines.append("  sku text NOT NULL,")
lines.append("  category text NOT NULL,")
lines.append("  unit text NOT NULL,")
lines.append("  initial_stock_qty numeric(18,4) NOT NULL,")
lines.append("  sale_price numeric(18,4) NOT NULL,")
lines.append("  purchase_price numeric(18,4) NOT NULL,")
lines.append("  currency text NOT NULL,")
lines.append("  oem_code text NOT NULL,")
lines.append("  equivalent_code text NOT NULL,")
lines.append("  vehicle_fitment_note text NOT NULL,")
lines.append("  brand text NOT NULL,")
lines.append("  part_group text NOT NULL,")
lines.append("  barcode text NULL,")
lines.append("  notes text NULL,")
lines.append("  validation_status text NOT NULL DEFAULT 'VALIDATED',")
lines.append("  created_at timestamptz NOT NULL DEFAULT now(),")
lines.append("  updated_at timestamptz NOT NULL DEFAULT now()")
lines.append(");")
lines.append("")
lines.append("-- 4. Insert sample rows into staging")
for idx, row in enumerate(rows, start=2):
    lines.append(f"INSERT INTO {staging_table} (")
    lines.append("  tenant_id,")
    lines.append("  import_batch_code,")
    lines.append("  source_file,")
    lines.append("  source_row_number,")
    lines.append("  product_name,")
    lines.append("  sku,")
    lines.append("  category,")
    lines.append("  unit,")
    lines.append("  initial_stock_qty,")
    lines.append("  sale_price,")
    lines.append("  purchase_price,")
    lines.append("  currency,")
    lines.append("  oem_code,")
    lines.append("  equivalent_code,")
    lines.append("  vehicle_fitment_note,")
    lines.append("  brand,")
    lines.append("  part_group,")
    lines.append("  barcode,")
    lines.append("  notes")
    lines.append(")")
    lines.append("SELECT")
    lines.append(f"  '{tenant_id}'::uuid,")
    lines.append(f"  '{import_batch_code}',")
    lines.append("  'product_import_sample.csv',")
    lines.append(f"  {idx},")
    lines.append(f"  '{esc(row['product_name'])}',")
    lines.append(f"  '{esc(row['sku'])}',")
    lines.append(f"  '{esc(row['category'])}',")
    lines.append(f"  '{esc(row['unit'])}',")
    lines.append(f"  {row['initial_stock_qty']},")
    lines.append(f"  {row['sale_price']},")
    lines.append(f"  {row['purchase_price']},")
    lines.append(f"  '{esc(row['currency'])}',")
    lines.append(f"  '{esc(row['oem_code'])}',")
    lines.append(f"  '{esc(row['equivalent_code'])}',")
    lines.append(f"  '{esc(row['vehicle_fitment_note'])}',")
    lines.append(f"  '{esc(row['brand'])}',")
    lines.append(f"  '{esc(row['part_group'])}',")
    barcode = row.get("barcode") or ""
    if barcode.strip():
        lines.append(f"  '{esc(barcode)}',")
    else:
        lines.append("  NULL,")
    lines.append(f"  '{esc(row.get('notes') or '')}'")
    lines.append("WHERE NOT EXISTS (")
    lines.append(f"  SELECT 1 FROM {staging_table}")
    lines.append(f"  WHERE tenant_id='{tenant_id}'::uuid")
    lines.append(f"    AND import_batch_code='{import_batch_code}'")
    lines.append(f"    AND sku='{esc(row['sku'])}'")
    lines.append(");")
    lines.append("")

lines.append("-- 5. Verification")
lines.append("SELECT 'staging_row_count' AS check_name, count(*)::text AS check_value")
lines.append(f"FROM {staging_table}")
lines.append(f"WHERE tenant_id='{tenant_id}'::uuid")
lines.append(f"  AND import_batch_code='{import_batch_code}';")
lines.append("")
lines.append("SELECT 'duplicate_sku_count' AS check_name, count(*)::text AS check_value")
lines.append("FROM (")
lines.append("  SELECT sku")
lines.append(f"  FROM {staging_table}")
lines.append(f"  WHERE tenant_id='{tenant_id}'::uuid")
lines.append(f"    AND import_batch_code='{import_batch_code}'")
lines.append("  GROUP BY sku")
lines.append("  HAVING count(*) > 1")
lines.append(") d;")
lines.append("")
lines.append("ROLLBACK;")
lines.append("")
lines.append("-- Note:")
lines.append("-- This preview intentionally ends with ROLLBACK.")
lines.append("-- 4C-5G will execute this preview and verify rollback safety.")

sql_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

[ -f "$SQL_FILE" ] || fail "SQL preview olusmadi: $SQL_FILE"

grep -q "BEGIN;" "$SQL_FILE" || fail "SQL preview BEGIN yok"
grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL preview ROLLBACK yok"

if grep -q "COMMIT;" "$SQL_FILE"; then
  fail "SQL preview COMMIT icermemeli"
fi

grep -q "CREATE TABLE IF NOT EXISTS tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" || fail "Staging table create yok"
grep -q "INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" || fail "Staging insert yok"
grep -q "staging_row_count" "$SQL_FILE" || fail "Verification staging_row_count yok"
grep -q "duplicate_sku_count" "$SQL_FILE" || fail "Verification duplicate_sku_count yok"

INSERT_COUNT="$(grep -c "INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" | tr -d ' ')"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
SQL_PACKAGE_STATUS="PASS"

if [ "$INSERT_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  SQL_PACKAGE_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-5F Import SQL Package / Dry Run Plan

## Amaç

uzmanparcaci sample CSV verisini staging/import tablosuna alacak SQL preview paketini üretmek.

Bu adım DB'ye yazmaz.

---

## Ön koşullar

4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS
4C_5E_SAMPLE_ROW_COUNT=5
4C_5E_ROW_ERROR_COUNT=0
4C_5F_READY=YES

---

## Seçilen strateji

SELECTED_IMPORT_MAPPING_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
CORE_DIRECT_APPLY_NOW=NO
STAGING_TABLE_CREATE_NEEDED=YES
STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging

---

## SQL preview

SQL_FILE=$SQL_FILE

Bu SQL:

- BEGIN ile başlar
- tenant doğrulaması yapar
- tenant schema doğrulaması yapar
- staging tabloyu CREATE TABLE IF NOT EXISTS ile hazırlar
- 5 sample CSV satırını staging tabloya INSERT eder
- staging row count doğrulaması yapar
- duplicate SKU kontrolü yapar
- ROLLBACK ile biter

---

## Güvenlik kararı

4C-5F sadece SQL dosyası üretir.
4C-5F SQL çalıştırmaz.
4C-5F DB write yapmaz.
Dry-run execution 4C-5G içinde yapılacaktır.

---

## Status

4C_5F_IMPORT_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS
4C_5F_SQL_FILE_CREATED=YES
4C_5F_SQL_FILE=$SQL_FILE
4C_5F_SQL_HAS_BEGIN=YES
4C_5F_SQL_HAS_ROLLBACK=YES
4C_5F_SQL_HAS_COMMIT=NO
4C_5F_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES
4C_5F_SAMPLE_INSERT_COUNT=$INSERT_COUNT
4C_5F_EXPECTED_INSERT_COUNT=5
4C_5F_DB_WRITE_APPLIED=NO
4C_5F_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5F_WARNING_COUNT=$WARNING_COUNT
4C_5G_READY=$NEXT_READY
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-5F Import SQL Package Report

Step: 4C-5F
Blok: Import SQL Package / Dry Run Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5F_IMPORT_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS
4C_5F_SQL_FILE_CREATED=YES
4C_5F_SQL_FILE=$SQL_FILE
4C_5F_SQL_HAS_BEGIN=YES
4C_5F_SQL_HAS_ROLLBACK=YES
4C_5F_SQL_HAS_COMMIT=NO
4C_5F_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES
4C_5F_SAMPLE_INSERT_COUNT=$INSERT_COUNT
4C_5F_EXPECTED_INSERT_COUNT=5
4C_5F_DB_WRITE_APPLIED=NO
4C_5F_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_5F_WARNING_COUNT=$WARNING_COUNT
4C_5G_READY=$NEXT_READY

## Sonuc

Import SQL preview paketi hazirlandi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-5G Import Dry Run / ROLLBACK Verification.
REPORT_EOF

echo "OK ✅ Import SQL preview paketi olusturuldu: $SQL_FILE"
echo "OK ✅ Import SQL package dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Import SQL package report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5F SQL PACKAGE OZET ====="
echo "4C_5F_IMPORT_SQL_PACKAGE_STATUS=$SQL_PACKAGE_STATUS"
echo "4C_5F_SQL_FILE_CREATED=YES"
echo "4C_5F_SQL_HAS_BEGIN=YES"
echo "4C_5F_SQL_HAS_ROLLBACK=YES"
echo "4C_5F_SQL_HAS_COMMIT=NO"
echo "4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES"
echo "4C_5F_SAMPLE_INSERT_COUNT=$INSERT_COUNT"
echo "4C_5F_EXPECTED_INSERT_COUNT=5"
echo "4C_5F_DB_WRITE_APPLIED=NO"
echo "4C_5G_READY=$NEXT_READY"
