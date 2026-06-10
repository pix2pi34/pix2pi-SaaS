#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_5_import_validation_raporu.v1.json}"
SCHEMA_FILE="${SCHEMA_FILE:-configs/faz4r/import_validation_report_schema.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "IMPORT_VALIDATION_REPORT_ERROR=$1"
  exit 1
}

if [ -z "$INPUT_FILE" ]; then
  fail "INPUT_FILE_REQUIRED"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$SCHEMA_FILE" ]; then
  fail "SCHEMA_FILE_NOT_FOUND"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$SCHEMA_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
schema_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
schema = json.loads(schema_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 202, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_5", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("report_policy", {})
supported_import_types = set(config.get("supported_import_types", []))
allowed_results = set(config.get("allowed_report_results", []))
allowed_severities = set(config.get("allowed_severities", []))

require(schema.get("schema_status") == "READY", "SCHEMA_STATUS_NOT_READY")
require(schema.get("validation_mode") == policy.get("validation_mode_required"), "SCHEMA_VALIDATION_MODE_INVALID")
require(schema.get("commit_allowed") is False, "SCHEMA_COMMIT_ALLOWED_TRUE")
require(schema.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "SCHEMA_CLOSED_POLICY_REFERENCE_MISSING")

summary = payload.get("summary", {})
row_results = payload.get("row_results", [])
report_errors = payload.get("errors", [])
warnings = payload.get("warnings", [])
external_policy = payload.get("external_policy", {})

required_summary_fields = schema.get("required_summary_fields", [])
for field in required_summary_fields:
    require(field in summary, f"SUMMARY_FIELD_MISSING:{field}")

tenant_id = summary.get("tenant_id")
batch_id = summary.get("batch_id")
import_type = summary.get("import_type")
report_id = summary.get("report_id")
report_status = summary.get("report_status")
report_result = summary.get("report_result")
validation_mode = summary.get("validation_mode")
commit_requested = summary.get("commit_requested")

total_rows = summary.get("total_rows")
valid_rows = summary.get("valid_rows")
invalid_rows = summary.get("invalid_rows")
warning_count = summary.get("warning_count")
error_count = summary.get("error_count")
evidence_ref = summary.get("evidence_ref")

require(non_empty(tenant_id), "TENANT_ID_REQUIRED")
require(non_empty(batch_id), "BATCH_ID_REQUIRED")
require(non_empty(report_id), "REPORT_ID_REQUIRED")
require(import_type in supported_import_types, "IMPORT_TYPE_NOT_SUPPORTED")
require(report_status == policy.get("report_status_required"), "REPORT_STATUS_NOT_READY")
require(report_result in allowed_results, "REPORT_RESULT_INVALID")
require(validation_mode == policy.get("validation_mode_required"), "VALIDATION_MODE_NOT_DRY_RUN")
require(commit_requested is False, "COMMIT_REQUESTED_NOT_ALLOWED")
require(non_empty(evidence_ref), "EVIDENCE_REF_REQUIRED")

for name, value in [
    ("total_rows", total_rows),
    ("valid_rows", valid_rows),
    ("invalid_rows", invalid_rows),
    ("warning_count", warning_count),
    ("error_count", error_count)
]:
    require(isinstance(value, int) and value >= 0, f"{name.upper()}_INVALID")

if all(isinstance(x, int) for x in [total_rows, valid_rows, invalid_rows]):
    require(total_rows == valid_rows + invalid_rows, "TOTAL_ROWS_RECONCILIATION_FAILED")

require(isinstance(row_results, list), "ROW_RESULTS_NOT_LIST")
if isinstance(row_results, list) and isinstance(total_rows, int):
    require(len(row_results) == total_rows, "ROW_RESULTS_COUNT_MISMATCH")

require(isinstance(report_errors, list), "ERRORS_NOT_LIST")
require(isinstance(warnings, list), "WARNINGS_NOT_LIST")

if isinstance(report_errors, list) and isinstance(error_count, int):
    require(error_count == len(report_errors), "ERROR_COUNT_MISMATCH")

if isinstance(warnings, list) and isinstance(warning_count, int):
    require(warning_count == len(warnings), "WARNING_COUNT_MISMATCH")

if isinstance(invalid_rows, int):
    if invalid_rows > 0:
        require(report_result == "FAIL", "INVALID_ROWS_REQUIRES_FAIL_RESULT")
        require(error_count and error_count > 0, "INVALID_ROWS_REQUIRES_ERROR_COUNT")
    if invalid_rows == 0:
        require(report_result == "PASS", "ZERO_INVALID_ROWS_REQUIRES_PASS_RESULT")

required_error_fields = schema.get("required_error_fields", [])
for idx, item in enumerate(report_errors, start=1):
    prefix = f"ERROR_{idx}"
    require(isinstance(item, dict), f"{prefix}_NOT_OBJECT")
    if not isinstance(item, dict):
        continue
    for field in required_error_fields:
        require(field in item, f"{prefix}_FIELD_MISSING:{field}")
    require(isinstance(item.get("row_no"), int) and item.get("row_no") > 0, f"{prefix}_ROW_NO_INVALID")
    require(non_empty(item.get("field")), f"{prefix}_FIELD_REQUIRED")
    require(non_empty(item.get("code")), f"{prefix}_CODE_REQUIRED")
    require(item.get("severity") == "ERROR", f"{prefix}_SEVERITY_INVALID")
    require(non_empty(item.get("message")), f"{prefix}_MESSAGE_REQUIRED")

required_warning_fields = schema.get("required_warning_fields", [])
for idx, item in enumerate(warnings, start=1):
    prefix = f"WARNING_{idx}"
    require(isinstance(item, dict), f"{prefix}_NOT_OBJECT")
    if not isinstance(item, dict):
        continue
    for field in required_warning_fields:
        require(field in item, f"{prefix}_FIELD_MISSING:{field}")
    require(isinstance(item.get("row_no"), int) and item.get("row_no") > 0, f"{prefix}_ROW_NO_INVALID")
    require(non_empty(item.get("field")), f"{prefix}_FIELD_REQUIRED")
    require(non_empty(item.get("code")), f"{prefix}_CODE_REQUIRED")
    require(item.get("severity") == "WARNING", f"{prefix}_SEVERITY_INVALID")
    require(non_empty(item.get("message")), f"{prefix}_MESSAGE_REQUIRED")

for idx, item in enumerate(row_results if isinstance(row_results, list) else [], start=1):
    prefix = f"ROW_RESULT_{idx}"
    require(isinstance(item, dict), f"{prefix}_NOT_OBJECT")
    if not isinstance(item, dict):
        continue
    require(isinstance(item.get("row_no"), int) and item.get("row_no") > 0, f"{prefix}_ROW_NO_INVALID")
    require(item.get("status") in {"VALID", "INVALID"}, f"{prefix}_STATUS_INVALID")
    require(isinstance(item.get("error_count"), int) and item.get("error_count") >= 0, f"{prefix}_ERROR_COUNT_INVALID")
    require(isinstance(item.get("warning_count"), int) and item.get("warning_count") >= 0, f"{prefix}_WARNING_COUNT_INVALID")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("IMPORT_VALIDATION_REPORT_STATUS=FAIL")
    print(f"IMPORT_VALIDATION_REPORT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"IMPORT_VALIDATION_REPORT_FAIL={error}")
    sys.exit(1)

print("IMPORT_VALIDATION_REPORT_STATUS=PASS")
print(f"IMPORT_VALIDATION_REPORT_ID={report_id}")
print(f"IMPORT_VALIDATION_REPORT_TENANT_ID={tenant_id}")
print(f"IMPORT_VALIDATION_REPORT_BATCH_ID={batch_id}")
print(f"IMPORT_VALIDATION_REPORT_IMPORT_TYPE={import_type}")
print(f"IMPORT_VALIDATION_REPORT_RESULT={report_result}")
print(f"IMPORT_VALIDATION_REPORT_TOTAL_ROWS={total_rows}")
print(f"IMPORT_VALIDATION_REPORT_VALID_ROWS={valid_rows}")
print(f"IMPORT_VALIDATION_REPORT_INVALID_ROWS={invalid_rows}")
print(f"IMPORT_VALIDATION_REPORT_ERROR_COUNT={error_count}")
print(f"IMPORT_VALIDATION_REPORT_WARNING_COUNT={warning_count}")
print("IMPORT_VALIDATION_REPORT_MODE=DRY_RUN")
print("IMPORT_VALIDATION_REPORT_COMMIT_ALLOWED=false")
print("IMPORT_VALIDATION_REPORT_EXTERNAL_POLICY=CLOSED")
PY_EOF
