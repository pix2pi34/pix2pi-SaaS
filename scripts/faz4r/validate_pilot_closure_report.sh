#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_8_5_pilot_closure_report.v1.json}"
CLOSURE_FILE="${CLOSURE_FILE:-configs/faz4r/pilot_closure_report.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "PILOT_CLOSURE_REPORT_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$CLOSURE_FILE" ]; then fail "CLOSURE_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$CLOSURE_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$CLOSURE_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 235, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_8_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("closure_policy", {})
required_items = set(config.get("required_closure_items", []))

require(payload.get("pilot_closure_status") == policy.get("pilot_closure_status_required"), "PILOT_CLOSURE_STATUS_NOT_READY")
require(payload.get("pilot_closure_mode") == policy.get("pilot_closure_mode_required"), "PILOT_CLOSURE_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closure_result") == policy.get("closure_result_required"), "CLOSURE_RESULT_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_CLOSED", "TENANT_STATUS_NOT_PILOT_CLOSED")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("closure_items", [])
controls = payload.get("closure_controls", {})
metrics = payload.get("closure_metrics", {})
summary = payload.get("summary", {})
values = payload.get("closure_values", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "CLOSURE_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"CLOSURE_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_CLOSURE_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_CLOSURE_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_CLOSURE_ITEM_CODE_FOUND")

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

for field, code in [
    ("critical_issue_count", "CRITICAL_ISSUE_COUNT_NOT_ZERO"),
    ("p0_issue_count", "P0_ISSUE_COUNT_NOT_ZERO"),
    ("p1_issue_count", "P1_ISSUE_COUNT_NOT_ZERO"),
    ("open_blocker_count", "OPEN_BLOCKER_COUNT_NOT_ZERO")
]:
    require(summary.get(field) == 0, "SUMMARY_" + code)
    require(values.get(field) == 0, "VALUE_" + code)
    require(metrics.get(field) == 0, "METRIC_" + code)

require(values.get("required_fail_count") == 0, "VALUE_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(values.get("missing_item_count") == 0, "VALUE_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")

require(summary.get("go_no_go_decision_status") == policy.get("go_no_go_decision_status_required"), "GO_NO_GO_DECISION_STATUS_NOT_PASS")
require(summary.get("decision_result") == policy.get("decision_result_required"), "DECISION_RESULT_NOT_GO")
require(summary.get("owner_approval_status") == policy.get("owner_approval_status_required"), "OWNER_APPROVAL_STATUS_NOT_APPROVED")
require(summary.get("next_phase_handoff_status") == policy.get("next_phase_handoff_status_required"), "NEXT_PHASE_HANDOFF_STATUS_NOT_READY")
require(summary.get("closure_result") == policy.get("closure_result_required"), "SUMMARY_CLOSURE_RESULT_NOT_CLOSED")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("go_no_go_decision_status") == "PASS", "CONTROL_GO_NO_GO_DECISION_NOT_PASS")
require(controls.get("decision_result") == "GO", "CONTROL_DECISION_RESULT_NOT_GO")
require(controls.get("pilot_kpi_status") == "PASS", "CONTROL_PILOT_KPI_NOT_PASS")
require(controls.get("uat_threshold_status") == "PASS", "CONTROL_UAT_THRESHOLD_NOT_PASS")
require(controls.get("critical_issue_reset_status") == "PASS", "CONTROL_CRITICAL_RESET_NOT_PASS")
require(controls.get("rehearsal_report_status") == "PASS", "CONTROL_REHEARSAL_REPORT_NOT_PASS")
require(controls.get("owner_approval_status") == "APPROVED", "CONTROL_OWNER_APPROVAL_NOT_APPROVED")
require(controls.get("evidence_index_status") == "READY", "CONTROL_EVIDENCE_INDEX_NOT_READY")
require(controls.get("final_risk_summary_status") == "READY", "CONTROL_FINAL_RISK_SUMMARY_NOT_READY")
require(controls.get("open_blocker_zero_status") == "PASS", "CONTROL_OPEN_BLOCKER_ZERO_NOT_PASS")
require(controls.get("next_phase_handoff_status") == "READY", "CONTROL_NEXT_PHASE_HANDOFF_NOT_READY")
require(controls.get("next_phase") == "236_FAZ_4_17_1_APPROVAL_INBOX", "NEXT_PHASE_NOT_APPROVAL_INBOX")

require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")
require(controls.get("no_dns_change") is True, "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is True, "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is True, "SSL_CHANGE_NOT_DISABLED")

if missing_count == 0 and required_fail_count == 0 and summary.get("closure_result") == "CLOSED":
    require(summary.get("pilot_closure_result") == "PASS", "PILOT_CLOSURE_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("pilot_closure_result") == "FAIL", "PILOT_CLOSURE_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("PILOT_CLOSURE_REPORT_STATUS=FAIL")
    print(f"PILOT_CLOSURE_REPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"PILOT_CLOSURE_REPORT_FAIL={error}")
    sys.exit(1)

print("PILOT_CLOSURE_REPORT_STATUS=PASS")
print(f"PILOT_CLOSURE_REPORT_TENANT_ID={tenant.get('tenant_id')}")
print(f"PILOT_CLOSURE_REPORT_TOTAL_ITEM_COUNT={total_item_count}")
print(f"PILOT_CLOSURE_REPORT_READY_ITEM_COUNT={ready_count}")
print(f"PILOT_CLOSURE_REPORT_MISSING_ITEM_COUNT={missing_count}")
print(f"PILOT_CLOSURE_REPORT_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("CRITICAL_ISSUE_COUNT=0")
print("P0_ISSUE_COUNT=0")
print("P1_ISSUE_COUNT=0")
print("OPEN_BLOCKER_COUNT=0")
print("GO_NO_GO_DECISION_STATUS=PASS")
print("DECISION_RESULT=GO")
print("OWNER_APPROVAL_STATUS=APPROVED")
print("NEXT_PHASE_HANDOFF_STATUS=READY")
print("CLOSURE_RESULT=CLOSED")
print(f"PILOT_CLOSURE_RESULT={summary.get('pilot_closure_result')}")
print("PILOT_CLOSURE_MODE=CONTROLLED_PILOT")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_LIVE_EXTERNAL_PROVIDER_ACTIVATION=true")
print("PILOT_CLOSURE_REPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
