#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_2_gunluk_pilot_review.v1.json"
REVIEW_FILE="configs/faz4r/daily_pilot_review.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_daily_pilot_review.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_2_gunluk_pilot_review_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" REVIEW_FILE="$REVIEW_FILE" INPUT_FILE="$REVIEW_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "DAILY_PILOT_REVIEW_STATUS=PASS" "$valid_out"; then
      record_pass "main daily pilot review artifact PASS"
    else
      record_fail "main daily pilot review artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main daily pilot review artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" REVIEW_FILE="$REVIEW_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "DAILY_PILOT_REVIEW_STATUS=PASS" "$valid_out"; then
      record_pass "valid daily pilot review fixture PASS"
    else
      record_fail "valid daily pilot review fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid daily pilot review fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_TOTAL_ITEM_COUNT=12" "$valid_out"; then
    record_pass "valid daily pilot review total item count"
  else
    record_fail "valid daily pilot review total item count"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_PASS_ITEM_COUNT=12" "$valid_out"; then
    record_pass "valid daily pilot review pass item count"
  else
    record_fail "valid daily pilot review pass item count"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL_ITEM_COUNT=0" "$valid_out"; then
    record_pass "valid daily pilot review fail item zero"
  else
    record_fail "valid daily pilot review fail item zero"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_OPEN_BLOCKER_COUNT=0" "$valid_out"; then
    record_pass "valid daily pilot review open blocker zero"
  else
    record_fail "valid daily pilot review open blocker zero"
  fi

  if grep -Fq "ROLLBACK_SIGNAL_STATUS=CLEAR" "$valid_out"; then
    record_pass "valid rollback signal clear"
  else
    record_fail "valid rollback signal clear"
  fi

  if CONFIG_FILE="$CONFIG_FILE" REVIEW_FILE="$REVIEW_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid daily pilot review fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "DAILY_PILOT_REVIEW_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid daily pilot review fixture FAIL guard"
    else
      record_fail "invalid daily pilot review fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REVIEW_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot review mode guard"
  else
    record_fail "controlled pilot review mode guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=CHAIN_DEPENDENCY_NOT_PASS:214_FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE" "$invalid_out"; then
    record_pass "training support smoke dependency guard"
  else
    record_fail "training support smoke dependency guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REQUIRED_REVIEW_ITEM_NOT_PASS:PILOT_HEALTH_REVIEW" "$invalid_out"; then
    record_pass "required review item pass guard"
  else
    record_fail "required review item pass guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REQUIRED_EVIDENCE_MISSING:PILOT_HEALTH_REVIEW" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REQUIRED_REVIEW_ITEMS_MISSING" "$invalid_out"; then
    record_pass "missing required review items guard"
  else
    record_fail "missing required review items guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=DUPLICATE_REVIEW_ITEM_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate review item guard"
  else
    record_fail "duplicate review item guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=TOTAL_REVIEW_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total review item count reconciliation guard"
  else
    record_fail "total review item count reconciliation guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=FAIL_REVIEW_ITEM_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "fail review item zero guard"
  else
    record_fail "fail review item zero guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=ROLLBACK_SIGNAL_STATUS_NOT_CLEAR" "$invalid_out"; then
    record_pass "rollback signal clear guard"
  else
    record_fail "rollback signal clear guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REAL_ROLLBACK_EXECUTION_NOT_DISABLED" "$invalid_out"; then
    record_pass "real rollback execution disabled guard"
  else
    record_fail "real rollback execution disabled guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=REAL_ROLLBACK_EXECUTION_NOT_CLOSED" "$invalid_out"; then
    record_pass "real rollback execution closed guard"
  else
    record_fail "real rollback execution closed guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "DAILY_PILOT_REVIEW_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 215 — FAZ 4-16.5.2 GUNLUK PILOT REVIEW REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "review file exists" "$REVIEW_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "pilot health review doc exists" "docs/faz4r/daily_pilot_review/pilot_health_review.md"
  check_file "rollback signal review doc exists" "docs/faz4r/daily_pilot_review/rollback_signal_review.md"
  check_file "closed provider policy review doc exists" "docs/faz4r/daily_pilot_review/closed_provider_policy_review.md"
  check_file "daily decision log review doc exists" "docs/faz4r/daily_pilot_review/daily_decision_log_review.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.2 Günlük Pilot Review"
  check_contains "doc pilot health marker" "$DOC_FILE" "Pilot health review"
  check_contains "doc rollback signal marker" "$DOC_FILE" "rollback_signal_status = CLEAR"
  check_contains "doc no real rollback marker" "$DOC_FILE" "no_real_rollback_execution = true"
  check_contains "doc open blocker zero marker" "$DOC_FILE" "open_blocker_count = 0"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 215"
  check_contains "config dependency 214 marker" "$CONFIG_FILE" "214_FAZ_4_16_4_5_EGITIM_DESTEK_SMOKE"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"review_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required review pass marker" "$CONFIG_FILE" "\"required_review_item_status_required\": \"PASS\""
  check_contains "config fail item zero marker" "$CONFIG_FILE" "\"fail_review_item_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config rollback clear marker" "$CONFIG_FILE" "\"rollback_signal_status_required\": \"CLEAR\""
  check_contains "config no real rollback marker" "$CONFIG_FILE" "\"no_real_rollback_execution_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "review status ready marker" "$REVIEW_FILE" "\"review_status\": \"READY\""
  check_contains "review controlled pilot marker" "$REVIEW_FILE" "\"review_mode\": \"CONTROLLED_PILOT\""
  check_contains "review pilot health marker" "$REVIEW_FILE" "PILOT_HEALTH_REVIEW"
  check_contains "review UAT marker" "$REVIEW_FILE" "UAT_STATUS_REVIEW"
  check_contains "review import marker" "$REVIEW_FILE" "IMPORT_STATUS_REVIEW"
  check_contains "review readmodel marker" "$REVIEW_FILE" "READMODEL_REPORTING_REVIEW"
  check_contains "review support triage marker" "$REVIEW_FILE" "SUPPORT_TRIAGE_REVIEW"
  check_contains "review issue escalation marker" "$REVIEW_FILE" "ISSUE_ESCALATION_REVIEW"
  check_contains "review rollback signal marker" "$REVIEW_FILE" "ROLLBACK_SIGNAL_REVIEW"
  check_contains "review decision log marker" "$REVIEW_FILE" "DAILY_DECISION_LOG_REVIEW"
  check_contains "review no real rollback marker" "$REVIEW_FILE" "\"no_real_rollback_execution\": true"
  check_contains "review open blocker zero marker" "$REVIEW_FILE" "\"open_blocker_count\": 0"
  check_contains "review closed policy marker" "$REVIEW_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime review file guard marker" "$RUNTIME_SCRIPT" "REVIEW_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "REVIEW_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_REVIEW_ITEM_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_REVIEW_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_REVIEW_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime open blocker guard marker" "$RUNTIME_SCRIPT" "OPEN_BLOCKER_COUNT_NOT_ZERO"
  check_contains "runtime rollback signal guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_SIGNAL_STATUS_NOT_CLEAR"
  check_contains "runtime real rollback guard marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_DISABLED"
  check_contains "runtime real rollback closed marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "DAILY_PILOT_REVIEW_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "DAILY_PILOT_REVIEW_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test review items marker" "$TEST_FILE" "\"review_items\""
  check_contains "test review controls marker" "$TEST_FILE" "\"review_controls\""
  check_contains "test daily metrics marker" "$TEST_FILE" "\"daily_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 215 — FAZ 4-16.5.2 GUNLUK PILOT REVIEW COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_DOC_STATUS=READY"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_2_GUNLUK_PILOT_REVIEW_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
