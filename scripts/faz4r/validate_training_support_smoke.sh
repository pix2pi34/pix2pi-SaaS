#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_4_5_egitim_destek_smoke.v1.json}"
SMOKE_FILE="${SMOKE_FILE:-configs/faz4r/training_support_smoke.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "TRAINING_SUPPORT_SMOKE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$SMOKE_FILE" ]; then
  fail "SMOKE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$SMOKE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$SMOKE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
smoke_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
smoke_artifact = json.loads(smoke_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 214, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_4_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("smoke_policy", {})
required_checks = set(config.get("required_smoke_checks", []))

require(payload.get("smoke_status") == policy.get("smoke_status_required"), "SMOKE_STATUS_NOT_READY")
require(payload.get("smoke_mode") == policy.get("smoke_mode_required"), "SMOKE_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

checks = payload.get("smoke_checks", [])
controls = payload.get("smoke_controls", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(checks, list), "SMOKE_CHECKS_NOT_LIST")

provided_checks = []
pass_count = 0
fail_count = 0
required_fail_count = 0

if isinstance(checks, list):
    for idx, check in enumerate(checks, start=1):
        prefix = f"SMOKE_CHECK_{idx}"
        require(isinstance(check, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(check, dict):
            continue

        code = check.get("code")
        status = check.get("status")
        required = check.get("required")
        area = check.get("area")
        evidence_ref = check.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_checks.append(code)

        require(status in {"PASS", "FAIL", "WARN"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")

        if status == "PASS":
            pass_count += 1
        elif status == "FAIL":
            fail_count += 1
            if required is True:
                required_fail_count += 1

        if required is True:
            require(status == policy.get("required_check_status_required"), f"REQUIRED_SMOKE_CHECK_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")

provided_set = set(provided_checks)
missing_checks = sorted(required_checks - provided_set)
require(not missing_checks, "REQUIRED_SMOKE_CHECKS_MISSING:" + ",".join(missing_checks))
require(len(provided_checks) == len(provided_set), "DUPLICATE_SMOKE_CHECK_CODE_FOUND")

total_check_count = summary.get("total_check_count")
summary_pass_check_count = summary.get("pass_check_count")
summary_fail_check_count = summary.get("fail_check_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_check_count, int) and total_check_count >= 0, "TOTAL_CHECK_COUNT_INVALID")
require(isinstance(summary_pass_check_count, int) and summary_pass_check_count >= 0, "PASS_CHECK_COUNT_INVALID")
require(isinstance(summary_fail_check_count, int) and summary_fail_check_count >= 0, "FAIL_CHECK_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

if isinstance(total_check_count, int):
    require(total_check_count == len(checks), "TOTAL_CHECK_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_check_count, int):
    require(summary_pass_check_count == pass_count, "PASS_CHECK_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_check_count, int):
    require(summary_fail_check_count == fail_count, "FAIL_CHECK_COUNT_RECONCILIATION_FAILED")
    require(summary_fail_check_count == policy.get("fail_check_count_required"), "FAIL_CHECK_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")

for key, err in [
    ("training_set_status", "TRAINING_SET_STATUS_NOT_PASS"),
    ("help_center_status", "HELP_CENTER_STATUS_NOT_PASS"),
    ("triage_status", "TRIAGE_STATUS_NOT_PASS"),
    ("escalation_status", "ESCALATION_STATUS_NOT_PASS")
]:
    require(summary.get(key) == policy.get(f"{key}_required"), err)

require(controls.get("training_set_status") == "PASS", "CONTROL_TRAINING_SET_STATUS_NOT_PASS")
require(controls.get("help_center_status") == "PASS", "CONTROL_HELP_CENTER_STATUS_NOT_PASS")
require(controls.get("triage_status") == "PASS", "CONTROL_TRIAGE_STATUS_NOT_PASS")
require(controls.get("escalation_status") == "PASS", "CONTROL_ESCALATION_STATUS_NOT_PASS")
require(controls.get("owner_matrix_status") == "READY", "OWNER_MATRIX_STATUS_NOT_READY")
require(controls.get("sla_matrix_status") == "READY", "SLA_MATRIX_STATUS_NOT_READY")
require(controls.get("evidence_attachment_status") == "READY", "EVIDENCE_ATTACHMENT_STATUS_NOT_READY")
require(controls.get("no_real_external_dispatch") is policy.get("no_real_external_dispatch_required"), "REAL_EXTERNAL_DISPATCH_NOT_DISABLED")

require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

if fail_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("smoke_result") == "PASS", "SMOKE_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("smoke_result") == "FAIL", "SMOKE_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_ticket_system") == "CLOSED", "REAL_TICKET_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_email_dispatch") == "CLOSED", "REAL_EMAIL_DISPATCH_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")

if errors:
    print("TRAINING_SUPPORT_SMOKE_STATUS=FAIL")
    print(f"TRAINING_SUPPORT_SMOKE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"TRAINING_SUPPORT_SMOKE_FAIL={error}")
    sys.exit(1)

print("TRAINING_SUPPORT_SMOKE_STATUS=PASS")
print(f"TRAINING_SUPPORT_SMOKE_TENANT_ID={tenant.get('tenant_id')}")
print(f"TRAINING_SUPPORT_SMOKE_TOTAL_CHECK_COUNT={total_check_count}")
print(f"TRAINING_SUPPORT_SMOKE_PASS_CHECK_COUNT={pass_count}")
print(f"TRAINING_SUPPORT_SMOKE_FAIL_CHECK_COUNT={fail_count}")
print(f"TRAINING_SUPPORT_SMOKE_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"TRAINING_SUPPORT_SMOKE_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"TRAINING_SUPPORT_SMOKE_RESULT={summary.get('smoke_result')}")
print("TRAINING_SUPPORT_SMOKE_MODE=CONTROLLED_PILOT")
print("TRAINING_SET_STATUS=PASS")
print("HELP_CENTER_STATUS=PASS")
print("TRIAGE_STATUS=PASS")
print("ESCALATION_STATUS=PASS")
print("NO_REAL_EXTERNAL_DISPATCH=true")
print("TRAINING_SUPPORT_SMOKE_EXTERNAL_POLICY=CLOSED")
PY_EOF
