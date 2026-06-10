#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_17_4_canli_bildirim_merkezi.v1.json}"
CENTER_FILE="${CENTER_FILE:-configs/faz4r/notification_center.controlled_pilot.v1.json}"
WEB_FILE="${WEB_FILE:-web/faz4r/notification-center/index.html}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "NOTIFICATION_CENTER_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$CENTER_FILE" ]; then fail "CENTER_FILE_NOT_FOUND"; fi
if [ ! -f "$WEB_FILE" ]; then fail "WEB_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$CENTER_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$CENTER_FILE" "$WEB_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 241, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_17_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("notification_center_policy", {})
required_items = set(config.get("required_notification_items", []))

require(payload.get("notification_center_status") == policy.get("notification_center_status_required"), "NOTIFICATION_CENTER_STATUS_NOT_READY")
require(payload.get("notification_center_mode") == policy.get("notification_center_mode_required"), "NOTIFICATION_CENTER_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("notification_items", [])
controls = payload.get("notification_controls", {})
metrics = payload.get("notification_metrics", {})
summary = payload.get("summary", {})
samples = payload.get("notification_samples", [])
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "NOTIFICATION_ITEMS_NOT_LIST")
require(isinstance(samples, list), "NOTIFICATION_SAMPLES_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"NOTIFICATION_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_NOTIFICATION_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_NOTIFICATION_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_NOTIFICATION_ITEM_CODE_FOUND")

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
require(summary.get("realtime_event_feed_status") == policy.get("realtime_event_feed_status_required"), "REALTIME_EVENT_FEED_STATUS_NOT_PASS")
require(summary.get("notification_list_status") == policy.get("notification_list_status_required"), "NOTIFICATION_LIST_STATUS_NOT_READY")
require(summary.get("unread_counter_status") == policy.get("unread_counter_status_required"), "UNREAD_COUNTER_STATUS_NOT_READY")
require(summary.get("read_state_placeholder_status") == policy.get("read_state_placeholder_status_required"), "READ_STATE_PLACEHOLDER_STATUS_NOT_READY")
require(summary.get("severity_badge_status") == policy.get("severity_badge_status_required"), "SEVERITY_BADGE_STATUS_NOT_READY")
require(summary.get("channel_badge_status") == policy.get("channel_badge_status_required"), "CHANNEL_BADGE_STATUS_NOT_READY")
require(summary.get("web_checkpoint_status") == policy.get("web_checkpoint_status_required"), "WEB_CHECKPOINT_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("realtime_event_feed_status") == "PASS", "CONTROL_REALTIME_EVENT_FEED_NOT_PASS")
require(controls.get("tenant_scope") == "SINGLE_TENANT", "CONTROL_TENANT_SCOPE_INVALID")
require(controls.get("notification_list_status") == "READY", "CONTROL_NOTIFICATION_LIST_NOT_READY")
require(controls.get("notification_metadata_status") == "READY", "CONTROL_NOTIFICATION_METADATA_NOT_READY")
require(controls.get("unread_counter_status") == "READY", "CONTROL_UNREAD_COUNTER_NOT_READY")
require(controls.get("read_state_placeholder_status") == "READY", "CONTROL_READ_STATE_NOT_READY")
require(controls.get("severity_badge_status") == "READY", "CONTROL_SEVERITY_BADGE_NOT_READY")
require(controls.get("channel_badge_status") == "READY", "CONTROL_CHANNEL_BADGE_NOT_READY")
require(controls.get("delivery_preference_placeholder_status") == "READY", "CONTROL_DELIVERY_PREFERENCE_NOT_READY")
require(controls.get("event_feed_link_status") == "READY", "CONTROL_EVENT_FEED_LINK_NOT_READY")
require(controls.get("workflow_monitor_link_status") == "READY", "CONTROL_WORKFLOW_MONITOR_LINK_NOT_READY")
require(controls.get("realtime_health_link_status") == "READY", "CONTROL_REALTIME_HEALTH_LINK_NOT_READY")
require(controls.get("empty_state_status") == "READY", "CONTROL_EMPTY_STATE_NOT_READY")
require(controls.get("error_state_status") == "READY", "CONTROL_ERROR_STATE_NOT_READY")
require(controls.get("web_checkpoint_status") == "READY", "CONTROL_WEB_CHECKPOINT_NOT_READY")

require(controls.get("no_push_delivery") is policy.get("no_push_delivery_required"), "PUSH_DELIVERY_NOT_DISABLED")
require(controls.get("no_email_delivery") is policy.get("no_email_delivery_required"), "EMAIL_DELIVERY_NOT_DISABLED")
require(controls.get("no_sms_delivery") is policy.get("no_sms_delivery_required"), "SMS_DELIVERY_NOT_DISABLED")
require(controls.get("no_live_websocket_connection") is policy.get("no_live_websocket_connection_required"), "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED")
require(controls.get("no_live_sse_connection") is policy.get("no_live_sse_connection_required"), "LIVE_SSE_CONNECTION_NOT_DISABLED")
require(controls.get("no_event_stream_subscribe") is policy.get("no_event_stream_subscribe_required"), "EVENT_STREAM_SUBSCRIBE_NOT_DISABLED")
require(controls.get("no_event_stream_publish") is policy.get("no_event_stream_publish_required"), "EVENT_STREAM_PUBLISH_NOT_DISABLED")
require(controls.get("no_notification_mutation") is policy.get("no_notification_mutation_required"), "NOTIFICATION_MUTATION_NOT_DISABLED")
require(controls.get("no_production_launch") is True, "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("total_item_count") == len(items), "METRIC_TOTAL_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("ready_item_count") == ready_count, "METRIC_READY_ITEM_COUNT_RECONCILIATION_FAILED")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("sample_notification_count") == len(samples), "SAMPLE_NOTIFICATION_COUNT_RECONCILIATION_FAILED")
require(metrics.get("unread_count") == sum(1 for s in samples if s.get("read_state") == "UNREAD_PLACEHOLDER"), "UNREAD_COUNT_RECONCILIATION_FAILED")
require(metrics.get("push_delivery_count") == 0, "PUSH_DELIVERY_COUNT_NOT_ZERO")
require(metrics.get("email_delivery_count") == 0, "EMAIL_DELIVERY_COUNT_NOT_ZERO")
require(metrics.get("sms_delivery_count") == 0, "SMS_DELIVERY_COUNT_NOT_ZERO")
require(metrics.get("active_websocket_connection_count") == 0, "ACTIVE_WEBSOCKET_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("active_sse_connection_count") == 0, "ACTIVE_SSE_CONNECTION_COUNT_NOT_ZERO")
require(metrics.get("event_stream_subscribe_count") == 0, "EVENT_STREAM_SUBSCRIBE_COUNT_NOT_ZERO")
require(metrics.get("event_stream_publish_count") == 0, "EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO")
require(metrics.get("notification_mutation_count") == 0, "NOTIFICATION_MUTATION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

seen_channels = set()
seen_severity = set()
seen_read_state = set()
for idx, sample in enumerate(samples, start=1):
    prefix = f"NOTIFICATION_SAMPLE_{idx}"
    seen_channels.add(sample.get("channel"))
    seen_severity.add(sample.get("severity"))
    seen_read_state.add(sample.get("read_state"))
    require(sample.get("tenant_id") == tenant.get("tenant_id"), f"{prefix}_TENANT_MISMATCH")
    require(non_empty(sample.get("notification_id")), f"{prefix}_NOTIFICATION_ID_REQUIRED")
    require(sample.get("severity") in {"INFO", "WARN", "ERROR"}, f"{prefix}_SEVERITY_INVALID")
    require(sample.get("channel") in {"workflow.status", "approval.inbox", "notification.center", "event.feed"}, f"{prefix}_CHANNEL_INVALID")
    require(sample.get("read_state") in {"UNREAD_PLACEHOLDER", "READ_PLACEHOLDER"}, f"{prefix}_READ_STATE_INVALID")
    require(sample.get("delivery_state") == "NOT_DELIVERED_PREVIEW_ONLY", f"{prefix}_DELIVERY_NOT_PREVIEW_ONLY")
    require(non_empty(sample.get("source_event_id")), f"{prefix}_SOURCE_EVENT_ID_REQUIRED")
    require(non_empty(sample.get("correlation_id")), f"{prefix}_CORRELATION_ID_REQUIRED")

require("workflow.status" in seen_channels, "WORKFLOW_STATUS_CHANNEL_MISSING")
require("approval.inbox" in seen_channels, "APPROVAL_INBOX_CHANNEL_MISSING")
require("notification.center" in seen_channels, "NOTIFICATION_CENTER_CHANNEL_MISSING")
require("INFO" in seen_severity, "INFO_SEVERITY_MISSING")
require("WARN" in seen_severity, "WARN_SEVERITY_MISSING")
require("UNREAD_PLACEHOLDER" in seen_read_state, "UNREAD_PLACEHOLDER_MISSING")
require("READ_PLACEHOLDER" in seen_read_state, "READ_PLACEHOLDER_MISSING")

require("FAZ_4_17_4_NOTIFICATION_CENTER_UI_CHECKPOINT" in web_text, "WEB_UI_CHECKPOINT_MARKER_MISSING")
require("CLOSED_POLICY_GATE_REFERENCE_ONLY" in web_text, "WEB_CLOSED_POLICY_MARKER_MISSING")
require("NO_PUSH_DELIVERY" in web_text, "WEB_NO_PUSH_MARKER_MISSING")
require("NO_EMAIL_DELIVERY" in web_text, "WEB_NO_EMAIL_MARKER_MISSING")
require("NO_SMS_DELIVERY" in web_text, "WEB_NO_SMS_MARKER_MISSING")
require("NO_LIVE_WEBSOCKET_CONNECTION" in web_text, "WEB_NO_WEBSOCKET_MARKER_MISSING")
require("NO_LIVE_SSE_CONNECTION" in web_text, "WEB_NO_SSE_MARKER_MISSING")
require("NO_EVENT_STREAM_SUBSCRIBE" in web_text, "WEB_NO_SUBSCRIBE_MARKER_MISSING")
require("NO_EVENT_STREAM_PUBLISH" in web_text, "WEB_NO_PUBLISH_MARKER_MISSING")
require("NO_NOTIFICATION_MUTATION" in web_text, "WEB_NO_NOTIFICATION_MUTATION_MARKER_MISSING")
require("Canlı Bildirim Merkezi" in web_text, "WEB_NOTIFICATION_CENTER_TITLE_MISSING")
require("UNREAD_PLACEHOLDER" in web_text, "WEB_UNREAD_PLACEHOLDER_MISSING")
require("READ_PLACEHOLDER" in web_text, "WEB_READ_PLACEHOLDER_MISSING")
require("NOT_DELIVERED_PREVIEW_ONLY" in web_text, "WEB_NOT_DELIVERED_MARKER_MISSING")
require("Empty state ready" in web_text, "WEB_EMPTY_STATE_MARKER_MISSING")
require("Error state ready" in web_text, "WEB_ERROR_STATE_MARKER_MISSING")

if missing_count == 0 and required_fail_count == 0 and metrics.get("sample_notification_count") == len(samples):
    require(summary.get("notification_center_result") == "PASS", "NOTIFICATION_CENTER_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("notification_center_result") == "FAIL", "NOTIFICATION_CENTER_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "push_delivery", "email_delivery", "sms_delivery",
    "live_websocket_connection", "live_sse_connection", "event_stream_subscribe",
    "event_stream_publish", "notification_mutation"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("NOTIFICATION_CENTER_STATUS=FAIL")
    print(f"NOTIFICATION_CENTER_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"NOTIFICATION_CENTER_FAIL={error}")
    sys.exit(1)

print("NOTIFICATION_CENTER_STATUS=PASS")
print(f"NOTIFICATION_CENTER_TENANT_ID={tenant.get('tenant_id')}")
print(f"NOTIFICATION_CENTER_TOTAL_ITEM_COUNT={total_item_count}")
print(f"NOTIFICATION_CENTER_READY_ITEM_COUNT={ready_count}")
print(f"NOTIFICATION_CENTER_MISSING_ITEM_COUNT={missing_count}")
print(f"NOTIFICATION_CENTER_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("NOTIFICATION_CENTER_MODE=CONTROLLED_PILOT")
print("TENANT_SCOPE=SINGLE_TENANT")
print("REALTIME_EVENT_FEED_STATUS=PASS")
print("NOTIFICATION_LIST_STATUS=READY")
print("UNREAD_COUNTER_STATUS=READY")
print("READ_STATE_PLACEHOLDER_STATUS=READY")
print("SEVERITY_BADGE_STATUS=READY")
print("CHANNEL_BADGE_STATUS=READY")
print("WEB_CHECKPOINT_STATUS=READY")
print("PUSH_DELIVERY_COUNT=0")
print("EMAIL_DELIVERY_COUNT=0")
print("SMS_DELIVERY_COUNT=0")
print("EVENT_STREAM_SUBSCRIBE_COUNT=0")
print("EVENT_STREAM_PUBLISH_COUNT=0")
print("NO_PUSH_DELIVERY=true")
print("NO_EMAIL_DELIVERY=true")
print("NO_SMS_DELIVERY=true")
print("NO_LIVE_WEBSOCKET_CONNECTION=true")
print("NO_LIVE_SSE_CONNECTION=true")
print("NO_EVENT_STREAM_SUBSCRIBE=true")
print("NO_EVENT_STREAM_PUBLISH=true")
print("NO_NOTIFICATION_MUTATION=true")
print("NOTIFICATION_CENTER_EXTERNAL_POLICY=CLOSED")
print(f"NOTIFICATION_CENTER_RESULT={summary.get('notification_center_result')}")
PY_EOF
