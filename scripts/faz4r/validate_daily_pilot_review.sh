#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_5_2_gunluk_pilot_review.v1.json}"
REVIEW_FILE="${REVIEW_FILE:-configs/faz4r/daily_pilot_review.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "DAILY_PILOT_REVIEW_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$REVIEW_FILE" ]; then
  fail "REVIEW_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$REVIEW_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$REVIEW_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
review_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
review_artifact = json.loads(review_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 215, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_5_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("review_policy", {})
required_items = set(config.get("required_review_items", []))

require(payload.get("review_status") == policy.get("review_status_required"), "REVIEW_STATUS_NOT_READY")
require(payload.get("review_mode") == policy.get("review_mode_required"), "REVIEW_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("review_items", [])
controls = payload.get("review_controls", {})
metrics = payload.get("daily_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "REVIEW_ITEMS_NOT_LIST")

provided_items = []
pass_count = 0
fail_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"REVIEW_ITEM_{idx}"
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

        require(status in {"PASS", "FAIL", "WARN"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "PASS":
            pass_count += 1
        elif status == "FAIL":
            fail_count += 1
            if required is True:
                required_fail_count += 1

        if required is True:
            require(status == policy.get("required_review_item_status_required"), f"REQUIRED_REVIEW_ITEM_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_REVIEW_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_REVIEW_ITEM_CODE_FOUND")

total_review_item_count = summary.get("total_review_item_count")
summary_pass_review_item_count = summary.get("pass_review_item_count")
summary_fail_review_item_count = summary.get("fail_review_item_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_review_item_count, int) and total_review_item_count >= 0, "TOTAL_REVIEW_ITEM_COUNT_INVALID")
require(isinstance(summary_pass_review_item_count, int) and summary_pass_review_item_count >= 0, "PASS_REVIEW_ITEM_COUNT_INVALID")
require(isinstance(summary_fail_review_item_count, int) and summary_fail_review_item_count >= 0, "FAIL_REVIEW_ITEM_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_review_item_count, int):
    require(total_review_item_count == len(items), "TOTAL_REVIEW_ITEM_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_review_item_count, int):
    require(summary_pass_review_item_count == pass_count, "PASS_REVIEW_ITEM_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_review_item_count, int):
    require(summary_fail_review_item_count == fail_count, "FAIL_REVIEW_ITEM_COUNT_RECONCILIATION_FAILED")
    require(summary_fail_review_item_count == policy.get("fail_review_item_count_required"), "FAIL_REVIEW_ITEM_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("training_support_smoke_status") == policy.get("training_support_smoke_status_required"), "TRAINING_SUPPORT_SMOKE_STATUS_NOT_PASS")
require(summary.get("support_triage_status") == policy.get("support_triage_status_required"), "SUPPORT_TRIAGE_STATUS_NOT_PASS")
require(summary.get("issue_escalation_status") == policy.get("issue_escalation_status_required"), "ISSUE_ESCALATION_STATUS_NOT_PASS")
require(summary.get("rollback_signal_status") == policy.get("rollback_signal_status_required"), "ROLLBACK_SIGNAL_STATUS_NOT_CLEAR")
require(summary.get("daily_decision_log_status") == policy.get("daily_decision_log_status_required"), "DAILY_DECISION_LOG_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("training_support_smoke_status") == "PASS", "CONTROL_TRAINING_SUPPORT_SMOKE_NOT_PASS")
require(controls.get("support_triage_status") == "PASS", "CONTROL_SUPPORT_TRIAGE_NOT_PASS")
require(controls.get("issue_escalation_status") == "PASS", "CONTROL_ISSUE_ESCALATION_NOT_PASS")
require(controls.get("pilot_health_status") == "PASS", "PILOT_HEALTH_STATUS_NOT_PASS")
require(controls.get("rollback_signal_status") == "CLEAR", "CONTROL_ROLLBACK_SIGNAL_NOT_CLEAR")
require(controls.get("daily_decision_log_status") == "READY", "CONTROL_DAILY_DECISION_LOG_NOT_READY")
require(controls.get("no_real_rollback_execution") is policy.get("no_real_rollback_execution_required"), "REAL_ROLLBACK_EXECUTION_NOT_DISABLED")
require(controls.get("no_hotfix_deploy") is True, "HOTFIX_DEPLOY_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("rollback_signal_count") == 0, "ROLLBACK_SIGNAL_COUNT_NOT_ZERO")
require(metrics.get("production_launch_signal") == "CLOSED", "PRODUCTION_LAUNCH_SIGNAL_NOT_CLOSED")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if fail_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("review_result") == "PASS", "REVIEW_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("review_result") == "FAIL", "REVIEW_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_ticket_system") == "CLOSED", "REAL_TICKET_SYSTEM_NOT_CLOSED")
require(external_policy.get("real_email_dispatch") == "CLOSED", "REAL_EMAIL_DISPATCH_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")
require(external_policy.get("real_rollback_execution") == "CLOSED", "REAL_ROLLBACK_EXECUTION_NOT_CLOSED")

if errors:
    print("DAILY_PILOT_REVIEW_STATUS=FAIL")
    print(f"DAILY_PILOT_REVIEW_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"DAILY_PILOT_REVIEW_FAIL={error}")
    sys.exit(1)

print("DAILY_PILOT_REVIEW_STATUS=PASS")
print(f"DAILY_PILOT_REVIEW_TENANT_ID={tenant.get('tenant_id')}")
print(f"DAILY_PILOT_REVIEW_TOTAL_ITEM_COUNT={total_review_item_count}")
print(f"DAILY_PILOT_REVIEW_PASS_ITEM_COUNT={pass_count}")
print(f"DAILY_PILOT_REVIEW_FAIL_ITEM_COUNT={fail_count}")
print(f"DAILY_PILOT_REVIEW_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"DAILY_PILOT_REVIEW_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"DAILY_PILOT_REVIEW_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"DAILY_PILOT_REVIEW_RESULT={summary.get('review_result')}")
print("DAILY_PILOT_REVIEW_MODE=CONTROLLED_PILOT")
print("ROLLBACK_SIGNAL_STATUS=CLEAR")
print("DAILY_DECISION_LOG_STATUS=READY")
print("NO_REAL_ROLLBACK_EXECUTION=true")
print("DAILY_PILOT_REVIEW_EXTERNAL_POLICY=CLOSED")
PY_EOF
