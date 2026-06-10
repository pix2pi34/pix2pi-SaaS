#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_7_5_REHEARSAL_RAPORU.md"
CONFIG_FILE="configs/faz4r/faz_4_16_7_5_rehearsal_raporu.v1.json"
REPORT_FILE="configs/faz4r/rehearsal_report.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_rehearsal_report.sh"
TEST_FILE="tests/faz4r/faz_4_16_7_5_rehearsal_raporu_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_7_5_REHEARSAL_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_7_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_7_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_7_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_7_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$REPORT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REHEARSAL_REPORT_STATUS=PASS" "$valid_out" && record_pass "main rehearsal report artifact PASS" || { record_fail "main rehearsal report artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main rehearsal report artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REHEARSAL_REPORT_STATUS=PASS" "$valid_out" && record_pass "valid rehearsal report fixture PASS" || { record_fail "valid rehearsal report fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid rehearsal report fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "REHEARSAL_REPORT_TOTAL_ITEM_COUNT=14" "$valid_out" && record_pass "valid rehearsal report total item count" || record_fail "valid rehearsal report total item count"
  grep -Fq "REHEARSAL_REPORT_READY_ITEM_COUNT=14" "$valid_out" && record_pass "valid rehearsal report ready item count" || record_fail "valid rehearsal report ready item count"
  grep -Fq "REHEARSAL_REPORT_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid rehearsal report missing item zero" || record_fail "valid rehearsal report missing item zero"
  grep -Fq "DRY_RUN_STATUS=PASS" "$valid_out" && record_pass "valid dry-run PASS guard" || record_fail "valid dry-run PASS guard"
  grep -Fq "CUTOVER_CHECKLIST_STATUS=PASS" "$valid_out" && record_pass "valid cutover PASS guard" || record_fail "valid cutover PASS guard"
  grep -Fq "ROLLBACK_REHEARSAL_STATUS=PASS" "$valid_out" && record_pass "valid rollback PASS guard" || record_fail "valid rollback PASS guard"
  grep -Fq "COMMUNICATION_PLAN_STATUS=PASS" "$valid_out" && record_pass "valid communication PASS guard" || record_fail "valid communication PASS guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid rehearsal report fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "REHEARSAL_REPORT_STATUS=FAIL" "$invalid_out" && record_pass "invalid rehearsal report fixture FAIL guard" || { record_fail "invalid rehearsal report fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "REHEARSAL_REPORT_FAIL=REHEARSAL_REPORT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot rehearsal report mode guard" || record_fail "controlled pilot rehearsal report mode guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:226_FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS" "$invalid_out" && record_pass "dry-run dependency guard" || record_fail "dry-run dependency guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:227_FAZ_4_16_7_2_CUTOVER_CHECKLIST" "$invalid_out" && record_pass "cutover dependency guard" || record_fail "cutover dependency guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:228_FAZ_4_16_7_3_GERI_DONUS_PROVASI" "$invalid_out" && record_pass "rollback dependency guard" || record_fail "rollback dependency guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:229_FAZ_4_16_7_4_ILETISIM_PLANI" "$invalid_out" && record_pass "communication dependency guard" || record_fail "communication dependency guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=REQUIRED_REPORT_ITEM_NOT_READY:REHEARSAL_REPORT_KICKOFF" "$invalid_out" && record_pass "required report item ready guard" || record_fail "required report item ready guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=REQUIRED_EVIDENCE_MISSING:REHEARSAL_REPORT_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=REQUIRED_REPORT_ITEMS_MISSING" "$invalid_out" && record_pass "missing required report items guard" || record_fail "missing required report items guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=DUPLICATE_REPORT_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate report item guard" || record_fail "duplicate report item guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=COMMUNICATION_PLAN_STATUS_NOT_PASS" "$invalid_out" && record_pass "communication plan PASS guard" || record_fail "communication plan PASS guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=DRY_RUN_STATUS_NOT_PASS" "$invalid_out" && record_pass "dry-run PASS guard" || record_fail "dry-run PASS guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CUTOVER_CHECKLIST_STATUS_NOT_PASS" "$invalid_out" && record_pass "cutover PASS guard" || record_fail "cutover PASS guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=ROLLBACK_REHEARSAL_STATUS_NOT_PASS" "$invalid_out" && record_pass "rollback PASS guard" || record_fail "rollback PASS guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=EVIDENCE_INDEX_STATUS_NOT_READY" "$invalid_out" && record_pass "evidence index ready guard" || record_fail "evidence index ready guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=RISK_SUMMARY_STATUS_NOT_READY" "$invalid_out" && record_pass "risk summary ready guard" || record_fail "risk summary ready guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=BLOCKER_SUMMARY_STATUS_NOT_READY" "$invalid_out" && record_pass "blocker summary ready guard" || record_fail "blocker summary ready guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=OWNER_SIGNOFF_STATUS_NOT_READY" "$invalid_out" && record_pass "owner signoff ready guard" || record_fail "owner signoff ready guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=GO_NO_GO_READINESS_NOTE_STATUS_NOT_READY" "$invalid_out" && record_pass "go/no-go readiness note guard" || record_fail "go/no-go readiness note guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=DRY_RUN_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "dry-run fail count zero guard" || record_fail "dry-run fail count zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=CUTOVER_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "cutover fail count zero guard" || record_fail "cutover fail count zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=ROLLBACK_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "rollback fail count zero guard" || record_fail "rollback fail count zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=COMMUNICATION_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "communication fail count zero guard" || record_fail "communication fail count zero guard"
  grep -Fq "REHEARSAL_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 230 — FAZ 4-16.7.5 REHEARSAL RAPORU REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "rehearsal report file exists" "$REPORT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "rehearsal kickoff doc exists" "docs/faz4r/rehearsal_report/rehearsal_report_kickoff.md"
  check_file "dry-run summary doc exists" "docs/faz4r/rehearsal_report/dry_run_result_summary.md"
  check_file "cutover summary doc exists" "docs/faz4r/rehearsal_report/cutover_checklist_summary.md"
  check_file "final rehearsal report doc exists" "docs/faz4r/rehearsal_report/final_rehearsal_report_status.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.7.5 Rehearsal Raporu"
  check_contains "doc report kickoff marker" "$DOC_FILE" "Rehearsal report kickoff"
  check_contains "doc no launch marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 230"
  check_contains "config dependency 226 marker" "$CONFIG_FILE" "226_FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS"
  check_contains "config dependency 227 marker" "$CONFIG_FILE" "227_FAZ_4_16_7_2_CUTOVER_CHECKLIST"
  check_contains "config dependency 228 marker" "$CONFIG_FILE" "228_FAZ_4_16_7_3_GERI_DONUS_PROVASI"
  check_contains "config dependency 229 marker" "$CONFIG_FILE" "229_FAZ_4_16_7_4_ILETISIM_PLANI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"rehearsal_report_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "report status ready marker" "$REPORT_FILE" "\"rehearsal_report_status\": \"READY\""
  check_contains "report controlled pilot marker" "$REPORT_FILE" "\"rehearsal_report_mode\": \"CONTROLLED_PILOT\""
  check_contains "report kickoff marker" "$REPORT_FILE" "REHEARSAL_REPORT_KICKOFF"
  check_contains "dry-run summary marker" "$REPORT_FILE" "DRY_RUN_RESULT_SUMMARY"
  check_contains "cutover summary marker" "$REPORT_FILE" "CUTOVER_CHECKLIST_SUMMARY"
  check_contains "rollback summary marker" "$REPORT_FILE" "ROLLBACK_REHEARSAL_SUMMARY"
  check_contains "communication summary marker" "$REPORT_FILE" "COMMUNICATION_PLAN_SUMMARY"
  check_contains "evidence index marker" "$REPORT_FILE" "EVIDENCE_INDEX"
  check_contains "risk summary marker" "$REPORT_FILE" "RISK_SUMMARY"
  check_contains "blocker summary marker" "$REPORT_FILE" "BLOCKER_SUMMARY"
  check_contains "owner signoff marker" "$REPORT_FILE" "OWNER_SIGNOFF_SUMMARY"
  check_contains "go no-go marker" "$REPORT_FILE" "GO_NO_GO_READINESS_NOTE"
  check_contains "report no production marker" "$REPORT_FILE" "\"no_production_launch\": true"
  check_contains "report no provider marker" "$REPORT_FILE" "\"no_live_external_provider_activation\": true"
  check_contains "report closed policy reference marker" "$REPORT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime report file guard marker" "$RUNTIME_SCRIPT" "REPORT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "REHEARSAL_REPORT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_REPORT_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_REPORT_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "REHEARSAL_REPORT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "REHEARSAL_REPORT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test report items marker" "$TEST_FILE" "\"report_items\""
  check_contains "test report controls marker" "$TEST_FILE" "\"report_controls\""
  check_contains "test report metrics marker" "$TEST_FILE" "\"report_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 230 — FAZ 4-16.7.5 REHEARSAL RAPORU COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_DOC_STATUS=READY"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_CONFIG_STATUS=READY"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_TEST_STATUS=PASS"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_FINAL_STATUS=PASS"
    echo "FAZ_4_16_8_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_TEST_STATUS=FAIL"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_7_5_REHEARSAL_RAPORU_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_8_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
