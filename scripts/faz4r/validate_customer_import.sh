#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_1_cari_import.v1.json}"
MAPPING_FILE="${MAPPING_FILE:-configs/faz4r/customer_import_mapping.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "CUSTOMER_IMPORT_ERROR=$1"
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
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
mapping_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
mapping = json.loads(mapping_path.read_text())
payload = json.loads(input_path.read_text())

errors = []
warnings = []

def require(condition, code):
    if not condition:
        errors.append(code)

def warn(condition, code):
    if not condition:
        warnings.append(code)

def get_nested(obj, path):
    current = obj
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

email_re = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
phone_re = re.compile(r"^\+?[0-9\s\-\(\)]{7,20}$")
tax_re = re.compile(r"^[0-9]{10}$")
national_id_re = re.compile(r"^[0-9]{11}$")

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 198, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("import_policy", {})

require(mapping.get("mapping_status") == "READY", "MAPPING_STATUS_NOT_READY")
require(mapping.get("target_staging_table") == "import_staging_customers", "TARGET_STAGING_TABLE_INVALID")
require(mapping.get("import_mode") == policy.get("import_mode_required"), "MAPPING_IMPORT_MODE_INVALID")
require(mapping.get("commit_allowed") is False, "MAPPING_COMMIT_ALLOWED_TRUE")
require(mapping.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "MAPPING_CLOSED_POLICY_REFERENCE_MISSING")

import_batch = payload.get("import_batch", {})
tenant_id = import_batch.get("tenant_id")
batch_id = import_batch.get("batch_id")
rows = payload.get("rows", [])
external_policy = payload.get("external_policy", {})

require(non_empty(tenant_id), "TENANT_ID_REQUIRED")
require(non_empty(batch_id), "BATCH_ID_REQUIRED")
require(import_batch.get("import_type") == "CUSTOMER", "IMPORT_TYPE_INVALID")
require(import_batch.get("import_mode") == policy.get("import_mode_required"), "IMPORT_MODE_NOT_DRY_RUN")
require(import_batch.get("commit_requested") is False, "COMMIT_REQUESTED_NOT_ALLOWED")
require(import_batch.get("source_format") in {"CSV", "XLSX", "JSON"}, "SOURCE_FORMAT_INVALID")

require(isinstance(rows, list), "ROWS_NOT_LIST")
if isinstance(rows, list):
    require(len(rows) > 0, "ROWS_EMPTY")
    require(len(rows) <= policy.get("max_rows_per_batch", 500), "ROWS_EXCEED_BATCH_LIMIT")
    require(import_batch.get("total_rows") == len(rows), "TOTAL_ROWS_MISMATCH")

customer_codes = set()
tax_nos = set()
valid_rows = 0

for idx, row in enumerate(rows, start=1):
    prefix = f"ROW_{idx}"

    require(row.get("tenant_id") == tenant_id, f"{prefix}_TENANT_ID_MISMATCH")

    customer_code = row.get("customer_code")
    customer_name = row.get("customer_name")
    customer_type = row.get("customer_type")
    customer_kind = row.get("customer_kind")
    tax_no = row.get("tax_no")
    national_id = row.get("national_id")
    tax_office = row.get("tax_office")
    email = row.get("email")
    phone = row.get("phone")
    address_full = get_nested(row, "address.full_address")
    address_city = get_nested(row, "address.city")

    require(non_empty(customer_code), f"{prefix}_CUSTOMER_CODE_REQUIRED")
    require(non_empty(customer_name), f"{prefix}_CUSTOMER_NAME_REQUIRED")
    require(customer_type in {"COMPANY", "INDIVIDUAL"}, f"{prefix}_CUSTOMER_TYPE_INVALID")
    require(customer_kind in {"CUSTOMER", "SUPPLIER", "BOTH"}, f"{prefix}_CUSTOMER_KIND_INVALID")
    require(non_empty(address_full), f"{prefix}_ADDRESS_FULL_REQUIRED")
    require(non_empty(address_city), f"{prefix}_ADDRESS_CITY_REQUIRED")

    if non_empty(customer_code):
        require(customer_code not in customer_codes, f"{prefix}_DUPLICATE_CUSTOMER_CODE")
        customer_codes.add(customer_code)

    if customer_type == "COMPANY":
        require(non_empty(tax_no), f"{prefix}_COMPANY_TAX_NO_REQUIRED")
        require(non_empty(tax_office), f"{prefix}_COMPANY_TAX_OFFICE_REQUIRED")
        if non_empty(tax_no):
            require(bool(tax_re.match(tax_no)), f"{prefix}_TAX_NO_FORMAT_INVALID")
            require(tax_no not in tax_nos, f"{prefix}_DUPLICATE_TAX_NO")
            tax_nos.add(tax_no)

    if customer_type == "INDIVIDUAL":
        require(non_empty(tax_no) or non_empty(national_id), f"{prefix}_INDIVIDUAL_TAX_OR_NATIONAL_ID_REQUIRED")
        if non_empty(national_id):
            require(bool(national_id_re.match(national_id)), f"{prefix}_NATIONAL_ID_FORMAT_INVALID")
        if non_empty(tax_no):
            require(bool(tax_re.match(tax_no)), f"{prefix}_TAX_NO_FORMAT_INVALID")
            require(tax_no not in tax_nos, f"{prefix}_DUPLICATE_TAX_NO")
            tax_nos.add(tax_no)

    if non_empty(email):
        require(bool(email_re.match(email)), f"{prefix}_EMAIL_FORMAT_INVALID")

    if non_empty(phone):
        require(bool(phone_re.match(phone)), f"{prefix}_PHONE_FORMAT_INVALID")

    valid_rows += 1

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("CUSTOMER_IMPORT_STATUS=FAIL")
    print(f"CUSTOMER_IMPORT_VALID_ROWS={valid_rows}")
    print(f"CUSTOMER_IMPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"CUSTOMER_IMPORT_FAIL={error}")
    for warning in warnings:
        print(f"CUSTOMER_IMPORT_WARN={warning}")
    sys.exit(1)

print("CUSTOMER_IMPORT_STATUS=PASS")
print(f"CUSTOMER_IMPORT_TENANT_ID={tenant_id}")
print(f"CUSTOMER_IMPORT_BATCH_ID={batch_id}")
print(f"CUSTOMER_IMPORT_TOTAL_ROWS={len(rows)}")
print(f"CUSTOMER_IMPORT_VALID_ROWS={valid_rows}")
print("CUSTOMER_IMPORT_MODE=DRY_RUN")
print("CUSTOMER_IMPORT_COMMIT_ALLOWED=false")
print("CUSTOMER_IMPORT_TARGET_STAGING_TABLE=import_staging_customers")
print("CUSTOMER_IMPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
