#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_3_2_POS_UAT.md"
CONFIG_FILE="configs/faz4r/faz_4_16_3_2_pos_uat.v1.json"
UAT_FILE="configs/faz4r/pos_uat.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pos_uat.sh"
TEST_FILE="tests/faz4r/faz_4_16_3_2_pos_uat_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_3_2_POS_UAT_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_3_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_3_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_3_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_3_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$UAT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "POS_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "main POS UAT artifact PASS"
    else
      record_fail "main POS UAT artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main POS UAT artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "POS_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "valid POS UAT fixture PASS"
    else
      record_fail "valid POS UAT fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid POS UAT fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "POS_UAT_TOTAL_CASE_COUNT=14" "$valid_out"; then
    record_pass "valid POS UAT total case count"
  else
    record_fail "valid POS UAT total case count"
  fi

  if grep -Fq "POS_UAT_REQUIRED_FAIL_COUNT=0" "$valid_out"; then
    record_pass "valid POS UAT required fail zero"
  else
    record_fail "valid POS UAT required fail zero"
  fi

  if grep -Fq "POS_UAT_PAYMENT_PROVIDER=CLOSED" "$valid_out"; then
    record_pass "valid POS UAT payment provider closed"
  else
    record_fail "valid POS UAT payment provider closed"
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid POS UAT fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "POS_UAT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid POS UAT fixture FAIL guard"
    else
      record_fail "invalid POS UAT fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "POS_UAT_FAIL=UAT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot POS UAT mode guard"
  else
    record_fail "controlled pilot POS UAT mode guard"
  fi

  if grep -Fq "POS_UAT_FAIL=POS_MODE_NOT_DRY_RUN" "$invalid_out"; then
    record_pass "POS dry-run mode guard"
  else
    record_fail "POS dry-run mode guard"
  fi

  if grep -Fq "POS_UAT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:198_FAZ_4_16_2_1_CARI_IMPORT" "$invalid_out"; then
    record_pass "chain dependency guard"
  else
    record_fail "chain dependency guard"
  fi

  if grep -Fq "POS_UAT_FAIL=REQUIRED_UAT_CASE_NOT_PASS:POS_LOGIN_ACCESS" "$invalid_out"; then
    record_pass "required POS UAT case pass guard"
  else
    record_fail "required POS UAT case pass guard"
  fi

  if grep -Fq "POS_UAT_FAIL=REQUIRED_EVIDENCE_MISSING:POS_LOGIN_ACCESS" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "POS_UAT_FAIL=REQUIRED_UAT_CASES_MISSING" "$invalid_out"; then
    record_pass "missing POS UAT cases guard"
  else
    record_fail "missing POS UAT cases guard"
  fi

  if grep -Fq "POS_UAT_FAIL=TOTAL_CASE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total case count reconciliation guard"
  else
    record_fail "total case count reconciliation guard"
  fi

  if grep -Fq "POS_UAT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "POS_UAT_FAIL=PAYMENT_PROVIDER_STATUS_NOT_CLOSED" "$invalid_out"; then
    record_pass "payment provider status closed guard"
  else
    record_fail "payment provider status closed guard"
  fi

  if grep -Fq "POS_UAT_FAIL=PAYMENT_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "payment provider external closed guard"
  else
    record_fail "payment provider external closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 205 — FAZ 4-16.3.2 POS UAT REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "UAT file exists" "$UAT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.3.2 POS UAT"
  check_contains "doc POS login marker" "$DOC_FILE" "POS login"
  check_contains "doc dry-run marker" "$DOC_FILE" "pos_mode = DRY_RUN"
  check_contains "doc payment closed marker" "$DOC_FILE" "payment_provider_status = CLOSED"
  check_contains "doc critical zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 205"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 203 marker" "$CONFIG_FILE" "203_FAZ_4_16_2_6_IMPORT_TESTLERI"
  check_contains "config dependency 204 marker" "$CONFIG_FILE" "204_FAZ_4_16_3_1_YONETIM_PANELI_UAT"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"uat_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config POS dry-run marker" "$CONFIG_FILE" "\"pos_mode_required\": \"DRY_RUN\""
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config payment provider closed marker" "$CONFIG_FILE" "\"payment_provider_status_required\": \"CLOSED\""
  check_contains "config evidence marker" "$CONFIG_FILE" "\"required_evidence_ref\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "UAT status ready marker" "$UAT_FILE" "\"uat_status\": \"READY\""
  check_contains "UAT controlled pilot marker" "$UAT_FILE" "\"uat_mode\": \"CONTROLLED_PILOT\""
  check_contains "UAT POS dry-run marker" "$UAT_FILE" "\"pos_mode\": \"DRY_RUN\""
  check_contains "UAT POS login marker" "$UAT_FILE" "POS_LOGIN_ACCESS"
  check_contains "UAT cashier marker" "$UAT_FILE" "POS_CASHIER_SESSION_OPEN"
  check_contains "UAT sale dry-run marker" "$UAT_FILE" "POS_SALE_DRY_RUN"
  check_contains "UAT payment closed marker" "$UAT_FILE" "POS_PAYMENT_PROVIDER_CLOSED_GATE"
  check_contains "UAT critical issue zero marker" "$UAT_FILE" "\"critical_issue_count\": 0"
  check_contains "UAT closed policy marker" "$UAT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime UAT guard marker" "$RUNTIME_SCRIPT" "UAT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "UAT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime POS dry-run guard marker" "$RUNTIME_SCRIPT" "POS_MODE_NOT_DRY_RUN"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required case guard marker" "$RUNTIME_SCRIPT" "REQUIRED_UAT_CASE_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_CASE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime payment closed guard marker" "$RUNTIME_SCRIPT" "PAYMENT_PROVIDER_STATUS_NOT_CLOSED"
  check_contains "runtime external policy marker" "$RUNTIME_SCRIPT" "PAYMENT_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "POS_UAT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "POS_UAT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test UAT cases marker" "$TEST_FILE" "\"uat_cases\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 205 — FAZ 4-16.3.2 POS UAT COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_3_2_POS_UAT_DOC_STATUS=READY"
    echo "FAZ_4_16_3_2_POS_UAT_CONFIG_STATUS=READY"
    echo "FAZ_4_16_3_2_POS_UAT_CASE_STATUS=READY"
    echo "FAZ_4_16_3_2_POS_UAT_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_3_2_POS_UAT_TEST_STATUS=PASS"
    echo "FAZ_4_16_3_2_POS_UAT_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_3_2_POS_UAT_FINAL_STATUS=PASS"
    echo "FAZ_4_16_3_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_3_2_POS_UAT_TEST_STATUS=FAIL"
    echo "FAZ_4_16_3_2_POS_UAT_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_3_2_POS_UAT_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_3_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
