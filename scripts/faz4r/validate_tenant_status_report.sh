#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_5_5_tenant_bazli_durum_raporu.v1.json}"
REPORT_FILE="${REPORT_FILE:-configs/faz4r/tenant_status_report.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "TENANT_STATUS_REPORT_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$REPORT_FILE" ]; then
  fail "REPORT_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$REPORT_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$REPORT_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
report_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
report_artifact = json.loads(report_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 220, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_5_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("report_policy", {})
required_sections = set(config.get("required_report_sections", []))

require(payload.get("report_status") == policy.get("report_status_required"), "REPORT_STATUS_NOT_READY")
require(payload.get("report_mode") == policy.get("report_mode_required"), "REPORT_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

sections = payload.get("report_sections", [])
controls = payload.get("report_controls", {})
metrics = payload.get("tenant_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(sections, list), "REPORT_SECTIONS_NOT_LIST")

provided_sections = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(sections, list):
    for idx, section in enumerate(sections, start=1):
        prefix = f"REPORT_SECTION_{idx}"
        require(isinstance(section, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(section, dict):
            continue

        code = section.get("code")
        status = section.get("status")
        required = section.get("required")
        area = section.get("area")
        result = section.get("result")
        evidence_ref = section.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_sections.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(result in {"PASS", "FAIL", "WARN"}, f"{prefix}_RESULT_INVALID")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_section_status_required"), f"REQUIRED_REPORT_SECTION_NOT_READY:{code}")
            require(result == "PASS", f"REQUIRED_REPORT_SECTION_RESULT_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY" or result != "PASS":
                required_fail_count += 1

provided_set = set(provided_sections)
missing_sections = sorted(required_sections - provided_set)
require(not missing_sections, "REQUIRED_REPORT_SECTIONS_MISSING:" + ",".join(missing_sections))
require(len(provided_sections) == len(provided_set), "DUPLICATE_REPORT_SECTION_CODE_FOUND")

total_section_count = summary.get("total_section_count")
summary_ready_section_count = summary.get("ready_section_count")
summary_missing_section_count = summary.get("missing_section_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_section_count, int) and total_section_count >= 0, "TOTAL_SECTION_COUNT_INVALID")
require(isinstance(summary_ready_section_count, int) and summary_ready_section_count >= 0, "READY_SECTION_COUNT_INVALID")
require(isinstance(summary_missing_section_count, int) and summary_missing_section_count >= 0, "MISSING_SECTION_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_section_count, int):
    require(total_section_count == len(sections), "TOTAL_SECTION_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_section_count, int):
    require(summary_ready_section_count == ready_count, "READY_SECTION_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_section_count, int):
    require(summary_missing_section_count == missing_count, "MISSING_SECTION_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_section_count == policy.get("missing_section_count_required"), "MISSING_SECTION_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("pilot_health_dashboard_status") == policy.get("pilot_health_dashboard_status_required"), "PILOT_HEALTH_DASHBOARD_STATUS_NOT_PASS")
require(summary.get("pilot_incident_management_status") == policy.get("pilot_incident_management_status_required"), "PILOT_INCIDENT_MANAGEMENT_STATUS_NOT_PASS")
require(summary.get("pilot_operations_tests_status") == policy.get("pilot_operations_tests_status_required"), "PILOT_OPERATIONS_TESTS_STATUS_NOT_PASS")
require(summary.get("rollback_signal_status") == policy.get("rollback_signal_status_required"), "ROLLBACK_SIGNAL_STATUS_NOT_CLEAR")
require(summary.get("operations_handoff_ready") == policy.get("operations_handoff_ready_required"), "OPERATIONS_HANDOFF_NOT_READY")
require(summary.get("report_result") == policy.get("report_result_required"), "REPORT_RESULT_NOT_PASS")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("pilot_health_dashboard_status") == "PASS", "CONTROL_PILOT_HEALTH_DASHBOARD_NOT_PASS")
require(controls.get("pilot_incident_management_status") == "PASS", "CONTROL_PILOT_INCIDENT_MANAGEMENT_NOT_PASS")
require(controls.get("pilot_operations_tests_status") == "PASS", "CONTROL_PILOT_OPERATIONS_TESTS_NOT_PASS")
require(controls.get("daily_pilot_review_status") == "PASS", "CONTROL_DAILY_PILOT_REVIEW_NOT_PASS")
require(controls.get("rollback_signal_status") == "CLEAR", "CONTROL_ROLLBACK_SIGNAL_NOT_CLEAR")
require(controls.get("operations_handoff_ready") == "YES", "CONTROL_OPERATIONS_HANDOFF_NOT_READY")
require(controls.get("tenant_report_visibility") == "CONTROLLED_PILOT_ONLY", "TENANT_REPORT_VISIBILITY_INVALID")
require(controls.get("no_real_ticket_system") is True, "REAL_TICKET_SYSTEM_NOT_DISABLED")
require(controls.get("no_real_email_dispatch") is True, "REAL_EMAIL_DISPATCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is True, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_incident_count") == 0, "OPEN_INCIDENT_COUNT_NOT_ZERO")
require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_section_count") == 0, "METRIC_MISSING_SECTION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("report_result") == "PASS", "REPORT_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("report_result") == "FAIL", "REPORT_RESULT_SHOULD_BE_FAIL")

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
    print("TENANT_STATUS_REPORT_STATUS=FAIL")
    print(f"TENANT_STATUS_REPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"TENANT_STATUS_REPORT_FAIL={error}")
    sys.exit(1)

print("TENANT_STATUS_REPORT_STATUS=PASS")
print(f"TENANT_STATUS_REPORT_TENANT_ID={tenant.get('tenant_id')}")
print(f"TENANT_STATUS_REPORT_TOTAL_SECTION_COUNT={total_section_count}")
print(f"TENANT_STATUS_REPORT_READY_SECTION_COUNT={ready_count}")
print(f"TENANT_STATUS_REPORT_MISSING_SECTION_COUNT={missing_count}")
print(f"TENANT_STATUS_REPORT_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"TENANT_STATUS_REPORT_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"TENANT_STATUS_REPORT_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"TENANT_STATUS_REPORT_RESULT={summary.get('report_result')}")
print("TENANT_STATUS_REPORT_MODE=CONTROLLED_PILOT")
print("ROLLBACK_SIGNAL_STATUS=CLEAR")
print("OPERATIONS_HANDOFF_READY=YES")
print("TENANT_STATUS_REPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
