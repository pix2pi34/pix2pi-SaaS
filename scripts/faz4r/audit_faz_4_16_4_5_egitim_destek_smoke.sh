#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE.md"
CONFIG_FILE="configs/faz4r/faz_4_16_4_5_egitim_destek_smoke.v1.json"
SMOKE_FILE="configs/faz4r/training_support_smoke.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_training_support_smoke.sh"
TEST_FILE="tests/faz4r/faz_4_16_4_5_egitim_destek_smoke_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_4_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_4_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_4_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_4_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" SMOKE_FILE="$SMOKE_FILE" INPUT_FILE="$SMOKE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TRAINING_SUPPORT_SMOKE_STATUS=PASS" "$valid_out"; then
      record_pass "main training support smoke artifact PASS"
    else
      record_fail "main training support smoke artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main training support smoke artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" SMOKE_FILE="$SMOKE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TRAINING_SUPPORT_SMOKE_STATUS=PASS" "$valid_out"; then
      record_pass "valid training support smoke fixture PASS"
    else
      record_fail "valid training support smoke fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid training support smoke fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_TOTAL_CHECK_COUNT=12" "$valid_out"; then
    record_pass "valid training support smoke total check count"
  else
    record_fail "valid training support smoke total check count"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_PASS_CHECK_COUNT=12" "$valid_out"; then
    record_pass "valid training support smoke pass check count"
  else
    record_fail "valid training support smoke pass check count"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL_CHECK_COUNT=0" "$valid_out"; then
    record_pass "valid training support smoke fail check zero"
  else
    record_fail "valid training support smoke fail check zero"
  fi

  if grep -Fq "NO_REAL_EXTERNAL_DISPATCH=true" "$valid_out"; then
    record_pass "valid no real external dispatch guard"
  else
    record_fail "valid no real external dispatch guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" SMOKE_FILE="$SMOKE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid training support smoke fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "TRAINING_SUPPORT_SMOKE_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid training support smoke fixture FAIL guard"
    else
      record_fail "invalid training support smoke fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=SMOKE_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot smoke mode guard"
  else
    record_fail "controlled pilot smoke mode guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:213_FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION" "$invalid_out"; then
    record_pass "escalation dependency guard"
  else
    record_fail "escalation dependency guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=REQUIRED_SMOKE_CHECK_NOT_PASS:TRAINING_SET_ACCESS_SMOKE" "$invalid_out"; then
    record_pass "required smoke check pass guard"
  else
    record_fail "required smoke check pass guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=REQUIRED_EVIDENCE_MISSING:TRAINING_SET_ACCESS_SMOKE" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=REQUIRED_SMOKE_CHECKS_MISSING" "$invalid_out"; then
    record_pass "missing required smoke checks guard"
  else
    record_fail "missing required smoke checks guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=DUPLICATE_SMOKE_CHECK_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate smoke check guard"
  else
    record_fail "duplicate smoke check guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=TOTAL_CHECK_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total check count reconciliation guard"
  else
    record_fail "total check count reconciliation guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=FAIL_CHECK_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "fail check zero guard"
  else
    record_fail "fail check zero guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=REAL_EXTERNAL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real external dispatch disabled guard"
  else
    record_fail "real external dispatch disabled guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=REAL_TICKET_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ticket system closed guard"
  else
    record_fail "real ticket system closed guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "TRAINING_SUPPORT_SMOKE_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 214 — FAZ 4-16.4.5 EGITIM / DESTEK SMOKE REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "smoke file exists" "$SMOKE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "training set smoke doc exists" "docs/faz4r/training_support_smoke/training_set_access_smoke.md"
  check_file "help center smoke doc exists" "docs/faz4r/training_support_smoke/help_center_access_smoke.md"
  check_file "support intake smoke doc exists" "docs/faz4r/training_support_smoke/support_intake_smoke.md"
  check_file "closed provider policy smoke doc exists" "docs/faz4r/training_support_smoke/closed_provider_policy_smoke.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.4.5 Eğitim / Destek Smoke"
  check_contains "doc training smoke marker" "$DOC_FILE" "Eğitim seti erişilebilirlik smoke"
  check_contains "doc support smoke marker" "$DOC_FILE" "Destek intake smoke"
  check_contains "doc no real dispatch marker" "$DOC_FILE" "no_real_external_dispatch = true"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 214"
  check_contains "config dependency 213 marker" "$CONFIG_FILE" "213_FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"smoke_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required check pass marker" "$CONFIG_FILE" "\"required_check_status_required\": \"PASS\""
  check_contains "config fail check zero marker" "$CONFIG_FILE" "\"fail_check_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config no real dispatch marker" "$CONFIG_FILE" "\"no_real_external_dispatch_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "smoke status ready marker" "$SMOKE_FILE" "\"smoke_status\": \"READY\""
  check_contains "smoke controlled pilot marker" "$SMOKE_FILE" "\"smoke_mode\": \"CONTROLLED_PILOT\""
  check_contains "smoke training marker" "$SMOKE_FILE" "TRAINING_SET_ACCESS_SMOKE"
  check_contains "smoke help center marker" "$SMOKE_FILE" "HELP_CENTER_ACCESS_SMOKE"
  check_contains "smoke support intake marker" "$SMOKE_FILE" "SUPPORT_INTAKE_SMOKE"
  check_contains "smoke triage marker" "$SMOKE_FILE" "TRIAGE_CLASSIFICATION_SMOKE"
  check_contains "smoke escalation marker" "$SMOKE_FILE" "ESCALATION_ROUTING_SMOKE"
  check_contains "smoke closed policy marker" "$SMOKE_FILE" "CLOSED_PROVIDER_POLICY_SMOKE"
  check_contains "smoke no real dispatch marker" "$SMOKE_FILE" "\"no_real_external_dispatch\": true"
  check_contains "smoke fail check zero marker" "$SMOKE_FILE" "\"fail_check_count\": 0"
  check_contains "smoke closed policy reference marker" "$SMOKE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime smoke file guard marker" "$RUNTIME_SCRIPT" "SMOKE_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "SMOKE_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required check guard marker" "$RUNTIME_SCRIPT" "REQUIRED_SMOKE_CHECK_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_SMOKE_CHECK_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_CHECK_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no real dispatch guard marker" "$RUNTIME_SCRIPT" "REAL_EXTERNAL_DISPATCH_NOT_DISABLED"
  check_contains "runtime real ticket closed marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_CLOSED"
  check_contains "runtime hotfix deploy closed marker" "$RUNTIME_SCRIPT" "HOTFIX_DEPLOY_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "TRAINING_SUPPORT_SMOKE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "TRAINING_SUPPORT_SMOKE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test smoke checks marker" "$TEST_FILE" "\"smoke_checks\""
  check_contains "test smoke controls marker" "$TEST_FILE" "\"smoke_controls\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 214 — FAZ 4-16.4.5 EGITIM / DESTEK SMOKE COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_DOC_STATUS=READY"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_CONFIG_STATUS=READY"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_TEST_STATUS=PASS"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_TEST_STATUS=FAIL"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
