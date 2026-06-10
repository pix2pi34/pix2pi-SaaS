#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_5_6_pilot_operations_testleri.v1.json}"
OPS_FILE="${OPS_FILE:-configs/faz4r/pilot_operations_tests.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PILOT_OPERATIONS_TESTS_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$OPS_FILE" ]; then
  fail "OPS_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$OPS_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$OPS_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
ops_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
ops_artifact = json.loads(ops_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 217, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_5_6", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("operations_test_policy", {})
required_tests = set(config.get("required_operations_tests", []))

require(payload.get("operations_test_status") == policy.get("operations_test_status_required"), "OPERATIONS_TEST_STATUS_NOT_READY")
require(payload.get("operations_test_mode") == policy.get("operations_test_mode_required"), "OPERATIONS_TEST_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

tests = payload.get("operations_tests", [])
controls = payload.get("operations_controls", {})
metrics = payload.get("operations_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(tests, list), "OPERATIONS_TESTS_NOT_LIST")

provided_tests = []
pass_count = 0
fail_count = 0
required_fail_count = 0

if isinstance(tests, list):
    for idx, test in enumerate(tests, start=1):
        prefix = f"OPERATIONS_TEST_{idx}"
        require(isinstance(test, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(test, dict):
            continue

        code = test.get("code")
        status = test.get("status")
        required = test.get("required")
        area = test.get("area")
        owner = test.get("owner")
        evidence_ref = test.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_tests.append(code)

        require(status in {"PASS", "FAIL", "WARN"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "PASS":
            pass_count += 1
        elif status == "FAIL":
            fail_count += 1
            if required is True:
                required_fail_count += 1

        if required is True:
            require(status == policy.get("required_test_status_required"), f"REQUIRED_OPERATIONS_TEST_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")

provided_set = set(provided_tests)
missing_tests = sorted(required_tests - provided_set)
require(not missing_tests, "REQUIRED_OPERATIONS_TESTS_MISSING:" + ",".join(missing_tests))
require(len(provided_tests) == len(provided_set), "DUPLICATE_OPERATIONS_TEST_CODE_FOUND")

total_test_count = summary.get("total_test_count")
summary_pass_test_count = summary.get("pass_test_count")
summary_fail_test_count = summary.get("fail_test_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_test_count, int) and total_test_count >= 0, "TOTAL_TEST_COUNT_INVALID")
require(isinstance(summary_pass_test_count, int) and summary_pass_test_count >= 0, "PASS_TEST_COUNT_INVALID")
require(isinstance(summary_fail_test_count, int) and summary_fail_test_count >= 0, "FAIL_TEST_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_test_count, int):
    require(total_test_count == len(tests), "TOTAL_TEST_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_test_count, int):
    require(summary_pass_test_count == pass_count, "PASS_TEST_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_test_count, int):
    require(summary_fail_test_count == fail_count, "FAIL_TEST_COUNT_RECONCILIATION_FAILED")
    require(summary_fail_test_count == policy.get("fail_test_count_required"), "FAIL_TEST_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("daily_pilot_review_status") == policy.get("daily_pilot_review_status_required"), "DAILY_PILOT_REVIEW_STATUS_NOT_PASS")
require(summary.get("rollback_decision_flow_status") == policy.get("rollback_decision_flow_status_required"), "ROLLBACK_DECISION_FLOW_STATUS_NOT_PASS")
require(summary.get("training_support_smoke_status") == policy.get("training_support_smoke_status_required"), "TRAINING_SUPPORT_SMOKE_STATUS_NOT_PASS")
require(summary.get("support_triage_status") == policy.get("support_triage_status_required"), "SUPPORT_TRIAGE_STATUS_NOT_PASS")
require(summary.get("issue_escalation_status") == policy.get("issue_escalation_status_required"), "ISSUE_ESCALATION_STATUS_NOT_PASS")
require(summary.get("operations_handoff_ready") == policy.get("operations_handoff_ready_required"), "OPERATIONS_HANDOFF_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("daily_pilot_review_status") == "PASS", "CONTROL_DAILY_PILOT_REVIEW_NOT_PASS")
require(controls.get("rollback_decision_flow_status") == "PASS", "CONTROL_ROLLBACK_DECISION_FLOW_NOT_PASS")
require(controls.get("training_support_smoke_status") == "PASS", "CONTROL_TRAINING_SUPPORT_SMOKE_NOT_PASS")
require(controls.get("support_triage_status") == "PASS", "CONTROL_SUPPORT_TRIAGE_NOT_PASS")
require(controls.get("issue_escalation_status") == "PASS", "CONTROL_ISSUE_ESCALATION_NOT_PASS")
require(controls.get("pilot_health_status") == "PASS", "CONTROL_PILOT_HEALTH_NOT_PASS")
require(controls.get("operations_handoff_ready") == "YES", "CONTROL_OPERATIONS_HANDOFF_NOT_READY")
require(controls.get("no_real_rollback_execution") is policy.get("no_real_rollback_execution_required"), "REAL_ROLLBACK_EXECUTION_NOT_DISABLED")
require(controls.get("no_hotfix_deploy") is policy.get("no_hotfix_deploy_required"), "HOTFIX_DEPLOY_NOT_DISABLED")
require(controls.get("production_launch_status") == policy.get("production_launch_status_required"), "PRODUCTION_LAUNCH_STATUS_NOT_CLOSED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("failed_operation_test_count") == 0, "FAILED_OPERATION_TEST_COUNT_NOT_ZERO")
require(metrics.get("rollback_execution_count") == 0, "ROLLBACK_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("hotfix_deploy_count") == 0, "HOTFIX_DEPLOY_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")

if fail_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("operations_test_result") == "PASS", "OPERATIONS_TEST_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("operations_test_result") == "FAIL", "OPERATIONS_TEST_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")
require(external_policy.get("real_rollback_execution") == "CLOSED", "REAL_ROLLBACK_EXECUTION_NOT_CLOSED")

if errors:
    print("PILOT_OPERATIONS_TESTS_STATUS=FAIL")
    print(f"PILOT_OPERATIONS_TESTS_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PILOT_OPERATIONS_TESTS_FAIL={error}")
    sys.exit(1)

print("PILOT_OPERATIONS_TESTS_STATUS=PASS")
print(f"PILOT_OPERATIONS_TESTS_TENANT_ID={tenant.get('tenant_id')}")
print(f"PILOT_OPERATIONS_TESTS_TOTAL_TEST_COUNT={total_test_count}")
print(f"PILOT_OPERATIONS_TESTS_PASS_TEST_COUNT={pass_count}")
print(f"PILOT_OPERATIONS_TESTS_FAIL_TEST_COUNT={fail_count}")
print(f"PILOT_OPERATIONS_TESTS_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"PILOT_OPERATIONS_TESTS_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"PILOT_OPERATIONS_TESTS_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"PILOT_OPERATIONS_TESTS_RESULT={summary.get('operations_test_result')}")
print("PILOT_OPERATIONS_TESTS_MODE=CONTROLLED_PILOT")
print("OPERATIONS_HANDOFF_READY=YES")
print("NO_REAL_ROLLBACK_EXECUTION=true")
print("NO_HOTFIX_DEPLOY=true")
print("PILOT_OPERATIONS_TESTS_EXTERNAL_POLICY=CLOSED")
PY_EOF
