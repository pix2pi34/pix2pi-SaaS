#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_5d_import_mapping_strategy_report.md"
PREV_TEST_REPORT="reports/pilot/faz4c/4c_5d_import_mapping_strategy_test_report.md"
STRATEGY_ENV="docs/pilot/faz4c/4c_5d_import_mapping_strategy.env"

SAMPLE_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv"
TEMPLATE_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_template.csv"

DOC_FILE="docs/pilot/faz4c/4c_5e_sample_csv_generation_validation.md"
REPORT_FILE="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_report.md"
TMP_RESULT="/tmp/4c_5e_sample_csv_validation_result.env"

echo "===== 4C-5E SAMPLE CSV GENERATION / VALIDATION ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$PREV_REPORT" ] || fail "4C-5D report yok: $PREV_REPORT"
[ -f "$PREV_TEST_REPORT" ] || fail "4C-5D test report yok: $PREV_TEST_REPORT"
[ -f "$STRATEGY_ENV" ] || fail "4C-5D strategy env yok: $STRATEGY_ENV"

grep -q "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=PASS" "$PREV_REPORT" || fail "4C-5D strategy PASS degil"
grep -q "4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING" "$PREV_REPORT" || fail "4C-5D selected strategy staging-first degil"
grep -q "4C_5D_CORE_DIRECT_APPLY_NOW=NO" "$PREV_REPORT" || fail "4C-5D core direct apply NO degil"
grep -q "4C_5E_READY=YES" "$PREV_REPORT" || fail "4C-5E ready YES yok"

python3 - <<'PY'
import csv
from pathlib import Path

sample_path = Path("imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv")
sample_path.parent.mkdir(parents=True, exist_ok=True)

