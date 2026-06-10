#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_1_approval_inbox.v1.json}"
INBOX_FILE="${INBOX_FILE:-configs/faz4r/approval_inbox.controlled_pilot.v1.json}"
WEB_FILE="${WEB_FILE:-web/faz4r/approval-inbox/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "APPROVAL_INBOX_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$INBOX_FILE" ]; then fail "INBOX_FILE_NOT_FOUND"; fi
if [ ! -f "$WEB_FILE" ]; then fail "WEB_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$INBOX_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$INBOX_FILE" "$WEB_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
web_text = Path(sys.argv[3]).read_text()
payload = json.loads(Path(sys.argv[4]).read_text())
errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 236, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("approval_inbox_policy", {})
required_items = set(config.get("required_inbox_items", []))

require(payload.get("approval_inbox_status") == policy.get("approval_inbox_status_required"), "APPROVAL_INBOX_STATUS_NOT_READY")
require(payload.get("approval_inbox_mode") == policy.get("approval_inbox_mode_required"), "APPROVAL_INBOX_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("inbox_items", [])
controls = payload.get("inbox_controls", {})
metrics = payload.get("inbox_metrics", {})
summary = payload.get("summary", {})
samples = payload.get("approval_samples", [])
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "INBOX_ITEMS_NOT_LIST")
require(isinstance(samples, list), "APPROVAL_SAMPLES_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"INBOX_ITEM_{idx}"
        require(isinstance(item, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(item, dict):
            continue

        code = item.get("code")
        status = item.get("status")
        required = item.get("required")
        area = item.get("area")
        owner = item.get("owner")
        evidence_ref = item.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_items.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_item_status_required"), f"REQUIRED_INBOX_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_INBOX_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_INBOX_ITEM_CODE_FOUND")

total_item_count = summary.get("total_item_count")
summary_ready_item_count = summary.get("ready_item_count")
summary_missing_item_count = summary.get("missing_item_count")
summary_required_fail_count = summary.get("required_fail_count")

require(isinstance(total_item_count, int) and total_item_count >= 0, "TOTAL_ITEM_COUNT_INVALID")
require(isinstance(summary_ready_item_count, int) and summary_ready_item_count >= 0, "READY_ITEM_COUNT_INVALID")
require(isinstance(summary_missing_item_count, int) and summary_missing_item_count >= 0, "MISSING_ITEM_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")

if isinstance(total_item_count, int):
    require(total_item_count == len(items), "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_item_count, int):
    require(summary_ready_item_count == ready_count, "READY_ITEM_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_item_count, int):
    require(summary_missing_item_count == missing_count, "MISSING_ITEM_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_item_count == policy.get("missing_item_count_required"), "MISSING_ITEM_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")

require(summary.get("tenant_scope") == policy.get("tenant_scope_required"), "SUMMARY_TENANT_SCOPE_INVALID")
require(summary.get("role_visibility_status") == policy.get("role_visibility_status_required"), "ROLE_VISIBILITY_STATUS_NOT_READY")
require(summary.get("action_state_status") == policy.get("action_state_status_required"), "ACTION_STATE_STATUS_NOT_READY")
require(summary.get("web_checkpoint_status") == policy.get("web_checkpoint_status_required"), "WEB_CHECKPOINT_STATUS_NOT_READY")
require(summary.get("pilot_closure_status") == policy.get("pilot_closure_status_required"), "PILOT_CLOSURE_STATUS_NOT_PASS")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("pilot_closure_status") == "PASS", "CONTROL_PILOT_CLOSURE_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("role_visibility_status") == "READY", "CONTROL_ROLE_VISIBILITY_NOT_READY")
require(controls.get("action_state_status") == "READY", "CONTROL_ACTION_STATE_NOT_READY")
require(controls.get("filter_model_status") == "READY", "CONTROL_FILTER_MODEL_NOT_READY")
require(controls.get("sort_model_status") == "READY", "CONTROL_SORT_MODEL_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")
require(controls.get("realtime_placeholder_status") == "READY", "CONTROL_REALTIME_PLACEHOLDER_NOT_READY")
require(controls.get("audit_trace_placeholder_status") == "READY", "CONTROL_AUDIT_TRACE_PLACEHOLDER_NOT_READY")
require(controls.get("web_checkpoint_status") == "READY", "CONTROL_WEB_CHECKPOINT_NOT_READY")

require(controls.get("no_workflow_mutation") is policy.get("no_workflow_mutation_required"), "WORKFLOW_MUTATION_NOT_DISABLED")
require(controls.get("no_real_approval_execution") is policy.get("no_real_approval_execution_required"), "REAL_APPROVAL_EXECUTION_NOT_DISABLED")
require(controls.get("no_realtime_socket_connection") is policy.get("no_realtime_socket_connection_required"), "REALTIME_SOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("enabled_action_count") == 0, "ENABLED_ACTION_COUNT_NOT_ZERO")
require(metrics.get("workflow_mutation_count") == 0, "WORKFLOW_MUTATION_COUNT_NOT_ZERO")
require(metrics.get("real_approval_execution_count") == 0, "REAL_APPROVAL_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("realtime_socket_connection_count") == 0, "REALTIME_SOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

for idx, sample in enumerate(samples, start=1):
    prefix = f"APPROVAL_SAMPLE_{idx}"
    require(sample.get("tenant_id") == tenant.get("tenant_id"), f"{prefix}_TENANT_MISMATCH")
    require(sample.get("status") == "PENDING", f"{prefix}_STATUS_NOT_PENDING")
    require(sample.get("action_state") == "DISABLED_PREVIEW_ONLY", f"{prefix}_ACTION_NOT_DISABLED")
    require(non_empty(sample.get("approval_id")), f"{prefix}_APPROVAL_ID_REQUIRED")
    require(non_empty(sample.get("approver_role")), f"{prefix}_APPROVER_ROLE_REQUIRED")

require("FAZ_4_17_1_APPROVAL_INBOX_UI_CHECKPOINT" in web_text, "WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in web_text, "WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_WORKFLOW_MUTATION" in web_text, "WEB_NO_WORKFLOW_MUTATION_MARKER_MISSING")
require("NO_REAL_APPROVAL_EXECUTION" in web_text, "WEB_NO_REAL_APPROVAL_EXECUTION_MARKER_MISSING")
require("NO_REALTIME_SOCKET_CONNECTION" in web_text, "WEB_NO_REALTIME_SOCKET_MARKER_MISSING")
require("Approval Inbox" in web_text, "WEB_APPROVAL_INBOX_TITLE_MISSING")
require("Approve disabled" in web_text, "WEB_APPROVE_DISABLED_MARKER_MISSING")
require("Reject disabled" in web_text, "WEB_REJECT_DISABLED_MARKER_MISSING")
require("Empty state ready" in web_text, "WEB_EMPTY_STATE_MARKER_MISSING")
require("Error state ready" in web_text, "WEB_ERROR_STATE_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and controls.get("no_workflow_mutation") is True:
    require(summary.get("approval_inbox_result") == "PASS", "APPROVAL_INBOX_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("approval_inbox_result") == "FAIL", "APPROVAL_INBOX_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "workflow_mutation", "real_approval_execution", "realtime_socket_connection"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("APPROVAL_INBOX_STATUS=FAIL")
    print(f"APPROVAL_INBOX_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"APPROVAL_INBOX_FAIL={error}")
    sys.exit(1)

print("APPROVAL_INBOX_STATUS=PASS")
print(f"APPROVAL_INBOX_TENANT_ID={tenant.get('tenant_id')}")
print(f"APPROVAL_INBOX_TOTAL_ITEM_COUNT={total_item_count}")
print(f"APPROVAL_INBOX_READY_ITEM_COUNT={ready_count}")
print(f"APPROVAL_INBOX_MISSING_ITEM_COUNT={missing_count}")
print(f"APPROVAL_INBOX_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("APPROVAL_INBOX_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("ROLE_VISIBILITY_STATUS=READY")
print("ACTION_STATE_STATUS=READY")
print("WEB_CHECKPOINT_STATUS=READY")
print("PILOT_CLOSURE_STATUS=PASS")
print("NO_WORKFLOW_MUTATION=true")
print("NO_REAL_APPROVAL_EXECUTION=true")
print("NO_REALTIME_SOCKET_CONNECTION=true")
print("APPROVAL_INBOX_EXTERNAL_POLICY=CLOSED")
print(f"APPROVAL_INBOX_RESULT={summary.get('approval_inbox_result')}")
PY_EOF
