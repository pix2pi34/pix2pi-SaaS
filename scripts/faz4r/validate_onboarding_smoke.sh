#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_1_6_onboarding_smoke.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "ONBOARDING_SMOKE_ERROR=$1"
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

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 194, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_1_6", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("onboarding_policy", {})
required_checks = set(config.get("required_smoke_checks", []))

tenant = payload.get("tenant", {})
summary = payload.get("summary", {})
smoke_checks = payload.get("smoke_checks", [])

require(isinstance(tenant.get("tenant_id"), str) and tenant.get("tenant_id").strip(), "TENANT_ID_REQUIRED")
require(isinstance(tenant.get("tenant_name"), str) and tenant.get("tenant_name").strip(), "TENANT_NAME_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_MUST_BE_SINGLE_TENANT")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

require(summary.get("onboarding_status") == policy.get("onboarding_status_required"), "ONBOARDING_STATUS_NOT_READY")
require(summary.get("tenant_acceptance_status") == policy.get("tenant_acceptance_status_required"), "TENANT_ACCEPTANCE_STATUS_NOT_PASS")
require(summary.get("pilot_data_boundary_status") == policy.get("pilot_data_boundary_status_required"), "PILOT_DATA_BOUNDARY_STATUS_NOT_PASS")
require(summary.get("critical_issue_count") == 0, "CRITICAL_ISSUE_COUNT_MUST_BE_ZERO")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

provided_codes = set()
for item in smoke_checks:
    code = item.get("code")
    status = item.get("status")
    required = item.get("required")
    evidence_ref = item.get("evidence_ref")

    if code:
        provided_codes.add(code)

    if required is True:
        require(status == "PASS", f"REQUIRED_SMOKE_CHECK_NOT_PASS:{code}")
        require(isinstance(evidence_ref, str) and len(evidence_ref.strip()) > 0, f"REQUIRED_EVIDENCE_MISSING:{code}")

missing_checks = sorted(required_checks - provided_codes)
require(not missing_checks, "REQUIRED_SMOKE_CHECKS_MISSING:" + ",".join(missing_checks))

for required_code in required_checks:
    matching = [item for item in smoke_checks if item.get("code") == required_code]
    require(len(matching) == 1, f"REQUIRED_SMOKE_CHECK_DUPLICATE_OR_MISSING:{required_code}")
    if matching:
        item = matching[0]
        require(item.get("required") is True, f"REQUIRED_FLAG_FALSE:{required_code}")
        require(item.get("status") == "PASS", f"REQUIRED_SMOKE_CHECK_NOT_PASS:{required_code}")
        require(isinstance(item.get("evidence_ref"), str) and item.get("evidence_ref").strip(), f"REQUIRED_EVIDENCE_MISSING:{required_code}")

external = payload.get("external_policy", {})
require(external.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")

if errors:
    print("ONBOARDING_SMOKE_STATUS=FAIL")
    for error in errors:
        print(f"ONBOARDING_SMOKE_FAIL={error}")
    sys.exit(1)

print("ONBOARDING_SMOKE_STATUS=PASS")
print(f"ONBOARDING_SMOKE_TENANT_ID={tenant.get('tenant_id')}")
print("ONBOARDING_SMOKE_REQUIRED_CHECKS_STATUS=PASS")
print("ONBOARDING_SMOKE_EVIDENCE_STATUS=PASS")
print("ONBOARDING_SMOKE_EXTERNAL_POLICY=CLOSED")
PY_EOF
