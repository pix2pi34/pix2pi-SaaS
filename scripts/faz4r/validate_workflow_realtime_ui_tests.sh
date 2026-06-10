#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_6_workflow_realtime_ui_testleri.v1.json}"
UI_TEST_FILE="${UI_TEST_FILE:-configs/faz4r/workflow_realtime_ui_tests.controlled_pilot.v1.json}"
APPROVAL_WEB="${APPROVAL_WEB:-web/faz4r/approval-inbox/index.html}"
MONITOR_WEB="${MONITOR_WEB:-web/faz4r/workflow-monitor/index.html}"
REALTIME_WEB="${REALTIME_WEB:-web/faz4r/realtime-health/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "WORKFLOW_REALTIME_UI_TEST_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$UI_TEST_FILE" ]; then fail "UI_TEST_FILE_NOT_FOUND"; fi
if [ ! -f "$APPROVAL_WEB" ]; then fail "APPROVAL_WEB_NOT_FOUND"; fi
if [ ! -f "$MONITOR_WEB" ]; then fail "MONITOR_WEB_NOT_FOUND"; fi
if [ ! -f "$REALTIME_WEB" ]; then fail "REALTIME_WEB_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$UI_TEST_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$UI_TEST_FILE" "$APPROVAL_WEB" "$MONITOR_WEB" "$REALTIME_WEB" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
approval_web = Path(sys.argv[3]).read_text()
monitor_web = Path(sys.argv[4]).read_text()
realtime_web = Path(sys.argv[5]).read_text()
payload = json.loads(Path(sys.argv[6]).read_text())
errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 239, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_6", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("ui_test_policy", {})
required_items = set(config.get("required_test_items", []))

