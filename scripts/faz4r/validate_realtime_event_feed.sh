#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_3_realtime_event_feed.v1.json}"
FEED_FILE="${FEED_FILE:-configs/faz4r/realtime_event_feed.controlled_pilot.v1.json}"
WEB_FILE="${WEB_FILE:-web/faz4r/realtime-event-feed/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "REALTIME_EVENT_FEED_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$FEED_FILE" ]; then fail "FEED_FILE_NOT_FOUND"; fi
if [ ! -f "$WEB_FILE" ]; then fail "WEB_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$FEED_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$FEED_FILE" "$WEB_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 240, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("realtime_event_feed_policy", {})
required_items = set(config.get("required_feed_items", []))

require(payload.get("realtime_event_feed_status") == policy.get("realtime_event_feed_status_required"), "REALTIME_EVENT_FEED_STATUS_NOT_READY")
require(payload.get("realtime_event_feed_mode") == policy.get("realtime_event_feed_mode_required"), "REALTIME_EVENT_FEED_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("feed_items", [])
controls = payload.get("feed_controls", {})
metrics = payload.get("feed_metrics", {})
summary = payload.get("summary", {})
samples = payload.get("event_samples", [])
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "FEED_ITEMS_NOT_LIST")
require(isinstance(samples, list), "EVENT_SAMPLES_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"FEED_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_FEED_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_FEED_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_FEED_ITEM_CODE_FOUND")

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
require(summary.get("workflow_realtime_ui_test_status") == policy.get("workflow_realtime_ui_test_status_required"), "WORKFLOW_REALTIME_UI_TEST_STATUS_NOT_PASS")
require(summary.get("event_timeline_status") == policy.get("event_timeline_status_required"), "EVENT_TIMELINE_STATUS_NOT_READY")
require(summary.get("severity_badge_status") == policy.get("severity_badge_status_required"), "SEVERITY_BADGE_STATUS_NOT_READY")
require(summary.get("channel_badge_status") == policy.get("channel_badge_status_required"), "CHANNEL_BADGE_STATUS_NOT_READY")
require(summary.get("web_checkpoint_status") == policy.get("web_checkpoint_status_required"), "WEB_CHECKPOINT_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("workflow_realtime_ui_test_status") == "PASS", "CONTROL_WORKFLOW_REALTIME_UI_TEST_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("event_timeline_status") == "READY", "CONTROL_EVENT_TIMELINE_NOT_READY")
require(controls.get("event_metadata_status") == "READY", "CONTROL_EVENT_METADATA_NOT_READY")
require(controls.get("severity_badge_status") == "READY", "CONTROL_SEVERITY_BADGE_NOT_READY")
require(controls.get("channel_badge_status") == "READY", "CONTROL_CHANNEL_BADGE_NOT_READY")
require(controls.get("source_label_status") == "READY", "CONTROL_SOURCE_LABEL_NOT_READY")
require(controls.get("correlation_id_placeholder_status") == "READY", "CONTROL_CORRELATION_ID_NOT_READY")
require(controls.get("workflow_monitor_link_status") == "READY", "CONTROL_WORKFLOW_MONITOR_LINK_NOT_READY")
require(controls.get("realtime_health_link_status") == "READY", "CONTROL_REALTIME_HEALTH_LINK_NOT_READY")
require(controls.get("notification_center_placeholder_status") == "READY", "CONTROL_NOTIFICATION_CENTER_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")
require(controls.get("web_checkpoint_status") == "READY", "CONTROL_WEB_CHECKPOINT_NOT_READY")

require(controls.get("no_event_stream_publish") is policy.get("no_event_stream_publish_required"), "EVENT_STREAM_PUBLISH_NOT_DISABLED")
require(controls.get("no_event_stream_subscribe") is policy.get("no_event_stream_subscribe_required"), "EVENT_STREAM_SUBSCRIBE_NOT_DISABLED")
require(controls.get("no_live_websocket_connection") is policy.get("no_live_websocket_connection_required"), "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_live_sse_connection") is policy.get("no_live_sse_connection_required"), "LIVE_SSE_CONNECTION_NOT_DISABLED")
require(controls.get("no_workflow_mutation") is policy.get("no_workflow_mutation_required"), "WORKFLOW_MUTATION_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("sample_event_count") == len(samples), "SAMPLE_EVENT_COUNT_RECONCILIATION_FAILED")
require(metrics.get("event_stream_publish_count") == 0, "EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO")
require(metrics.get("event_stream_subscribe_count") == 0, "EVENT_STREAM_SUBSCRIBE_COUNT_NOT_ZERO")
require(metrics.get("active_websocket_connection_count") == 0, "ACTIVE_WEBSOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("active_sse_connection_count") == 0, "ACTIVE_SSE_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("workflow_mutation_count") == 0, "WORKFLOW_MUTATION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

seen_channels = set()
seen_severity = set()
for idx, sample in enumerate(samples, start=1):
    prefix = f"EVENT_SAMPLE_{idx}"
    seen_channels.add(sample.get("channel"))
    seen_severity.add(sample.get("severity"))
    require(sample.get("tenant_id") == tenant.get("tenant_id"), f"{prefix}_TENANT_MISMATCH")
    require(non_empty(sample.get("event_id")), f"{prefix}_EVENT_ID_REQUIRED")
    require(sample.get("status") == "READ_ONLY_SAMPLE", f"{prefix}_STATUS_NOT_READ_ONLY")
    require(sample.get("severity") in {"INFO", "WARN", "ERROR"}, f"{prefix}_SEVERITY_INVALID")
    require(sample.get("channel") in {"workflow.status", "approval.inbox", "notification.center", "event.feed"}, f"{prefix}_CHANNEL_INVALID")
    require(non_empty(sample.get("source")), f"{prefix}_SOURCE_REQUIRED")
    require(non_empty(sample.get("correlation_id")), f"{prefix}_CORRELATION_ID_REQUIRED")
    require(non_empty(sample.get("event_time")), f"{prefix}_EVENT_TIME_REQUIRED")

require("workflow.status" in seen_channels, "WORKFLOW_STATUS_CHANNEL_MISSING")
require("approval.inbox" in seen_channels, "APPROVAL_INBOX_CHANNEL_MISSING")
require("notification.center" in seen_channels, "NOTIFICATION_CENTER_CHANNEL_MISSING")
require("INFO" in seen_severity, "INFO_SEVERITY_MISSING")
require("WARN" in seen_severity, "WARN_SEVERITY_MISSING")

require("FAZ_4_17_3_REALTIME_EVENT_FEED_UI_CHECKPOINT" in web_text, "WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in web_text, "WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_EVENT_STREAM_PUBLISH" in web_text, "WEB_NO_EVENT_PUBLISH_MARKER_MISSING")
require("NO_EVENT_STREAM_SUBSCRIBE" in web_text, "WEB_NO_EVENT_SUBSCRIBE_MARKER_MISSING")
require("NO_LIVE_WEBSOCKET_CONNECTION" in web_text, "WEB_NO_WEBSOCKET_MARKER_MISSING")
require("NO_LIVE_SSE_CONNECTION" in web_text, "WEB_NO_SSE_MARKER_MISSING")
require("NO_WORKFLOW_MUTATION" in web_text, "WEB_NO_WORKFLOW_MUTATION_MARKER_MISSING")
require("Realtime Event Feed" in web_text, "WEB_REALTIME_EVENT_FEED_TITLE_MISSING")
require("READ_ONLY_SAMPLE" in web_text, "WEB_READ_ONLY_SAMPLE_MARKER_MISSING")
require("workflow.status" in web_text, "WEB_WORKFLOW_CHANNEL_MARKER_MISSING")
require("approval.inbox" in web_text, "WEB_APPROVAL_CHANNEL_MARKER_MISSING")
require("notification.center" in web_text, "WEB_NOTIFICATION_CHANNEL_MARKER_MISSING")
require("Empty state ready" in web_text, "WEB_EMPTY_STATE_MARKER_MISSING")
require("Error state ready" in web_text, "WEB_ERROR_STATE_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and metrics.get("sample_event_count") == len(samples):
    require(summary.get("realtime_event_feed_result") == "PASS", "REALTIME_EVENT_FEED_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("realtime_event_feed_result") == "FAIL", "REALTIME_EVENT_FEED_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "workflow_mutation", "event_stream_publish",
    "event_stream_subscribe", "live_websocket_connection", "live_sse_connection"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("REALTIME_EVENT_FEED_STATUS=FAIL")
    print(f"REALTIME_EVENT_FEED_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"REALTIME_EVENT_FEED_FAIL={error}")
    sys.exit(1)

print("REALTIME_EVENT_FEED_STATUS=PASS")
print(f"REALTIME_EVENT_FEED_TENANT_ID={tenant.get('tenant_id')}")
print(f"REALTIME_EVENT_FEED_TOTAL_ITEM_COUNT={total_item_count}")
print(f"REALTIME_EVENT_FEED_READY_ITEM_COUNT={ready_count}")
print(f"REALTIME_EVENT_FEED_MISSING_ITEM_COUNT={missing_count}")
print(f"REALTIME_EVENT_FEED_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("REALTIME_EVENT_FEED_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("WORKFLOW_REALTIME_UI_TEST_STATUS=PASS")
print("EVENT_TIMELINE_STATUS=READY")
print("SEVERITY_BADGE_STATUS=READY")
print("CHANNEL_BADGE_STATUS=READY")
print("WEB_CHECKPOINT_STATUS=READY")
print("EVENT_STREAM_PUBLISH_COUNT=0")
print("EVENT_STREAM_SUBSCRIBE_COUNT=0")
print("ACTIVE_WEBSOCKET_CONNECTION_COUNT=0")
print("ACTIVE_SSE_CONNECTION_COUNT=0")
print("NO_EVENT_STREAM_PUBLISH=true")
print("NO_EVENT_STREAM_SUBSCRIBE=true")
print("NO_LIVE_WEBSOCKET_CONNECTION=true")
print("NO_LIVE_SSE_CONNECTION=true")
print("REALTIME_EVENT_FEED_EXTERNAL_POLICY=CLOSED")
print(f"REALTIME_EVENT_FEED_RESULT={summary.get('realtime_event_feed_result')}")
PY_EOF
