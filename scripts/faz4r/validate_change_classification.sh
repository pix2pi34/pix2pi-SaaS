#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_6_2_degisiklik_siniflandirma.v1.json}"
CHANGE_FILE="${CHANGE_FILE:-configs/faz4r/change_classification.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "CHANGE_CLASSIFICATION_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$CHANGE_FILE" ]; then
  fail "CHANGE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$CHANGE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$CHANGE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
change_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
change_artifact = json.loads(change_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 222, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_6_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("classification_policy", {})
required_rules = set(config.get("required_classification_rules", []))

require(payload.get("classification_status") == policy.get("classification_status_required"), "CLASSIFICATION_STATUS_NOT_READY")
require(payload.get("classification_mode") == policy.get("classification_mode_required"), "CLASSIFICATION_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("classification_rules", [])
controls = payload.get("classification_controls", {})
metrics = payload.get("classification_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "CLASSIFICATION_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"CLASSIFICATION_RULE_{idx}"
        require(isinstance(rule, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(rule, dict):
            continue

        code = rule.get("code")
        status = rule.get("status")
        required = rule.get("required")
        category = rule.get("category")
        owner = rule.get("owner")
        evidence_ref = rule.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_rules.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(category), f"{prefix}_CATEGORY_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_CLASSIFICATION_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_CLASSIFICATION_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_CLASSIFICATION_RULE_CODE_FOUND")

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

require(summary.get("feedback_channel_status") == policy.get("feedback_channel_status_required"), "FEEDBACK_CHANNEL_STATUS_NOT_PASS")
require(summary.get("priority_mapping_status") == policy.get("priority_mapping_status_required"), "PRIORITY_MAPPING_STATUS_NOT_READY")
require(summary.get("severity_mapping_status") == policy.get("severity_mapping_status_required"), "SEVERITY_MAPPING_STATUS_NOT_READY")
require(summary.get("owner_routing_status") == policy.get("owner_routing_status_required"), "OWNER_ROUTING_STATUS_NOT_READY")
require(summary.get("quick_fix_candidate_status") == policy.get("quick_fix_candidate_status_required"), "QUICK_FIX_CANDIDATE_STATUS_NOT_READY")
require(summary.get("product_decision_candidate_status") == policy.get("product_decision_candidate_status_required"), "PRODUCT_DECISION_CANDIDATE_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("feedback_channel_status") == "PASS", "CONTROL_FEEDBACK_CHANNEL_NOT_PASS")
require(controls.get("priority_mapping_status") == "READY", "CONTROL_PRIORITY_MAPPING_NOT_READY")
require(controls.get("severity_mapping_status") == "READY", "CONTROL_SEVERITY_MAPPING_NOT_READY")
require(controls.get("owner_routing_status") == "READY", "CONTROL_OWNER_ROUTING_NOT_READY")
require(controls.get("quick_fix_candidate_status") == "READY", "CONTROL_QUICK_FIX_CANDIDATE_NOT_READY")
require(controls.get("product_decision_candidate_status") == "READY", "CONTROL_PRODUCT_DECISION_CANDIDATE_NOT_READY")
require(controls.get("deferred_change_status") == "READY", "CONTROL_DEFERRED_CHANGE_NOT_READY")
require(controls.get("out_of_scope_status") == "READY", "CONTROL_OUT_OF_SCOPE_NOT_READY")
require(controls.get("no_auto_apply_change") is policy.get("no_auto_apply_change_required"), "AUTO_APPLY_CHANGE_NOT_DISABLED")
require(controls.get("no_hotfix_deploy") is policy.get("no_hotfix_deploy_required"), "HOTFIX_DEPLOY_NOT_DISABLED")
require(controls.get("no_real_crm_system") is policy.get("no_real_crm_system_required"), "REAL_CRM_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_ticket_system") is policy.get("no_real_ticket_system_required"), "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_rule_count") == 0, "METRIC_MISSING_RULE_COUNT_NOT_ZERO")
require(metrics.get("auto_apply_change_count") == 0, "AUTO_APPLY_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("hotfix_deploy_count") == 0, "HOTFIX_DEPLOY_COUNT_NOT_ZERO")
require(metrics.get("real_crm_dispatch_count") == 0, "REAL_CRM_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_ticket_dispatch_count") == 0, "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("classification_result") == "PASS", "CLASSIFICATION_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("classification_result") == "FAIL", "CLASSIFICATION_RESULT_SHOULD_BE_FAIL")

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
    print("CHANGE_CLASSIFICATION_STATUS=FAIL")
    print(f"CHANGE_CLASSIFICATION_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"CHANGE_CLASSIFICATION_FAIL={error}")
    sys.exit(1)

print("CHANGE_CLASSIFICATION_STATUS=PASS")
print(f"CHANGE_CLASSIFICATION_TENANT_ID={tenant.get('tenant_id')}")
print(f"CHANGE_CLASSIFICATION_TOTAL_RULE_COUNT={total_rule_count}")
print(f"CHANGE_CLASSIFICATION_READY_RULE_COUNT={ready_count}")
print(f"CHANGE_CLASSIFICATION_MISSING_RULE_COUNT={missing_count}")
print(f"CHANGE_CLASSIFICATION_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"CHANGE_CLASSIFICATION_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"CHANGE_CLASSIFICATION_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"CHANGE_CLASSIFICATION_RESULT={summary.get('classification_result')}")
print("CHANGE_CLASSIFICATION_MODE=CONTROLLED_PILOT")
print("PRIORITY_MAPPING_STATUS=READY")
print("SEVERITY_MAPPING_STATUS=READY")
print("OWNER_ROUTING_STATUS=READY")
print("NO_AUTO_APPLY_CHANGE=true")
print("NO_HOTFIX_DEPLOY=true")
print("CHANGE_CLASSIFICATION_EXTERNAL_POLICY=CLOSED")
PY_EOF
