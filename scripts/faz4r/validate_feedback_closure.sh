#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_6_5_feedback_closure.v1.json}"
CLOSURE_FILE="${CLOSURE_FILE:-configs/faz4r/feedback_closure.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "FEEDBACK_CLOSURE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$CLOSURE_FILE" ]; then
  fail "CLOSURE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$CLOSURE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$CLOSURE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
payload = json.loads(Path(sys.argv[3]).read_text())
errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 225, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_6_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("feedback_closure_policy", {})
required_rules = set(config.get("required_closure_rules", []))

require(payload.get("feedback_closure_status") == policy.get("feedback_closure_status_required"), "FEEDBACK_CLOSURE_STATUS_NOT_READY")
require(payload.get("feedback_closure_mode") == policy.get("feedback_closure_mode_required"), "FEEDBACK_CLOSURE_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("closure_rules", [])
controls = payload.get("closure_controls", {})
metrics = payload.get("closure_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "CLOSURE_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"CLOSURE_RULE_{idx}"
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
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_CLOSURE_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_CLOSURE_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_CLOSURE_RULE_CODE_FOUND")

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

require(summary.get("product_decision_log_status") == policy.get("product_decision_log_status_required"), "PRODUCT_DECISION_LOG_STATUS_NOT_PASS")
require(summary.get("closure_outcome_taxonomy_status") == policy.get("closure_outcome_taxonomy_status_required"), "CLOSURE_OUTCOME_TAXONOMY_STATUS_NOT_READY")
require(summary.get("owner_confirmation_status") == policy.get("owner_confirmation_status_required"), "OWNER_CONFIRMATION_STATUS_NOT_READY")
require(summary.get("evidence_completion_status") == policy.get("evidence_completion_status_required"), "EVIDENCE_COMPLETION_STATUS_NOT_READY")
require(summary.get("user_communication_note_status") == policy.get("user_communication_note_status_required"), "USER_COMMUNICATION_NOTE_STATUS_NOT_READY")
require(summary.get("reopen_guard_status") == policy.get("reopen_guard_status_required"), "REOPEN_GUARD_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("product_decision_log_status") == "PASS", "CONTROL_PRODUCT_DECISION_LOG_NOT_PASS")
require(controls.get("closure_outcome_taxonomy_status") == "READY", "CONTROL_CLOSURE_OUTCOME_TAXONOMY_NOT_READY")
require(controls.get("owner_confirmation_status") == "READY", "CONTROL_OWNER_CONFIRMATION_NOT_READY")
require(controls.get("evidence_completion_status") == "READY", "CONTROL_EVIDENCE_COMPLETION_NOT_READY")
require(controls.get("user_communication_note_status") == "READY", "CONTROL_USER_COMMUNICATION_NOTE_NOT_READY")
require(controls.get("reopen_guard_status") == "READY", "CONTROL_REOPEN_GUARD_NOT_READY")
require(controls.get("closure_metrics_status") == "READY", "CONTROL_CLOSURE_METRICS_NOT_READY")
require(controls.get("no_auto_delete_feedback") is policy.get("no_auto_delete_feedback_required"), "AUTO_DELETE_FEEDBACK_NOT_DISABLED")
require(controls.get("no_auto_apply_change") is policy.get("no_auto_apply_change_required"), "AUTO_APPLY_CHANGE_NOT_DISABLED")
require(controls.get("no_real_crm_system") is policy.get("no_real_crm_system_required"), "REAL_CRM_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_ticket_system") is policy.get("no_real_ticket_system_required"), "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_email_dispatch") is policy.get("no_real_email_dispatch_required"), "REAL_EMAIL_DISPATCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_rule_count") == 0, "METRIC_MISSING_RULE_COUNT_NOT_ZERO")
require(metrics.get("auto_delete_feedback_count") == 0, "AUTO_DELETE_FEEDBACK_COUNT_NOT_ZERO")
require(metrics.get("auto_apply_change_count") == 0, "AUTO_APPLY_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("real_crm_dispatch_count") == 0, "REAL_CRM_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_ticket_dispatch_count") == 0, "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_email_dispatch_count") == 0, "REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("feedback_closure_result") == "PASS", "FEEDBACK_CLOSURE_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("feedback_closure_result") == "FAIL", "FEEDBACK_CLOSURE_RESULT_SHOULD_BE_FAIL")

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
    print("FEEDBACK_CLOSURE_STATUS=FAIL")
    print(f"FEEDBACK_CLOSURE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"FEEDBACK_CLOSURE_FAIL={error}")
    sys.exit(1)

print("FEEDBACK_CLOSURE_STATUS=PASS")
print(f"FEEDBACK_CLOSURE_TENANT_ID={tenant.get('tenant_id')}")
print(f"FEEDBACK_CLOSURE_TOTAL_RULE_COUNT={total_rule_count}")
print(f"FEEDBACK_CLOSURE_READY_RULE_COUNT={ready_count}")
print(f"FEEDBACK_CLOSURE_MISSING_RULE_COUNT={missing_count}")
print(f"FEEDBACK_CLOSURE_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"FEEDBACK_CLOSURE_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"FEEDBACK_CLOSURE_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"FEEDBACK_CLOSURE_RESULT={summary.get('feedback_closure_result')}")
print("FEEDBACK_CLOSURE_MODE=CONTROLLED_PILOT")
print("CLOSURE_OUTCOME_TAXONOMY_STATUS=READY")
print("OWNER_CONFIRMATION_STATUS=READY")
print("EVIDENCE_COMPLETION_STATUS=READY")
print("USER_COMMUNICATION_NOTE_STATUS=READY")
print("REOPEN_GUARD_STATUS=READY")
print("NO_AUTO_DELETE_FEEDBACK=true")
print("NO_AUTO_APPLY_CHANGE=true")
print("NO_REAL_CRM_SYSTEM=true")
print("NO_REAL_TICKET_SYSTEM=true")
print("NO_REAL_EMAIL_DISPATCH=true")
print("FEEDBACK_CLOSURE_EXTERNAL_POLICY=CLOSED")
PY_EOF
