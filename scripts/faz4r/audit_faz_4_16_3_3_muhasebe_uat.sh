#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_3_3_MUHASEBE_UAT.md"
CONFIG_FILE="configs/faz4r/faz_4_16_3_3_muhasebe_uat.v1.json"
UAT_FILE="configs/faz4r/accounting_uat.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_accounting_uat.sh"
TEST_FILE="tests/faz4r/faz_4_16_3_3_muhasebe_uat_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_3_3_MUHASEBE_UAT_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_3_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_3_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_3_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_3_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$UAT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "ACCOUNTING_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "main accounting UAT artifact PASS"
    else
      record_fail "main accounting UAT artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main accounting UAT artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "ACCOUNTING_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "valid accounting UAT fixture PASS"
    else
      record_fail "valid accounting UAT fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid accounting UAT fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "ACCOUNTING_UAT_TOTAL_CASE_COUNT=16" "$valid_out"; then
    record_pass "valid accounting UAT total case count"
  else
    record_fail "valid accounting UAT total case count"
  fi

  if grep -Fq "ACCOUNTING_UAT_REQUIRED_FAIL_COUNT=0" "$valid_out"; then
    record_pass "valid accounting UAT required fail zero"
  else
    record_fail "valid accounting UAT required fail zero"
  fi

  if grep -Fq "ACCOUNTING_DEBIT_CREDIT_BALANCE=PASS" "$valid_out"; then
    record_pass "valid debit credit balance pass"
  else
    record_fail "valid debit credit balance pass"
  fi

  if grep -Fq "ACCOUNTING_REAL_LEDGER_POSTING=CLOSED" "$valid_out"; then
    record_pass "valid real ledger posting closed"
  else
    record_fail "valid real ledger posting closed"
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid accounting UAT fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "ACCOUNTING_UAT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid accounting UAT fixture FAIL guard"
    else
      record_fail "invalid accounting UAT fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=UAT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot accounting UAT mode guard"
  else
    record_fail "controlled pilot accounting UAT mode guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=ACCOUNTING_MODE_NOT_PREVIEW" "$invalid_out"; then
    record_pass "accounting preview mode guard"
  else
    record_fail "accounting preview mode guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:198_FAZ_4_16_2_1_CARI_IMPORT" "$invalid_out"; then
    record_pass "chain dependency guard"
  else
    record_fail "chain dependency guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=REQUIRED_UAT_CASE_NOT_PASS:ACCOUNTING_ACCESS" "$invalid_out"; then
    record_pass "required accounting UAT case pass guard"
  else
    record_fail "required accounting UAT case pass guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=REQUIRED_EVIDENCE_MISSING:ACCOUNTING_ACCESS" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=REQUIRED_UAT_CASES_MISSING" "$invalid_out"; then
    record_pass "missing accounting UAT cases guard"
  else
    record_fail "missing accounting UAT cases guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=TOTAL_CASE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total case count reconciliation guard"
  else
    record_fail "total case count reconciliation guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=DEBIT_CREDIT_TOTAL_NOT_BALANCED" "$invalid_out"; then
    record_pass "debit credit balance guard"
  else
    record_fail "debit credit balance guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=REAL_LEDGER_POSTING_STATUS_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ledger posting status closed guard"
  else
    record_fail "real ledger posting status closed guard"
  fi

  if grep -Fq "ACCOUNTING_UAT_FAIL=REAL_LEDGER_POSTING_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ledger posting external closed guard"
  else
    record_fail "real ledger posting external closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 206 — FAZ 4-16.3.3 MUHASEBE UAT REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "UAT file exists" "$UAT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.3.3 Muhasebe UAT"
  check_contains "doc TDHP marker" "$DOC_FILE" "TDHP"
  check_contains "doc preview marker" "$DOC_FILE" "accounting_mode = PREVIEW"
  check_contains "doc debit credit marker" "$DOC_FILE" "debit_credit_balance_status = PASS"
  check_contains "doc real ledger closed marker" "$DOC_FILE" "real_ledger_posting_status = CLOSED"
  check_contains "doc critical zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 206"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 205 marker" "$CONFIG_FILE" "205_FAZ_4_16_3_2_POS_UAT"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"uat_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config accounting preview marker" "$CONFIG_FILE" "\"accounting_mode_required\": \"PREVIEW\""
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config debit credit balance marker" "$CONFIG_FILE" "\"debit_credit_balance_status_required\": \"PASS\""
  check_contains "config real ledger closed marker" "$CONFIG_FILE" "\"real_ledger_posting_status_required\": \"CLOSED\""
  check_contains "config evidence marker" "$CONFIG_FILE" "\"required_evidence_ref\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "UAT status ready marker" "$UAT_FILE" "\"uat_status\": \"READY\""
  check_contains "UAT controlled pilot marker" "$UAT_FILE" "\"uat_mode\": \"CONTROLLED_PILOT\""
  check_contains "UAT accounting preview marker" "$UAT_FILE" "\"accounting_mode\": \"PREVIEW\""
  check_contains "UAT TDHP marker" "$UAT_FILE" "TDHP_CHART_VIEW"
  check_contains "UAT journal preview marker" "$UAT_FILE" "JOURNAL_DRAFT_PREVIEW"
  check_contains "UAT debit credit marker" "$UAT_FILE" "DEBIT_CREDIT_BALANCE_CHECK"
  check_contains "UAT real ledger closed marker" "$UAT_FILE" "REAL_LEDGER_POSTING_CLOSED_GATE"
  check_contains "UAT critical issue zero marker" "$UAT_FILE" "\"critical_issue_count\": 0"
  check_contains "UAT closed policy marker" "$UAT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime UAT guard marker" "$RUNTIME_SCRIPT" "UAT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "UAT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime accounting preview guard marker" "$RUNTIME_SCRIPT" "ACCOUNTING_MODE_NOT_PREVIEW"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required case guard marker" "$RUNTIME_SCRIPT" "REQUIRED_UAT_CASE_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_CASE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime debit credit guard marker" "$RUNTIME_SCRIPT" "DEBIT_CREDIT_TOTAL_NOT_BALANCED"
  check_contains "runtime real ledger guard marker" "$RUNTIME_SCRIPT" "REAL_LEDGER_POSTING_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "ACCOUNTING_UAT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "ACCOUNTING_UAT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test UAT cases marker" "$TEST_FILE" "\"uat_cases\""
  check_contains "test accounting preview marker" "$TEST_FILE" "\"accounting_preview\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 206 — FAZ 4-16.3.3 MUHASEBE UAT COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_DOC_STATUS=READY"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_CONFIG_STATUS=READY"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_CASE_STATUS=READY"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_TEST_STATUS=PASS"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_FINAL_STATUS=PASS"
    echo "FAZ_4_16_3_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_TEST_STATUS=FAIL"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_3_3_MUHASEBE_UAT_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_3_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
