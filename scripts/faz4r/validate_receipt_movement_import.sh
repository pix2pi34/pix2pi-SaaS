#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_3_fis_hareket_import.v1.json}"
MAPPING_FILE="${MAPPING_FILE:-configs/faz4r/receipt_movement_import_mapping.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "RECEIPT_MOVEMENT_IMPORT_ERROR=$1"
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
from decimal import Decimal, InvalidOperation
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

def to_decimal(value):
    try:
        if isinstance(value, bool) or value is None:
            return None
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None

def is_number(value):
    return to_decimal(value) is not None

def d(value):
    result = to_decimal(value)
    return result if result is not None else Decimal("0")

def money_equal(a, b):
    return d(a).quantize(Decimal("0.01")) == d(b).quantize(Decimal("0.01"))

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 200, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("import_policy", {})

require(mapping.get("mapping_status") == "READY", "MAPPING_STATUS_NOT_READY")
require(mapping.get("import_mode") == policy.get("import_mode_required"), "MAPPING_IMPORT_MODE_INVALID")
require(mapping.get("commit_allowed") is False, "MAPPING_COMMIT_ALLOWED_TRUE")
require("import_staging_finance_documents" in mapping.get("target_staging_tables", []), "FINANCE_DOCUMENT_STAGING_TABLE_MISSING")
require("import_staging_stock_entries" in mapping.get("target_staging_tables", []), "STOCK_STAGING_TABLE_MISSING")
require(mapping.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "MAPPING_CLOSED_POLICY_REFERENCE_MISSING")

import_batch = payload.get("import_batch", {})
tenant_id = import_batch.get("tenant_id")
batch_id = import_batch.get("batch_id")
customers = set(payload.get("known_customers", []))
products = set(payload.get("known_products", []))
receipts = payload.get("receipts", [])
movements = payload.get("movements", [])
external_policy = payload.get("external_policy", {})

require(non_empty(tenant_id), "TENANT_ID_REQUIRED")
require(non_empty(batch_id), "BATCH_ID_REQUIRED")
require(import_batch.get("import_type") == "RECEIPT_MOVEMENT", "IMPORT_TYPE_INVALID")
require(import_batch.get("import_mode") == policy.get("import_mode_required"), "IMPORT_MODE_NOT_DRY_RUN")
require(import_batch.get("commit_requested") is False, "COMMIT_REQUESTED_NOT_ALLOWED")
require(import_batch.get("source_format") in {"CSV", "XLSX", "JSON"}, "SOURCE_FORMAT_INVALID")

require(isinstance(receipts, list), "RECEIPT_ROWS_NOT_LIST")
require(isinstance(movements, list), "MOVEMENT_ROWS_NOT_LIST")

if isinstance(receipts, list):
    require(len(receipts) > 0, "RECEIPT_ROWS_EMPTY")
    require(len(receipts) <= policy.get("max_receipt_rows_per_batch", 5000), "RECEIPT_ROWS_EXCEED_BATCH_LIMIT")
    require(import_batch.get("total_receipt_rows") == len(receipts), "TOTAL_RECEIPT_ROWS_MISMATCH")

if isinstance(movements, list):
    require(len(movements) <= policy.get("max_movement_rows_per_batch", 20000), "MOVEMENT_ROWS_EXCEED_BATCH_LIMIT")
    require(import_batch.get("total_movement_rows") == len(movements), "TOTAL_MOVEMENT_ROWS_MISMATCH")

allowed_receipt_types = {"SALE", "PURCHASE", "SALE_RETURN", "PURCHASE_RETURN", "PAYMENT", "COLLECTION", "STOCK_MOVEMENT"}
allowed_movement_types = {"SALE", "PURCHASE", "SALE_RETURN", "PURCHASE_RETURN", "PAYMENT", "COLLECTION", "STOCK_IN", "STOCK_OUT", "STOCK_TRANSFER"}

receipt_nos = set()
valid_receipt_rows = 0