header = [
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

rows = [
    {
        "product_name": "Fren Balatasi On Takim",
        "sku": "UZP-FREN-0001",
        "category": "Fren Sistemi",
        "unit": "ADET",
        "initial_stock_qty": "12",
        "sale_price": "1250",
        "purchase_price": "850",
        "currency": "TRY",
        "oem_code": "OEM-FREN-001",
        "equivalent_code": "EQ-FREN-001",
        "vehicle_fitment_note": "Renault Megane 3 / Fluence uyumlu",
        "brand": "Ornek Marka",
        "part_group": "Fren",
        "barcode": "",
        "notes": "Pilot sample 1",
    },
    {
        "product_name": "Yag Filtresi",
        "sku": "UZP-FILTRE-0002",
        "category": "Filtre",
        "unit": "ADET",
        "initial_stock_qty": "25",
        "sale_price": "320",
        "purchase_price": "210",
        "currency": "TRY",
        "oem_code": "OEM-FILTRE-002",
        "equivalent_code": "EQ-FILTRE-002",
        "vehicle_fitment_note": "Renault Clio / Symbol uyumlu",
        "brand": "Ornek Marka",
        "part_group": "Filtre",
        "barcode": "",
        "notes": "Pilot sample 2",
    },
    {
        "product_name": "Hava Filtresi",
        "sku": "UZP-FILTRE-0003",
        "category": "Filtre",
        "unit": "ADET",
        "initial_stock_qty": "18",
        "sale_price": "450",
        "purchase_price": "300",
        "currency": "TRY",
        "oem_code": "OEM-HAVA-003",
        "equivalent_code": "EQ-HAVA-003",
        "vehicle_fitment_note": "Fiat Egea / Linea uyumlu",
        "brand": "Ornek Marka",
        "part_group": "Filtre",
        "barcode": "",
        "notes": "Pilot sample 3",
    },
    {
        "product_name": "Amortisor On Sag",
        "sku": "UZP-SUSP-0004",
        "category": "Suspansiyon",
        "unit": "ADET",
        "initial_stock_qty": "6",
        "sale_price": "2100",
        "purchase_price": "1500",
        "currency": "TRY",
        "oem_code": "OEM-AMORT-004",
        "equivalent_code": "EQ-AMORT-004",
        "vehicle_fitment_note": "Ford Focus 3 on sag uyumlu",
        "brand": "Ornek Marka",
        "part_group": "Suspansiyon",
        "barcode": "",
        "notes": "Pilot sample 4",
    },
    {
        "product_name": "Triger Seti",
        "sku": "UZP-MOTOR-0005",
        "category": "Motor",
        "unit": "SET",
        "initial_stock_qty": "4",
        "sale_price": "3900",
        "purchase_price": "2800",
        "currency": "TRY",
        "oem_code": "OEM-TRIGER-005",
        "equivalent_code": "EQ-TRIGER-005",
        "vehicle_fitment_note": "Volkswagen Golf / Jetta uyumlu",
        "brand": "Ornek Marka",
        "part_group": "Motor",
        "barcode": "",
        "notes": "Pilot sample 5",
    },
]

with sample_path.open("w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=header)
    writer.writeheader()
    writer.writerows(rows)
PY

python3 - <<'PY' > "$TMP_RESULT"
import csv
from pathlib import Path

sample_path = Path("imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv")
template_path = Path("imports/pilot/faz4c/uzmanparcaci/product_import_template.csv")

expected_header = [
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

numeric_columns = ["initial_stock_qty", "sale_price", "purchase_price"]
allowed_currency = {"TRY", "USD", "EUR"}

errors = []
warnings = []

def read_csv(path):
    if not path.exists():
        return [], []
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        return reader.fieldnames or [], list(reader)

sample_header, sample_rows = read_csv(sample_path)
template_header, template_rows = read_csv(template_path)

if not sample_path.exists():
    errors.append("SAMPLE_CSV_MISSING")

if sample_header != expected_header:
    errors.append("SAMPLE_HEADER_ORDER_MISMATCH")

if template_header and template_header != expected_header:
    errors.append("TEMPLATE_HEADER_ORDER_MISMATCH")

missing_columns = [c for c in expected_header if c not in sample_header]
extra_columns = [c for c in sample_header if c not in expected_header]

if missing_columns:
    errors.append("MISSING_COLUMNS_" + "_".join(missing_columns))

if extra_columns:
    warnings.append("EXTRA_COLUMNS_" + "_".join(extra_columns))

row_count = len(sample_rows)
if row_count < 5:
    errors.append("SAMPLE_ROW_COUNT_LT_5")

sku_values = set()
duplicate_sku_count = 0
row_error_count = 0
barcode_blank_count = 0

for idx, row in enumerate(sample_rows, start=2):
    for col in required_non_empty:
        val = (row.get(col) or "").strip()
        if not val:
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
        val = (row.get(col) or "").strip()
        try:
            num = float(val)
            if num < 0:
                errors.append(f"ROW_{idx}_NEGATIVE_{col}")
                row_error_count += 1
        except Exception:
            errors.append(f"ROW_{idx}_INVALID_NUMBER_{col}")
            row_error_count += 1

    currency = (row.get("currency") or "").strip().upper()
    if currency not in allowed_currency:
        errors.append(f"ROW_{idx}_INVALID_CURRENCY")
        row_error_count += 1

    barcode = (row.get("barcode") or "").strip()
    if not barcode:
        barcode_blank_count += 1

    sale_price = float((row.get("sale_price") or "0").strip())
    purchase_price = float((row.get("purchase_price") or "0").strip())
    if sale_price < purchase_price:
        errors.append(f"ROW_{idx}_SALE_LT_PURCHASE")
        row_error_count += 1

if barcode_blank_count > 0:
    warnings.append("BARCODE_BLANK_ALLOWED_FOR_PILOT")

status = "PASS" if not errors else "BLOCKED"
critical = 0 if not errors else len(errors)
warning_count = len(warnings)

print(f"SAMPLE_CSV_CREATED={'YES' if sample_path.exists() else 'NO'}")
print(f"TEMPLATE_CSV_FOUND={'YES' if template_path.exists() else 'NO'}")
print(f"HEADER_COLUMN_COUNT={len(sample_header)}")
print(f"EXPECTED_COLUMN_COUNT={len(expected_header)}")
print(f"HEADER_ORDER_STATUS={'PASS' if sample_header == expected_header else 'FAIL'}")
print(f"MISSING_COLUMN_COUNT={len(missing_columns)}")
print(f"EXTRA_COLUMN_COUNT={len(extra_columns)}")
print(f"SAMPLE_ROW_COUNT={row_count}")
print(f"DUPLICATE_SKU_COUNT={duplicate_sku_count}")
print(f"ROW_ERROR_COUNT={row_error_count}")
print(f"BARCODE_BLANK_COUNT={barcode_blank_count}")
print(f"NUMERIC_COLUMN_COUNT={len(numeric_columns)}")
print(f"CRITICAL_BLOCKER_COUNT={critical}")
print(f"WARNING_COUNT={warning_count}")
print(f"SAMPLE_VALIDATION_STATUS={status}")
print("ERRORS=" + ("NONE" if not errors else "|".join(errors)))
print("WARNINGS=" + ("NONE" if not warnings else "|".join(warnings)))
PY

# shellcheck disable=SC1090
source "$TMP_RESULT"

NEXT_READY="YES"
if [ "$SAMPLE_VALIDATION_STATUS" != "PASS" ]; then
  NEXT_READY="NO"
fi

{
  echo "# FAZ 4C — 4C-5E Sample CSV Generation / Validation"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci icin kontrollu sample product/stock CSV dosyasi uretmek ve veri kalitesini dogrulamak."
  echo
  echo "Bu adim DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. Onceki karar"
  echo
  echo "SELECTED_IMPORT_MAPPING_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING"
  echo "CORE_DIRECT_APPLY_NOW=NO"
  echo "STAGING_TABLE_CREATE_NEEDED=YES"
  echo
  echo "---"
  echo
  echo "## 2. Dosyalar"
  echo
  echo "TEMPLATE_CSV=$TEMPLATE_CSV"
  echo "SAMPLE_CSV=$SAMPLE_CSV"
  echo "SAMPLE_CSV_CREATED=$SAMPLE_CSV_CREATED"
  echo "TEMPLATE_CSV_FOUND=$TEMPLATE_CSV_FOUND"
  echo
  echo "---"
  echo
  echo "## 3. Header kontrolu"
  echo
  echo "HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo "MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo
  echo "---"
  echo
  echo "## 4. Satir kontrolu"
  echo
  echo "SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT"
  echo "NUMERIC_COLUMN_COUNT=$NUMERIC_COLUMN_COUNT"
  echo
  echo "---"
  echo
  echo "## 5. Warnings"
  echo
  echo "WARNINGS=$WARNINGS"
  echo
  echo "Not:"
  echo "Barcode bos olabilir. Pilot isletme barkod kullanmadigini bildirdigi icin blocker degildir."
  echo
  echo "---"
  echo
  echo "## 6. Errors"
  echo
  echo "ERRORS=$ERRORS"
  echo
  echo "---"
  echo
  echo "## 7. Status"
  echo
  echo "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=$SAMPLE_VALIDATION_STATUS"
  echo "4C_5E_SAMPLE_CSV_CREATED=$SAMPLE_CSV_CREATED"
  echo "4C_5E_TEMPLATE_CSV_FOUND=$TEMPLATE_CSV_FOUND"
  echo "4C_5E_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "4C_5E_EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "4C_5E_HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo "4C_5E_MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "4C_5E_EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo "4C_5E_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "4C_5E_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "4C_5E_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "4C_5E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT"
  echo "4C_5E_DB_WRITE_APPLIED=NO"
  echo "4C_5E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5E_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5F_READY=$NEXT_READY"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-5E Sample CSV Generation Validation Report"
  echo
  echo "Step: 4C-5E"
  echo "Blok: Sample CSV Generation / Validation"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=$SAMPLE_VALIDATION_STATUS"
  echo "4C_5E_SAMPLE_CSV_CREATED=$SAMPLE_CSV_CREATED"
  echo "4C_5E_TEMPLATE_CSV_FOUND=$TEMPLATE_CSV_FOUND"
  echo "4C_5E_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
  echo "4C_5E_EXPECTED_COLUMN_COUNT=$EXPECTED_COLUMN_COUNT"
  echo "4C_5E_HEADER_ORDER_STATUS=$HEADER_ORDER_STATUS"
  echo "4C_5E_MISSING_COLUMN_COUNT=$MISSING_COLUMN_COUNT"
  echo "4C_5E_EXTRA_COLUMN_COUNT=$EXTRA_COLUMN_COUNT"
  echo "4C_5E_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
  echo "4C_5E_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
  echo "4C_5E_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
  echo "4C_5E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT"
  echo "4C_5E_DB_WRITE_APPLIED=NO"
  echo "4C_5E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
  echo "4C_5E_WARNING_COUNT=$WARNING_COUNT"
  echo "4C_5F_READY=$NEXT_READY"
  echo
  echo "## Files"
  echo "SAMPLE_CSV=$SAMPLE_CSV"
  echo "TEMPLATE_CSV=$TEMPLATE_CSV"
  echo
  echo "## Errors"
  echo "$ERRORS"
  echo
  echo "## Warnings"
  echo "$WARNINGS"
  echo
  echo "## Sonuc"
  echo "Sample CSV generation / validation tamamlandi."
  echo "Bu adimda DB yazma islemi yapilmadi."
  echo "Sonraki adim: 4C-5F Import SQL Package / Dry Run Plan."
} > "$REPORT_FILE"

echo "OK ✅ Sample CSV olusturuldu: $SAMPLE_CSV"
echo "OK ✅ Sample CSV validation dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Sample CSV validation report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-5E VALIDATION OZET ====="
echo "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=$SAMPLE_VALIDATION_STATUS"
echo "4C_5E_SAMPLE_CSV_CREATED=$SAMPLE_CSV_CREATED"
echo "4C_5E_HEADER_COLUMN_COUNT=$HEADER_COLUMN_COUNT"
echo "4C_5E_SAMPLE_ROW_COUNT=$SAMPLE_ROW_COUNT"
echo "4C_5E_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
echo "4C_5E_ROW_ERROR_COUNT=$ROW_ERROR_COUNT"
echo "4C_5E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT"
echo "4C_5E_DB_WRITE_APPLIED=NO"
echo "4C_5F_READY=$NEXT_READY"
