#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_5a_data_import_scope_freeze_report.md"
CSV_FILE="imports/pilot/faz4c/uzmanparcaci/product_import_template.csv"

DOC_FILE="docs/pilot/faz4c/4c_5b_import_template_structure_precheck.md"
REPORT_FILE="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_report.md"
TMP_RESULT="/tmp/4c_5b_import_template_validation_result.env"

echo "===== 4C-5B IMPORT TEMPLATE STRUCTURE PRECHECK ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$PREV_REPORT" ] || fail "4C-5A report yok: $PREV_REPORT"
[ -f "$CSV_FILE" ] || fail "Import CSV yok: $CSV_FILE"

grep -q "4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS" "$PREV_REPORT" || fail "4C-5A PASS degil"
grep -q "4C_5B_READY=YES" "$PREV_REPORT" || fail "4C-5B ready YES degil"

python3 - <<'PY' > "$TMP_RESULT"
import csv
import re
from pathlib import Path

csv_file = Path("imports/pilot/faz4c/uzmanparcaci/product_import_template.csv")

required_columns = [
    "product_name",
    "sku",
    "category",
    "unit",
    "initial_stock_qty",
    "sale_price",
    "purchase_price",
    "currency",
    "oem_code",
    "equivalent_code",
    "vehicle_fitment_note",
    "brand",
    "part_group",
    "barcode",
    "notes",
]

required_non_empty = [
    "product_name",
    "sku",
    "category",
    "unit",
    "initial_stock_qty",
    "sale_price",
    "purchase_price",
    "currency",
    "oem_code",
    "equivalent_code",
    "vehicle_fitment_note",
    "brand",
    "part_group",
]

numeric_columns = [
    "initial_stock_qty",
    "sale_price",
    "purchase_price",
]

allowed_currency = {"TRY", "USD", "EUR"}

errors = []
warnings = []

if not csv_file.exists():
    errors.append("CSV_FILE_MISSING")
    rows = []
    header = []
else:
    with csv_file.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        header = reader.fieldnames or []
        rows = list(reader)

missing = [c for c in required_columns if c not in header]
extra = [c for c in header if c not in required_columns]

if missing:
    errors.append("MISSING_COLUMNS:" + ",".join(missing))

if extra:
    warnings.append("EXTRA_COLUMNS:" + ",".join(extra))

if header != required_columns:
    errors.append("HEADER_ORDER_MISMATCH")

if len(rows) < 1:
    errors.append("NO_SAMPLE_ROW")

sku_values = set()
duplicate_sku_count = 0
row_error_count = 0
row_warning_count = 0

for idx, row in enumerate(rows, start=2):
    for col in required_non_empty:
        value = (row.get(col) or "").strip()
        if not value:
            errors.append(f"ROW_{idx}_EMPTY_{col}")
            row_error_count += 1

    sku = (row.get("sku") or "").strip()
    if sku:
        if sku in sku_values:
            duplicate_sku_count += 1
            errors.append(f"ROW_{idx}_DUPLICATE_SKU")
            row_error_count += 1
        sku_values.add(sku)

    for col in numeric_columns:
        value = (row.get(col) or "").strip()
        try:
            number = float(value)
            if number < 0:
                errors.append(f"ROW_{idx}_NEGATIVE_{col}")
                row_error_count += 1
        except Exception:
            errors.append(f"ROW_{idx}_INVALID_NUMBER_{col}")
            row_error_count += 1

    currency = (row.get("currency") or "").strip().upper()
    if currency and currency not in allowed_currency:
        errors.append(f"ROW_{idx}_INVALID_CURRENCY")
        row_error_count += 1

    barcode = (row.get("barcode") or "").strip()
    if not barcode:
        row_warning_count += 1

status = "PASS" if not errors else "BLOCKED"
critical = 0 if not errors else len(errors)

print(f"CSV_FILE_FOUND={'YES' if csv_file.exists() else 'NO'}")
print(f"HEADER_COLUMN_COUNT={len(header)}")
print(f"EXPECTED_COLUMN_COUNT={len(required_columns)}")
print(f"HEADER_ORDER_STATUS={'PASS' if header == required_columns else 'FAIL'}")
print(f"MISSING_COLUMN_COUNT={len(missing)}")
print(f"EXTRA_COLUMN_COUNT={len(extra)}")
print(f"SAMPLE_ROW_COUNT={len(rows)}")
print(f"REQUIRED_NON_EMPTY_FIELD_COUNT={len(required_non_empty)}")
print(f"NUMERIC_COLUMN_COUNT={len(numeric_columns)}")
print(f"DUPLICATE_SKU_COUNT={duplicate_sku_count}")
print(f"ROW_ERROR_COUNT={row_error_count}")
print(f"ROW_WARNING_COUNT={row_warning_count}")
print(f"CRITICAL_BLOCKER_COUNT={critical}")
print(f"WARNING_COUNT={len(warnings) + row_warning_count}")
print(f"TEMPLATE_STRUCTURE_STATUS={status}")
print("MISSING_COLUMNS=" + ("NONE" if not missing else ",".join(missing)))
print("EXTRA_COLUMNS=" + ("NONE" if not extra else ",".join(extra)))
print("ERRORS=" + ("NONE" if not errors else " | ".join(errors)))
print("WARNINGS=" + ("NONE" if not warnings else " | ".join(warnings)))
PY

