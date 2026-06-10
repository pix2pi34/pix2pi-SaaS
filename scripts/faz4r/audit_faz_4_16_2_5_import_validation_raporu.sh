#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU.md"
CONFIG_FILE="configs/faz4r/faz_4_16_2_5_import_validation_raporu.v1.json"
SCHEMA_FILE="configs/faz4r/import_validation_report_schema.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_import_validation_report.sh"
TEST_FILE="tests/faz4r/faz_4_16_2_5_import_validation_raporu_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_executable() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

extract_fixture() {
  local fixture_name="$1"
  local output_file="$2"

  python3 - "$TEST_FILE" "$fixture_name" "$output_file" <<'PY_EOF'
import json
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
fixture_name = sys.argv[2]
output_file = Path(sys.argv[3])

payload = json.loads(test_file.read_text())
output_file.write_text(json.dumps(payload[fixture_name], ensure_ascii=False, indent=2))
PY_EOF
}

run_fixture_tests() {
  local valid_pass_file="/tmp/faz_4_16_2_5_valid_pass_$$.json"
  local valid_fail_file="/tmp/faz_4_16_2_5_valid_fail_$$.json"
  local invalid_file="/tmp/faz_4_16_2_5_invalid_$$.json"
  local valid_pass_out="/tmp/faz_4_16_2_5_valid_pass_$$.out"
  local valid_fail_out="/tmp/faz_4_16_2_5_valid_fail_$$.out"
  local invalid_out="/tmp/faz_4_16_2_5_invalid_$$.out"

  extract_fixture "valid_pass_fixture" "$valid_pass_file"
  extract_fixture "valid_fail_fixture" "$valid_fail_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" SCHEMA_FILE="$SCHEMA_FILE" INPUT_FILE="$valid_pass_file" "$RUNTIME_SCRIPT" > "$valid_pass_out" 2>&1; then
    if grep -Fq "IMPORT_VALIDATION_REPORT_STATUS=PASS" "$valid_pass_out"; then
      record_pass "valid PASS validation report fixture PASS"
    else
      record_fail "valid PASS validation report fixture PASS"
      cat "$valid_pass_out" || true
    fi
  else
    record_fail "valid PASS validation report fixture execution"
    cat "$valid_pass_out" || true
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_RESULT=PASS" "$valid_pass_out"; then
    record_pass "valid PASS report result marker"
  else
    record_fail "valid PASS report result marker"
  fi

  if CONFIG_FILE="$CONFIG_FILE" SCHEMA_FILE="$SCHEMA_FILE" INPUT_FILE="$valid_fail_file" "$RUNTIME_SCRIPT" > "$valid_fail_out" 2>&1; then
    if grep -Fq "IMPORT_VALIDATION_REPORT_STATUS=PASS" "$valid_fail_out" && grep -Fq "IMPORT_VALIDATION_REPORT_RESULT=FAIL" "$valid_fail_out"; then
      record_pass "valid FAIL validation report fixture PASS"
    else
      record_fail "valid FAIL validation report fixture PASS"
      cat "$valid_fail_out" || true
    fi
  else
    record_fail "valid FAIL validation report fixture execution"
    cat "$valid_fail_out" || true
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_ERROR_COUNT=2" "$valid_fail_out"; then
    record_pass "valid FAIL report error count marker"
  else
    record_fail "valid FAIL report error count marker"
  fi

  if CONFIG_FILE="$CONFIG_FILE" SCHEMA_FILE="$SCHEMA_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid validation report fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "IMPORT_VALIDATION_REPORT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid validation report fixture FAIL guard"
    else
      record_fail "invalid validation report fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=TENANT_ID_REQUIRED" "$invalid_out"; then
    record_pass "tenant id required guard"
  else
    record_fail "tenant id required guard"
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=TOTAL_ROWS_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rows reconciliation guard"
  else
    record_fail "total rows reconciliation guard"
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=ERROR_COUNT_MISMATCH" "$invalid_out"; then
    record_pass "error count mismatch guard"
  else
    record_fail "error count mismatch guard"
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=WARNING_COUNT_MISMATCH" "$invalid_out"; then
    record_pass "warning count mismatch guard"
  else
    record_fail "warning count mismatch guard"
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=ERROR_1_SEVERITY_INVALID" "$invalid_out"; then
    record_pass "error severity guard"
  else
    record_fail "error severity guard"
  fi

  if grep -Fq "IMPORT_VALIDATION_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider validation report guard"
  else
    record_fail "closed external provider validation report guard"
  fi

  rm -f "$valid_pass_file" "$valid_fail_file" "$invalid_file" "$valid_pass_out" "$valid_fail_out" "$invalid_out"
}

