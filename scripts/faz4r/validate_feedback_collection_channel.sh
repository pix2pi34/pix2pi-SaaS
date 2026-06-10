#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_6_1_feedback_toplama_kanali.v1.json}"
FEEDBACK_FILE="${FEEDBACK_FILE:-configs/faz4r/feedback_collection_channel.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "FEEDBACK_COLLECTION_CHANNEL_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$FEEDBACK_FILE" ]; then
  fail "FEEDBACK_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$FEEDBACK_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$FEEDBACK_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
feedback_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
feedback_artifact = json.loads(feedback_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 221, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_6_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("feedback_policy", {})
required_channels = set(config.get("required_feedback_channels", []))

require(payload.get("feedback_channel_status") == policy.get("feedback_channel_status_required"), "FEEDBACK_CHANNEL_STATUS_NOT_READY")
require(payload.get("feedback_channel_mode") == policy.get("feedback_channel_mode_required"), "CHANNEL_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

channels = payload.get("feedback_channels", [])
controls = payload.get("feedback_controls", {})
metrics = payload.get("feedback_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(channels, list), "FEEDBACK_CHANNELS_NOT_LIST")

provided_channels = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(channels, list):
    for idx, channel in enumerate(channels, start=1):
        prefix = f"FEEDBACK_CHANNEL_{idx}"
        require(isinstance(channel, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(channel, dict):
            continue

        code = channel.get("code")
        status = channel.get("status")
        required = channel.get("required")
        source = channel.get("source")
        owner = channel.get("owner")
        evidence_ref = channel.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_channels.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(source), f"{prefix}_SOURCE_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_channel_status_required"), f"REQUIRED_FEEDBACK_CHANNEL_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_channels)
missing_channels = sorted(required_channels - provided_set)
require(not missing_channels, "REQUIRED_FEEDBACK_CHANNELS_MISSING:" + ",".join(missing_channels))
require(len(provided_channels) == len(provided_set), "DUPLICATE_FEEDBACK_CHANNEL_CODE_FOUND")

total_channel_count = summary.get("total_channel_count")
summary_ready_channel_count = summary.get("ready_channel_count")
summary_missing_channel_count = summary.get("missing_channel_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_channel_count, int) and total_channel_count >= 0, "TOTAL_CHANNEL_COUNT_INVALID")
require(isinstance(summary_ready_channel_count, int) and summary_ready_channel_count >= 0, "READY_CHANNEL_COUNT_INVALID")
require(isinstance(summary_missing_channel_count, int) and summary_missing_channel_count >= 0, "MISSING_CHANNEL_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_channel_count, int):
    require(total_channel_count == len(channels), "TOTAL_CHANNEL_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_channel_count, int):
    require(summary_ready_channel_count == ready_count, "READY_CHANNEL_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_channel_count, int):
    require(summary_missing_channel_count == missing_count, "MISSING_CHANNEL_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_channel_count == policy.get("missing_channel_count_required"), "MISSING_CHANNEL_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("tenant_status_report_status") == policy.get("tenant_status_report_status_required"), "TENANT_STATUS_REPORT_STATUS_NOT_PASS")
require(summary.get("feedback_privacy_policy_status") == policy.get("feedback_privacy_policy_status_required"), "FEEDBACK_PRIVACY_POLICY_STATUS_NOT_READY")
require(summary.get("feedback_category_mapping_status") == policy.get("feedback_category_mapping_status_required"), "FEEDBACK_CATEGORY_MAPPING_STATUS_NOT_READY")
require(summary.get("feedback_priority_mapping_status") == policy.get("feedback_priority_mapping_status_required"), "FEEDBACK_PRIORITY_MAPPING_STATUS_NOT_READY")
require(summary.get("feedback_owner_routing_status") == policy.get("feedback_owner_routing_status_required"), "FEEDBACK_OWNER_ROUTING_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("tenant_status_report_status") == "PASS", "CONTROL_TENANT_STATUS_REPORT_NOT_PASS")
require(controls.get("feedback_privacy_policy_status") == "READY", "CONTROL_FEEDBACK_PRIVACY_POLICY_NOT_READY")
require(controls.get("feedback_category_mapping_status") == "READY", "CONTROL_FEEDBACK_CATEGORY_MAPPING_NOT_READY")
require(controls.get("feedback_priority_mapping_status") == "READY", "CONTROL_FEEDBACK_PRIORITY_MAPPING_NOT_READY")
require(controls.get("feedback_owner_routing_status") == "READY", "CONTROL_FEEDBACK_OWNER_ROUTING_NOT_READY")
require(controls.get("feedback_evidence_attachment_status") == "READY", "CONTROL_FEEDBACK_EVIDENCE_ATTACHMENT_NOT_READY")
require(controls.get("no_real_crm_system") is policy.get("no_real_crm_system_required"), "REAL_CRM_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_ticket_system") is policy.get("no_real_ticket_system_required"), "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_email_dispatch") is policy.get("no_real_email_dispatch_required"), "REAL_EMAIL_DISPATCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_channel_count") == 0, "METRIC_MISSING_CHANNEL_COUNT_NOT_ZERO")
require(metrics.get("real_crm_dispatch_count") == 0, "REAL_CRM_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_ticket_dispatch_count") == 0, "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("real_email_dispatch_count") == 0, "REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("feedback_channel_result") == "PASS", "FEEDBACK_CHANNEL_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("feedback_channel_result") == "FAIL", "FEEDBACK_CHANNEL_RESULT_SHOULD_BE_FAIL")

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
    print("FEEDBACK_COLLECTION_CHANNEL_STATUS=FAIL")
    print(f"FEEDBACK_COLLECTION_CHANNEL_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"FEEDBACK_COLLECTION_CHANNEL_FAIL={error}")
    sys.exit(1)

print("FEEDBACK_COLLECTION_CHANNEL_STATUS=PASS")
print(f"FEEDBACK_COLLECTION_CHANNEL_TENANT_ID={tenant.get('tenant_id')}")
print(f"FEEDBACK_COLLECTION_CHANNEL_TOTAL_CHANNEL_COUNT={total_channel_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_READY_CHANNEL_COUNT={ready_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_MISSING_CHANNEL_COUNT={missing_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"FEEDBACK_COLLECTION_CHANNEL_RESULT={summary.get('feedback_channel_result')}")
print("FEEDBACK_COLLECTION_CHANNEL_MODE=CONTROLLED_PILOT")
print("FEEDBACK_PRIVACY_POLICY_STATUS=READY")
print("FEEDBACK_CATEGORY_MAPPING_STATUS=READY")
print("FEEDBACK_PRIORITY_MAPPING_STATUS=READY")
print("FEEDBACK_OWNER_ROUTING_STATUS=READY")
print("NO_REAL_CRM_SYSTEM=true")
print("NO_REAL_TICKET_SYSTEM=true")
print("NO_REAL_EMAIL_DISPATCH=true")
print("FEEDBACK_COLLECTION_CHANNEL_EXTERNAL_POLICY=CLOSED")
PY_EOF
