#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_8_5_PILOT_CLOSURE_REPORT.md"
CONFIG_FILE="configs/faz4r/faz_4_16_8_5_pilot_closure_report.v1.json"
CLOSURE_FILE="configs/faz4r/pilot_closure_report.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_closure_report.sh"
TEST_FILE="tests/faz4r/faz_4_16_8_5_pilot_closure_report_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
record_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then record_pass "$label"; else record_fail "$label"; fi
}

check_executable() {
  local label="$1"
  local file="$2"
  if [ -x "$file" ]; then record_pass "$label"; else record_fail "$label"; fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then record_pass "$label"; else record_fail "$label"; fi
}

extract_fixture() {
  local fixture_name="$1"
  local output_file="$2"
  python3 - "$TEST_FILE" "$fixture_name" "$output_file" <<'PY_EOF'
import json, sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text())
Path(sys.argv[3]).write_text(json.dumps(payload[sys.argv[2]], ensure_ascii=False, indent=2))
PY_EOF
}

run_fixture_tests() {
  local valid_file="/tmp/faz_4_16_8_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_8_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_8_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_8_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$CLOSURE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "PILOT_CLOSURE_REPORT_STATUS=PASS" "$valid_out" && record_pass "main pilot closure artifact PASS" || { record_fail "main pilot closure artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main pilot closure artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "PILOT_CLOSURE_REPORT_STATUS=PASS" "$valid_out" && record_pass "valid pilot closure fixture PASS" || { record_fail "valid pilot closure fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid pilot closure fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "PILOT_CLOSURE_REPORT_TOTAL_ITEM_COUNT=15" "$valid_out" && record_pass "valid pilot closure total item count" || record_fail "valid pilot closure total item count"
  grep -Fq "PILOT_CLOSURE_REPORT_READY_ITEM_COUNT=15" "$valid_out" && record_pass "valid pilot closure ready item count" || record_fail "valid pilot closure ready item count"
  grep -Fq "CLOSURE_RESULT=CLOSED" "$valid_out" && record_pass "valid closure result CLOSED guard" || record_fail "valid closure result CLOSED guard"
  grep -Fq "GO_NO_GO_DECISION_STATUS=PASS" "$valid_out" && record_pass "valid go/no-go PASS guard" || record_fail "valid go/no-go PASS guard"
  grep -Fq "DECISION_RESULT=GO" "$valid_out" && record_pass "valid decision result GO guard" || record_fail "valid decision result GO guard"
  grep -Fq "NEXT_PHASE_HANDOFF_STATUS=READY" "$valid_out" && record_pass "valid next phase handoff guard" || record_fail "valid next phase handoff guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot closure fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "PILOT_CLOSURE_REPORT_STATUS=FAIL" "$invalid_out" && record_pass "invalid pilot closure fixture FAIL guard" || { record_fail "invalid pilot closure fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=PILOT_CLOSURE_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot closure mode guard" || record_fail "controlled pilot closure mode guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=CLOSURE_RESULT_NOT_CLOSED" "$invalid_out" && record_pass "closure result CLOSED guard" || record_fail "closure result CLOSED guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=TENANT_STATUS_NOT_PILOT_CLOSED" "$invalid_out" && record_pass "tenant closed status guard" || record_fail "tenant closed status guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:234_FAZ_4_16_8_4_GO_NO_GO_KARARI" "$invalid_out" && record_pass "go/no-go dependency guard" || record_fail "go/no-go dependency guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=REQUIRED_CLOSURE_ITEM_NOT_READY:PILOT_CLOSURE_KICKOFF" "$invalid_out" && record_pass "required closure item ready guard" || record_fail "required closure item ready guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=REQUIRED_EVIDENCE_MISSING:PILOT_CLOSURE_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=REQUIRED_CLOSURE_ITEMS_MISSING" "$invalid_out" && record_pass "missing required closure items guard" || record_fail "missing required closure items guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=DUPLICATE_CLOSURE_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate closure item guard" || record_fail "duplicate closure item guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=SUMMARY_CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary critical issue zero guard" || record_fail "summary critical issue zero guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=SUMMARY_P0_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P0 zero guard" || record_fail "summary P0 zero guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=SUMMARY_P1_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P1 zero guard" || record_fail "summary P1 zero guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=SUMMARY_OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary open blocker zero guard" || record_fail "summary open blocker zero guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=GO_NO_GO_DECISION_STATUS_NOT_PASS" "$invalid_out" && record_pass "go/no-go PASS guard" || record_fail "go/no-go PASS guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=DECISION_RESULT_NOT_GO" "$invalid_out" && record_pass "decision result GO guard" || record_fail "decision result GO guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=OWNER_APPROVAL_STATUS_NOT_APPROVED" "$invalid_out" && record_pass "owner approval guard" || record_fail "owner approval guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=NEXT_PHASE_HANDOFF_STATUS_NOT_READY" "$invalid_out" && record_pass "next phase handoff ready guard" || record_fail "next phase handoff ready guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=NEXT_PHASE_NOT_APPROVAL_INBOX" "$invalid_out" && record_pass "next phase approval inbox guard" || record_fail "next phase approval inbox guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "PILOT_CLOSURE_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 235 — FAZ 4-16.8.5 PILOT CLOSURE REPORT REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "pilot closure report file exists" "$CLOSURE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "pilot closure kickoff doc exists" "docs/faz4r/pilot_closure_report/pilot_closure_kickoff.md"
  check_file "go/no-go decision link doc exists" "docs/faz4r/pilot_closure_report/go_no_go_decision_link.md"
  check_file "next phase handoff doc exists" "docs/faz4r/pilot_closure_report/next_phase_handoff.md"
  check_file "final pilot closure report doc exists" "docs/faz4r/pilot_closure_report/final_pilot_closure_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.8.5 Pilot Closure Report"
  check_contains "doc closure kickoff marker" "$DOC_FILE" "Pilot closure kickoff"
  check_contains "doc closure result marker" "$DOC_FILE" "closure_result = CLOSED"
  check_contains "doc next phase marker" "$DOC_FILE" "FAZ_4_17_1_READY=YES"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 235"
  check_contains "config dependency 234 marker" "$CONFIG_FILE" "234_FAZ_4_16_8_4_GO_NO_GO_KARARI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"pilot_closure_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config closure result marker" "$CONFIG_FILE" "\"closure_result_required\": \"CLOSED\""
  check_contains "config go/no-go pass marker" "$CONFIG_FILE" "\"go_no_go_decision_status_required\": \"PASS\""
  check_contains "config next phase marker" "$CONFIG_FILE" "236_FAZ_4_17_1_APPROVAL_INBOX"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "closure status ready marker" "$CLOSURE_FILE" "\"pilot_closure_status\": \"READY\""
  check_contains "closure controlled pilot marker" "$CLOSURE_FILE" "\"pilot_closure_mode\": \"CONTROLLED_PILOT\""
  check_contains "closure result CLOSED marker" "$CLOSURE_FILE" "\"closure_result\": \"CLOSED\""
  check_contains "tenant closed marker" "$CLOSURE_FILE" "\"tenant_status\": \"PILOT_CLOSED\""
  check_contains "closure kickoff marker" "$CLOSURE_FILE" "PILOT_CLOSURE_KICKOFF"
  check_contains "go/no-go decision link marker" "$CLOSURE_FILE" "GO_NO_GO_DECISION_LINK"
  check_contains "pilot KPI summary marker" "$CLOSURE_FILE" "PILOT_KPI_SUMMARY"
  check_contains "UAT threshold summary marker" "$CLOSURE_FILE" "UAT_THRESHOLD_SUMMARY"
  check_contains "critical reset summary marker" "$CLOSURE_FILE" "CRITICAL_ISSUE_RESET_SUMMARY"
  check_contains "next phase handoff marker" "$CLOSURE_FILE" "NEXT_PHASE_HANDOFF"
  check_contains "closure no production marker" "$CLOSURE_FILE" "\"no_production_launch\": true"
  check_contains "closure closed policy reference marker" "$CLOSURE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime closure file guard marker" "$RUNTIME_SCRIPT" "CLOSURE_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "PILOT_CLOSURE_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime closure result guard marker" "$RUNTIME_SCRIPT" "CLOSURE_RESULT_NOT_CLOSED"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_CLOSURE_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_CLOSURE_ITEM_CODE_FOUND"
  check_contains "runtime next phase guard marker" "$RUNTIME_SCRIPT" "NEXT_PHASE_NOT_APPROVAL_INBOX"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_CLOSURE_REPORT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_CLOSURE_REPORT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test closure items marker" "$TEST_FILE" "\"closure_items\""
  check_contains "test closure values marker" "$TEST_FILE" "\"closure_values\""
  check_contains "test closure controls marker" "$TEST_FILE" "\"closure_controls\""
  check_contains "test closure metrics marker" "$TEST_FILE" "\"closure_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 235 — FAZ 4-16.8.5 PILOT CLOSURE REPORT COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_DOC_STATUS=READY"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_CONFIG_STATUS=READY"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_TEST_STATUS=PASS"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_FINAL_STATUS=PASS"
    echo "FAZ_4_17_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_TEST_STATUS=FAIL"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_8_5_PILOT_CLOSURE_REPORT_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
