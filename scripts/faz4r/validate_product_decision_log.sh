#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_6_4_urun_karar_defteri.v1.json}"
DECISION_FILE="${DECISION_FILE:-configs/faz4r/product_decision_log.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PRODUCT_DECISION_LOG_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$DECISION_FILE" ]; then
  fail "DECISION_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$DECISION_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$DECISION_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 224, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_6_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("decision_log_policy", {})
required_rules = set(config.get("required_decision_rules", []))

require(payload.get("decision_log_status") == policy.get("decision_log_status_required"), "DECISION_LOG_STATUS_NOT_READY")
require(payload.get("decision_log_mode") == policy.get("decision_log_mode_required"), "DECISION_LOG_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("decision_rules", [])
controls = payload.get("decision_controls", {})
metrics = payload.get("decision_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "DECISION_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"DECISION_RULE_{idx}"
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
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_DECISION_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_DECISION_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_DECISION_RULE_CODE_FOUND")

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

require(summary.get("quick_fix_lane_status") == policy.get("quick_fix_lane_status_required"), "QUICK_FIX_LANE_STATUS_NOT_PASS")
require(summary.get("decision_type_taxonomy_status") == policy.get("decision_type_taxonomy_status_required"), "DECISION_TYPE_TAXONOMY_STATUS_NOT_READY")
require(summary.get("owner_assignment_status") == policy.get("owner_assignment_status_required"), "OWNER_ASSIGNMENT_STATUS_NOT_READY")
require(summary.get("impact_area_mapping_status") == policy.get("impact_area_mapping_status_required"), "IMPACT_AREA_MAPPING_STATUS_NOT_READY")
require(summary.get("approval_record_status") == policy.get("approval_record_status_required"), "APPROVAL_RECORD_STATUS_NOT_READY")
require(summary.get("closure_checklist_status") == policy.get("closure_checklist_status_required"), "CLOSURE_CHECKLIST_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("quick_fix_lane_status") == "PASS", "CONTROL_QUICK_FIX_LANE_NOT_PASS")
require(controls.get("decision_type_taxonomy_status") == "READY", "CONTROL_DECISION_TYPE_TAXONOMY_NOT_READY")
require(controls.get("owner_assignment_status") == "READY", "CONTROL_OWNER_ASSIGNMENT_NOT_READY")
require(controls.get("impact_area_mapping_status") == "READY", "CONTROL_IMPACT_AREA_MAPPING_NOT_READY")
require(controls.get("approval_record_status") == "READY", "CONTROL_APPROVAL_RECORD_NOT_READY")
require(controls.get("closure_checklist_status") == "READY", "CONTROL_CLOSURE_CHECKLIST_NOT_READY")
require(controls.get("no_auto_apply_decision") is policy.get("no_auto_apply_decision_required"), "AUTO_APPLY_DECISION_NOT_DISABLED")
require(controls.get("no_hotfix_deploy") is policy.get("no_hotfix_deploy_required"), "HOTFIX_DEPLOY_NOT_DISABLED")
require(controls.get("no_real_roadmap_tool") is policy.get("no_real_roadmap_tool_required"), "REAL_ROADMAP_TOOL_NOT_DISABLED")
require(controls.get("no_real_crm_system") is policy.get("no_real_crm_system_required"), "REAL_CRM_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_ticket_system") is policy.get("no_real_ticket_system_required"), "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_rule_count") == 0, "METRIC_MISSING_RULE_COUNT_NOT_ZERO")
require(metrics.get("auto_apply_decision_count") == 0, "AUTO_APPLY_DECISION_COUNT_NOT_ZERO")
require(metrics.get("hotfix_deploy_count") == 0, "HOTFIX_DEPLOY_COUNT_NOT_ZERO")
require(metrics.get("real_roadmap_tool_dispatch_count") == 0, "REAL_ROADMAP_TOOL_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_crm_dispatch_count") == 0, "REAL_CRM_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_ticket_dispatch_count") == 0, "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("decision_log_result") == "PASS", "DECISION_LOG_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("decision_log_result") == "FAIL", "DECISION_LOG_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_roadmap_tool") == "CLOSED", "REAL_ROADMAP_TOOL_NOT_CLOSED")
require(external_policy.get("real_crm_system") == "CLOSED", "REAL_CRM_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_ticket_system") == "CLOSED", "REAL_TICKET_SYSTEM_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")
require(external_policy.get("real_rollback_execution") == "CLOSED", "REAL_ROLLBACK_EXECUTION_NOT_CLOSED")

if errors:
    print("PRODUCT_DECISION_LOG_STATUS=FAIL")
    print(f"PRODUCT_DECISION_LOG_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PRODUCT_DECISION_LOG_FAIL={error}")
    sys.exit(1)

print("PRODUCT_DECISION_LOG_STATUS=PASS")
print(f"PRODUCT_DECISION_LOG_TENANT_ID={tenant.get('tenant_id')}")
print(f"PRODUCT_DECISION_LOG_TOTAL_RULE_COUNT={total_rule_count}")
print(f"PRODUCT_DECISION_LOG_READY_RULE_COUNT={ready_count}")
print(f"PRODUCT_DECISION_LOG_MISSING_RULE_COUNT={missing_count}")
print(f"PRODUCT_DECISION_LOG_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"PRODUCT_DECISION_LOG_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"PRODUCT_DECISION_LOG_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"PRODUCT_DECISION_LOG_RESULT={summary.get('decision_log_result')}")
print("PRODUCT_DECISION_LOG_MODE=CONTROLLED_PILOT")
print("DECISION_TYPE_TAXONOMY_STATUS=READY")
print("OWNER_ASSIGNMENT_STATUS=READY")
print("IMPACT_AREA_MAPPING_STATUS=READY")
print("APPROVAL_RECORD_STATUS=READY")
print("CLOSURE_CHECKLIST_STATUS=READY")
print("NO_AUTO_APPLY_DECISION=true")
print("NO_HOTFIX_DEPLOY=true")
print("NO_REAL_ROADMAP_TOOL=true")
print("PRODUCT_DECISION_LOG_EXTERNAL_POLICY=CLOSED")
PY_EOF
