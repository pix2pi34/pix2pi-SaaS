#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_6_pilot_operations_testleri.v1.json"
OPS_FILE="configs/faz4r/pilot_operations_tests.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_operations_tests.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_6_pilot_operations_testleri_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_6_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_6_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_6_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_6_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" OPS_FILE="$OPS_FILE" INPUT_FILE="$OPS_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_OPERATIONS_TESTS_STATUS=PASS" "$valid_out"; then
      record_pass "main pilot operations tests artifact PASS"
    else
      record_fail "main pilot operations tests artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main pilot operations tests artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" OPS_FILE="$OPS_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_OPERATIONS_TESTS_STATUS=PASS" "$valid_out"; then
      record_pass "valid pilot operations tests fixture PASS"
    else
      record_fail "valid pilot operations tests fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid pilot operations tests fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_TOTAL_TEST_COUNT=14" "$valid_out"; then
    record_pass "valid pilot operations total test count"
  else
    record_fail "valid pilot operations total test count"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_PASS_TEST_COUNT=14" "$valid_out"; then
    record_pass "valid pilot operations pass test count"
  else
    record_fail "valid pilot operations pass test count"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL_TEST_COUNT=0" "$valid_out"; then
    record_pass "valid pilot operations fail test zero"
  else
    record_fail "valid pilot operations fail test zero"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_OPEN_BLOCKER_COUNT=0" "$valid_out"; then
    record_pass "valid pilot operations open blocker zero"
  else
    record_fail "valid pilot operations open blocker zero"
  fi

  if grep -Fq "OPERATIONS_HANDOFF_READY=YES" "$valid_out"; then
    record_pass "valid pilot operations handoff ready"
  else
    record_fail "valid pilot operations handoff ready"
  fi

  if CONFIG_FILE="$CONFIG_FILE" OPS_FILE="$OPS_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot operations tests fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PILOT_OPERATIONS_TESTS_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid pilot operations tests fixture FAIL guard"
    else
      record_fail "invalid pilot operations tests fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=OPERATIONS_TEST_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot operations mode guard"
  else
    record_fail "controlled pilot operations mode guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=CHAIN_DEPENDENCY_NOT_PASS:216_FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI" "$invalid_out"; then
    record_pass "rollback decision dependency guard"
  else
    record_fail "rollback decision dependency guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=REQUIRED_OPERATIONS_TEST_NOT_PASS:DAILY_PILOT_REVIEW_TEST" "$invalid_out"; then
    record_pass "required operations test pass guard"
  else
    record_fail "required operations test pass guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=REQUIRED_EVIDENCE_MISSING:DAILY_PILOT_REVIEW_TEST" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=REQUIRED_OPERATIONS_TESTS_MISSING" "$invalid_out"; then
    record_pass "missing required operations tests guard"
  else
    record_fail "missing required operations tests guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=DUPLICATE_OPERATIONS_TEST_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate operations test guard"
  else
    record_fail "duplicate operations test guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=TOTAL_TEST_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total test count reconciliation guard"
  else
    record_fail "total test count reconciliation guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=FAIL_TEST_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "fail test zero guard"
  else
    record_fail "fail test zero guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=OPERATIONS_HANDOFF_NOT_READY" "$invalid_out"; then
    record_pass "operations handoff ready guard"
  else
    record_fail "operations handoff ready guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=REAL_ROLLBACK_EXECUTION_NOT_DISABLED" "$invalid_out"; then
    record_pass "real rollback execution disabled guard"
  else
    record_fail "real rollback execution disabled guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=HOTFIX_DEPLOY_NOT_DISABLED" "$invalid_out"; then
    record_pass "hotfix deploy disabled guard"
  else
    record_fail "hotfix deploy disabled guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=PRODUCTION_LAUNCH_STATUS_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch status closed guard"
  else
    record_fail "production launch status closed guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=REAL_ROLLBACK_EXECUTION_NOT_CLOSED" "$invalid_out"; then
    record_pass "real rollback execution closed guard"
  else
    record_fail "real rollback execution closed guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "PILOT_OPERATIONS_TESTS_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 217 — FAZ 4-16.5.6 PILOT OPERATIONS TESTLERI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "operations tests file exists" "$OPS_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "daily pilot review test doc exists" "docs/faz4r/pilot_operations_tests/daily_pilot_review_test.md"
  check_file "rollback decision flow test doc exists" "docs/faz4r/pilot_operations_tests/rollback_decision_flow_test.md"
  check_file "closed provider policy test doc exists" "docs/faz4r/pilot_operations_tests/closed_provider_policy_test.md"
  check_file "operations handoff readiness test doc exists" "docs/faz4r/pilot_operations_tests/operations_handoff_readiness_test.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.6 Pilot Operations Testleri"
  check_contains "doc daily review marker" "$DOC_FILE" "Daily pilot review test"
  check_contains "doc rollback decision marker" "$DOC_FILE" "Rollback decision flow test"
  check_contains "doc no real rollback marker" "$DOC_FILE" "no_real_rollback_execution = true"
  check_contains "doc handoff marker" "$DOC_FILE" "operations_handoff_ready = YES"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 217"
  check_contains "config dependency 216 marker" "$CONFIG_FILE" "216_FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"operations_test_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required test pass marker" "$CONFIG_FILE" "\"required_test_status_required\": \"PASS\""
  check_contains "config fail test zero marker" "$CONFIG_FILE" "\"fail_test_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config handoff ready marker" "$CONFIG_FILE" "\"operations_handoff_ready_required\": \"YES\""
  check_contains "config no real rollback marker" "$CONFIG_FILE" "\"no_real_rollback_execution_required\": true"
  check_contains "config no hotfix deploy marker" "$CONFIG_FILE" "\"no_hotfix_deploy_required\": true"
  check_contains "config production launch closed marker" "$CONFIG_FILE" "\"production_launch_status_required\": \"CLOSED\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "ops status ready marker" "$OPS_FILE" "\"operations_test_status\": \"READY\""
  check_contains "ops controlled pilot marker" "$OPS_FILE" "\"operations_test_mode\": \"CONTROLLED_PILOT\""
  check_contains "ops daily review marker" "$OPS_FILE" "DAILY_PILOT_REVIEW_TEST"
  check_contains "ops rollback decision marker" "$OPS_FILE" "ROLLBACK_DECISION_FLOW_TEST"
  check_contains "ops training support marker" "$OPS_FILE" "TRAINING_SUPPORT_SMOKE_TEST"
  check_contains "ops support triage marker" "$OPS_FILE" "SUPPORT_TRIAGE_TEST"
  check_contains "ops issue escalation marker" "$OPS_FILE" "ISSUE_ESCALATION_TEST"
  check_contains "ops pilot health marker" "$OPS_FILE" "PILOT_HEALTH_TEST"
  check_contains "ops open blocker zero marker" "$OPS_FILE" "OPEN_BLOCKER_ZERO_TEST"
  check_contains "ops critical issue zero marker" "$OPS_FILE" "CRITICAL_ISSUE_ZERO_TEST"
  check_contains "ops closed provider marker" "$OPS_FILE" "CLOSED_PROVIDER_POLICY_TEST"
  check_contains "ops no real rollback marker" "$OPS_FILE" "\"no_real_rollback_execution\": true"
  check_contains "ops no hotfix deploy marker" "$OPS_FILE" "\"no_hotfix_deploy\": true"
  check_contains "ops handoff ready marker" "$OPS_FILE" "\"operations_handoff_ready\": \"YES\""
  check_contains "ops closed policy marker" "$OPS_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime ops file guard marker" "$RUNTIME_SCRIPT" "OPS_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "OPERATIONS_TEST_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required test guard marker" "$RUNTIME_SCRIPT" "REQUIRED_OPERATIONS_TEST_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_OPERATIONS_TEST_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_TEST_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime open blocker guard marker" "$RUNTIME_SCRIPT" "OPEN_BLOCKER_COUNT_NOT_ZERO"
  check_contains "runtime handoff guard marker" "$RUNTIME_SCRIPT" "OPERATIONS_HANDOFF_NOT_READY"
  check_contains "runtime no real rollback guard marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_DISABLED"
  check_contains "runtime hotfix deploy guard marker" "$RUNTIME_SCRIPT" "HOTFIX_DEPLOY_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_OPERATIONS_TESTS_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_OPERATIONS_TESTS_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test operations tests marker" "$TEST_FILE" "\"operations_tests\""
  check_contains "test operations controls marker" "$TEST_FILE" "\"operations_controls\""
  check_contains "test operations metrics marker" "$TEST_FILE" "\"operations_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 217 — FAZ 4-16.5.6 PILOT OPERATIONS TESTLERI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_DOC_STATUS=READY"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
