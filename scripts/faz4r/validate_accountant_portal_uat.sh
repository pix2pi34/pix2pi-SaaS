#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_3_4_muhasebeci_portali_uat.v1.json}"
UAT_FILE="${UAT_FILE:-configs/faz4r/accountant_portal_uat.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "ACCOUNTANT_PORTAL_UAT_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$UAT_FILE" ]; then
  fail "UAT_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$UAT_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$UAT_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
uat_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
uat_artifact = json.loads(uat_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 207, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_3_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("uat_policy", {})
required_cases = set(config.get("required_uat_cases", []))

require(payload.get("uat_status") == policy.get("uat_status_required"), "UAT_STATUS_NOT_READY")
require(payload.get("uat_mode") == policy.get("uat_mode_required"), "UAT_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("portal_mode") == policy.get("portal_mode_required"), "PORTAL_MODE_NOT_READ_ONLY_PREVIEW")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

accountant_context = payload.get("accountant_context", {})
require(non_empty(accountant_context.get("accountant_user_id")), "ACCOUNTANT_USER_ID_REQUIRED")
require(accountant_context.get("accountant_role") == "ACCOUNTANT", "ACCOUNTANT_ROLE_INVALID")
require(accountant_context.get("tenant_scope") == "ASSIGNED_TENANTS_ONLY", "ACCOUNTANT_TENANT_SCOPE_INVALID")
require(accountant_context.get("cross_tenant_access") == "DENIED", "CROSS_TENANT_ACCESS_NOT_DENIED")

assigned_tenant_ids = accountant_context.get("assigned_tenant_ids", [])
require(isinstance(assigned_tenant_ids, list), "ASSIGNED_TENANT_IDS_NOT_LIST")
require(isinstance(assigned_tenant_ids, list) and len(assigned_tenant_ids) > 0, "ASSIGNED_TENANT_IDS_EMPTY")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

uat_cases = payload.get("uat_cases", [])
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})
portal_permissions = payload.get("portal_permissions", {})

require(isinstance(uat_cases, list), "UAT_CASES_NOT_LIST")

provided_cases = []
pass_count = 0
fail_count = 0
required_fail_count = 0
optional_warn_count = 0

