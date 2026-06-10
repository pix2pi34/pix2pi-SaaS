#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_4_4_pilot_issue_escalation.v1.json}"
ESCALATION_FILE="${ESCALATION_FILE:-configs/faz4r/pilot_issue_escalation.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PILOT_ISSUE_ESCALATION_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$ESCALATION_FILE" ]; then
  fail "ESCALATION_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$ESCALATION_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$ESCALATION_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
escalation_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
escalation_artifact = json.loads(escalation_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 213, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_4_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("escalation_policy", {})
required_rules = set(config.get("required_escalation_rules", []))

require(payload.get("escalation_status") == policy.get("escalation_status_required"), "ESCALATION_STATUS_NOT_READY")
require(payload.get("escalation_mode") == policy.get("escalation_mode_required"), "ESCALATION_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("escalation_rules", [])
owner_matrix = payload.get("owner_matrix", {})
controls = payload.get("escalation_controls", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "ESCALATION_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"ESCALATION_RULE_{idx}"
        require(isinstance(rule, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(rule, dict):
            continue

        code = rule.get("code")
        status = rule.get("status")
        required = rule.get("required")
        owner = rule.get("owner")
        severity = rule.get("severity")
        sla = rule.get("sla")
        evidence_ref = rule.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_rules.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")
        require(non_empty(severity), f"{prefix}_SEVERITY_REQUIRED")
        require(non_empty(sla), f"{prefix}_SLA_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_ESCALATION_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_ESCALATION_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_ESCALATION_RULE_CODE_FOUND")

require(owner_matrix.get("owner_matrix_status") == policy.get("owner_matrix_status_required"), "OWNER_MATRIX_STATUS_NOT_READY")
require(non_empty(owner_matrix.get("product_owner")), "PRODUCT_OWNER_ROLE_REQUIRED")
require(non_empty(owner_matrix.get("tech_owner")), "TECH_OWNER_ROLE_REQUIRED")
require(non_empty(owner_matrix.get("support_owner")), "SUPPORT_OWNER_ROLE_REQUIRED")
require(non_empty(owner_matrix.get("business_owner")), "BUSINESS_OWNER_ROLE_REQUIRED")

require(controls.get("escalation_sla_status") == policy.get("escalation_sla_status_required"), "ESCALATION_SLA_STATUS_NOT_READY")
require(controls.get("evidence_completeness_status") == policy.get("evidence_completeness_status_required"), "EVIDENCE_COMPLETENESS_STATUS_NOT_READY")
require(controls.get("decision_log_status") == policy.get("decision_log_status_required"), "DECISION_LOG_STATUS_NOT_READY")
require(controls.get("duplicate_linked_issue_status") == "READY", "DUPLICATE_LINKED_ISSUE_STATUS_NOT_READY")
require(controls.get("hotfix_candidate_marker_status") == "READY", "HOTFIX_CANDIDATE_MARKER_STATUS_NOT_READY")
require(controls.get("policy_only_route_status") == "READY", "POLICY_ONLY_ROUTE_STATUS_NOT_READY")
require(controls.get("no_real_external_dispatch") is policy.get("no_real_external_dispatch_required"), "REAL_EXTERNAL_DISPATCH_NOT_DISABLED")

total_rule_count = summary.get("total_rule_count")
summary_ready_rule_count = summary.get("ready_rule_count")
summary_missing_rule_count = summary.get("missing_rule_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_rule_count, int) and total_rule_count >= 0, "TOTAL_RULE_COUNT_INVALID")
require(isinstance(summary_ready_rule_count, int) and summary_ready_rule_count >= 0, "READY_RULE_COUNT_INVALID")
require(isinstance(summary_missing_rule_count, int) and summary_missing_rule_count >= 0, "MISSING_RULE_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

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

require(summary.get("triage_status") == policy.get("triage_status_required"), "TRIAGE_STATUS_NOT_PASS")
require(summary.get("owner_matrix_status") == policy.get("owner_matrix_status_required"), "SUMMARY_OWNER_MATRIX_NOT_READY")
require(summary.get("escalation_sla_status") == policy.get("escalation_sla_status_required"), "SUMMARY_ESCALATION_SLA_NOT_READY")
require(summary.get("evidence_completeness_status") == policy.get("evidence_completeness_status_required"), "SUMMARY_EVIDENCE_COMPLETENESS_NOT_READY")
require(summary.get("decision_log_status") == policy.get("decision_log_status_required"), "SUMMARY_DECISION_LOG_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("escalation_result") == "PASS", "ESCALATION_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("escalation_result") == "FAIL", "ESCALATION_RESULT_SHOULD_BE_FAIL")

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
    print("PILOT_ISSUE_ESCALATION_STATUS=FAIL")
    print(f"PILOT_ISSUE_ESCALATION_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PILOT_ISSUE_ESCALATION_FAIL={error}")
    sys.exit(1)

print("PILOT_ISSUE_ESCALATION_STATUS=PASS")
print(f"PILOT_ISSUE_ESCALATION_TENANT_ID={tenant.get('tenant_id')}")
print(f"PILOT_ISSUE_ESCALATION_TOTAL_RULE_COUNT={total_rule_count}")
print(f"PILOT_ISSUE_ESCALATION_READY_RULE_COUNT={ready_count}")
print(f"PILOT_ISSUE_ESCALATION_MISSING_RULE_COUNT={missing_count}")
print(f"PILOT_ISSUE_ESCALATION_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"PILOT_ISSUE_ESCALATION_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"PILOT_ISSUE_ESCALATION_RESULT={summary.get('escalation_result')}")
print("PILOT_ISSUE_ESCALATION_MODE=CONTROLLED_PILOT")
print("TRIAGE_STATUS=PASS")
print("OWNER_MATRIX_STATUS=READY")
print("ESCALATION_SLA_STATUS=READY")
print("EVIDENCE_COMPLETENESS_STATUS=READY")
print("DECISION_LOG_STATUS=READY")
print("NO_REAL_EXTERNAL_DISPATCH=true")
print("PILOT_ISSUE_ESCALATION_EXTERNAL_POLICY=CLOSED")
PY_EOF
