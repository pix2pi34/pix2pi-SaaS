#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_2_urun_stok_import.v1.json}"
MAPPING_FILE="${MAPPING_FILE:-configs/faz4r/product_stock_import_mapping.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PRODUCT_STOCK_IMPORT_ERROR=$1"
  exit 1
}

if [ -z "$INPUT_FILE" ]; then
  fail "INPUT_FILE_REQUIRED"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$MAPPING_FILE" ]; then
  fail "MAPPING_FILE_NOT_FOUND"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$MAPPING_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
mapping_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
mapping = json.loads(mapping_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

def is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 199, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("import_policy", {})

require(mapping.get("mapping_status") == "READY", "MAPPING_STATUS_NOT_READY")
require(mapping.get("import_mode") == policy.get("import_mode_required"), "MAPPING_IMPORT_MODE_INVALID")
require(mapping.get("commit_allowed") is False, "MAPPING_COMMIT_ALLOWED_TRUE")
require("import_staging_products" in mapping.get("target_staging_tables", []), "PRODUCT_STAGING_TABLE_MISSING")
require("import_staging_stock_entries" in mapping.get("target_staging_tables", []), "STOCK_STAGING_TABLE_MISSING")
require(mapping.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "MAPPING_CLOSED_POLICY_REFERENCE_MISSING")

import_batch = payload.get("import_batch", {})
tenant_id = import_batch.get("tenant_id")
batch_id = import_batch.get("batch_id")
products = payload.get("products", [])
stock_entries = payload.get("stock_entries", [])
external_policy = payload.get("external_policy", {})

require(non_empty(tenant_id), "TENANT_ID_REQUIRED")
require(non_empty(batch_id), "BATCH_ID_REQUIRED")
require(import_batch.get("import_type") == "PRODUCT_STOCK", "IMPORT_TYPE_INVALID")
require(import_batch.get("import_mode") == policy.get("import_mode_required"), "IMPORT_MODE_NOT_DRY_RUN")
require(import_batch.get("commit_requested") is False, "COMMIT_REQUESTED_NOT_ALLOWED")
require(import_batch.get("source_format") in {"CSV", "XLSX", "JSON"}, "SOURCE_FORMAT_INVALID")

require(isinstance(products, list), "PRODUCT_ROWS_NOT_LIST")
require(isinstance(stock_entries, list), "STOCK_ROWS_NOT_LIST")

if isinstance(products, list):
    require(len(products) > 0, "PRODUCT_ROWS_EMPTY")
    require(len(products) <= policy.get("max_product_rows_per_batch", 5000), "PRODUCT_ROWS_EXCEED_BATCH_LIMIT")
    require(import_batch.get("total_product_rows") == len(products), "TOTAL_PRODUCT_ROWS_MISMATCH")

if isinstance(stock_entries, list):
    require(len(stock_entries) <= policy.get("max_stock_rows_per_batch", 20000), "STOCK_ROWS_EXCEED_BATCH_LIMIT")
    require(import_batch.get("total_stock_rows") == len(stock_entries), "TOTAL_STOCK_ROWS_MISMATCH")

product_codes = set()
barcodes = set()
skus = set()
valid_product_rows = 0

allowed_product_types = {"PHYSICAL", "SERVICE", "BUNDLE", "RAW_MATERIAL"}
allowed_unit_codes = {"ADET", "KG", "LT", "MT", "PAKET", "KOLI", "SAAT"}

for idx, row in enumerate(products, start=1):
    prefix = f"PRODUCT_ROW_{idx}"

    require(row.get("tenant_id") == tenant_id, f"{prefix}_TENANT_ID_MISMATCH")

    product_code = row.get("product_code")
    product_name = row.get("product_name")
    product_type = row.get("product_type")
    unit_code = row.get("unit_code")
    barcode = row.get("barcode")
    sku = row.get("sku")
    tax_rate = row.get("tax_rate")
    sales_price = row.get("sales_price", 0)
    purchase_price = row.get("purchase_price", 0)
    track_stock = row.get("track_stock")

    require(non_empty(product_code), f"{prefix}_PRODUCT_CODE_REQUIRED")
    require(non_empty(product_name), f"{prefix}_PRODUCT_NAME_REQUIRED")
    require(product_type in allowed_product_types, f"{prefix}_PRODUCT_TYPE_INVALID")
    require(unit_code in allowed_unit_codes, f"{prefix}_UNIT_CODE_INVALID")
    require(is_number(tax_rate), f"{prefix}_TAX_RATE_REQUIRED")
    if is_number(tax_rate):
        require(0 <= tax_rate <= 100, f"{prefix}_TAX_RATE_INVALID")
    require(is_number(sales_price), f"{prefix}_SALES_PRICE_NUMBER_REQUIRED")
    if is_number(sales_price):
        require(sales_price >= 0, f"{prefix}_SALES_PRICE_NEGATIVE")
    require(is_number(purchase_price), f"{prefix}_PURCHASE_PRICE_NUMBER_REQUIRED")
    if is_number(purchase_price):
        require(purchase_price >= 0, f"{prefix}_PURCHASE_PRICE_NEGATIVE")
    require(isinstance(track_stock, bool), f"{prefix}_TRACK_STOCK_BOOLEAN_REQUIRED")

    if non_empty(product_code):
        require(product_code not in product_codes, f"{prefix}_DUPLICATE_PRODUCT_CODE")
        product_codes.add(product_code)

    if non_empty(barcode):
        require(barcode not in barcodes, f"{prefix}_DUPLICATE_BARCODE")
        barcodes.add(barcode)

    if non_empty(sku):
        require(sku not in skus, f"{prefix}_DUPLICATE_SKU")
        skus.add(sku)

    valid_product_rows += 1

valid_stock_rows = 0
stock_seen = set()

for idx, row in enumerate(stock_entries, start=1):
    prefix = f"STOCK_ROW_{idx}"

    require(row.get("tenant_id") == tenant_id, f"{prefix}_TENANT_ID_MISMATCH")

    product_code = row.get("product_code")
    warehouse_code = row.get("warehouse_code")
    quantity = row.get("quantity")
    reserved_quantity = row.get("reserved_quantity")
    min_stock_quantity = row.get("min_stock_quantity")

    require(non_empty(product_code), f"{prefix}_PRODUCT_CODE_REQUIRED")
    require(non_empty(warehouse_code), f"{prefix}_WAREHOUSE_CODE_REQUIRED")
    require(product_code in product_codes, f"{prefix}_UNKNOWN_PRODUCT_CODE")

    key = (product_code, warehouse_code)
    require(key not in stock_seen, f"{prefix}_DUPLICATE_PRODUCT_WAREHOUSE")
    stock_seen.add(key)

    require(is_number(quantity), f"{prefix}_QUANTITY_NUMBER_REQUIRED")
    if is_number(quantity):
        require(quantity >= 0, f"{prefix}_NEGATIVE_STOCK_QUANTITY")

    require(is_number(reserved_quantity), f"{prefix}_RESERVED_QUANTITY_NUMBER_REQUIRED")
    if is_number(reserved_quantity):
        require(reserved_quantity >= 0, f"{prefix}_NEGATIVE_RESERVED_QUANTITY")

    require(is_number(min_stock_quantity), f"{prefix}_MIN_STOCK_NUMBER_REQUIRED")
    if is_number(min_stock_quantity):
        require(min_stock_quantity >= 0, f"{prefix}_NEGATIVE_MIN_STOCK_QUANTITY")

    if is_number(quantity) and is_number(reserved_quantity):
        require(reserved_quantity <= quantity, f"{prefix}_RESERVED_EXCEEDS_QUANTITY")

    valid_stock_rows += 1

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("PRODUCT_STOCK_IMPORT_STATUS=FAIL")
    print(f"PRODUCT_IMPORT_VALID_ROWS={valid_product_rows}")
    print(f"STOCK_IMPORT_VALID_ROWS={valid_stock_rows}")
    print(f"PRODUCT_STOCK_IMPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PRODUCT_STOCK_IMPORT_FAIL={error}")
    sys.exit(1)

print("PRODUCT_STOCK_IMPORT_STATUS=PASS")
print(f"PRODUCT_STOCK_IMPORT_TENANT_ID={tenant_id}")
print(f"PRODUCT_STOCK_IMPORT_BATCH_ID={batch_id}")
print(f"PRODUCT_IMPORT_TOTAL_ROWS={len(products)}")
print(f"STOCK_IMPORT_TOTAL_ROWS={len(stock_entries)}")
print(f"PRODUCT_IMPORT_VALID_ROWS={valid_product_rows}")
print(f"STOCK_IMPORT_VALID_ROWS={valid_stock_rows}")
print("PRODUCT_STOCK_IMPORT_MODE=DRY_RUN")
print("PRODUCT_STOCK_IMPORT_COMMIT_ALLOWED=false")
print("PRODUCT_STOCK_IMPORT_TARGET_PRODUCT_STAGING_TABLE=import_staging_products")
print("PRODUCT_STOCK_IMPORT_TARGET_STOCK_STAGING_TABLE=import_staging_stock_entries")
print("PRODUCT_STOCK_IMPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
