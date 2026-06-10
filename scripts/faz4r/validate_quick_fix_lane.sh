#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_6_3_hizli_duzeltme_hatti.v1.json}"
QUICK_FIX_FILE="${QUICK_FIX_FILE:-configs/faz4r/quick_fix_lane.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "QUICK_FIX_LANE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$QUICK_FIX_FILE" ]; then
  fail "QUICK_FIX_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$QUICK_FIX_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$QUICK_FIX_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
quick_fix_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
quick_fix_artifact = json.loads(quick_fix_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 223, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_6_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("quick_fix_policy", {})
required_rules = set(config.get("required_quick_fix_rules", []))

require(payload.get("quick_fix_lane_status") == policy.get("quick_fix_lane_status_required"), "QUICK_FIX_LANE_STATUS_NOT_READY")
require(payload.get("quick_fix_lane_mode") == policy.get("quick_fix_lane_mode_required"), "QUICK_FIX_LANE_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("quick_fix_rules", [])
controls = payload.get("quick_fix_controls", {})
metrics = payload.get("quick_fix_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "QUICK_FIX_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"QUICK_FIX_RULE_{idx}"
        require(isinstance(rule, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(rule, dict):
            continue

        code = rule.get("code")
        status = rule.get("status")
        required = rule.get("required")
        area = rule.get("area")
        owner = rule.get("owner")
        evidence_ref = rule.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_rules.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_QUICK_FIX_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_QUICK_FIX_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_QUICK_FIX_RULE_CODE_FOUND")

total_rule_count = summary.get("total_rule_count")
summary_ready_rule_count = summary.get("ready_rule_count")
summary_missing_rule_count = summary.get("missing_rule_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_rule_count, int) and total_rule_count >= 0, "TOTAL_RULE_COUNT_INVALID")
require(isinstance(summary_ready_rule_count, int) and summary_ready_rule_count >= 0, "READY_RULE_COUNT_INVALID")
require(isinstance(summary_missing_rule_count, int) and summary_missing_rule_count >= 0, "MISSING_RULE_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_rule_count, int):
    require(total_rule_count == len(rules), "TOTAL_RULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_rule_count, int):
    require(summary_ready_rule_count == ready_count, "READY_RULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_rule_count, int):
    require(summary_missing_rule_count == missing_count, "MISSING_RULE_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_rule_count == policy.get("missing_rule_count_required"), "MISSING_RULE_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("change_classification_status") == policy.get("change_classification_status_required"), "CHANGE_CLASSIFICATION_STATUS_NOT_PASS")
require(summary.get("quick_fix_candidate_status") == policy.get("quick_fix_candidate_status_required"), "QUICK_FIX_CANDIDATE_STATUS_NOT_READY")
require(summary.get("eligibility_gate_status") == policy.get("eligibility_gate_status_required"), "ELIGIBILITY_GATE_STATUS_NOT_READY")
require(summary.get("risk_assessment_status") == policy.get("risk_assessment_status_required"), "RISK_ASSESSMENT_STATUS_NOT_READY")
require(summary.get("test_plan_status") == policy.get("test_plan_status_required"), "TEST_PLAN_STATUS_NOT_READY")
require(summary.get("rollback_plan_status") == policy.get("rollback_plan_status_required"), "ROLLBACK_PLAN_STATUS_NOT_READY")
require(summary.get("approval_gate_status") == policy.get("approval_gate_status_required"), "APPROVAL_GATE_STATUS_NOT_READY")
require(summary.get("qa_verification_status") == policy.get("qa_verification_status_required"), "QA_VERIFICATION_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("change_classification_status") == "PASS", "CONTROL_CHANGE_CLASSIFICATION_NOT_PASS")
require(controls.get("quick_fix_candidate_status") == "READY", "CONTROL_QUICK_FIX_CANDIDATE_NOT_READY")
require(controls.get("eligibility_gate_status") == "READY", "CONTROL_ELIGIBILITY_GATE_NOT_READY")
require(controls.get("risk_assessment_status") == "READY", "CONTROL_RISK_ASSESSMENT_NOT_READY")
require(controls.get("test_plan_status") == "READY", "CONTROL_TEST_PLAN_NOT_READY")
require(controls.get("rollback_plan_status") == "READY", "CONTROL_ROLLBACK_PLAN_NOT_READY")
require(controls.get("approval_gate_status") == "READY", "CONTROL_APPROVAL_GATE_NOT_READY")
require(controls.get("qa_verification_status") == "READY", "CONTROL_QA_VERIFICATION_NOT_READY")
require(controls.get("closure_gate_status") == "READY", "CONTROL_CLOSURE_GATE_NOT_READY")
require(controls.get("no_auto_apply_change") is policy.get("no_auto_apply_change_required"), "AUTO_APPLY_CHANGE_NOT_DISABLED")
require(controls.get("no_hotfix_deploy") is policy.get("no_hotfix_deploy_required"), "HOTFIX_DEPLOY_NOT_DISABLED")
require(controls.get("no_real_rollback_execution") is policy.get("no_real_rollback_execution_required"), "REAL_ROLLBACK_EXECUTION_NOT_DISABLED")
require(controls.get("no_real_crm_system") is True, "REAL_CRM_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_ticket_system") is True, "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_rule_count") == 0, "METRIC_MISSING_RULE_COUNT_NOT_ZERO")
require(metrics.get("auto_apply_change_count") == 0, "AUTO_APPLY_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("hotfix_deploy_count") == 0, "HOTFIX_DEPLOY_COUNT_NOT_ZERO")
require(metrics.get("real_rollback_execution_count") == 0, "REAL_ROLLBACK_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("real_crm_dispatch_count") == 0, "REAL_CRM_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_ticket_dispatch_count") == 0, "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("quick_fix_lane_result") == "PASS", "QUICK_FIX_LANE_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("quick_fix_lane_result") == "FAIL", "QUICK_FIX_LANE_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_crm_system") == "CLOSED", "REAL_CRM_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_ticket_system") == "CLOSED", "REAL_TICKET_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_email_dispatch") == "CLOSED", "REAL_EMAIL_DISPATCH_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")
require(external_policy.get("real_rollback_execution") == "CLOSED", "REAL_ROLLBACK_EXECUTION_NOT_CLOSED")

if errors:
    print("QUICK_FIX_LANE_STATUS=FAIL")
    print(f"QUICK_FIX_LANE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"QUICK_FIX_LANE_FAIL={error}")
    sys.exit(1)

print("QUICK_FIX_LANE_STATUS=PASS")
print(f"QUICK_FIX_LANE_TENANT_ID={tenant.get('tenant_id')}")
print(f"QUICK_FIX_LANE_TOTAL_RULE_COUNT={total_rule_count}")
print(f"QUICK_FIX_LANE_READY_RULE_COUNT={ready_count}")
print(f"QUICK_FIX_LANE_MISSING_RULE_COUNT={missing_count}")
print(f"QUICK_FIX_LANE_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"QUICK_FIX_LANE_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"QUICK_FIX_LANE_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"QUICK_FIX_LANE_RESULT={summary.get('quick_fix_lane_result')}")
print("QUICK_FIX_LANE_MODE=CONTROLLED_PILOT")
print("ELIGIBILITY_GATE_STATUS=READY")
print("RISK_ASSESSMENT_STATUS=READY")
print("TEST_PLAN_STATUS=READY")
print("ROLLBACK_PLAN_STATUS=READY")
print("APPROVAL_GATE_STATUS=READY")
print("QA_VERIFICATION_STATUS=READY")
print("NO_AUTO_APPLY_CHANGE=true")
print("NO_HOTFIX_DEPLOY=true")
print("NO_REAL_ROLLBACK_EXECUTION=true")
print("QUICK_FIX_LANE_EXTERNAL_POLICY=CLOSED")
PY_EOF
