#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_2_6_IMPORT_TESTLERI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_2_6_import_testleri.v1.json"
SUITE_FILE="configs/faz4r/import_test_suite.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_import_test_suite.sh"
TEST_FILE="tests/faz4r/faz_4_16_2_6_import_testleri_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_2_6_IMPORT_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_2_6_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_2_6_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_2_6_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_2_6_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" SUITE_FILE="$SUITE_FILE" INPUT_FILE="$SUITE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "IMPORT_TEST_SUITE_STATUS=PASS" "$valid_out"; then
      record_pass "main import test suite artifact PASS"
    else
      record_fail "main import test suite artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main import test suite artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" SUITE_FILE="$SUITE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "IMPORT_TEST_SUITE_STATUS=PASS" "$valid_out"; then
      record_pass "valid import test suite fixture PASS"
    else
      record_fail "valid import test suite fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid import test suite fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "IMPORT_TEST_SUITE_TOTAL_TEST_COUNT=9" "$valid_out"; then
    record_pass "valid import suite total test count"
  else
    record_fail "valid import suite total test count"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_REQUIRED_FAIL_COUNT=0" "$valid_out"; then
    record_pass "valid import suite required fail zero"
  else
    record_fail "valid import suite required fail zero"
  fi

  if CONFIG_FILE="$CONFIG_FILE" SUITE_FILE="$SUITE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid import test suite fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "IMPORT_TEST_SUITE_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid import test suite fixture FAIL guard"
    else
      record_fail "invalid import test suite fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=TEST_MODE_NOT_DRY_RUN" "$invalid_out"; then
    record_pass "dry-run required guard"
  else
    record_fail "dry-run required guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=COMMIT_ALLOWED_TRUE" "$invalid_out"; then
    record_pass "commit forbidden guard"
  else
    record_fail "commit forbidden guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:198_FAZ_4_16_2_1_CARI_IMPORT" "$invalid_out"; then
    record_pass "chain dependency guard"
  else
    record_fail "chain dependency guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=REQUIRED_TEST_CASE_NOT_PASS:CUSTOMER_IMPORT_TEST" "$invalid_out"; then
    record_pass "required test case pass guard"
  else
    record_fail "required test case pass guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=REQUIRED_EVIDENCE_MISSING:CUSTOMER_IMPORT_TEST" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=REQUIRED_TEST_CASES_MISSING" "$invalid_out"; then
    record_pass "missing test cases guard"
  else
    record_fail "missing test cases guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=TOTAL_TEST_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total test count reconciliation guard"
  else
    record_fail "total test count reconciliation guard"
  fi

  if grep -Fq "IMPORT_TEST_SUITE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider import test guard"
  else
    record_fail "closed external provider import test guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 203 — FAZ 4-16.2.6 IMPORT TESTLERI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "suite file exists" "$SUITE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.2.6 Import Testleri"
  check_contains "doc customer import test marker" "$DOC_FILE" "CUSTOMER_IMPORT_TEST"
  check_contains "doc dry-run marker" "$DOC_FILE" "test_mode = DRY_RUN"
  check_contains "doc required fail marker" "$DOC_FILE" "required_fail_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 203"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 198 marker" "$CONFIG_FILE" "198_FAZ_4_16_2_1_CARI_IMPORT"
  check_contains "config dependency 199 marker" "$CONFIG_FILE" "199_FAZ_4_16_2_2_URUN_STOK_IMPORT"
  check_contains "config dependency 200 marker" "$CONFIG_FILE" "200_FAZ_4_16_2_3_FIS_HAREKET_IMPORT"
  check_contains "config dependency 201 marker" "$CONFIG_FILE" "201_FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI"
  check_contains "config dependency 202 marker" "$CONFIG_FILE" "202_FAZ_4_16_2_5_IMPORT_VALIDATION_RAPORU"
  check_contains "config dry-run marker" "$CONFIG_FILE" "\"test_mode_required\": \"DRY_RUN\""
  check_contains "config commit forbidden marker" "$CONFIG_FILE" "\"commit_allowed\": false"
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config evidence marker" "$CONFIG_FILE" "\"required_evidence_ref\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "suite status ready marker" "$SUITE_FILE" "\"suite_status\": \"READY\""
  check_contains "suite dry-run marker" "$SUITE_FILE" "\"test_mode\": \"DRY_RUN\""
  check_contains "suite customer import marker" "$SUITE_FILE" "CUSTOMER_IMPORT_TEST"
  check_contains "suite product stock marker" "$SUITE_FILE" "PRODUCT_STOCK_IMPORT_TEST"
  check_contains "suite receipt movement marker" "$SUITE_FILE" "RECEIPT_MOVEMENT_IMPORT_TEST"
  check_contains "suite mapping marker" "$SUITE_FILE" "MAPPING_TRANSFORM_TEST"
  check_contains "suite validation report marker" "$SUITE_FILE" "IMPORT_VALIDATION_REPORT_TEST"
  check_contains "suite required fail zero marker" "$SUITE_FILE" "\"required_fail_count\": 0"
  check_contains "suite closed policy marker" "$SUITE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime suite guard marker" "$RUNTIME_SCRIPT" "SUITE_FILE_NOT_FOUND"
  check_contains "runtime dry-run guard marker" "$RUNTIME_SCRIPT" "TEST_MODE_NOT_DRY_RUN"
  check_contains "runtime commit guard marker" "$RUNTIME_SCRIPT" "COMMIT_ALLOWED_TRUE"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required test guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TEST_CASE_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_TEST_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime external policy marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "IMPORT_TEST_SUITE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "IMPORT_TEST_SUITE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test cases marker" "$TEST_FILE" "\"test_cases\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 203 — FAZ 4-16.2.6 IMPORT TESTLERI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_DOC_STATUS=READY"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_SUITE_STATUS=READY"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_TEST_STATUS=PASS"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_3_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_2_6_IMPORT_TESTLERI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_3_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
