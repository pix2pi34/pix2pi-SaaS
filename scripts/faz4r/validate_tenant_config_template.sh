#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_1_2_tenant_config_sablonlari.v1.json}"
TEMPLATE_FILE="${TEMPLATE_FILE:-configs/faz4r/tenant_config_template.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "TENANT_CONFIG_TEMPLATE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  fail "TEMPLATE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$TEMPLATE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$TEMPLATE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
template_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
template = json.loads(template_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 196, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_1_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("template_policy", {})
required_sections = set(config.get("required_config_sections", []))

for section in required_sections:
    require(section in payload and isinstance(payload.get(section), dict), f"REQUIRED_CONFIG_SECTION_MISSING:{section}")

tenant_identity = payload.get("tenant_identity", {})
locale = payload.get("locale", {})
isolation = payload.get("isolation", {})
module_flags = payload.get("module_flags", {})
pilot_limits = payload.get("pilot_limits", {})
audit_policy = payload.get("audit_policy", {})
external_policy = payload.get("external_policy", {})

require(payload.get("template_status") == policy.get("template_status_required"), "TEMPLATE_STATUS_NOT_READY")
require(tenant_identity.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant_identity.get("pilot_mode") == policy.get("pilot_mode_required"), "PILOT_MODE_INVALID")
require(tenant_identity.get("tenant_opening_type") == "PILOT", "TENANT_OPENING_TYPE_INVALID")

require(locale.get("timezone") == policy.get("timezone_required"), "TIMEZONE_INVALID")
require(locale.get("language") == policy.get("language_required"), "LANGUAGE_INVALID")
require(locale.get("default_currency") == policy.get("default_currency_required"), "DEFAULT_CURRENCY_INVALID")

require(isolation.get("tenant_id_required") is True, "TENANT_ID_REQUIRED_FLAG_FALSE")
require(isolation.get("schema_guard_required") is True, "SCHEMA_GUARD_REQUIRED_FALSE")
require(isolation.get("cross_tenant_access_allowed") is False, "CROSS_TENANT_ACCESS_NOT_FORBIDDEN")

required_enabled_flags = [
    "erp_core_enabled",
    "import_enabled",
    "reporting_enabled",
    "operational_readmodel_enabled",
    "uat_enabled",
    "support_enabled"
]
for flag in required_enabled_flags:
    require(module_flags.get(flag) is True, f"MODULE_FLAG_NOT_ENABLED:{flag}")

required_closed_flags = [
    "payment_live_enabled",
    "e_document_live_enabled",
    "bank_live_enabled",
    "pos_provider_live_enabled"
]
for flag in required_closed_flags:
    require(module_flags.get(flag) is False, f"LIVE_MODULE_FLAG_NOT_CLOSED:{flag}")

require(pilot_limits.get("max_critical_issue_count") == policy.get("critical_issue_limit_required"), "CRITICAL_ISSUE_LIMIT_NOT_ZERO")
require(pilot_limits.get("max_customer_count") == 500, "MAX_CUSTOMER_COUNT_INVALID")
require(pilot_limits.get("max_product_count") == 5000, "MAX_PRODUCT_COUNT_INVALID")
require(pilot_limits.get("max_import_batch_count") == 25, "MAX_IMPORT_BATCH_COUNT_INVALID")
require(pilot_limits.get("max_uat_case_count") == 100, "MAX_UAT_CASE_COUNT_INVALID")

require(audit_policy.get("audit_evidence_required") is True, "AUDIT_EVIDENCE_REQUIRED_FALSE")
require(audit_policy.get("counter_based_final_status_required") is True, "COUNTER_BASED_STATUS_REQUIRED_FALSE")
require(audit_policy.get("hardcoded_ok_forbidden") is True, "HARDCODED_OK_FORBIDDEN_MISSING")

require(external_policy.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")
require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("TENANT_CONFIG_TEMPLATE_STATUS=FAIL")
    for error in errors:
        print(f"TENANT_CONFIG_TEMPLATE_FAIL={error}")
    sys.exit(1)

print("TENANT_CONFIG_TEMPLATE_STATUS=PASS")
print("TENANT_CONFIG_TEMPLATE_SCOPE=SINGLE_TENANT")
print("TENANT_CONFIG_TEMPLATE_PILOT_MODE=CONTROLLED_PILOT")
print("TENANT_CONFIG_TEMPLATE_EXTERNAL_POLICY=CLOSED")
print("TENANT_CONFIG_TEMPLATE_AUDIT_POLICY=READY")
PY_EOF
