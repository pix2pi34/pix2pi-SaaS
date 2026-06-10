#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_5_websocket_sse_baglanti_sagligi_gorunumu.v1.json}"
HEALTH_FILE="${HEALTH_FILE:-configs/faz4r/realtime_connection_health.controlled_pilot.v1.json}"
WEB_FILE="${WEB_FILE:-web/faz4r/realtime-health/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "REALTIME_CONNECTION_HEALTH_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$HEALTH_FILE" ]; then fail "HEALTH_FILE_NOT_FOUND"; fi
if [ ! -f "$WEB_FILE" ]; then fail "WEB_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$HEALTH_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$HEALTH_FILE" "$WEB_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 238, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("realtime_health_policy", {})
required_items = set(config.get("required_health_items", []))

require(payload.get("realtime_health_status") == policy.get("realtime_health_status_required"), "REALTIME_HEALTH_STATUS_NOT_READY")
require(payload.get("realtime_health_mode") == policy.get("realtime_health_mode_required"), "REALTIME_HEALTH_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("health_items", [])
controls = payload.get("health_controls", {})
metrics = payload.get("health_metrics", {})
summary = payload.get("summary", {})
samples = payload.get("connection_samples", [])
channels = payload.get("subscription_channels", [])
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "HEALTH_ITEMS_NOT_LIST")
require(isinstance(samples, list), "CONNECTION_SAMPLES_NOT_LIST")
require(isinstance(channels, list), "SUBSCRIPTION_CHANNELS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"HEALTH_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_HEALTH_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_HEALTH_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_HEALTH_ITEM_CODE_FOUND")

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
require(summary.get("workflow_monitor_status") == policy.get("workflow_monitor_status_required"), "WORKFLOW_MONITOR_STATUS_NOT_PASS")
require(summary.get("websocket_health_status") == policy.get("websocket_health_status_required"), "WEBSOCKET_HEALTH_STATUS_NOT_READY")
require(summary.get("sse_health_status") == policy.get("sse_health_status_required"), "SSE_HEALTH_STATUS_NOT_READY")
require(summary.get("connection_status_badge_status") == policy.get("connection_status_badge_status_required"), "CONNECTION_STATUS_BADGE_STATUS_NOT_READY")
require(summary.get("heartbeat_indicator_status") == policy.get("heartbeat_indicator_status_required"), "HEARTBEAT_INDICATOR_STATUS_NOT_READY")
require(summary.get("reconnect_indicator_status") == policy.get("reconnect_indicator_status_required"), "RECONNECT_INDICATOR_STATUS_NOT_READY")
require(summary.get("latency_indicator_status") == policy.get("latency_indicator_status_required"), "LATENCY_INDICATOR_STATUS_NOT_READY")
require(summary.get("web_checkpoint_status") == policy.get("web_checkpoint_status_required"), "WEB_CHECKPOINT_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("workflow_monitor_status") == "PASS", "CONTROL_WORKFLOW_MONITOR_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("websocket_health_status") == "READY", "CONTROL_WEBSOCKET_HEALTH_NOT_READY")
require(controls.get("sse_health_status") == "READY", "CONTROL_SSE_HEALTH_NOT_READY")
require(controls.get("connection_status_badge_status") == "READY", "CONTROL_CONNECTION_BADGE_NOT_READY")
require(controls.get("heartbeat_indicator_status") == "READY", "CONTROL_HEARTBEAT_INDICATOR_NOT_READY")
require(controls.get("reconnect_indicator_status") == "READY", "CONTROL_RECONNECT_INDICATOR_NOT_READY")
require(controls.get("latency_indicator_status") == "READY", "CONTROL_LATENCY_INDICATOR_NOT_READY")
require(controls.get("last_event_id_placeholder_status") == "READY", "CONTROL_LAST_EVENT_ID_NOT_READY")
require(controls.get("subscription_channel_list_status") == "READY", "CONTROL_CHANNEL_LIST_NOT_READY")
require(controls.get("event_feed_placeholder_status") == "READY", "CONTROL_EVENT_FEED_NOT_READY")
require(controls.get("notification_center_placeholder_status") == "READY", "CONTROL_NOTIFICATION_CENTER_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")
require(controls.get("web_checkpoint_status") == "READY", "CONTROL_WEB_CHECKPOINT_NOT_READY")

require(controls.get("no_live_websocket_connection") is policy.get("no_live_websocket_connection_required"), "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_live_sse_connection") is policy.get("no_live_sse_connection_required"), "LIVE_SSE_CONNECTION_NOT_DISABLED")
require(controls.get("no_event_stream_publish") is policy.get("no_event_stream_publish_required"), "EVENT_STREAM_PUBLISH_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("sample_connection_count") == len(samples), "SAMPLE_CONNECTION_COUNT_RECONCILIATION_FAILED")
require(metrics.get("active_websocket_connection_count") == 0, "ACTIVE_WEBSOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("active_sse_connection_count") == 0, "ACTIVE_SSE_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("event_stream_publish_count") == 0, "EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO")
require(metrics.get("reconnect_attempt_count") == 0, "RECONNECT_ATTEMPT_COUNT_NOT_ZERO")
require(metrics.get("failed_connection_count") == 0, "FAILED_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

require("workflow.status" in channels, "CHANNEL_WORKFLOW_STATUS_MISSING")
require("approval.inbox" in channels, "CHANNEL_APPROVAL_INBOX_MISSING")
require("event.feed" in channels, "CHANNEL_EVENT_FEED_MISSING")
require("notification.center" in channels, "CHANNEL_NOTIFICATION_CENTER_MISSING")

seen_transports = set()
for idx, sample in enumerate(samples, start=1):
    prefix = f"CONNECTION_SAMPLE_{idx}"
    transport = sample.get("transport")
    seen_transports.add(transport)
    require(sample.get("tenant_id") == tenant.get("tenant_id"), f"{prefix}_TENANT_MISMATCH")
    require(transport in {"WEBSOCKET", "SSE"}, f"{prefix}_TRANSPORT_INVALID")
    require(sample.get("status") == "PLACEHOLDER_READY", f"{prefix}_STATUS_NOT_PLACEHOLDER_READY")
    require(sample.get("connection_state") == "NOT_CONNECTED_PREVIEW_ONLY", f"{prefix}_STATE_NOT_PREVIEW_ONLY")
    require(isinstance(sample.get("heartbeat_age_seconds"), int) and sample.get("heartbeat_age_seconds") >= 0, f"{prefix}_HEARTBEAT_INVALID")
    require(isinstance(sample.get("latency_ms"), int) and sample.get("latency_ms") >= 0, f"{prefix}_LATENCY_INVALID")
    require(sample.get("reconnect_attempt_count") == 0, f"{prefix}_RECONNECT_NOT_ZERO")
    require(non_empty(sample.get("last_event_id")), f"{prefix}_LAST_EVENT_ID_REQUIRED")
    require(non_empty(sample.get("channel")), f"{prefix}_CHANNEL_REQUIRED")

require("WEBSOCKET" in seen_transports, "WEBSOCKET_SAMPLE_MISSING")
require("SSE" in seen_transports, "SSE_SAMPLE_MISSING")

require("FAZ_4_17_5_WEBSOCKET_SSE_HEALTH_UI_CHECKPOINT" in web_text, "WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in web_text, "WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_LIVE_WEBSOCKET_CONNECTION" in web_text, "WEB_NO_LIVE_WEBSOCKET_MARKER_MISSING")
require("NO_LIVE_SSE_CONNECTION" in web_text, "WEB_NO_LIVE_SSE_MARKER_MISSING")
require("NO_EVENT_STREAM_PUBLISH" in web_text, "WEB_NO_EVENT_STREAM_MARKER_MISSING")
require("WebSocket / SSE Health" in web_text, "WEB_REALTIME_HEALTH_TITLE_MISSING")
require("PLACEHOLDER READY" in web_text, "WEB_PLACEHOLDER_READY_MARKER_MISSING")
require("NOT CONNECTED PREVIEW ONLY" in web_text, "WEB_NOT_CONNECTED_MARKER_MISSING")
require("workflow.status" in web_text, "WEB_WORKFLOW_CHANNEL_MARKER_MISSING")
require("notification.center" in web_text, "WEB_NOTIFICATION_CHANNEL_MARKER_MISSING")
require("Empty state ready" in web_text, "WEB_EMPTY_STATE_MARKER_MISSING")
require("Error state ready" in web_text, "WEB_ERROR_STATE_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and controls.get("no_live_websocket_connection") is True and controls.get("no_live_sse_connection") is True:
    require(summary.get("realtime_health_result") == "PASS", "REALTIME_HEALTH_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("realtime_health_result") == "FAIL", "REALTIME_HEALTH_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "live_websocket_connection", "live_sse_connection", "event_stream_publish"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("REALTIME_CONNECTION_HEALTH_STATUS=FAIL")
    print(f"REALTIME_CONNECTION_HEALTH_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"REALTIME_CONNECTION_HEALTH_FAIL={error}")
    sys.exit(1)

print("REALTIME_CONNECTION_HEALTH_STATUS=PASS")
print(f"REALTIME_CONNECTION_HEALTH_TENANT_ID={tenant.get('tenant_id')}")
print(f"REALTIME_CONNECTION_HEALTH_TOTAL_ITEM_COUNT={total_item_count}")
print(f"REALTIME_CONNECTION_HEALTH_READY_ITEM_COUNT={ready_count}")
print(f"REALTIME_CONNECTION_HEALTH_MISSING_ITEM_COUNT={missing_count}")
print(f"REALTIME_CONNECTION_HEALTH_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("REALTIME_CONNECTION_HEALTH_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("WORKFLOW_MONITOR_STATUS=PASS")
print("WEBSOCKET_HEALTH_STATUS=READY")
print("SSE_HEALTH_STATUS=READY")
print("CONNECTION_STATUS_BADGE_STATUS=READY")
print("HEARTBEAT_INDICATOR_STATUS=READY")
print("RECONNECT_INDICATOR_STATUS=READY")
print("LATENCY_INDICATOR_STATUS=READY")
print("WEB_CHECKPOINT_STATUS=READY")
print("ACTIVE_WEBSOCKET_CONNECTION_COUNT=0")
print("ACTIVE_SSE_CONNECTION_COUNT=0")
print("EVENT_STREAM_PUBLISH_COUNT=0")
print("NO_LIVE_WEBSOCKET_CONNECTION=true")
print("NO_LIVE_SSE_CONNECTION=true")
print("NO_EVENT_STREAM_PUBLISH=true")
print("REALTIME_CONNECTION_HEALTH_EXTERNAL_POLICY=CLOSED")
print(f"REALTIME_CONNECTION_HEALTH_RESULT={summary.get('realtime_health_result')}")
PY_EOF
