#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_1_4_pilot_veri_sinirlari_tanimi.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PILOT_DATA_BOUNDARY_ERROR=$1"
  exit 1
}

if [ -z "$INPUT_FILE" ]; then
  fail "INPUT_FILE_REQUIRED"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
input_path = Path(sys.argv[2])

config = json.loads(config_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

scope = config.get("pilot_scope", {})
boundaries = config.get("data_boundaries", {})
policy = config.get("closed_policy_reference")

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 192, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_1_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(policy == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

require(scope.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(scope.get("tenant_count_max") == 1, "TENANT_MAX_INVALID")
require(scope.get("live_external_activation") == "CLOSED", "LIVE_EXTERNAL_ACTIVATION_NOT_CLOSED")
require(scope.get("real_provider_api_status") == "CLOSED", "REAL_PROVIDER_API_NOT_CLOSED")
require(scope.get("real_gib_operation_status") == "CLOSED", "REAL_GIB_NOT_CLOSED")
require(scope.get("real_bank_operation_status") == "CLOSED", "REAL_BANK_NOT_CLOSED")
require(scope.get("real_pos_provider_operation_status") == "CLOSED", "REAL_POS_NOT_CLOSED")

pilot = payload.get("pilot_data", {})

checks = [
    ("tenant_count", "tenant_count_max"),
    ("admin_user_count", "max_admin_user_count"),
    ("operator_user_count", "max_operator_user_count"),
    ("accountant_user_count", "max_accountant_user_count"),
    ("customer_count", "max_customer_count"),
    ("supplier_count", "max_supplier_count"),
    ("product_count", "max_product_count"),
    ("stock_entry_count", "max_stock_entry_count"),
    ("finance_document_count", "max_finance_document_count"),
    ("e_document_export_count", "max_e_document_export_count"),
    ("import_batch_count", "max_import_batch_count"),
    ("uat_case_count", "max_uat_case_count"),
    ("training_item_count", "max_training_item_count"),
    ("support_ticket_count", "max_support_ticket_count"),
    ("open_issue_count", "max_open_issue_count"),
    ("critical_issue_count", "max_critical_issue_count")
]

for payload_key, boundary_key in checks:
    value = pilot.get(payload_key)
    limit = scope.get(boundary_key, boundaries.get(boundary_key))
    require(isinstance(value, int), f"{payload_key.upper()}_MISSING_OR_NOT_INTEGER")
    require(isinstance(limit, int), f"{boundary_key.upper()}_LIMIT_MISSING")
    if isinstance(value, int) and isinstance(limit, int):
        require(value <= limit, f"{payload_key.upper()}_EXCEEDS_LIMIT")

require(pilot.get("tenant_count") == 1, "TENANT_COUNT_MUST_BE_ONE")
require(pilot.get("critical_issue_count") == 0, "CRITICAL_ISSUE_COUNT_MUST_BE_ZERO")

external = payload.get("external_policy", {})
require(external.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")

required_domains = set(config.get("required_domains", []))
provided_domains = set(payload.get("covered_domains", []))
missing_domains = sorted(required_domains - provided_domains)
require(not missing_domains, "REQUIRED_DOMAINS_MISSING:" + ",".join(missing_domains))

if errors:
    print("PILOT_DATA_BOUNDARY_VALIDATION_STATUS=FAIL")
    for error in errors:
        print(f"BOUNDARY_FAIL={error}")
    sys.exit(1)

print("PILOT_DATA_BOUNDARY_VALIDATION_STATUS=PASS")
print("PILOT_DATA_BOUNDARY_VALIDATION_SCOPE=SINGLE_TENANT")
print("PILOT_DATA_BOUNDARY_CRITICAL_ISSUE_COUNT=0")
print("PILOT_DATA_BOUNDARY_EXTERNAL_POLICY=CLOSED")
PY_EOF