# shellcheck disable=SC1090
source "$TMP_RESULT"

NEXT_READY="YES"
if [ "$TEMPLATE_STRUCTURE_STATUS" != "PASS" ]; then
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-5B Import Template Structure Precheck"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci product/stock import template yapisini ve ornek satir veri kalitesini kontrol etmek."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Template"
  echo
  echo "CSV_FILE=$CSV_FILE"
  echo "CSV_FILE_FOUND=$CSV_FILE_FOUND"
  echo "HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo
  echo "---"
  echo
  echo "## 2. Kolon kalite kontrolu"
  echo
  echo "MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo "MISSING_COLUMNS=$MISSING_COLUMNS"
  echo "EXTRA_COLUMNS=$EXTRA_COLUMNS"
  echo
  echo "---"
  echo
  echo "## 3. Satir kalite kontrolu"
  echo
  echo "SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "REQUIRED_NON_EMPTY_FIELD_COUNT=$REQUIRED_NON_EMPTY_FIELD_COUNT"
  echo "NUMERIC_COLUMN_COUNT=$NUMERIC_COLUMN_COUNT"
  echo "DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "ROW_WARNING_COUNT=$ROW_WARNING_COUNT"
  echo
  echo "---"
  echo
  echo "## 4. Uyarilar"
  echo
  echo "WARNINGS=$WARNINGS"
  echo
  echo "Not:"
  echo "Barcode bos olabilir. Pilot isletme barkod kullanmadigini bildirdigi icin bu blocker degildir."
  echo
  echo "---"
  echo
  echo "## 5. Hatalar"
  echo
  echo "ERRORS=$ERRORS"
  echo
  echo "---"
  echo
  echo "## 6. Status"
  echo
  echo "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=$TEMPLATE_STRUCTURE_STATUS"
  echo "4C_5B_CSV_FILE_FOUND=$CSV_FILE_FOUND"
  echo "4C_5B_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "4C_5B_EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "4C_5B_HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo "4C_5B_MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "4C_5B_EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo "4C_5B_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "4C_5B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "4C_5B_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "4C_5B_ROW_WARNING_COUNT=$ROW_WARNING_COUNT"
  echo "4C_5B_DB_WRITE_APPLIED=NO"
  echo "4C_5B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5B_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5C_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-5B Import Template Structure Precheck Report"
  echo
  echo "Step: 4C-5B"
  echo "Blok: Import Template Structure Precheck"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=$TEMPLATE_STRUCTURE_STATUS"
  echo "4C_5B_CSV_FILE_FOUND=$CSV_FILE_FOUND"
  echo "4C_5B_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "4C_5B_EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "4C_5B_HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo "4C_5B_MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "4C_5B_EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo "4C_5B_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "4C_5B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "4C_5B_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "4C_5B_ROW_WARNING_COUNT=$ROW_WARNING_COUNT"
  echo "4C_5B_DB_WRITE_APPLIED=NO"
  echo "4C_5B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5B_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5C_READY=$NEXT_READY"
  echo
  echo "## Errors"
  echo "$ERRORS"
  echo
  echo "## Warnings"
  echo "$WARNINGS"
  echo
  echo "## Sonuc"
  echo "Import template structure precheck tamamlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-5C Product / Stock Table Discovery."
} > "$REPORT_FILE"

echo "OK ✅ Import template precheck dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Import template precheck report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5B PRECHECK OZET ====="
echo "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=$TEMPLATE_STRUCTURE_STATUS"
echo "4C_5B_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
echo "4C_5B_EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
echo "4C_5B_HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
echo "4C_5B_MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
echo "4C_5B_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
echo "4C_5B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
echo "4C_5B_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
echo "4C_5B_ROW_WARNING_COUNT=$ROW_WARNING_COUNT"
echo "4C_5B_DB_WRITE_APPLIED=NO"
echo "4C_5C_READY=$NEXT_READY"
