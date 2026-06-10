#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_4_pilot_rollback_karari_akisi.v1.json"
ROLLBACK_FILE="configs/faz4r/pilot_rollback_decision_flow.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_rollback_decision_flow.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_4_pilot_rollback_karari_akisi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$ROLLBACK_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_ROLLBACK_DECISION_STATUS=PASS" "$valid_out"; then
      record_pass "main pilot rollback decision artifact PASS"
    else
      record_fail "main pilot rollback decision artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main pilot rollback decision artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_ROLLBACK_DECISION_STATUS=PASS" "$valid_out"; then
      record_pass "valid pilot rollback decision fixture PASS"
    else
      record_fail "valid pilot rollback decision fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid pilot rollback decision fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_TOTAL_RULE_COUNT=14" "$valid_out"; then
    record_pass "valid pilot rollback decision total rule count"
  else
    record_fail "valid pilot rollback decision total rule count"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_READY_RULE_COUNT=14" "$valid_out"; then
    record_pass "valid pilot rollback decision ready rule count"
  else
    record_fail "valid pilot rollback decision ready rule count"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_OPEN_BLOCKER_COUNT=0" "$valid_out"; then
    record_pass "valid pilot rollback decision open blocker zero"
  else
    record_fail "valid pilot rollback decision open blocker zero"
  fi

  if grep -Fq "ROLLBACK_SIGNAL_STATUS=CLEAR" "$valid_out"; then
    record_pass "valid rollback signal clear"
  else
    record_fail "valid rollback signal clear"
  fi

  if grep -Fq "NO_REAL_ROLLBACK_EXECUTION=true" "$valid_out"; then
    record_pass "valid no real rollback execution guard"
  else
    record_fail "valid no real rollback execution guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot rollback decision fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PILOT_ROLLBACK_DECISION_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid pilot rollback decision fixture FAIL guard"
    else
      record_fail "invalid pilot rollback decision fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=ROLLBACK_DECISION_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot rollback decision mode guard"
  else
    record_fail "controlled pilot rollback decision mode guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:215_FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW" "$invalid_out"; then
    record_pass "daily pilot review dependency guard"
  else
    record_fail "daily pilot review dependency guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=REQUIRED_DECISION_RULE_NOT_READY:ROLLBACK_SIGNAL_INTAKE" "$invalid_out"; then
    record_pass "required decision rule ready guard"
  else
    record_fail "required decision rule ready guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=REQUIRED_EVIDENCE_MISSING:ROLLBACK_SIGNAL_INTAKE" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=REQUIRED_DECISION_RULES_MISSING" "$invalid_out"; then
    record_pass "missing required decision rules guard"
  else
    record_fail "missing required decision rules guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=DUPLICATE_DECISION_RULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate decision rule guard"
  else
    record_fail "duplicate decision rule guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rule count reconciliation guard"
  else
    record_fail "total rule count reconciliation guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing rule zero guard"
  else
    record_fail "missing rule zero guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=ROLLBACK_SIGNAL_STATUS_NOT_CLEAR" "$invalid_out"; then
    record_pass "rollback signal clear guard"
  else
    record_fail "rollback signal clear guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=ROLLBACK_DECISION_RESULT_INVALID" "$invalid_out"; then
    record_pass "rollback decision result guard"
  else
    record_fail "rollback decision result guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=REAL_ROLLBACK_EXECUTION_NOT_DISABLED" "$invalid_out"; then
    record_pass "real rollback execution disabled guard"
  else
    record_fail "real rollback execution disabled guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=ROLLBACK_EXECUTION_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "rollback execution count zero guard"
  else
    record_fail "rollback execution count zero guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=REAL_ROLLBACK_EXECUTION_NOT_CLOSED" "$invalid_out"; then
    record_pass "real rollback execution closed guard"
  else
    record_fail "real rollback execution closed guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "PILOT_ROLLBACK_DECISION_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 216 — FAZ 4-16.5.4 PILOT ROLLBACK KARARI AKISI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "rollback decision file exists" "$ROLLBACK_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "rollback signal intake doc exists" "docs/faz4r/pilot_rollback_decision/rollback_signal_intake.md"
  check_file "owner approval matrix doc exists" "docs/faz4r/pilot_rollback_decision/owner_approval_matrix.md"
  check_file "recovery validation plan doc exists" "docs/faz4r/pilot_rollback_decision/recovery_validation_plan.md"
  check_file "real rollback execution closed gate doc exists" "docs/faz4r/pilot_rollback_decision/real_rollback_execution_closed_gate.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.4 Pilot Rollback Kararı Akışı"
  check_contains "doc rollback signal marker" "$DOC_FILE" "rollback_signal_status = CLEAR"
  check_contains "doc no rollback required marker" "$DOC_FILE" "rollback_decision_result = NO_ROLLBACK_REQUIRED"
  check_contains "doc no real rollback marker" "$DOC_FILE" "no_real_rollback_execution = true"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 216"
  check_contains "config dependency 215 marker" "$CONFIG_FILE" "215_FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"rollback_decision_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config rule ready marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config rollback clear marker" "$CONFIG_FILE" "\"rollback_signal_status_required\": \"CLEAR\""
  check_contains "config decision result marker" "$CONFIG_FILE" "\"rollback_decision_result_required\": \"NO_ROLLBACK_REQUIRED\""
  check_contains "config no real rollback marker" "$CONFIG_FILE" "\"no_real_rollback_execution_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "rollback status ready marker" "$ROLLBACK_FILE" "\"rollback_decision_status\": \"READY\""
  check_contains "rollback controlled pilot marker" "$ROLLBACK_FILE" "\"rollback_decision_mode\": \"CONTROLLED_PILOT\""
  check_contains "rollback signal intake marker" "$ROLLBACK_FILE" "ROLLBACK_SIGNAL_INTAKE"
  check_contains "rollback trigger matrix marker" "$ROLLBACK_FILE" "P0_P1_TRIGGER_MATRIX"
  check_contains "rollback open blocker marker" "$ROLLBACK_FILE" "OPEN_BLOCKER_ASSESSMENT"
  check_contains "rollback data safety marker" "$ROLLBACK_FILE" "DATA_SAFETY_PRECHECK"
  check_contains "rollback owner approval marker" "$ROLLBACK_FILE" "OWNER_APPROVAL_MATRIX"
  check_contains "rollback no rollback path marker" "$ROLLBACK_FILE" "NO_ROLLBACK_DECISION_PATH"
  check_contains "rollback candidate path marker" "$ROLLBACK_FILE" "ROLLBACK_CANDIDATE_DECISION_PATH"
  check_contains "rollback recovery plan marker" "$ROLLBACK_FILE" "RECOVERY_VALIDATION_PLAN"
  check_contains "rollback real execution closed marker" "$ROLLBACK_FILE" "REAL_ROLLBACK_EXECUTION_CLOSED_GATE"
  check_contains "rollback no real execution marker" "$ROLLBACK_FILE" "\"no_real_rollback_execution\": true"
  check_contains "rollback decision result marker" "$ROLLBACK_FILE" "\"rollback_decision_result\": \"NO_ROLLBACK_REQUIRED\""
  check_contains "rollback closed policy marker" "$ROLLBACK_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime rollback file guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_DECISION_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_DECISION_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_DECISION_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime rollback signal guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_SIGNAL_STATUS_NOT_CLEAR"
  check_contains "runtime no real rollback guard marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_DISABLED"
  check_contains "runtime rollback execution closed marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_ROLLBACK_DECISION_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_ROLLBACK_DECISION_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test decision rules marker" "$TEST_FILE" "\"decision_rules\""
  check_contains "test decision controls marker" "$TEST_FILE" "\"decision_controls\""
  check_contains "test decision metrics marker" "$TEST_FILE" "\"decision_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 216 — FAZ 4-16.5.4 PILOT ROLLBACK KARARI AKISI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_DOC_STATUS=READY"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_4_PILOT_ROLLBACK_KARARI_AKISI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