if isinstance(uat_cases, list):
    for idx, case in enumerate(uat_cases, start=1):
        prefix = f"UAT_CASE_{idx}"
        require(isinstance(case, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(case, dict):
            continue

        code = case.get("code")
        status = case.get("status")
        required = case.get("required")
        evidence_ref = case.get("evidence_ref")
        area = case.get("area")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_cases.append(code)

        require(status in {"PASS", "FAIL", "WARN"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")

        if status == "PASS":
            pass_count += 1
        elif status == "FAIL":
            fail_count += 1
            if required is True:
                required_fail_count += 1
        elif status == "WARN":
            optional_warn_count += 1

        if required is True:
            require(status == "PASS", f"REQUIRED_UAT_CASE_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")

provided_set = set(provided_cases)
missing_cases = sorted(required_cases - provided_set)
require(not missing_cases, "REQUIRED_UAT_CASES_MISSING:" + ",".join(missing_cases))
require(len(provided_cases) == len(provided_set), "DUPLICATE_UAT_CASE_CODE_FOUND")

total_case_count = summary.get("total_case_count")
summary_pass_count = summary.get("pass_count")
summary_fail_count = summary.get("fail_count")
summary_required_fail_count = summary.get("required_fail_count")
summary_optional_warn_count = summary.get("optional_warn_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_case_count, int) and total_case_count >= 0, "TOTAL_CASE_COUNT_INVALID")
require(isinstance(summary_pass_count, int) and summary_pass_count >= 0, "PASS_COUNT_INVALID")
require(isinstance(summary_fail_count, int) and summary_fail_count >= 0, "FAIL_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(summary_optional_warn_count, int) and summary_optional_warn_count >= 0, "OPTIONAL_WARN_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

if isinstance(total_case_count, int):
    require(total_case_count == len(uat_cases), "TOTAL_CASE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_count, int):
    require(summary_pass_count == pass_count, "PASS_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_count, int):
    require(summary_fail_count == fail_count, "FAIL_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(summary_optional_warn_count, int):
    require(summary_optional_warn_count == optional_warn_count, "OPTIONAL_WARN_COUNT_RECONCILIATION_FAILED")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")

require(summary.get("accountant_context_status") == policy.get("accountant_context_status_required"), "ACCOUNTANT_CONTEXT_STATUS_NOT_PASS")
require(summary.get("assigned_tenant_scope_status") == policy.get("assigned_tenant_scope_status_required"), "ASSIGNED_TENANT_SCOPE_STATUS_NOT_PASS")
require(summary.get("cross_tenant_guard_status") == policy.get("cross_tenant_guard_status_required"), "CROSS_TENANT_GUARD_STATUS_NOT_PASS")
require(summary.get("read_only_guard_status") == policy.get("read_only_guard_status_required"), "READ_ONLY_GUARD_STATUS_NOT_PASS")
require(summary.get("export_preview_status") == policy.get("export_preview_status_required"), "EXPORT_PREVIEW_STATUS_NOT_PASS")
require(summary.get("real_export_status") == policy.get("real_export_status_required"), "REAL_EXPORT_STATUS_NOT_CLOSED")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(portal_permissions.get("read_only") is True, "PORTAL_READ_ONLY_NOT_TRUE")
require(portal_permissions.get("can_view_assigned_tenants") is True, "CAN_VIEW_ASSIGNED_TENANTS_NOT_TRUE")
require(portal_permissions.get("can_preview_exports") is True, "CAN_PREVIEW_EXPORTS_NOT_TRUE")
require(portal_permissions.get("can_create_or_modify_records") is False, "WRITE_PERMISSION_NOT_DENIED")
require(portal_permissions.get("can_access_unassigned_tenant") is False, "UNASSIGNED_TENANT_ACCESS_NOT_DENIED")
require(portal_permissions.get("can_run_real_export") is False, "REAL_EXPORT_PERMISSION_NOT_DENIED")

if fail_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("uat_result") == "PASS", "UAT_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("uat_result") == "FAIL", "UAT_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_export") == "CLOSED", "REAL_EXPORT_NOT_CLOSED")

if errors:
    print("ACCOUNTANT_PORTAL_UAT_STATUS=FAIL")
    print(f"ACCOUNTANT_PORTAL_UAT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"ACCOUNTANT_PORTAL_UAT_FAIL={error}")
    sys.exit(1)

print("ACCOUNTANT_PORTAL_UAT_STATUS=PASS")
print(f"ACCOUNTANT_PORTAL_UAT_ACCOUNTANT_USER_ID={accountant_context.get('accountant_user_id')}")
print(f"ACCOUNTANT_PORTAL_UAT_ASSIGNED_TENANT_COUNT={len(assigned_tenant_ids)}")
print(f"ACCOUNTANT_PORTAL_UAT_TOTAL_CASE_COUNT={total_case_count}")
print(f"ACCOUNTANT_PORTAL_UAT_PASS_COUNT={pass_count}")
print(f"ACCOUNTANT_PORTAL_UAT_FAIL_COUNT={fail_count}")
print(f"ACCOUNTANT_PORTAL_UAT_REQUIRED_FAIL_COUNT={required_fail_count}")
print(f"ACCOUNTANT_PORTAL_UAT_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"ACCOUNTANT_PORTAL_UAT_RESULT={summary.get('uat_result')}")
print("ACCOUNTANT_PORTAL_UAT_MODE=CONTROLLED_PILOT")
print("ACCOUNTANT_PORTAL_MODE=READ_ONLY_PREVIEW")
print("ACCOUNTANT_PORTAL_CROSS_TENANT_GUARD=PASS")
print("ACCOUNTANT_PORTAL_REAL_EXPORT=CLOSED")
print("ACCOUNTANT_PORTAL_UAT_EXTERNAL_POLICY=CLOSED")
PY_EOF
