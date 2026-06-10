#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_2_workflow_monitor.v1.json}"
MONITOR_FILE="${MONITOR_FILE:-configs/faz4r/workflow_monitor.controlled_pilot.v1.json}"
WEB_FILE="${WEB_FILE:-web/faz4r/workflow-monitor/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "WORKFLOW_MONITOR_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$MONITOR_FILE" ]; then fail "MONITOR_FILE_NOT_FOUND"; fi
if [ ! -f "$WEB_FILE" ]; then fail "WEB_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$MONITOR_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$MONITOR_FILE" "$WEB_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 237, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("workflow_monitor_policy", {})
required_items = set(config.get("required_monitor_items", []))

require(payload.get("workflow_monitor_status") == policy.get("workflow_monitor_status_required"), "WORKFLOW_MONITOR_STATUS_NOT_READY")
require(payload.get("workflow_monitor_mode") == policy.get("workflow_monitor_mode_required"), "WORKFLOW_MONITOR_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("monitor_items", [])
controls = payload.get("monitor_controls", {})
metrics = payload.get("monitor_metrics", {})
summary = payload.get("summary", {})
samples = payload.get("workflow_samples", [])
counters = payload.get("workflow_counters", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "MONITOR_ITEMS_NOT_LIST")
require(isinstance(samples, list), "WORKFLOW_SAMPLES_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"MONITOR_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_MONITOR_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_MONITOR_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_MONITOR_ITEM_CODE_FOUND")

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
require(summary.get("approval_inbox_status") == policy.get("approval_inbox_status_required"), "APPROVAL_INBOX_STATUS_NOT_PASS")
require(summary.get("workflow_summary_status") == policy.get("workflow_summary_status_required"), "WORKFLOW_SUMMARY_STATUS_NOT_READY")
require(summary.get("status_counter_status") == policy.get("status_counter_status_required"), "STATUS_COUNTER_STATUS_NOT_READY")
require(summary.get("sla_indicator_status") == policy.get("sla_indicator_status_required"), "SLA_INDICATOR_STATUS_NOT_READY")
require(summary.get("web_checkpoint_status") == policy.get("web_checkpoint_status_required"), "WEB_CHECKPOINT_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("approval_inbox_status") == "PASS", "CONTROL_APPROVAL_INBOX_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("workflow_summary_status") == "READY", "CONTROL_WORKFLOW_SUMMARY_NOT_READY")
require(controls.get("status_counter_status") == "READY", "CONTROL_STATUS_COUNTER_NOT_READY")
require(controls.get("sla_indicator_status") == "READY", "CONTROL_SLA_INDICATOR_NOT_READY")
require(controls.get("status_badge_status") == "READY", "CONTROL_STATUS_BADGE_NOT_READY")
require(controls.get("filter_model_status") == "READY", "CONTROL_FILTER_MODEL_NOT_READY")
require(controls.get("sort_model_status") == "READY", "CONTROL_SORT_MODEL_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")
require(controls.get("audit_trace_placeholder_status") == "READY", "CONTROL_AUDIT_TRACE_PLACEHOLDER_NOT_READY")
require(controls.get("realtime_placeholder_status") == "READY", "CONTROL_REALTIME_PLACEHOLDER_NOT_READY")
require(controls.get("web_checkpoint_status") == "READY", "CONTROL_WEB_CHECKPOINT_NOT_READY")

require(controls.get("no_workflow_mutation") is policy.get("no_workflow_mutation_required"), "WORKFLOW_MUTATION_NOT_DISABLED")
require(controls.get("no_real_workflow_execution") is policy.get("no_real_workflow_execution_required"), "REAL_WORKFLOW_EXECUTION_NOT_DISABLED")
require(controls.get("no_realtime_socket_connection") is policy.get("no_realtime_socket_connection_required"), "REALTIME_SOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("enabled_action_count") == 0, "ENABLED_ACTION_COUNT_NOT_ZERO")
require(metrics.get("workflow_mutation_count") == 0, "WORKFLOW_MUTATION_COUNT_NOT_ZERO")
require(metrics.get("real_workflow_execution_count") == 0, "REAL_WORKFLOW_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("realtime_socket_connection_count") == 0, "REALTIME_SOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

total_workflows = counters.get("total_workflow_count")
pending_count = counters.get("pending_approval_count")
running_count = counters.get("running_workflow_count")
completed_count = counters.get("completed_workflow_count")
failed_count = counters.get("failed_workflow_count")
sla_breached_count = counters.get("sla_breached_count")

for field, value in [
    ("total_workflow_count", total_workflows),
    ("pending_approval_count", pending_count),
    ("running_workflow_count", running_count),
    ("completed_workflow_count", completed_count),
    ("failed_workflow_count", failed_count),
    ("sla_breached_count", sla_breached_count)
]:
    require(isinstance(value, int) and value >= 0, f"{field.upper()}_INVALID")

if isinstance(total_workflows, int):
    require(total_workflows == len(samples), "TOTAL_WORKFLOW_COUNT_RECONCILIATION_FAILED")
if all(isinstance(v, int) for v in [pending_count, running_count, completed_count, failed_count]):
    require(total_workflows == pending_count + running_count + completed_count + failed_count, "WORKFLOW_STATUS_COUNTER_RECONCILIATION_FAILED")
require(failed_count == 0, "FAILED_WORKFLOW_COUNT_NOT_ZERO")
require(sla_breached_count == 0, "SLA_BREACHED_COUNT_NOT_ZERO")

for idx, sample in enumerate(samples, start=1):
    prefix = f"WORKFLOW_SAMPLE_{idx}"
    require(sample.get("tenant_id") == tenant.get("tenant_id"), f"{prefix}_TENANT_MISMATCH")
    require(sample.get("status") in {"PENDING_APPROVAL", "RUNNING", "COMPLETED", "FAILED"}, f"{prefix}_STATUS_INVALID")
    require(sample.get("action_state") == "READ_ONLY_MONITOR", f"{prefix}_ACTION_NOT_READ_ONLY")
    require(non_empty(sample.get("workflow_id")), f"{prefix}_WORKFLOW_ID_REQUIRED")
    require(non_empty(sample.get("current_step")), f"{prefix}_CURRENT_STEP_REQUIRED")
    require(isinstance(sample.get("age_minutes"), int) and sample.get("age_minutes") >= 0, f"{prefix}_AGE_INVALID")
    require(sample.get("sla_status") == "ON_TRACK", f"{prefix}_SLA_NOT_ON_TRACK")

require("FAZ_4_17_2_WORKFLOW_MONITOR_UI_CHECKPOINT" in web_text, "WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in web_text, "WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_WORKFLOW_MUTATION" in web_text, "WEB_NO_WORKFLOW_MUTATION_MARKER_MISSING")
require("NO_REAL_WORKFLOW_EXECUTION" in web_text, "WEB_NO_REAL_WORKFLOW_EXECUTION_MARKER_MISSING")
require("NO_REALTIME_SOCKET_CONNECTION" in web_text, "WEB_NO_REALTIME_SOCKET_MARKER_MISSING")
require("Workflow Monitor" in web_text, "WEB_WORKFLOW_MONITOR_TITLE_MISSING")
require("Monitor only" in web_text, "WEB_MONITOR_ONLY_MARKER_MISSING")
require("Retry disabled" in web_text, "WEB_RETRY_DISABLED_MARKER_MISSING")
require("Cancel disabled" in web_text, "WEB_CANCEL_DISABLED_MARKER_MISSING")
require("Empty state ready" in web_text, "WEB_EMPTY_STATE_MARKER_MISSING")
require("Error state ready" in web_text, "WEB_ERROR_STATE_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and controls.get("no_workflow_mutation") is True:
    require(summary.get("workflow_monitor_result") == "PASS", "WORKFLOW_MONITOR_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("workflow_monitor_result") == "FAIL", "WORKFLOW_MONITOR_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "workflow_mutation", "real_workflow_execution", "realtime_socket_connection"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("WORKFLOW_MONITOR_STATUS=FAIL")
    print(f"WORKFLOW_MONITOR_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"WORKFLOW_MONITOR_FAIL={error}")
    sys.exit(1)

print("WORKFLOW_MONITOR_STATUS=PASS")
print(f"WORKFLOW_MONITOR_TENANT_ID={tenant.get('tenant_id')}")
print(f"WORKFLOW_MONITOR_TOTAL_ITEM_COUNT={total_item_count}")
print(f"WORKFLOW_MONITOR_READY_ITEM_COUNT={ready_count}")
print(f"WORKFLOW_MONITOR_MISSING_ITEM_COUNT={missing_count}")
print(f"WORKFLOW_MONITOR_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("WORKFLOW_MONITOR_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("APPROVAL_INBOX_STATUS=PASS")
print("WORKFLOW_SUMMARY_STATUS=READY")
print("STATUS_COUNTER_STATUS=READY")
print("SLA_INDICATOR_STATUS=READY")
print("WEB_CHECKPOINT_STATUS=READY")
print("FAILED_WORKFLOW_COUNT=0")
print("SLA_BREACHED_COUNT=0")
print("NO_WORKFLOW_MUTATION=true")
print("NO_REAL_WORKFLOW_EXECUTION=true")
print("NO_REALTIME_SOCKET_CONNECTION=true")
print("WORKFLOW_MONITOR_EXTERNAL_POLICY=CLOSED")
print(f"WORKFLOW_MONITOR_RESULT={summary.get('workflow_monitor_result')}")
PY_EOF
