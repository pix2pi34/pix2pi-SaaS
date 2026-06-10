#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_8_1_pilot_kpi_degerlendirmesi.v1.json}"
KPI_FILE="${KPI_FILE:-configs/faz4r/pilot_kpi_evaluation.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PILOT_KPI_EVALUATION_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$KPI_FILE" ]; then fail "KPI_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$KPI_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$KPI_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 231, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_8_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("pilot_kpi_policy", {})
required_items = set(config.get("required_kpi_items", []))

require(payload.get("pilot_kpi_status") == policy.get("pilot_kpi_status_required"), "PILOT_KPI_STATUS_NOT_READY")
require(payload.get("pilot_kpi_mode") == policy.get("pilot_kpi_mode_required"), "PILOT_KPI_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("kpi_items", [])
controls = payload.get("kpi_controls", {})
metrics = payload.get("kpi_metrics", {})
summary = payload.get("summary", {})
values = payload.get("kpi_values", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "KPI_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"KPI_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_KPI_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_KPI_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_KPI_ITEM_CODE_FOUND")

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

require(summary.get("rehearsal_report_status") == policy.get("rehearsal_report_status_required"), "REHEARSAL_REPORT_STATUS_NOT_PASS")
require(summary.get("import_success_status") == policy.get("import_success_status_required"), "IMPORT_SUCCESS_STATUS_NOT_PASS")
require(summary.get("uat_pass_status") == policy.get("uat_pass_status_required"), "UAT_PASS_STATUS_NOT_PASS")
require(summary.get("support_response_status") == policy.get("support_response_status_required"), "SUPPORT_RESPONSE_STATUS_NOT_READY")
require(summary.get("feedback_closure_status") == policy.get("feedback_closure_status_required"), "FEEDBACK_CLOSURE_STATUS_NOT_PASS")
require(summary.get("runtime_health_status") == policy.get("runtime_health_status_required"), "RUNTIME_HEALTH_STATUS_NOT_READY")
require(summary.get("incident_count_status") == policy.get("incident_count_status_required"), "INCIDENT_COUNT_STATUS_NOT_READY")
require(summary.get("rollback_readiness_status") == policy.get("rollback_readiness_status_required"), "ROLLBACK_READINESS_STATUS_NOT_READY")
require(summary.get("communication_readiness_status") == policy.get("communication_readiness_status_required"), "COMMUNICATION_READINESS_STATUS_NOT_READY")
require(summary.get("kpi_evidence_index_status") == policy.get("kpi_evidence_index_status_required"), "KPI_EVIDENCE_INDEX_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("rehearsal_report_status") == "PASS", "CONTROL_REHEARSAL_REPORT_NOT_PASS")
require(controls.get("tenant_readiness_status") == "READY", "CONTROL_TENANT_READINESS_NOT_READY")
require(controls.get("import_success_status") == "PASS", "CONTROL_IMPORT_SUCCESS_NOT_PASS")
require(controls.get("uat_pass_status") == "PASS", "CONTROL_UAT_PASS_NOT_PASS")
require(controls.get("support_response_status") == "READY", "CONTROL_SUPPORT_RESPONSE_NOT_READY")
require(controls.get("feedback_closure_status") == "PASS", "CONTROL_FEEDBACK_CLOSURE_NOT_PASS")
require(controls.get("runtime_health_status") == "READY", "CONTROL_RUNTIME_HEALTH_NOT_READY")
require(controls.get("incident_count_status") == "READY", "CONTROL_INCIDENT_COUNT_NOT_READY")
require(controls.get("critical_issue_zero_status") == "PASS", "CONTROL_CRITICAL_ISSUE_ZERO_NOT_PASS")
require(controls.get("rollback_readiness_status") == "READY", "CONTROL_ROLLBACK_READINESS_NOT_READY")
require(controls.get("communication_readiness_status") == "READY", "CONTROL_COMMUNICATION_READINESS_NOT_READY")
require(controls.get("kpi_evidence_index_status") == "READY", "CONTROL_KPI_EVIDENCE_INDEX_NOT_READY")

require(controls.get("no_go_no_go_decision") is policy.get("no_go_no_go_decision_required"), "GO_NO_GO_DECISION_NOT_DISABLED")
require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")
require(controls.get("no_dns_change") is True, "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is True, "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is True, "SSL_CHANGE_NOT_DISABLED")

for key in [
    "tenant_readiness_score", "import_success_rate", "uat_pass_rate", "support_response_readiness",
    "feedback_closure_rate", "runtime_health_readiness", "rollback_readiness_score",
    "communication_readiness_score"
]:
    require(isinstance(values.get(key), int) and values.get(key) >= 100, f"{key.upper()}_BELOW_REQUIRED")

require(values.get("critical_issue_count") == 0, "VALUE_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(values.get("open_blocker_count") == 0, "VALUE_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(values.get("incident_open_count") == 0, "VALUE_INCIDENT_OPEN_COUNT_NOT_ZERO")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("kpi_below_threshold_count") == 0, "KPI_BELOW_THRESHOLD_COUNT_NOT_ZERO")
require(metrics.get("go_no_go_decision_count") == 0, "GO_NO_GO_DECISION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("pilot_kpi_result") == "PASS", "PILOT_KPI_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("pilot_kpi_result") == "FAIL", "PILOT_KPI_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "go_no_go_decision", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("PILOT_KPI_EVALUATION_STATUS=FAIL")
    print(f"PILOT_KPI_EVALUATION_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PILOT_KPI_EVALUATION_FAIL={error}")
    sys.exit(1)

print("PILOT_KPI_EVALUATION_STATUS=PASS")
print(f"PILOT_KPI_EVALUATION_TENANT_ID={tenant.get('tenant_id')}")
print(f"PILOT_KPI_EVALUATION_TOTAL_ITEM_COUNT={total_item_count}")
print(f"PILOT_KPI_EVALUATION_READY_ITEM_COUNT={ready_count}")
print(f"PILOT_KPI_EVALUATION_MISSING_ITEM_COUNT={missing_count}")
print(f"PILOT_KPI_EVALUATION_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"PILOT_KPI_EVALUATION_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"PILOT_KPI_EVALUATION_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"PILOT_KPI_EVALUATION_RESULT={summary.get('pilot_kpi_result')}")
print("PILOT_KPI_EVALUATION_MODE=CONTROLLED_PILOT")
print("IMPORT_SUCCESS_STATUS=PASS")
print("UAT_PASS_STATUS=PASS")
print("SUPPORT_RESPONSE_STATUS=READY")
print("FEEDBACK_CLOSURE_STATUS=PASS")
print("RUNTIME_HEALTH_STATUS=READY")
print("INCIDENT_COUNT_STATUS=READY")
print("ROLLBACK_READINESS_STATUS=READY")
print("COMMUNICATION_READINESS_STATUS=READY")
print("KPI_EVIDENCE_INDEX_STATUS=READY")
print("NO_GO_NO_GO_DECISION=true")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_LIVE_EXTERNAL_PROVIDER_ACTIVATION=true")
print("PILOT_KPI_EVALUATION_EXTERNAL_POLICY=CLOSED")
PY_EOF
