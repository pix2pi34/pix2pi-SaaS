#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_4_1_kullanici_egitim_seti.v1.json}"
TRAINING_FILE="${TRAINING_FILE:-configs/faz4r/user_training_set.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "USER_TRAINING_SET_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$TRAINING_FILE" ]; then
  fail "TRAINING_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$TRAINING_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$TRAINING_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
training_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
training_artifact = json.loads(training_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 210, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_4_1", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("training_policy", {})
required_modules = set(config.get("required_training_modules", []))

require(payload.get("training_set_status") == policy.get("training_set_status_required"), "TRAINING_SET_STATUS_NOT_READY")
require(payload.get("training_mode") == policy.get("training_mode_required"), "TRAINING_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

modules = payload.get("training_modules", [])
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(modules, list), "TRAINING_MODULES_NOT_LIST")

provided_modules = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(modules, list):
    for idx, module in enumerate(modules, start=1):
        prefix = f"TRAINING_MODULE_{idx}"
        require(isinstance(module, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(module, dict):
            continue

        code = module.get("code")
        status = module.get("status")
        required = module.get("required")
        evidence_ref = module.get("evidence_ref")
        audience = module.get("audience")
        fmt = module.get("format")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_modules.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(audience), f"{prefix}_AUDIENCE_REQUIRED")
        require(non_empty(fmt), f"{prefix}_FORMAT_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_module_status_required"), f"REQUIRED_TRAINING_MODULE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_modules)
missing_modules = sorted(required_modules - provided_set)
require(not missing_modules, "REQUIRED_TRAINING_MODULES_MISSING:" + ",".join(missing_modules))
require(len(provided_modules) == len(provided_set), "DUPLICATE_TRAINING_MODULE_CODE_FOUND")

total_module_count = summary.get("total_module_count")
summary_ready_module_count = summary.get("ready_module_count")
summary_missing_module_count = summary.get("missing_module_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_module_count, int) and total_module_count >= 0, "TOTAL_MODULE_COUNT_INVALID")
require(isinstance(summary_ready_module_count, int) and summary_ready_module_count >= 0, "READY_MODULE_COUNT_INVALID")
require(isinstance(summary_missing_module_count, int) and summary_missing_module_count >= 0, "MISSING_MODULE_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

if isinstance(total_module_count, int):
    require(total_module_count == len(modules), "TOTAL_MODULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_module_count, int):
    require(summary_ready_module_count == ready_count, "READY_MODULE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_module_count, int):
    require(summary_missing_module_count == missing_count, "MISSING_MODULE_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_module_count == policy.get("missing_module_count_required"), "MISSING_MODULE_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")

require(summary.get("uat_signoff_status") == policy.get("uat_signoff_status_required"), "UAT_SIGNOFF_STATUS_NOT_PASS")
require(summary.get("support_handoff_ready") == policy.get("support_handoff_ready_required"), "SUPPORT_HANDOFF_NOT_READY")
require(summary.get("completion_checklist_status") == policy.get("completion_checklist_status_required"), "COMPLETION_CHECKLIST_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("training_result") == "PASS", "TRAINING_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("training_result") == "FAIL", "TRAINING_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_export") == "CLOSED", "REAL_EXPORT_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")

if errors:
    print("USER_TRAINING_SET_STATUS=FAIL")
    print(f"USER_TRAINING_SET_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"USER_TRAINING_SET_FAIL={error}")
    sys.exit(1)

print("USER_TRAINING_SET_STATUS=PASS")
print(f"USER_TRAINING_SET_TENANT_ID={tenant.get('tenant_id')}")
print(f"USER_TRAINING_SET_TOTAL_MODULE_COUNT={total_module_count}")
print(f"USER_TRAINING_SET_READY_MODULE_COUNT={ready_count}")
print(f"USER_TRAINING_SET_MISSING_MODULE_COUNT={missing_count}")
print(f"USER_TRAINING_SET_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"USER_TRAINING_SET_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"USER_TRAINING_SET_RESULT={summary.get('training_result')}")
print("USER_TRAINING_SET_MODE=CONTROLLED_PILOT")
print("UAT_SIGNOFF_STATUS=PASS")
print("SUPPORT_HANDOFF_READY=YES")
print("COMPLETION_CHECKLIST_STATUS=READY")
print("USER_TRAINING_SET_EXTERNAL_POLICY=CLOSED")
PY_EOF
