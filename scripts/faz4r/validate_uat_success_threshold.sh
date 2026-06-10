#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_8_2_uat_basari_esigi.v1.json}"
THRESHOLD_FILE="${THRESHOLD_FILE:-configs/faz4r/uat_success_threshold.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "UAT_SUCCESS_THRESHOLD_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$THRESHOLD_FILE" ]; then fail "THRESHOLD_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$THRESHOLD_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$THRESHOLD_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
payload = json.loads(Path(sys.argv[3]).read_text())
errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 232, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_8_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("uat_threshold_policy", {})
required_items = set(config.get("required_threshold_items", []))

require(payload.get("uat_threshold_status") == policy.get("uat_threshold_status_required"), "UAT_THRESHOLD_STATUS_NOT_READY")
require(payload.get("uat_threshold_mode") == policy.get("uat_threshold_mode_required"), "UAT_THRESHOLD_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("threshold_items", [])
controls = payload.get("threshold_controls", {})
metrics = payload.get("threshold_metrics", {})
summary = payload.get("summary", {})
values = payload.get("threshold_values", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "THRESHOLD_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"THRESHOLD_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_THRESHOLD_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_THRESHOLD_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_THRESHOLD_ITEM_CODE_FOUND")

total_item_count = summary.get("total_item_count")
summary_ready_item_count = summary.get("ready_item_count")
summary_missing_item_count = summary.get("missing_item_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_item_count, int) and total_item_count >= 0, "TOTAL_ITEM_COUNT_INVALID")
require(isinstance(summary_ready_item_count, int) and summary_ready_item_count >= 0, "READY_ITEM_COUNT_INVALID")
require(isinstance(summary_missing_item_count, int) and summary_missing_item_count >= 0, "MISSING_ITEM_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

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
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("pilot_kpi_status") == policy.get("pilot_kpi_status_required"), "PILOT_KPI_STATUS_NOT_PASS")
require(summary.get("management_panel_uat_status") == policy.get("management_panel_uat_status_required"), "MANAGEMENT_PANEL_UAT_STATUS_NOT_PASS")
require(summary.get("pos_uat_status") == policy.get("pos_uat_status_required"), "POS_UAT_STATUS_NOT_PASS")
require(summary.get("accounting_uat_status") == policy.get("accounting_uat_status_required"), "ACCOUNTING_UAT_STATUS_NOT_PASS")
require(summary.get("accountant_portal_uat_status") == policy.get("accountant_portal_uat_status_required"), "ACCOUNTANT_PORTAL_UAT_STATUS_NOT_PASS")
require(summary.get("edocument_export_uat_status") == policy.get("edocument_export_uat_status_required"), "EDOCUMENT_EXPORT_UAT_STATUS_NOT_PASS")
require(summary.get("required_case_pass_rate") >= policy.get("required_case_pass_rate_min"), "REQUIRED_CASE_PASS_RATE_BELOW_MIN")
require(summary.get("evidence_completeness_rate") >= policy.get("evidence_completeness_rate_min"), "EVIDENCE_COMPLETENESS_RATE_BELOW_MIN")
require(summary.get("signoff_completeness_rate") >= policy.get("signoff_completeness_rate_min"), "SIGNOFF_COMPLETENESS_RATE_BELOW_MIN")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("pilot_kpi_status") == "PASS", "CONTROL_PILOT_KPI_NOT_PASS")
require(controls.get("management_panel_uat_status") == "PASS", "CONTROL_MANAGEMENT_PANEL_UAT_NOT_PASS")
require(controls.get("pos_uat_status") == "PASS", "CONTROL_POS_UAT_NOT_PASS")
require(controls.get("accounting_uat_status") == "PASS", "CONTROL_ACCOUNTING_UAT_NOT_PASS")
require(controls.get("accountant_portal_uat_status") == "PASS", "CONTROL_ACCOUNTANT_PORTAL_UAT_NOT_PASS")
require(controls.get("edocument_export_uat_status") == "PASS", "CONTROL_EDOCUMENT_EXPORT_UAT_NOT_PASS")
require(controls.get("required_case_pass_threshold_status") == "PASS", "CONTROL_REQUIRED_CASE_THRESHOLD_NOT_PASS")
require(controls.get("evidence_completeness_status") == "PASS", "CONTROL_EVIDENCE_COMPLETENESS_NOT_PASS")
require(controls.get("signoff_completeness_status") == "PASS", "CONTROL_SIGNOFF_COMPLETENESS_NOT_PASS")
require(controls.get("critical_issue_zero_status") == "PASS", "CONTROL_CRITICAL_ISSUE_ZERO_NOT_PASS")
require(controls.get("open_blocker_zero_status") == "PASS", "CONTROL_OPEN_BLOCKER_ZERO_NOT_PASS")
require(controls.get("exception_policy_status") == "READY", "CONTROL_EXCEPTION_POLICY_NOT_READY")

require(controls.get("no_go_no_go_decision") is policy.get("no_go_no_go_decision_required"), "GO_NO_GO_DECISION_NOT_DISABLED")
require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")
require(controls.get("no_dns_change") is True, "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is True, "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is True, "SSL_CHANGE_NOT_DISABLED")

require(values.get("required_case_pass_rate") >= policy.get("required_case_pass_rate_min"), "VALUE_REQUIRED_CASE_PASS_RATE_BELOW_MIN")
require(values.get("evidence_completeness_rate") >= policy.get("evidence_completeness_rate_min"), "VALUE_EVIDENCE_COMPLETENESS_RATE_BELOW_MIN")
require(values.get("signoff_completeness_rate") >= policy.get("signoff_completeness_rate_min"), "VALUE_SIGNOFF_COMPLETENESS_RATE_BELOW_MIN")
require(values.get("critical_issue_count") == 0, "VALUE_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(values.get("open_blocker_count") == 0, "VALUE_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(values.get("required_fail_count") == 0, "VALUE_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(values.get("exception_count") == 0, "VALUE_EXCEPTION_COUNT_NOT_ZERO")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("threshold_below_min_count") == 0, "THRESHOLD_BELOW_MIN_COUNT_NOT_ZERO")
require(metrics.get("go_no_go_decision_count") == 0, "GO_NO_GO_DECISION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("uat_threshold_result") == "PASS", "UAT_THRESHOLD_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("uat_threshold_result") == "FAIL", "UAT_THRESHOLD_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "go_no_go_decision", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("UAT_SUCCESS_THRESHOLD_STATUS=FAIL")
    print(f"UAT_SUCCESS_THRESHOLD_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"UAT_SUCCESS_THRESHOLD_FAIL={error}")
    sys.exit(1)

print("UAT_SUCCESS_THRESHOLD_STATUS=PASS")
print(f"UAT_SUCCESS_THRESHOLD_TENANT_ID={tenant.get('tenant_id')}")
print(f"UAT_SUCCESS_THRESHOLD_TOTAL_ITEM_COUNT={total_item_count}")
print(f"UAT_SUCCESS_THRESHOLD_READY_ITEM_COUNT={ready_count}")
print(f"UAT_SUCCESS_THRESHOLD_MISSING_ITEM_COUNT={missing_count}")
print(f"UAT_SUCCESS_THRESHOLD_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"UAT_SUCCESS_THRESHOLD_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"UAT_SUCCESS_THRESHOLD_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"UAT_SUCCESS_THRESHOLD_RESULT={summary.get('uat_threshold_result')}")
print("UAT_SUCCESS_THRESHOLD_MODE=CONTROLLED_PILOT")
print("MANAGEMENT_PANEL_UAT_STATUS=PASS")
print("POS_UAT_STATUS=PASS")
print("ACCOUNTING_UAT_STATUS=PASS")
print("ACCOUNTANT_PORTAL_UAT_STATUS=PASS")
print("EDOCUMENT_EXPORT_UAT_STATUS=PASS")
print("REQUIRED_CASE_PASS_RATE=100")
print("EVIDENCE_COMPLETENESS_RATE=100")
print("SIGNOFF_COMPLETENESS_RATE=100")
print("NO_GO_NO_GO_DECISION=true")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_LIVE_EXTERNAL_PROVIDER_ACTIVATION=true")
print("UAT_SUCCESS_THRESHOLD_EXTERNAL_POLICY=CLOSED")
PY_EOF