{
  echo "===== 202 — FAZ 4-16.2.5 IMPORT VALIDATION RAPORU REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "schema file exists" "$SCHEMA_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.2.5 Import Validation Raporu"
  check_contains "doc supported customer marker" "$DOC_FILE" "CUSTOMER"
  check_contains "doc dry-run marker" "$DOC_FILE" "validation_mode = DRY_RUN"
  check_contains "doc count reconciliation marker" "$DOC_FILE" "total_rows = valid_rows + invalid_rows"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 202"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 198 marker" "$CONFIG_FILE" "198_FAZ_4_16_2_1_CARI_IMPORT"
  check_contains "config dependency 199 marker" "$CONFIG_FILE" "199_FAZ_4_16_2_2_URUN_STOK_IMPORT"
  check_contains "config dependency 200 marker" "$CONFIG_FILE" "200_FAZ_4_16_2_3_FIS_HAREKET_IMPORT"
  check_contains "config dependency 201 marker" "$CONFIG_FILE" "201_FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI"
  check_contains "config dry-run marker" "$CONFIG_FILE" "\"validation_mode_required\": \"DRY_RUN\""
  check_contains "config commit forbidden marker" "$CONFIG_FILE" "\"commit_allowed\": false"
  check_contains "config count reconciliation marker" "$CONFIG_FILE" "\"count_reconciliation_required\": true"
  check_contains "config evidence marker" "$CONFIG_FILE" "\"evidence_ref_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "schema status ready marker" "$SCHEMA_FILE" "\"schema_status\": \"READY\""
  check_contains "schema dry-run marker" "$SCHEMA_FILE" "\"validation_mode\": \"DRY_RUN\""
  check_contains "schema customer marker" "$SCHEMA_FILE" "\"CUSTOMER\""
  check_contains "schema product stock marker" "$SCHEMA_FILE" "\"PRODUCT_STOCK\""
  check_contains "schema receipt movement marker" "$SCHEMA_FILE" "\"RECEIPT_MOVEMENT\""
  check_contains "schema summary fields marker" "$SCHEMA_FILE" "\"required_summary_fields\""
  check_contains "schema error fields marker" "$SCHEMA_FILE" "\"required_error_fields\""
  check_contains "schema warning fields marker" "$SCHEMA_FILE" "\"required_warning_fields\""
  check_contains "schema closed policy marker" "$SCHEMA_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime schema guard marker" "$RUNTIME_SCRIPT" "SCHEMA_FILE_NOT_FOUND"
  check_contains "runtime tenant guard marker" "$RUNTIME_SCRIPT" "TENANT_ID_REQUIRED"
  check_contains "runtime dry-run guard marker" "$RUNTIME_SCRIPT" "VALIDATION_MODE_NOT_DRY_RUN"
  check_contains "runtime commit guard marker" "$RUNTIME_SCRIPT" "COMMIT_REQUESTED_NOT_ALLOWED"
  check_contains "runtime total reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ROWS_RECONCILIATION_FAILED"
  check_contains "runtime error count guard marker" "$RUNTIME_SCRIPT" "ERROR_COUNT_MISMATCH"
  check_contains "runtime warning count guard marker" "$RUNTIME_SCRIPT" "WARNING_COUNT_MISMATCH"
  check_contains "runtime external policy marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "IMPORT_VALIDATION_REPORT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "IMPORT_VALIDATION_REPORT_STATUS=FAIL"

  check_contains "test valid pass fixture marker" "$TEST_FILE" "\"valid_pass_fixture\""
  check_contains "test valid fail fixture marker" "$TEST_FILE" "\"valid_fail_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test row results marker" "$TEST_FILE" "\"row_results\""
  check_contains "test errors marker" "$TEST_FILE" "\"errors\""
  check_contains "test warnings marker" "$TEST_FILE" "\"warnings\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 202 — FAZ 4-16.2.5 IMPORT VALIDATION RAPORU COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_DOC_STATUS=READY"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_CONFIG_STATUS=READY"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_SCHEMA_STATUS=READY"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_TEST_STATUS=PASS"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_FINAL_STATUS=PASS"
    echo "FAZ_4_16_2_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_TEST_STATUS=FAIL"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_2_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
