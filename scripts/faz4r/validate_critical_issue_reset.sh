#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_8_3_kritik_hata_sifirlama.v1.json}"
RESET_FILE="${RESET_FILE:-configs/faz4r/critical_issue_reset.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "CRITICAL_ISSUE_RESET_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$RESET_FILE" ]; then fail "RESET_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$RESET_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$RESET_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 233, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_8_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("critical_reset_policy", {})
required_items = set(config.get("required_reset_items", []))

require(payload.get("critical_issue_reset_status") == policy.get("critical_issue_reset_status_required"), "CRITICAL_ISSUE_RESET_STATUS_NOT_READY")
require(payload.get("critical_issue_reset_mode") == policy.get("critical_issue_reset_mode_required"), "CRITICAL_ISSUE_RESET_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("reset_items", [])
controls = payload.get("reset_controls", {})
metrics = payload.get("reset_metrics", {})
summary = payload.get("summary", {})
values = payload.get("issue_values", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "RESET_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"RESET_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_RESET_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_RESET_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_RESET_ITEM_CODE_FOUND")

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

zero_fields = [
    ("critical_issue_count", "CRITICAL_ISSUE_COUNT_NOT_ZERO"),
    ("p0_issue_count", "P0_ISSUE_COUNT_NOT_ZERO"),
    ("p1_issue_count", "P1_ISSUE_COUNT_NOT_ZERO"),
    ("open_blocker_count", "OPEN_BLOCKER_COUNT_NOT_ZERO"),
    ("open_incident_count", "OPEN_INCIDENT_COUNT_NOT_ZERO"),
    ("regression_fail_count", "REGRESSION_FAIL_COUNT_NOT_ZERO"),
    ("exception_count", "EXCEPTION_COUNT_NOT_ZERO")
]

for field, code in zero_fields:
    require(summary.get(field) == 0, "SUMMARY_" + code)
    require(values.get(field) == 0, "VALUE_" + code)
    require(metrics.get(field) == 0, "METRIC_" + code)

require(values.get("unresolved_critical_count") == 0, "VALUE_UNRESOLVED_CRITICAL_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("go_no_go_decision_count") == 0, "GO_NO_GO_DECISION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")

require(summary.get("uat_threshold_status") == policy.get("uat_threshold_status_required"), "UAT_THRESHOLD_STATUS_NOT_PASS")
require(summary.get("resolution_evidence_status") == policy.get("resolution_evidence_status_required"), "RESOLUTION_EVIDENCE_STATUS_NOT_READY")
require(summary.get("regression_evidence_status") == policy.get("regression_evidence_status_required"), "REGRESSION_EVIDENCE_STATUS_NOT_READY")
require(summary.get("owner_signoff_status") == policy.get("owner_signoff_status_required"), "OWNER_SIGNOFF_STATUS_NOT_READY")
require(summary.get("support_confirmation_status") == policy.get("support_confirmation_status_required"), "SUPPORT_CONFIRMATION_STATUS_NOT_READY")
require(summary.get("tenant_confirmation_status") == policy.get("tenant_confirmation_status_required"), "TENANT_CONFIRMATION_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("uat_threshold_status") == "PASS", "CONTROL_UAT_THRESHOLD_NOT_PASS")
require(controls.get("critical_issue_inventory_status") == "READY", "CONTROL_CRITICAL_ISSUE_INVENTORY_NOT_READY")
require(controls.get("severity_classification_status") == "READY", "CONTROL_SEVERITY_CLASSIFICATION_NOT_READY")
require(controls.get("p0_p1_zero_status") == "PASS", "CONTROL_P0_P1_ZERO_NOT_PASS")
require(controls.get("resolution_evidence_status") == "READY", "CONTROL_RESOLUTION_EVIDENCE_NOT_READY")
require(controls.get("regression_evidence_status") == "READY", "CONTROL_REGRESSION_EVIDENCE_NOT_READY")
require(controls.get("owner_signoff_status") == "READY", "CONTROL_OWNER_SIGNOFF_NOT_READY")
require(controls.get("support_confirmation_status") == "READY", "CONTROL_SUPPORT_CONFIRMATION_NOT_READY")
require(controls.get("tenant_confirmation_status") == "READY", "CONTROL_TENANT_CONFIRMATION_NOT_READY")
require(controls.get("incident_backlog_zero_status") == "PASS", "CONTROL_INCIDENT_BACKLOG_ZERO_NOT_PASS")
require(controls.get("open_blocker_zero_status") == "PASS", "CONTROL_OPEN_BLOCKER_ZERO_NOT_PASS")
require(controls.get("exception_policy_status") == "CLOSED", "CONTROL_EXCEPTION_POLICY_NOT_CLOSED")

require(controls.get("no_go_no_go_decision") is policy.get("no_go_no_go_decision_required"), "GO_NO_GO_DECISION_NOT_DISABLED")
require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")
require(controls.get("no_dns_change") is True, "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is True, "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is True, "SSL_CHANGE_NOT_DISABLED")

if missing_count == 0 and required_fail_count == 0 and summary.get("critical_issue_count") == 0 and summary.get("open_blocker_count") == 0:
    require(summary.get("critical_issue_reset_result") == "PASS", "CRITICAL_ISSUE_RESET_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("critical_issue_reset_result") == "FAIL", "CRITICAL_ISSUE_RESET_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "go_no_go_decision", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("CRITICAL_ISSUE_RESET_STATUS=FAIL")
    print(f"CRITICAL_ISSUE_RESET_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"CRITICAL_ISSUE_RESET_FAIL={error}")
    sys.exit(1)

print("CRITICAL_ISSUE_RESET_STATUS=PASS")
print(f"CRITICAL_ISSUE_RESET_TENANT_ID={tenant.get('tenant_id')}")
print(f"CRITICAL_ISSUE_RESET_TOTAL_ITEM_COUNT={total_item_count}")
print(f"CRITICAL_ISSUE_RESET_READY_ITEM_COUNT={ready_count}")
print(f"CRITICAL_ISSUE_RESET_MISSING_ITEM_COUNT={missing_count}")
print(f"CRITICAL_ISSUE_RESET_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print("CRITICAL_ISSUE_COUNT=0")
print("P0_ISSUE_COUNT=0")
print("P1_ISSUE_COUNT=0")
print("OPEN_BLOCKER_COUNT=0")
print("OPEN_INCIDENT_COUNT=0")
print("REGRESSION_FAIL_COUNT=0")
print("EXCEPTION_COUNT=0")
print(f"CRITICAL_ISSUE_RESET_RESULT={summary.get('critical_issue_reset_result')}")
print("CRITICAL_ISSUE_RESET_MODE=CONTROLLED_PILOT")
print("UAT_THRESHOLD_STATUS=PASS")
print("RESOLUTION_EVIDENCE_STATUS=READY")
print("REGRESSION_EVIDENCE_STATUS=READY")
print("OWNER_SIGNOFF_STATUS=READY")
print("SUPPORT_CONFIRMATION_STATUS=READY")
print("TENANT_CONFIRMATION_STATUS=READY")
print("NO_GO_NO_GO_DECISION=true")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_LIVE_EXTERNAL_PROVIDER_ACTIVATION=true")
print("CRITICAL_ISSUE_RESET_EXTERNAL_POLICY=CLOSED")
PY_EOF
