#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_4_3_ilk_destek_triage_akisi.v1.json}"
TRIAGE_FILE="${TRIAGE_FILE:-configs/faz4r/initial_support_triage_flow.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "INITIAL_SUPPORT_TRIAGE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$TRIAGE_FILE" ]; then
  fail "TRIAGE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$TRIAGE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$TRIAGE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
triage_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
triage_artifact = json.loads(triage_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 212, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_4_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("triage_policy", {})
required_flows = set(config.get("required_triage_flows", []))

require(payload.get("triage_status") == policy.get("triage_status_required"), "TRIAGE_STATUS_NOT_READY")
require(payload.get("triage_mode") == policy.get("triage_mode_required"), "TRIAGE_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

flows = payload.get("triage_flows", [])
support_channels = payload.get("support_channels", {})
severity_matrix = payload.get("severity_matrix", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(flows, list), "TRIAGE_FLOWS_NOT_LIST")

provided_flows = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(flows, list):
    for idx, flow in enumerate(flows, start=1):
        prefix = f"TRIAGE_FLOW_{idx}"
        require(isinstance(flow, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(flow, dict):
            continue

        code = flow.get("code")
        status = flow.get("status")
        required = flow.get("required")
        owner = flow.get("owner")
        severity = flow.get("severity")
        evidence_ref = flow.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_flows.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")
        require(non_empty(severity), f"{prefix}_SEVERITY_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_flow_status_required"), f"REQUIRED_TRIAGE_FLOW_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_flows)
missing_flows = sorted(required_flows - provided_set)
require(not missing_flows, "REQUIRED_TRIAGE_FLOWS_MISSING:" + ",".join(missing_flows))
require(len(provided_flows) == len(provided_set), "DUPLICATE_TRIAGE_FLOW_CODE_FOUND")

required_severities = {"P0", "P1", "P2", "P3"}
require(required_severities.issubset(set(severity_matrix.keys())), "SEVERITY_MATRIX_MISSING_REQUIRED_LEVELS")
for sev in required_severities:
    node = severity_matrix.get(sev, {})
    require(non_empty(node.get("label")), f"SEVERITY_{sev}_LABEL_REQUIRED")
    require(non_empty(node.get("first_response_target")), f"SEVERITY_{sev}_SLA_REQUIRED")
    require(non_empty(node.get("owner")), f"SEVERITY_{sev}_OWNER_REQUIRED")

require(support_channels.get("intake_channel_status") == policy.get("intake_channel_status_required"), "INTAKE_CHANNEL_STATUS_NOT_READY")
require(support_channels.get("severity_matrix_status") == policy.get("severity_matrix_status_required"), "SEVERITY_MATRIX_STATUS_NOT_READY")
require(support_channels.get("routing_matrix_status") == policy.get("routing_matrix_status_required"), "ROUTING_MATRIX_STATUS_NOT_READY")
require(support_channels.get("response_sla_status") == policy.get("response_sla_status_required"), "RESPONSE_SLA_STATUS_NOT_READY")
require(support_channels.get("evidence_attachment_status") == policy.get("evidence_attachment_status_required"), "EVIDENCE_ATTACHMENT_STATUS_NOT_READY")
require(support_channels.get("no_real_external_dispatch") is policy.get("no_real_external_dispatch_required"), "REAL_EXTERNAL_DISPATCH_NOT_DISABLED")

total_flow_count = summary.get("total_flow_count")
summary_ready_flow_count = summary.get("ready_flow_count")
summary_missing_flow_count = summary.get("missing_flow_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_flow_count, int) and total_flow_count >= 0, "TOTAL_FLOW_COUNT_INVALID")
require(isinstance(summary_ready_flow_count, int) and summary_ready_flow_count >= 0, "READY_FLOW_COUNT_INVALID")
require(isinstance(summary_missing_flow_count, int) and summary_missing_flow_count >= 0, "MISSING_FLOW_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

if isinstance(total_flow_count, int):
    require(total_flow_count == len(flows), "TOTAL_FLOW_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_flow_count, int):
    require(summary_ready_flow_count == ready_count, "READY_FLOW_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_flow_count, int):
    require(summary_missing_flow_count == missing_count, "MISSING_FLOW_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_flow_count == policy.get("missing_flow_count_required"), "MISSING_FLOW_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")

require(summary.get("training_set_status") == policy.get("training_set_status_required"), "TRAINING_SET_STATUS_NOT_PASS")
require(summary.get("help_center_status") == policy.get("help_center_status_required"), "HELP_CENTER_STATUS_NOT_PASS")
require(summary.get("intake_channel_status") == policy.get("intake_channel_status_required"), "SUMMARY_INTAKE_CHANNEL_NOT_READY")
require(summary.get("severity_matrix_status") == policy.get("severity_matrix_status_required"), "SUMMARY_SEVERITY_MATRIX_NOT_READY")
require(summary.get("routing_matrix_status") == policy.get("routing_matrix_status_required"), "SUMMARY_ROUTING_MATRIX_NOT_READY")
require(summary.get("response_sla_status") == policy.get("response_sla_status_required"), "SUMMARY_RESPONSE_SLA_NOT_READY")
require(summary.get("evidence_attachment_status") == policy.get("evidence_attachment_status_required"), "SUMMARY_EVIDENCE_ATTACHMENT_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("triage_result") == "PASS", "TRIAGE_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("triage_result") == "FAIL", "TRIAGE_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_ticket_system") == "CLOSED", "REAL_TICKET_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_email_dispatch") == "CLOSED", "REAL_EMAIL_DISPATCH_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")

if errors:
    print("INITIAL_SUPPORT_TRIAGE_STATUS=FAIL")
    print(f"INITIAL_SUPPORT_TRIAGE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"INITIAL_SUPPORT_TRIAGE_FAIL={error}")
    sys.exit(1)

print("INITIAL_SUPPORT_TRIAGE_STATUS=PASS")
print(f"INITIAL_SUPPORT_TRIAGE_TENANT_ID={tenant.get('tenant_id')}")
print(f"INITIAL_SUPPORT_TRIAGE_TOTAL_FLOW_COUNT={total_flow_count}")
print(f"INITIAL_SUPPORT_TRIAGE_READY_FLOW_COUNT={ready_count}")
print(f"INITIAL_SUPPORT_TRIAGE_MISSING_FLOW_COUNT={missing_count}")
print(f"INITIAL_SUPPORT_TRIAGE_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"INITIAL_SUPPORT_TRIAGE_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"INITIAL_SUPPORT_TRIAGE_RESULT={summary.get('triage_result')}")
print("INITIAL_SUPPORT_TRIAGE_MODE=CONTROLLED_PILOT")
print("TRAINING_SET_STATUS=PASS")
print("HELP_CENTER_STATUS=PASS")
print("INTAKE_CHANNEL_STATUS=READY")
print("SEVERITY_MATRIX_STATUS=READY")
print("ROUTING_MATRIX_STATUS=READY")
print("RESPONSE_SLA_STATUS=READY")
print("NO_REAL_EXTERNAL_DISPATCH=true")
print("INITIAL_SUPPORT_TRIAGE_EXTERNAL_POLICY=CLOSED")
PY_EOF
