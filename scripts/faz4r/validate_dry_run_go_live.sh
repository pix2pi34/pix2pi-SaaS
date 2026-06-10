#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_7_1_dry_run_canliya_gecis.v1.json}"
DRY_RUN_FILE="${DRY_RUN_FILE:-configs/faz4r/dry_run_go_live.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "DRY_RUN_GO_LIVE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then fail "CONFIG_FILE_NOT_FOUND"; fi
if [ ! -f "$DRY_RUN_FILE" ]; then fail "DRY_RUN_FILE_NOT_FOUND"; fi
if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$DRY_RUN_FILE"; fi
if [ ! -f "$INPUT_FILE" ]; then fail "INPUT_FILE_NOT_FOUND"; fi
if ! command -v python3 >/dev/null 2>&1; then fail "PYTHON3_NOT_FOUND"; fi

python3 - "$CONFIG_FILE" "$DRY_RUN_FILE" "$INPUT_FILE" <<'PY_EOF'
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
require(config.get("phase_no") == 226, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_7_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("dry_run_policy", {})
required_rules = set(config.get("required_dry_run_rules", []))

require(payload.get("dry_run_status") == policy.get("dry_run_status_required"), "DRY_RUN_STATUS_NOT_READY")
require(payload.get("dry_run_mode") == policy.get("dry_run_mode_required"), "DRY_RUN_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")
require(tenant.get("tenant_status") == "PILOT_ACTIVE", "TENANT_STATUS_NOT_PILOT_ACTIVE")

for dependency in config.get("depends_on", []):
    require(payload.get("chain_dependencies", {}).get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

rules = payload.get("dry_run_rules", [])
controls = payload.get("dry_run_controls", {})
metrics = payload.get("dry_run_metrics", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(rules, list), "DRY_RUN_RULES_NOT_LIST")

provided_rules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(rules, list):
    for idx, rule in enumerate(rules, start=1):
        prefix = f"DRY_RUN_RULE_{idx}"
        require(isinstance(rule, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(rule, dict):
            continue

        code = rule.get("code")
        status = rule.get("status")
        required = rule.get("required")
        area = rule.get("area")
        owner = rule.get("owner")
        evidence_ref = rule.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_rules.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(area), f"{prefix}_AREA_REQUIRED")
        require(non_empty(owner), f"{prefix}_OWNER_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_rule_status_required"), f"REQUIRED_DRY_RUN_RULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_rules)
missing_rules = sorted(required_rules - provided_set)
require(not missing_rules, "REQUIRED_DRY_RUN_RULES_MISSING:" + ",".join(missing_rules))
require(len(provided_rules) == len(provided_set), "DUPLICATE_DRY_RUN_RULE_CODE_FOUND")

total_rule_count = summary.get("total_rule_count")
summary_ready_rule_count = summary.get("ready_rule_count")
summary_missing_rule_count = summary.get("missing_rule_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")
open_blocker_count = summary.get("open_blocker_count")

require(isinstance(total_rule_count, int) and total_rule_count >= 0, "TOTAL_RULE_COUNT_INVALID")
require(isinstance(summary_ready_rule_count, int) and summary_ready_rule_count >= 0, "READY_RULE_COUNT_INVALID")
require(isinstance(summary_missing_rule_count, int) and summary_missing_rule_count >= 0, "MISSING_RULE_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")
require(isinstance(open_blocker_count, int) and open_blocker_count >= 0, "OPEN_BLOCKER_COUNT_INVALID")

if isinstance(total_rule_count, int):
    require(total_rule_count == len(rules), "TOTAL_RULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_rule_count, int):
    require(summary_ready_rule_count == ready_count, "READY_RULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_rule_count, int):
    require(summary_missing_rule_count == missing_count, "MISSING_RULE_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_rule_count == policy.get("missing_rule_count_required"), "MISSING_RULE_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")
if isinstance(open_blocker_count, int):
    require(open_blocker_count == policy.get("open_blocker_count_required"), "OPEN_BLOCKER_COUNT_NOT_ZERO")

require(summary.get("feedback_closure_status") == policy.get("feedback_closure_status_required"), "FEEDBACK_CLOSURE_STATUS_NOT_PASS")
require(summary.get("tenant_readiness_status") == policy.get("tenant_readiness_status_required"), "TENANT_READINESS_STATUS_NOT_READY")
require(summary.get("import_closure_status") == policy.get("import_closure_status_required"), "IMPORT_CLOSURE_STATUS_NOT_READY")
require(summary.get("uat_closure_status") == policy.get("uat_closure_status_required"), "UAT_CLOSURE_STATUS_NOT_READY")
require(summary.get("backup_snapshot_status") == policy.get("backup_snapshot_status_required"), "BACKUP_SNAPSHOT_STATUS_NOT_READY")
require(summary.get("rollback_readiness_status") == policy.get("rollback_readiness_status_required"), "ROLLBACK_READINESS_STATUS_NOT_READY")
require(summary.get("monitoring_status") == policy.get("monitoring_status_required"), "MONITORING_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(controls.get("feedback_closure_status") == "PASS", "CONTROL_FEEDBACK_CLOSURE_NOT_PASS")
require(controls.get("tenant_readiness_status") == "READY", "CONTROL_TENANT_READINESS_NOT_READY")
require(controls.get("import_closure_status") == "READY", "CONTROL_IMPORT_CLOSURE_NOT_READY")
require(controls.get("readmodel_reporting_status") == "READY", "CONTROL_READMODEL_REPORTING_NOT_READY")
require(controls.get("uat_closure_status") == "READY", "CONTROL_UAT_CLOSURE_NOT_READY")
require(controls.get("support_feedback_closure_status") == "READY", "CONTROL_SUPPORT_FEEDBACK_CLOSURE_NOT_READY")
require(controls.get("backup_snapshot_status") == "READY", "CONTROL_BACKUP_SNAPSHOT_NOT_READY")
require(controls.get("rollback_readiness_status") == "READY", "CONTROL_ROLLBACK_READINESS_NOT_READY")
require(controls.get("communication_draft_status") == "READY", "CONTROL_COMMUNICATION_DRAFT_NOT_READY")
require(controls.get("runtime_health_status") == "READY", "CONTROL_RUNTIME_HEALTH_NOT_READY")
require(controls.get("monitoring_status") == "READY", "CONTROL_MONITORING_NOT_READY")

require(controls.get("no_production_launch") is policy.get("no_production_launch_required"), "PRODUCTION_LAUNCH_NOT_DISABLED")
require(controls.get("no_dns_change") is policy.get("no_dns_change_required"), "DNS_CHANGE_NOT_DISABLED")
require(controls.get("no_nginx_change") is policy.get("no_nginx_change_required"), "NGINX_CHANGE_NOT_DISABLED")
require(controls.get("no_ssl_change") is True, "SSL_CHANGE_NOT_DISABLED")
require(controls.get("no_live_external_provider_activation") is policy.get("no_live_external_provider_activation_required"), "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED")

require(metrics.get("open_blocker_count") == 0, "METRIC_OPEN_BLOCKER_COUNT_NOT_ZERO")
require(metrics.get("critical_issue_count") == 0, "METRIC_CRITICAL_ISSUE_COUNT_NOT_ZERO")
require(metrics.get("required_fail_count") == 0, "METRIC_REQUIRED_FAIL_COUNT_NOT_ZERO")
require(metrics.get("missing_rule_count") == 0, "METRIC_MISSING_RULE_COUNT_NOT_ZERO")
require(metrics.get("production_launch_count") == 0, "PRODUCTION_LAUNCH_COUNT_NOT_ZERO")
require(metrics.get("dns_change_count") == 0, "DNS_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("nginx_change_count") == 0, "NGINX_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("ssl_change_count") == 0, "SSL_CHANGE_COUNT_NOT_ZERO")
require(metrics.get("live_external_provider_activation_count") == 0, "LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO")
require(metrics.get("live_external_policy_status") == "CLOSED", "METRIC_LIVE_EXTERNAL_POLICY_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0 and open_blocker_count == 0:
    require(summary.get("dry_run_result") == "PASS", "DRY_RUN_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("dry_run_result") == "FAIL", "DRY_RUN_RESULT_SHOULD_BE_FAIL")

for key in [
    "live_external_provider", "gib", "bank", "pos_provider", "payment_provider",
    "production_launch", "dns_change", "nginx_change", "ssl_change",
    "hotfix_deploy", "real_rollback_execution"
]:
    require(external_policy.get(key) == "CLOSED", f"{key.upper()}_NOT_CLOSED")

if errors:
    print("DRY_RUN_GO_LIVE_STATUS=FAIL")
    print(f"DRY_RUN_GO_LIVE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"DRY_RUN_GO_LIVE_FAIL={error}")
    sys.exit(1)

print("DRY_RUN_GO_LIVE_STATUS=PASS")
print(f"DRY_RUN_GO_LIVE_TENANT_ID={tenant.get('tenant_id')}")
print(f"DRY_RUN_GO_LIVE_TOTAL_RULE_COUNT={total_rule_count}")
print(f"DRY_RUN_GO_LIVE_READY_RULE_COUNT={ready_count}")
print(f"DRY_RUN_GO_LIVE_MISSING_RULE_COUNT={missing_count}")
print(f"DRY_RUN_GO_LIVE_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"DRY_RUN_GO_LIVE_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"DRY_RUN_GO_LIVE_OPEN_BLOCKER_COUNT={open_blocker_count}")
print(f"DRY_RUN_GO_LIVE_RESULT={summary.get('dry_run_result')}")
print("DRY_RUN_GO_LIVE_MODE=CONTROLLED_PILOT")
print("TENANT_READINESS_STATUS=READY")
print("IMPORT_CLOSURE_STATUS=READY")
print("UAT_CLOSURE_STATUS=READY")
print("BACKUP_SNAPSHOT_STATUS=READY")
print("ROLLBACK_READINESS_STATUS=READY")
print("MONITORING_STATUS=READY")
print("NO_PRODUCTION_LAUNCH=true")
print("NO_DNS_CHANGE=true")
print("NO_NGINX_CHANGE=true")
print("DRY_RUN_GO_LIVE_EXTERNAL_POLICY=CLOSED")
PY_EOF