for r_idx, receipt in enumerate(receipts, start=1):
    prefix = f"RECEIPT_ROW_{r_idx}"

    require(receipt.get("tenant_id") == tenant_id, f"{prefix}_TENANT_ID_MISMATCH")

    receipt_no = receipt.get("receipt_no")
    receipt_type = receipt.get("receipt_type")
    receipt_date = receipt.get("receipt_date")
    customer_code = receipt.get("customer_code")
    currency_code = receipt.get("currency_code")
    net_total = receipt.get("net_total")
    tax_total = receipt.get("tax_total")
    gross_total = receipt.get("gross_total")
    lines = receipt.get("lines", [])

    require(non_empty(receipt_no), f"{prefix}_RECEIPT_NO_REQUIRED")
    require(receipt_type in allowed_receipt_types, f"{prefix}_RECEIPT_TYPE_INVALID")
    require(non_empty(receipt_date), f"{prefix}_RECEIPT_DATE_REQUIRED")
    require(non_empty(customer_code), f"{prefix}_CUSTOMER_CODE_REQUIRED")
    require(customer_code in customers, f"{prefix}_UNKNOWN_CUSTOMER_CODE")
    require(non_empty(currency_code), f"{prefix}_CURRENCY_CODE_REQUIRED")

    for field_name, value in [("NET_TOTAL", net_total), ("TAX_TOTAL", tax_total), ("GROSS_TOTAL", gross_total)]:
        require(is_number(value), f"{prefix}_{field_name}_NUMBER_REQUIRED")
        if is_number(value):
            require(d(value) >= 0, f"{prefix}_{field_name}_NEGATIVE")

    if non_empty(receipt_no):
        require(receipt_no not in receipt_nos, f"{prefix}_DUPLICATE_RECEIPT_NO")
        receipt_nos.add(receipt_no)

    require(isinstance(lines, list), f"{prefix}_LINES_NOT_LIST")
    require(isinstance(lines, list) and len(lines) > 0, f"{prefix}_LINES_EMPTY")

    line_net_sum = Decimal("0")
    line_tax_sum = Decimal("0")
    line_gross_sum = Decimal("0")
    seen_line_nos = set()

    if isinstance(lines, list):
        for l_idx, line in enumerate(lines, start=1):
            lp = f"{prefix}_LINE_{l_idx}"

            line_no = line.get("line_no")
            product_code = line.get("product_code")
            quantity = line.get("quantity")
            unit_price = line.get("unit_price")
            tax_rate = line.get("tax_rate")
            net_amount = line.get("net_amount")
            tax_amount = line.get("tax_amount")
            gross_amount = line.get("gross_amount")

            require(isinstance(line_no, int), f"{lp}_LINE_NO_INTEGER_REQUIRED")
            if isinstance(line_no, int):
                require(line_no not in seen_line_nos, f"{lp}_DUPLICATE_LINE_NO")
                seen_line_nos.add(line_no)

            require(non_empty(product_code), f"{lp}_PRODUCT_CODE_REQUIRED")
            require(product_code in products, f"{lp}_UNKNOWN_PRODUCT_CODE")

            for field_name, value in [
                ("QUANTITY", quantity),
                ("UNIT_PRICE", unit_price),
                ("TAX_RATE", tax_rate),
                ("NET_AMOUNT", net_amount),
                ("TAX_AMOUNT", tax_amount),
                ("GROSS_AMOUNT", gross_amount)
            ]:
                require(is_number(value), f"{lp}_{field_name}_NUMBER_REQUIRED")

            if is_number(quantity):
                require(d(quantity) > 0, f"{lp}_QUANTITY_NOT_POSITIVE")
            if is_number(unit_price):
                require(d(unit_price) >= 0, f"{lp}_UNIT_PRICE_NEGATIVE")
            if is_number(tax_rate):
                require(Decimal("0") <= d(tax_rate) <= Decimal("100"), f"{lp}_TAX_RATE_INVALID")
            if is_number(net_amount):
                require(d(net_amount) >= 0, f"{lp}_NET_AMOUNT_NEGATIVE")
                line_net_sum += d(net_amount)
            if is_number(tax_amount):
                require(d(tax_amount) >= 0, f"{lp}_TAX_AMOUNT_NEGATIVE")
                line_tax_sum += d(tax_amount)
            if is_number(gross_amount):
                require(d(gross_amount) >= 0, f"{lp}_GROSS_AMOUNT_NEGATIVE")
                line_gross_sum += d(gross_amount)

            if is_number(net_amount) and is_number(tax_amount) and is_number(gross_amount):
                require(money_equal(d(net_amount) + d(tax_amount), d(gross_amount)), f"{lp}_LINE_TOTAL_RECONCILIATION_FAILED")

    if is_number(net_total):
        require(money_equal(line_net_sum, net_total), f"{prefix}_HEADER_NET_TOTAL_RECONCILIATION_FAILED")
    if is_number(tax_total):
        require(money_equal(line_tax_sum, tax_total), f"{prefix}_HEADER_TAX_TOTAL_RECONCILIATION_FAILED")
    if is_number(gross_total):
        require(money_equal(line_gross_sum, gross_total), f"{prefix}_HEADER_GROSS_TOTAL_RECONCILIATION_FAILED")

    valid_receipt_rows += 1

