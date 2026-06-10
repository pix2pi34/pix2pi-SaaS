#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_6_import_testleri.v1.json}"
SUITE_FILE="${SUITE_FILE:-configs/faz4r/import_test_suite.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "IMPORT_TEST_SUITE_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$SUITE_FILE" ]; then
  fail "SUITE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$SUITE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$SUITE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
suite_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
suite = json.loads(suite_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 203, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_6", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("test_suite_policy", {})
required_cases = set(config.get("required_test_cases", []))

require(payload.get("suite_status") == policy.get("suite_status_required"), "SUITE_STATUS_NOT_READY")
require(payload.get("test_mode") == policy.get("test_mode_required"), "TEST_MODE_NOT_DRY_RUN")
require(payload.get("commit_allowed") is False, "COMMIT_ALLOWED_TRUE")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

test_cases = payload.get("test_cases", [])
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(test_cases, list), "TEST_CASES_NOT_LIST")

provided_cases = set()
pass_count = 0
fail_count = 0
required_fail_count = 0
optional_warn_count = 0

if isinstance(test_cases, list):
    for idx, case in enumerate(test_cases, start=1):
        prefix = f"TEST_CASE_{idx}"
        require(isinstance(case, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(case, dict):
            continue

        code = case.get("code")
        status = case.get("status")
        required = case.get("required")
        evidence_ref = case.get("evidence_ref")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_cases.add(code)

        require(status in {"PASS", "FAIL", "WARN"}, f"{prefix}_STATUS_INVALID")

        if status == "PASS":
            pass_count += 1
        elif status == "FAIL":
            fail_count += 1
            if required is True:
                required_fail_count += 1
        elif status == "WARN":
            optional_warn_count += 1

        if required is True:
            require(status == "PASS", f"REQUIRED_TEST_CASE_NOT_PASS:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")

missing_cases = sorted(required_cases - provided_cases)
require(not missing_cases, "REQUIRED_TEST_CASES_MISSING:" + ",".join(missing_cases))

duplicate_cases = len(provided_cases) != len(test_cases) if isinstance(test_cases, list) else True
require(not duplicate_cases, "DUPLICATE_TEST_CASE_CODE_FOUND")

total_test_count = summary.get("total_test_count")
summary_pass_count = summary.get("pass_count")
summary_fail_count = summary.get("fail_count")
summary_required_fail_count = summary.get("required_fail_count")
summary_optional_warn_count = summary.get("optional_warn_count")
suite_result = summary.get("suite_result")

require(isinstance(total_test_count, int) and total_test_count >= 0, "TOTAL_TEST_COUNT_INVALID")
require(isinstance(summary_pass_count, int) and summary_pass_count >= 0, "PASS_COUNT_INVALID")
require(isinstance(summary_fail_count, int) and summary_fail_count >= 0, "FAIL_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(summary_optional_warn_count, int) and summary_optional_warn_count >= 0, "OPTIONAL_WARN_COUNT_INVALID")

if isinstance(total_test_count, int):
    require(total_test_count == len(test_cases), "TOTAL_TEST_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_pass_count, int):
    require(summary_pass_count == pass_count, "PASS_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_fail_count, int):
    require(summary_fail_count == fail_count, "FAIL_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(summary_optional_warn_count, int):
    require(summary_optional_warn_count == optional_warn_count, "OPTIONAL_WARN_COUNT_RECONCILIATION_FAILED")
    require(summary_optional_warn_count <= policy.get("optional_warn_count_max", 0), "OPTIONAL_WARN_COUNT_EXCEEDS_LIMIT")

if fail_count == 0 and required_fail_count == 0:
    require(suite_result == "PASS", "SUITE_RESULT_SHOULD_BE_PASS")
else:
    require(suite_result == "FAIL", "SUITE_RESULT_SHOULD_BE_FAIL")

require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")
require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")

if errors:
    print("IMPORT_TEST_SUITE_STATUS=FAIL")
    print(f"IMPORT_TEST_SUITE_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"IMPORT_TEST_SUITE_FAIL={error}")
    sys.exit(1)

print("IMPORT_TEST_SUITE_STATUS=PASS")
print(f"IMPORT_TEST_SUITE_TOTAL_TEST_COUNT={total_test_count}")
print(f"IMPORT_TEST_SUITE_PASS_COUNT={pass_count}")
print(f"IMPORT_TEST_SUITE_FAIL_COUNT={fail_count}")
print(f"IMPORT_TEST_SUITE_REQUIRED_FAIL_COUNT={required_fail_count}")
print(f"IMPORT_TEST_SUITE_OPTIONAL_WARN_COUNT={optional_warn_count}")
print(f"IMPORT_TEST_SUITE_RESULT={suite_result}")
print("IMPORT_TEST_SUITE_MODE=DRY_RUN")
print("IMPORT_TEST_SUITE_COMMIT_ALLOWED=false")
print("IMPORT_TEST_SUITE_EXTERNAL_POLICY=CLOSED")
PY_EOF