require(payload.get("workflow_realtime_ui_test_status") == policy.get("workflow_realtime_ui_test_status_required"), "WORKFLOW_REALTIME_UI_TEST_STATUS_NOT_READY")
require(payload.get("workflow_realtime_ui_test_mode") == policy.get("workflow_realtime_ui_test_mode_required"), "WORKFLOW_REALTIME_UI_TEST_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("test_items", [])
controls = payload.get("ui_test_controls", {})
metrics = payload.get("ui_test_metrics", {})
summary = payload.get("summary", {})
surfaces = payload.get("ui_surfaces", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "TEST_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"TEST_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_TEST_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_TEST_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_TEST_ITEM_CODE_FOUND")

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

require(summary.get("approval_inbox_status") == policy.get("approval_inbox_status_required"), "APPROVAL_INBOX_STATUS_NOT_PASS")
require(summary.get("workflow_monitor_status") == policy.get("workflow_monitor_status_required"), "WORKFLOW_MONITOR_STATUS_NOT_PASS")
require(summary.get("realtime_health_status") == policy.get("realtime_health_status_required"), "REALTIME_HEALTH_STATUS_NOT_PASS")
require(summary.get("tenant_scope") == policy.get("tenant_scope_required"), "SUMMARY_TENANT_SCOPE_INVALID")
require(summary.get("approval_web_checkpoint_status") == policy.get("approval_web_checkpoint_status_required"), "APPROVAL_WEB_CHECKPOINT_NOT_PASS")
require(summary.get("workflow_web_checkpoint_status") == policy.get("workflow_web_checkpoint_status_required"), "WORKFLOW_WEB_CHECKPOINT_NOT_PASS")
require(summary.get("realtime_web_checkpoint_status") == policy.get("realtime_web_checkpoint_status_required"), "REALTIME_WEB_CHECKPOINT_NOT_PASS")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("approval_inbox_status") == "PASS", "CONTROL_APPROVAL_INBOX_NOT_PASS")
require(controls.get("workflow_monitor_status") == "PASS", "CONTROL_WORKFLOW_MONITOR_NOT_PASS")
require(controls.get("realtime_health_status") == "PASS", "CONTROL_REALTIME_HEALTH_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("approval_web_checkpoint_status") == "PASS", "CONTROL_APPROVAL_WEB_NOT_PASS")
require(controls.get("workflow_web_checkpoint_status") == "PASS", "CONTROL_WORKFLOW_WEB_NOT_PASS")
require(controls.get("realtime_web_checkpoint_status") == "PASS", "CONTROL_REALTIME_WEB_NOT_PASS")
require(controls.get("cross_navigation_status") == "READY", "CONTROL_CROSS_NAVIGATION_NOT_READY")
require(controls.get("status_badge_status") == "READY", "CONTROL_STATUS_BADGE_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")

require(controls.get("no_workflow_mutation") is policy.get("no_workflow_mutation_required"), "WORKFLOW_MUTATION_NOT_DISABLED")
require(controls.get("no_real_approval_execution") is policy.get("no_real_approval_execution_required"), "REAL_APPROVAL_EXECUTION_NOT_DISABLED")
require(controls.get("no_real_workflow_execution") is policy.get("no_real_workflow_execution_required"), "REAL_WORKFLOW_EXECUTION_NOT_DISABLED")
require(controls.get("no_live_websocket_connection") is policy.get("no_live_websocket_connection_required"), "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_live_sse_connection") is policy.get("no_live_sse_connection_required"), "LIVE_SSE_CONNECTION_NOT_DISABLED")
require(controls.get("no_event_stream_publish") is policy.get("no_event_stream_publish_required"), "EVENT_STREAM_PUBLISH_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("ui_surface_count") == 3, "UI_SURFACE_COUNT_INVALID")
require(metrics.get("ui_surface_pass_count") == 3, "UI_SURFACE_PASS_COUNT_INVALID")
require(metrics.get("workflow_mutation_count") == 0, "WORKFLOW_MUTATION_COUNT_NOT_ZERO")
require(metrics.get("real_approval_execution_count") == 0, "REAL_APPROVAL_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("real_workflow_execution_count") == 0, "REAL_WORKFLOW_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("active_websocket_connection_count") == 0, "ACTIVE_WEBSOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("active_sse_connection_count") == 0, "ACTIVE_SSE_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("event_stream_publish_count") == 0, "EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

surface_text = {
    "approval_inbox": approval_web,
    "workflow_monitor": monitor_web,
    "realtime_health": realtime_web
}

for surface_name, surface in surfaces.items():
    require(surface.get("status") == "PASS", f"SURFACE_{surface_name.upper()}_STATUS_NOT_PASS")
    markers = surface.get("required_markers", [])
    require(isinstance(markers, list) and len(markers) > 0, f"SURFACE_{surface_name.upper()}_MARKERS_INVALID")
    text = surface_text.get(surface_name, "")
    for marker in markers:
        require(marker in text, f"SURFACE_{surface_name.upper()}_MARKER_MISSING:{marker}")

require("FAZ_4_17_1_APPROVAL_INBOX_UI_CHECKPOINT" in approval_web, "APPROVAL_WEB_UI_CHECKPOINT_MARKER_MISSING")
require("FAZ_4_17_2_WORKFLOW_MONITOR_UI_CHECKPOINT" in monitor_web, "WORKFLOW_WEB_UI_CHECKPOINT_MARKER_MISSING")
require("FAZ_4_17_5_WEBSOCKET_SSE_HEALTH_UI_CHECKPOINT" in realtime_web, "REALTIME_WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in approval_web, "APPROVAL_WEB_CLOSED_POLICY_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in monitor_web, "WORKFLOW_WEB_CLOSED_POLICY_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in realtime_web, "REALTIME_WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_WORKFLOW_MUTATION" in approval_web, "APPROVAL_WEB_NO_MUTATION_MARKER_MISSING")
require("NO_REAL_APPROVAL_EXECUTION" in approval_web, "APPROVAL_WEB_NO_APPROVAL_MARKER_MISSING")
require("NO_REAL_WORKFLOW_EXECUTION" in monitor_web, "WORKFLOW_WEB_NO_EXECUTION_MARKER_MISSING")
require("NO_LIVE_WEBSOCKET_CONNECTION" in realtime_web, "REALTIME_WEB_NO_WEBSOCKET_MARKER_MISSING")
require("NO_LIVE_SSE_CONNECTION" in realtime_web, "REALTIME_WEB_NO_SSE_MARKER_MISSING")
require("NO_EVENT_STREAM_PUBLISH" in realtime_web, "REALTIME_WEB_NO_EVENT_PUBLISH_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and metrics.get("ui_surface_pass_count") == 3:
    require(summary.get("workflow_realtime_ui_test_result") == "PASS", "WORKFLOW_REALTIME_UI_TEST_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("workflow_realtime_ui_test_result") == "FAIL", "WORKFLOW_REALTIME_UI_TEST_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "workflow_mutation", "real_approval_execution",
    "real_workflow_execution", "live_websocket_connection", "live_sse_connection", "event_stream_publish"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("WORKFLOW_REALTIME_UI_TEST_STATUS=FAIL")
    print(f"WORKFLOW_REALTIME_UI_TEST_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"WORKFLOW_REALTIME_UI_TEST_FAIL={error}")
    sys.exit(1)

print("WORKFLOW_REALTIME_UI_TEST_STATUS=PASS")
print(f"WORKFLOW_REALTIME_UI_TEST_TENANT_ID={tenant.get('tenant_id')}")
print(f"WORKFLOW_REALTIME_UI_TEST_TOTAL_ITEM_COUNT={total_item_count}")
print(f"WORKFLOW_REALTIME_UI_TEST_READY_ITEM_COUNT={ready_count}")
print(f"WORKFLOW_REALTIME_UI_TEST_MISSING_ITEM_COUNT={missing_count}")
print(f"WORKFLOW_REALTIME_UI_TEST_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("WORKFLOW_REALTIME_UI_TEST_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("APPROVAL_INBOX_STATUS=PASS")
print("WORKFLOW_MONITOR_STATUS=PASS")
print("REALTIME_HEALTH_STATUS=PASS")
print("APPROVAL_WEB_CHECKPOINT_STATUS=PASS")
print("WORKFLOW_WEB_CHECKPOINT_STATUS=PASS")
print("REALTIME_WEB_CHECKPOINT_STATUS=PASS")
print("NO_WORKFLOW_MUTATION=true")
print("NO_REAL_APPROVAL_EXECUTION=true")
print("NO_REAL_WORKFLOW_EXECUTION=true")
print("NO_LIVE_WEBSOCKET_CONNECTION=true")
print("NO_LIVE_SSE_CONNECTION=true")
print("NO_EVENT_STREAM_PUBLISH=true")
print("WORKFLOW_REALTIME_UI_TEST_EXTERNAL_POLICY=CLOSED")
print(f"WORKFLOW_REALTIME_UI_TEST_RESULT={summary.get('workflow_realtime_ui_test_result')}")
PY_EOF
