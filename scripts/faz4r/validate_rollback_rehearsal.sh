#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_7_3_geri_donus_provasi.v1.json}"
ROLLBACK_FILE="${ROLLBACK_FILE:-configs/faz4r/rollback_rehearsal.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "ROLLBACK_REHEARSAL_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$ROLLBACK_FILE" ]; then fail "ROLLBACK_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$ROLLBACK_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$ROLLBACK_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 228, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_7_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("rollback_rehearsal_policy", {})
required_items = set(config.get("required_rehearsal_items", []))

require(payload.get("rollback_rehearsal_status") == policy.get("rollback_rehearsal_status_required"), "ROLLBACK_REHEARSAL_STATUS_NOT_READY")
require(payload.get("rollback_rehearsal_mode") == policy.get("rollback_rehearsal_mode_required"), "ROLLBACK_REHEARSAL_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

items = payload.get("rehearsal_items", [])
controls = payload.get("rollback_controls", {})
metrics = payload.get("rollback_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(items, list), "REHEARSAL_ITEMS_NOT_LIST")

provided_items = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(items, list):
    for idx, item in enumerate(items, start=1):
        prefix = f"REHEARSAL_ITEM_{idx}"
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
            require(status == policy.get("required_item_status_required"), f"REQUIRED_REHEARSAL_ITEM_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_items)
missing_items = sorted(required_items - provided_set)
require(not missing_items, "REQUIRED_REHEARSAL_ITEMS_MISSING:" + ",".join(missing_items))
require(len(provided_items) == len(provided_set), "DUPLICATE_REHEARSAL_ITEM_CODE_FOUND")

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

require(summary.get("cutover_checklist_status") == policy.get("cutover_checklist_status_required"), "CUTOVER_CHECKLIST_STATUS_NOT_PASS")
require(summary.get("backup_snapshot_status") == policy.get("backup_snapshot_status_required"), "BACKUP_SNAPSHOT_STATUS_NOT_READY")
require(summary.get("rollback_package_status") == policy.get("rollback_package_status_required"), "ROLLBACK_PACKAGE_STATUS_NOT_READY")
require(summary.get("data_restore_plan_status") == policy.get("data_restore_plan_status_required"), "DATA_RESTORE_PLAN_STATUS_NOT_READY")
require(summary.get("app_restore_plan_status") == policy.get("app_restore_plan_status_required"), "APP_RESTORE_PLAN_STATUS_NOT_READY")
require(summary.get("route_rollback_plan_status") == policy.get("route_rollback_plan_status_required"), "ROUTE_ROLLBACK_PLAN_STATUS_NOT_READY")
require(summary.get("runtime_health_after_rollback_status") == policy.get("runtime_health_after_rollback_status_required"), "RUNTIME_HEALTH_AFTER_ROLLBACK_STATUS_NOT_READY")
require(summary.get("monitoring_after_rollback_status") == policy.get("monitoring_after_rollback_status_required"), "MONITORING_AFTER_ROLLBACK_STATUS_NOT_READY")
require(summary.get("support_communication_status") == policy.get("support_communication_status_required"), "SUPPORT_COMMUNICATION_STATUS_NOT_READY")
require(summary.get("approval_owner_status") == policy.get("approval_owner_status_required"), "APPROVAL_OWNER_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("cutover_checklist_status") == "PASS", "CONTROL_CUTOVER_CHECKLIST_NOT_PASS")
require(controls.get("backup_snapshot_status") == "READY", "CONTROL_BACKUP_SNAPSHOT_NOT_READY")
require(controls.get("rollback_package_status") == "READY", "CONTROL_ROLLBACK_PACKAGE_NOT_READY")
require(controls.get("rollback_scope_boundary_status") == "READY", "CONTROL_ROLLBACK_SCOPE_NOT_READY")
require(controls.get("data_restore_plan_status") == "READY", "CONTROL_DATA_RESTORE_PLAN_NOT_READY")
require(controls.get("app_restore_plan_status") == "READY", "CONTROL_APP_RESTORE_PLAN_NOT_READY")
require(controls.get("route_rollback_plan_status") == "READY", "CONTROL_ROUTE_ROLLBACK_PLAN_NOT_READY")
require(controls.get("runtime_health_after_rollback_status") == "READY", "CONTROL_RUNTIME_HEALTH_AFTER_ROLLBACK_NOT_READY")
require(controls.get("monitoring_after_rollback_status") == "READY", "CONTROL_MONITORING_AFTER_ROLLBACK_NOT_READY")
require(controls.get("support_communication_status") == "READY", "CONTROL_SUPPORT_COMMUNICATION_NOT_READY")
require(controls.get("approval_owner_status") == "READY", "CONTROL_APPROVAL_OWNER_NOT_READY")

require(controls.get("no_real_rollback_execution") is policy.get("no_real_rollback_execution_required"), "REAL_ROLLBACK_EXECUTION_NOT_DISABLED")
require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_dns_change") is policy.get("no_dns_change_required"), "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is policy.get("no_nginx_change_required"), "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is policy.get("no_ssl_change_required"), "SSL_CHANGE_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_item_count") == 0, "METRIC_MISSING_ITEM_COUNT_NOT_ZERO")
require(metrics.get("real_rollback_execution_count") == 0, "REAL_ROLLBACK_EXECUTION_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("dns_change_count") == 0, "DNS_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("nginx_change_count") == 0, "NGINX_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("ssl_change_count") == 0, "SSL_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("rollback_rehearsal_result") == "PASS", "ROLLBACK_REHEARSAL_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("rollback_rehearsal_result") == "FAIL", "ROLLBACK_REHEARSAL_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("ROLLBACK_REHEARSAL_STATUS=FAIL")
    print(f"ROLLBACK_REHEARSAL_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"ROLLBACK_REHEARSAL_FAIL={error}")
    sys.exit(1)

print("ROLLBACK_REHEARSAL_STATUS=PASS")
print(f"ROLLBACK_REHEARSAL_TENANT_ID={tenant.get('tenant_id')}")
print(f"ROLLBACK_REHEARSAL_TOTAL_ITEM_COUNT={total_item_count}")
print(f"ROLLBACK_REHEARSAL_READY_ITEM_COUNT={ready_count}")
print(f"ROLLBACK_REHEARSAL_MISSING_ITEM_COUNT={missing_count}")
print(f"ROLLBACK_REHEARSAL_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"ROLLBACK_REHEARSAL_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"ROLLBACK_REHEARSAL_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"ROLLBACK_REHEARSAL_RESULT={summary.get('rollback_rehearsal_result')}")
print("ROLLBACK_REHEARSAL_MODE=CONTROLLED_PILOT")
print("BACKUP_SNAPSHOT_STATUS=READY")
print("ROLLBACK_PACKAGE_STATUS=READY")
print("DATA_RESTORE_PLAN_STATUS=READY")
print("APP_RESTORE_PLAN_STATUS=READY")
print("ROUTE_ROLLBACK_PLAN_STATUS=READY")
print("RUNTIME_HEALTH_AFTER_ROLLBACK_STATUS=READY")
print("MONITORING_AFTER_ROLLBACK_STATUS=READY")
print("SUPPORT_COMMUNICATION_STATUS=READY")
print("APPROVAL_OWNER_STATUS=READY")
print("NO_REAL_ROLLBACK_EXECUTION=true")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_DNS_CHANGE=true")
print("NO_NGINX_CHANGE=true")
print("NO_SSL_CHANGE=true")
print("ROLLBACK_REHEARSAL_EXTERNAL_POLICY=CLOSED")
PY_EOF
