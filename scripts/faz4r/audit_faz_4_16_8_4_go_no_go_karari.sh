#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_8_4_GO_NO_GO_KARARI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_8_4_go_no_go_karari.v1.json"
DECISION_FILE="configs/faz4r/go_no_go_decision.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_go_no_go_decision.sh"
TEST_FILE="tests/faz4r/faz_4_16_8_4_go_no_go_karari_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_8_4_GO_NO_GO_KARARI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_8_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_8_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_8_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_8_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$DECISION_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "GO_NO_GO_DECISION_STATUS=PASS" "$valid_out" && record_pass "main go/no-go decision artifact PASS" || { record_fail "main go/no-go decision artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main go/no-go decision artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "GO_NO_GO_DECISION_STATUS=PASS" "$valid_out" && record_pass "valid go/no-go decision fixture PASS" || { record_fail "valid go/no-go decision fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid go/no-go decision fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "GO_NO_GO_DECISION_TOTAL_ITEM_COUNT=17" "$valid_out" && record_pass "valid go/no-go total item count" || record_fail "valid go/no-go total item count"
  grep -Fq "GO_NO_GO_DECISION_READY_ITEM_COUNT=17" "$valid_out" && record_pass "valid go/no-go ready item count" || record_fail "valid go/no-go ready item count"
  grep -Fq "DECISION_RESULT=GO" "$valid_out" && record_pass "valid decision result GO guard" || record_fail "valid decision result GO guard"
  grep -Fq "CRITICAL_ISSUE_RESET_STATUS=PASS" "$valid_out" && record_pass "valid critical reset PASS guard" || record_fail "valid critical reset PASS guard"
  grep -Fq "UAT_THRESHOLD_STATUS=PASS" "$valid_out" && record_pass "valid UAT threshold PASS guard" || record_fail "valid UAT threshold PASS guard"
  grep -Fq "PILOT_KPI_STATUS=PASS" "$valid_out" && record_pass "valid pilot KPI PASS guard" || record_fail "valid pilot KPI PASS guard"
  grep -Fq "REHEARSAL_REPORT_STATUS=PASS" "$valid_out" && record_pass "valid rehearsal report PASS guard" || record_fail "valid rehearsal report PASS guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid go/no-go decision fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "GO_NO_GO_DECISION_STATUS=FAIL" "$invalid_out" && record_pass "invalid go/no-go decision fixture FAIL guard" || { record_fail "invalid go/no-go decision fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "GO_NO_GO_DECISION_FAIL=GO_NO_GO_DECISION_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot decision mode guard" || record_fail "controlled pilot decision mode guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=DECISION_RESULT_NOT_GO" "$invalid_out" && record_pass "decision result GO guard" || record_fail "decision result GO guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:233_FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA" "$invalid_out" && record_pass "critical reset dependency guard" || record_fail "critical reset dependency guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:232_FAZ_4_16_8_2_UAT_BASARI_ESIGI" "$invalid_out" && record_pass "UAT threshold dependency guard" || record_fail "UAT threshold dependency guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:231_FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI" "$invalid_out" && record_pass "pilot KPI dependency guard" || record_fail "pilot KPI dependency guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:230_FAZ_4_16_7_5_REHEARSAL_RAPORU" "$invalid_out" && record_pass "rehearsal dependency guard" || record_fail "rehearsal dependency guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=REQUIRED_DECISION_ITEM_NOT_READY:GO_NO_GO_DECISION_KICKOFF" "$invalid_out" && record_pass "required decision item ready guard" || record_fail "required decision item ready guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=REQUIRED_EVIDENCE_MISSING:GO_NO_GO_DECISION_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=REQUIRED_DECISION_ITEMS_MISSING" "$invalid_out" && record_pass "missing required decision items guard" || record_fail "missing required decision items guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=DUPLICATE_DECISION_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate decision item guard" || record_fail "duplicate decision item guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary critical issue zero guard" || record_fail "summary critical issue zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_P0_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P0 zero guard" || record_fail "summary P0 zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_P1_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P1 zero guard" || record_fail "summary P1 zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary open blocker zero guard" || record_fail "summary open blocker zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_OPEN_INCIDENT_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary open incident zero guard" || record_fail "summary open incident zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=SUMMARY_REGRESSION_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary regression fail zero guard" || record_fail "summary regression fail zero guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=CRITICAL_ISSUE_RESET_STATUS_NOT_PASS" "$invalid_out" && record_pass "critical reset PASS guard" || record_fail "critical reset PASS guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=UAT_THRESHOLD_STATUS_NOT_PASS" "$invalid_out" && record_pass "UAT threshold PASS guard" || record_fail "UAT threshold PASS guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=PILOT_KPI_STATUS_NOT_PASS" "$invalid_out" && record_pass "pilot KPI PASS guard" || record_fail "pilot KPI PASS guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=REHEARSAL_REPORT_STATUS_NOT_PASS" "$invalid_out" && record_pass "rehearsal report PASS guard" || record_fail "rehearsal report PASS guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=OWNER_APPROVAL_STATUS_NOT_APPROVED" "$invalid_out" && record_pass "owner approval guard" || record_fail "owner approval guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "GO_NO_GO_DECISION_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 234 — FAZ 4-16.8.4 GO / NO-GO KARARI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "go/no-go decision file exists" "$DECISION_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "decision kickoff doc exists" "docs/faz4r/go_no_go_decision/go_no_go_decision_kickoff.md"
  check_file "critical issue reset link doc exists" "docs/faz4r/go_no_go_decision/critical_issue_reset_link.md"
  check_file "owner approval doc exists" "docs/faz4r/go_no_go_decision/owner_approval_check.md"
  check_file "final decision report doc exists" "docs/faz4r/go_no_go_decision/final_decision_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.8.4 Go / No-Go Kararı"
  check_contains "doc decision kickoff marker" "$DOC_FILE" "Go / No-Go decision kickoff"
  check_contains "doc decision GO marker" "$DOC_FILE" "decision_result = GO"
  check_contains "doc no launch marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 234"
  check_contains "config dependency 233 marker" "$CONFIG_FILE" "233_FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA"
  check_contains "config dependency 232 marker" "$CONFIG_FILE" "232_FAZ_4_16_8_2_UAT_BASARI_ESIGI"
  check_contains "config dependency 231 marker" "$CONFIG_FILE" "231_FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI"
  check_contains "config dependency 230 marker" "$CONFIG_FILE" "230_FAZ_4_16_7_5_REHEARSAL_RAPORU"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"go_no_go_decision_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config decision result marker" "$CONFIG_FILE" "\"decision_result_required\": \"GO\""
  check_contains "config P0 zero marker" "$CONFIG_FILE" "\"p0_issue_count_required\": 0"
  check_contains "config P1 zero marker" "$CONFIG_FILE" "\"p1_issue_count_required\": 0"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "decision status ready marker" "$DECISION_FILE" "\"go_no_go_decision_status\": \"READY\""
  check_contains "decision controlled pilot marker" "$DECISION_FILE" "\"go_no_go_decision_mode\": \"CONTROLLED_PILOT\""
  check_contains "decision result GO marker" "$DECISION_FILE" "\"decision_result\": \"GO\""
  check_contains "decision kickoff marker" "$DECISION_FILE" "GO_NO_GO_DECISION_KICKOFF"
  check_contains "critical issue reset link marker" "$DECISION_FILE" "CRITICAL_ISSUE_RESET_LINK"
  check_contains "UAT threshold link marker" "$DECISION_FILE" "UAT_THRESHOLD_LINK"
  check_contains "pilot KPI link marker" "$DECISION_FILE" "PILOT_KPI_LINK"
  check_contains "rehearsal report link marker" "$DECISION_FILE" "REHEARSAL_REPORT_LINK"
  check_contains "owner approval marker" "$DECISION_FILE" "OWNER_APPROVAL_CHECK"
  check_contains "decision outcome marker" "$DECISION_FILE" "DECISION_OUTCOME"
  check_contains "critical issue count zero marker" "$DECISION_FILE" "\"critical_issue_count\": 0"
  check_contains "P0 issue count zero marker" "$DECISION_FILE" "\"p0_issue_count\": 0"
  check_contains "P1 issue count zero marker" "$DECISION_FILE" "\"p1_issue_count\": 0"
  check_contains "decision no production marker" "$DECISION_FILE" "\"no_production_launch\": true"
  check_contains "decision closed policy reference marker" "$DECISION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime decision file guard marker" "$RUNTIME_SCRIPT" "DECISION_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime decision result guard marker" "$RUNTIME_SCRIPT" "DECISION_RESULT_NOT_GO"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_DECISION_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_DECISION_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime P0 guard marker" "$RUNTIME_SCRIPT" "P0_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test decision items marker" "$TEST_FILE" "\"decision_items\""
  check_contains "test decision values marker" "$TEST_FILE" "\"decision_values\""
  check_contains "test decision controls marker" "$TEST_FILE" "\"decision_controls\""
  check_contains "test decision metrics marker" "$TEST_FILE" "\"decision_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 234 — FAZ 4-16.8.4 GO / NO-GO KARARI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_DOC_STATUS=READY"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_TEST_STATUS=PASS"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_8_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_8_4_GO_NO_GO_KARARI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_8_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