movement_ids = set()
valid_movement_rows = 0

for idx, movement in enumerate(movements, start=1):
    prefix = f"MOVEMENT_ROW_{idx}"

    require(movement.get("tenant_id") == tenant_id, f"{prefix}_TENANT_ID_MISMATCH")

    movement_id = movement.get("movement_id")
    movement_type = movement.get("movement_type")
    receipt_no = movement.get("receipt_no")
    product_code = movement.get("product_code")
    customer_code = movement.get("customer_code")
    amount = movement.get("amount")
    quantity = movement.get("quantity")

    require(non_empty(movement_id), f"{prefix}_MOVEMENT_ID_REQUIRED")
    require(movement_type in allowed_movement_types, f"{prefix}_MOVEMENT_TYPE_INVALID")
    require(non_empty(receipt_no), f"{prefix}_RECEIPT_NO_REQUIRED")
    require(receipt_no in receipt_nos, f"{prefix}_UNKNOWN_RECEIPT_NO")

    if non_empty(movement_id):
        require(movement_id not in movement_ids, f"{prefix}_DUPLICATE_MOVEMENT_ID")
        movement_ids.add(movement_id)

    if movement_type in {"PAYMENT", "COLLECTION"}:
        require(non_empty(customer_code), f"{prefix}_CUSTOMER_CODE_REQUIRED_FOR_PAYMENT")
        require(customer_code in customers, f"{prefix}_UNKNOWN_CUSTOMER_CODE")
        require(is_number(amount), f"{prefix}_AMOUNT_NUMBER_REQUIRED")
        if is_number(amount):
            require(d(amount) >= 0, f"{prefix}_NEGATIVE_AMOUNT")

    if movement_type in {"SALE", "PURCHASE", "SALE_RETURN", "PURCHASE_RETURN", "STOCK_IN", "STOCK_OUT", "STOCK_TRANSFER"}:
        require(non_empty(product_code), f"{prefix}_PRODUCT_CODE_REQUIRED_FOR_STOCK")
        require(product_code in products, f"{prefix}_UNKNOWN_PRODUCT_CODE")
        require(is_number(quantity), f"{prefix}_QUANTITY_NUMBER_REQUIRED")
        if is_number(quantity):
            require(d(quantity) != 0, f"{prefix}_ZERO_STOCK_MOVEMENT_QUANTITY")

    valid_movement_rows += 1

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("RECEIPT_MOVEMENT_IMPORT_STATUS=FAIL")
    print(f"RECEIPT_IMPORT_VALID_ROWS={valid_receipt_rows}")
    print(f"MOVEMENT_IMPORT_VALID_ROWS={valid_movement_rows}")
    print(f"RECEIPT_MOVEMENT_IMPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"RECEIPT_MOVEMENT_IMPORT_FAIL={error}")
    sys.exit(1)

print("RECEIPT_MOVEMENT_IMPORT_STATUS=PASS")
print(f"RECEIPT_MOVEMENT_IMPORT_TENANT_ID={tenant_id}")
print(f"RECEIPT_MOVEMENT_IMPORT_BATCH_ID={batch_id}")
print(f"RECEIPT_IMPORT_TOTAL_ROWS={len(receipts)}")
print(f"MOVEMENT_IMPORT_TOTAL_ROWS={len(movements)}")
print(f"RECEIPT_IMPORT_VALID_ROWS={valid_receipt_rows}")
print(f"MOVEMENT_IMPORT_VALID_ROWS={valid_movement_rows}")
print("RECEIPT_MOVEMENT_IMPORT_MODE=DRY_RUN")
print("RECEIPT_MOVEMENT_IMPORT_COMMIT_ALLOWED=false")
print("RECEIPT_MOVEMENT_IMPORT_TARGET_FINANCE_STAGING_TABLE=import_staging_finance_documents")
print("RECEIPT_MOVEMENT_IMPORT_TARGET_STOCK_STAGING_TABLE=import_staging_stock_entries")
print("RECEIPT_MOVEMENT_IMPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
