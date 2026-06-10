#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_5_1_pilot_health_dashboard.v1.json}"
DASHBOARD_FILE="${DASHBOARD_FILE:-configs/faz4r/pilot_health_dashboard.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"
HTML_FILE="${HTML_FILE:-docs/faz4r/pilot_health_dashboard/pilot_health_dashboard.html}"

fail() {
  echo "PILOT_HEALTH_DASHBOARD_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$DASHBOARD_FILE" ]; then
  fail "DASHBOARD_FILE_NOT_FOUND"
fi

if [ ! -f "$HTML_FILE" ]; then
  fail "HTML_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$DASHBOARD_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$DASHBOARD_FILE" "$INPUT_FILE" "$HTML_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
dashboard_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])
html_path = Path(sys.argv[4])

config = json.loads(config_path.read_text())
dashboard_artifact = json.loads(dashboard_path.read_text())
payload = json.loads(input_path.read_text())
html = html_path.read_text()

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 218, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_5_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("dashboard_policy", {})
required_widgets = set(config.get("required_widgets", []))

require(payload.get("dashboard_status") == policy.get("dashboard_status_required"), "DASHBOARD_STATUS_NOT_READY")
require(payload.get("dashboard_mode") == policy.get("dashboard_mode_required"), "DASHBOARD_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

widgets = payload.get("widgets", [])
controls = payload.get("dashboard_controls", {})
metrics = payload.get("dashboard_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(widgets, list), "WIDGETS_NOT_LIST")

provided_widgets = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(widgets, list):
    for idx, widget in enumerate(widgets, start=1):
        prefix = f"DASHBOARD_WIDGET_{idx}"
        require(isinstance(widget, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(widget, dict):
            continue

        code = widget.get("code")
        status = widget.get("status")
        required = widget.get("required")
        area = widget.get("area")
        health = widget.get("health")
        evidence_ref = widget.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_widgets.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(health in {"GREEN", "YELLOW", "RED"}, f"{prefix}_HEALTH_INVALID")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_widget_status_required"), f"REQUIRED_WIDGET_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_widgets)
missing_widgets = sorted(required_widgets - provided_set)
require(not missing_widgets, "REQUIRED_WIDGETS_MISSING:" + ",".join(missing_widgets))
require(len(provided_widgets) == len(provided_set), "DUPLICATE_WIDGET_CODE_FOUND")

total_widget_count = summary.get("total_widget_count")
summary_ready_widget_count = summary.get("ready_widget_count")
summary_missing_widget_count = summary.get("missing_widget_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_widget_count, int) and total_widget_count >= 0, "TOTAL_WIDGET_COUNT_INVALID")
require(isinstance(summary_ready_widget_count, int) and summary_ready_widget_count >= 0, "READY_WIDGET_COUNT_INVALID")
require(isinstance(summary_missing_widget_count, int) and summary_missing_widget_count >= 0, "MISSING_WIDGET_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_widget_count, int):
    require(total_widget_count == len(widgets), "TOTAL_WIDGET_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_widget_count, int):
    require(summary_ready_widget_count == ready_count, "READY_WIDGET_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_widget_count, int):
    require(summary_missing_widget_count == missing_count, "MISSING_WIDGET_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_widget_count == policy.get("missing_widget_count_required"), "MISSING_WIDGET_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("pilot_operations_tests_status") == policy.get("pilot_operations_tests_status_required"), "PILOT_OPERATIONS_TESTS_STATUS_NOT_PASS")
require(summary.get("last_review_status") == policy.get("last_review_status_required"), "LAST_REVIEW_STATUS_NOT_PASS")
require(summary.get("rollback_signal_status") == policy.get("rollback_signal_status_required"), "ROLLBACK_SIGNAL_STATUS_NOT_CLEAR")
require(summary.get("operations_handoff_ready") == policy.get("operations_handoff_ready_required"), "OPERATIONS_HANDOFF_NOT_READY")
require(summary.get("html_dashboard_status") == policy.get("html_dashboard_status_required"), "HTML_DASHBOARD_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("pilot_operations_tests_status") == "PASS", "CONTROL_PILOT_OPERATIONS_TESTS_NOT_PASS")
require(controls.get("last_review_status") == "PASS", "CONTROL_LAST_REVIEW_STATUS_NOT_PASS")
require(controls.get("rollback_signal_status") == "CLEAR", "CONTROL_ROLLBACK_SIGNAL_NOT_CLEAR")
require(controls.get("operations_handoff_ready") == "YES", "CONTROL_OPERATIONS_HANDOFF_NOT_READY")
require(controls.get("html_dashboard_status") == "READY", "CONTROL_HTML_DASHBOARD_NOT_READY")
require(controls.get("dashboard_visibility") == "CONTROLLED_PILOT_ONLY", "DASHBOARD_VISIBILITY_INVALID")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_widget_count") == 0, "METRIC_MISSING_WIDGET_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

for marker in [
    "Pix2pi FAZ 4-R Pilot Health Dashboard",
    "pilot-tenant-health-summary",
    "service-health-widget",
    "import-pipeline-health-widget",
    "readmodel-reporting-health-widget",
    "uat-status-widget",
    "training-support-health-widget",
    "support-triage-health-widget",
    "issue-escalation-health-widget",
    "rollback-signal-health-widget",
    "kpi-snapshot-widget",
    "open-blocker-critical-issue-widget",
    "closed-provider-policy-widget",
    "operations-handoff-widget",
    "last-review-timestamp-widget",
    "CLOSED_POLICY_GATE_REFERENCE_ONLY"
]:
    require(marker in html, f"HTML_MARKER_MISSING:{marker}")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("dashboard_result") == "PASS", "DASHBOARD_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("dashboard_result") == "FAIL", "DASHBOARD_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")
require(external_policy.get("hotfix_deploy") == "CLOSED", "HOTFIX_DEPLOY_NOT_CLOSED")
require(external_policy.get("real_rollback_execution") == "CLOSED", "REAL_ROLLBACK_EXECUTION_NOT_CLOSED")

if errors:
    print("PILOT_HEALTH_DASHBOARD_STATUS=FAIL")
    print(f"PILOT_HEALTH_DASHBOARD_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PILOT_HEALTH_DASHBOARD_FAIL={error}")
    sys.exit(1)

print("PILOT_HEALTH_DASHBOARD_STATUS=PASS")
print(f"PILOT_HEALTH_DASHBOARD_TENANT_ID={tenant.get('tenant_id')}")
print(f"PILOT_HEALTH_DASHBOARD_TOTAL_WIDGET_COUNT={total_widget_count}")
print(f"PILOT_HEALTH_DASHBOARD_READY_WIDGET_COUNT={ready_count}")
print(f"PILOT_HEALTH_DASHBOARD_MISSING_WIDGET_COUNT={missing_count}")
print(f"PILOT_HEALTH_DASHBOARD_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"PILOT_HEALTH_DASHBOARD_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"PILOT_HEALTH_DASHBOARD_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"PILOT_HEALTH_DASHBOARD_RESULT={summary.get('dashboard_result')}")
print("PILOT_HEALTH_DASHBOARD_MODE=CONTROLLED_PILOT")
print("ROLLBACK_SIGNAL_STATUS=CLEAR")
print("OPERATIONS_HANDOFF_READY=YES")
print("HTML_DASHBOARD_STATUS=READY")
print("PILOT_HEALTH_DASHBOARD_EXTERNAL_POLICY=CLOSED")
PY_EOF
