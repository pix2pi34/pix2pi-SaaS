#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_3_6_uat_sign_off.v1.json}"
SIGNOFF_FILE="${SIGNOFF_FILE:-configs/faz4r/uat_sign_off.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "UAT_SIGN_OFF_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$SIGNOFF_FILE" ]; then
  fail "SIGNOFF_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$SIGNOFF_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$SIGNOFF_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
signoff_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
signoff_artifact = json.loads(signoff_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 209, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_3_6", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("signoff_policy", {})
required_areas = set(config.get("required_uat_areas", []))

require(payload.get("signoff_status") == policy.get("signoff_status_required"), "SIGNOFF_STATUS_NOT_READY")
require(payload.get("signoff_mode") == policy.get("signoff_mode_required"), "SIGNOFF_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

uat_areas = payload.get("uat_areas", [])
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})
owner_signoffs = payload.get("owner_signoffs", {})

require(isinstance(uat_areas, list), "UAT_AREAS_NOT_LIST")

provided_areas = []
pass_area_count = 0
fail_area_count = 0
required_fail_total = 0
critical_issue_total = 0

if isinstance(uat_areas, list):
    for idx, area in enumerate(uat_areas, start=1):
        prefix = f"UAT_AREA_{idx}"
        require(isinstance(area, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(area, dict):
            continue

        code = area.get("code")
        status = area.get("status")
        required = area.get("required")
        evidence_ref = area.get("evidence_ref")
        area_required_fail = area.get("required_fail_count")
        area_critical_issue = area.get("critical_issue_count")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_areas.append(code)

        require(status in {"PASS", "FAIL"}, f"{prefix}_STATUS_INVALID")
        require(isinstance(area_required_fail, int) and area_required_fail >= 0, f"{prefix}_REQUIRED_FAIL_COUNT_INVALID")
        require(isinstance(area_critical_issue, int) and area_critical_issue >= 0, f"{prefix}_CRITICAL_ISSUE_COUNT_INVALID")

        if isinstance(area_required_fail, int):
            required_fail_total += area_required_fail
        if isinstance(area_critical_issue, int):
            critical_issue_total += area_critical_issue

        if status == "PASS":
            pass_area_count += 1
        elif status == "FAIL":
            fail_area_count += 1

        if required is True:
            require(status == "PASS", f"REQUIRED_UAT_AREA_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            require(area_required_fail == 0, f"REQUIRED_UAT_AREA_HAS_FAIL:{code}")
            require(area_critical_issue == 0, f"REQUIRED_UAT_AREA_HAS_CRITICAL_ISSUE:{code}")

provided_set = set(provided_areas)
missing_areas = sorted(required_areas - provided_set)
require(not missing_areas, "REQUIRED_UAT_AREAS_MISSING:" + ",".join(missing_areas))
require(len(provided_areas) == len(provided_set), "DUPLICATE_UAT_AREA_CODE_FOUND")

total_uat_area_count = summary.get("total_uat_area_count")
summary_pass_area_count = summary.get("pass_uat_area_count")
summary_fail_area_count = summary.get("fail_uat_area_count")
summary_required_fail_count = summary.get("required_fail_count")
summary_critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_uat_area_count, int) and total_uat_area_count >= 0, "TOTAL_UAT_AREA_COUNT_INVALID")
require(isinstance(summary_pass_area_count, int) and summary_pass_area_count >= 0, "PASS_UAT_AREA_COUNT_INVALID")
require(isinstance(summary_fail_area_count, int) and summary_fail_area_count >= 0, "FAIL_UAT_AREA_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(summary_critical_issue_count, int) and summary_critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_uat_area_count, int):
    require(total_uat_area_count == len(uat_areas), "TOTAL_UAT_AREA_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_area_count, int):
    require(summary_pass_area_count == pass_area_count, "PASS_UAT_AREA_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_area_count, int):
    require(summary_fail_area_count == fail_area_count, "FAIL_UAT_AREA_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_total, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(summary_critical_issue_count, int):
    require(summary_critical_issue_count == critical_issue_total, "CRITICAL_ISSUE_COUNT_RECONCILIATION_FAILED")
    require(summary_critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("all_uat_status") == policy.get("all_uat_status_required"), "ALL_UAT_STATUS_NOT_PASS")
require(summary.get("support_handoff_ready") == policy.get("support_handoff_ready_required"), "SUPPORT_HANDOFF_NOT_READY")
require(summary.get("next_phase_ready") == policy.get("next_phase_ready_required"), "NEXT_PHASE_READY_INVALID")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(owner_signoffs.get("business_owner_signoff") == policy.get("business_owner_signoff_required"), "BUSINESS_OWNER_SIGNOFF_NOT_READY")
require(owner_signoffs.get("technical_owner_signoff") == policy.get("technical_owner_signoff_required"), "TECHNICAL_OWNER_SIGNOFF_NOT_READY")
require(owner_signoffs.get("product_owner_signoff") == policy.get("product_owner_signoff_required"), "PRODUCT_OWNER_SIGNOFF_NOT_READY")
require(owner_signoffs.get("signoff_mode") == "PREVIEW_ONLY", "OWNER_SIGNOFF_MODE_NOT_PREVIEW_ONLY")
require(owner_signoffs.get("real_contractual_approval") == "NOT_REQUIRED_FOR_THIS_PHASE", "REAL_CONTRACTUAL_APPROVAL_POLICY_INVALID")

if fail_area_count == 0 and required_fail_total == 0 and critical_issue_total == 0 and open_blocker_count == 0:
    require(summary.get("signoff_result") == "PASS", "SIGNOFF_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("signoff_result") == "FAIL", "SIGNOFF_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_export") == "CLOSED", "REAL_EXPORT_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")

if errors:
    print("UAT_SIGN_OFF_STATUS=FAIL")
    print(f"UAT_SIGN_OFF_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"UAT_SIGN_OFF_FAIL={error}")
    sys.exit(1)

print("UAT_SIGN_OFF_STATUS=PASS")
print(f"UAT_SIGN_OFF_TENANT_ID={tenant.get('tenant_id')}")
print(f"UAT_SIGN_OFF_TOTAL_UAT_AREA_COUNT={total_uat_area_count}")
print(f"UAT_SIGN_OFF_PASS_UAT_AREA_COUNT={pass_area_count}")
print(f"UAT_SIGN_OFF_FAIL_UAT_AREA_COUNT={fail_area_count}")
print(f"UAT_SIGN_OFF_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"UAT_SIGN_OFF_CRITICAL_ISSUE_COUNT={summary_critical_issue_count}")
print(f"UAT_SIGN_OFF_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"UAT_SIGN_OFF_RESULT={summary.get('signoff_result')}")
print("UAT_SIGN_OFF_MODE=CONTROLLED_PILOT")
print("BUSINESS_OWNER_SIGNOFF=READY")
print("TECHNICAL_OWNER_SIGNOFF=READY")
print("PRODUCT_OWNER_SIGNOFF=READY")
print("SUPPORT_HANDOFF_READY=YES")
print("NEXT_PHASE_READY=FAZ_4_16_4_1_READY")
print("UAT_SIGN_OFF_EXTERNAL_POLICY=CLOSED")
PY_EOF
