#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_8_2_UAT_BASARI_ESIGI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_8_2_uat_basari_esigi.v1.json"
THRESHOLD_FILE="configs/faz4r/uat_success_threshold.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_uat_success_threshold.sh"
TEST_FILE="tests/faz4r/faz_4_16_8_2_uat_basari_esigi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_8_2_UAT_BASARI_ESIGI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_8_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_8_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_8_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_8_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" THRESHOLD_FILE="$THRESHOLD_FILE" INPUT_FILE="$THRESHOLD_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "UAT_SUCCESS_THRESHOLD_STATUS=PASS" "$valid_out" && record_pass "main UAT threshold artifact PASS" || { record_fail "main UAT threshold artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main UAT threshold artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" THRESHOLD_FILE="$THRESHOLD_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "UAT_SUCCESS_THRESHOLD_STATUS=PASS" "$valid_out" && record_pass "valid UAT threshold fixture PASS" || { record_fail "valid UAT threshold fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid UAT threshold fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "UAT_SUCCESS_THRESHOLD_TOTAL_ITEM_COUNT=15" "$valid_out" && record_pass "valid UAT threshold total item count" || record_fail "valid UAT threshold total item count"
  grep -Fq "UAT_SUCCESS_THRESHOLD_READY_ITEM_COUNT=15" "$valid_out" && record_pass "valid UAT threshold ready item count" || record_fail "valid UAT threshold ready item count"
  grep -Fq "UAT_SUCCESS_THRESHOLD_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid UAT threshold missing item zero" || record_fail "valid UAT threshold missing item zero"
  grep -Fq "MANAGEMENT_PANEL_UAT_STATUS=PASS" "$valid_out" && record_pass "valid management panel UAT PASS guard" || record_fail "valid management panel UAT PASS guard"
  grep -Fq "POS_UAT_STATUS=PASS" "$valid_out" && record_pass "valid POS UAT PASS guard" || record_fail "valid POS UAT PASS guard"
  grep -Fq "ACCOUNTING_UAT_STATUS=PASS" "$valid_out" && record_pass "valid accounting UAT PASS guard" || record_fail "valid accounting UAT PASS guard"
  grep -Fq "ACCOUNTANT_PORTAL_UAT_STATUS=PASS" "$valid_out" && record_pass "valid accountant portal UAT PASS guard" || record_fail "valid accountant portal UAT PASS guard"
  grep -Fq "EDOCUMENT_EXPORT_UAT_STATUS=PASS" "$valid_out" && record_pass "valid e-document export UAT PASS guard" || record_fail "valid e-document export UAT PASS guard"
  grep -Fq "NO_GO_NO_GO_DECISION=true" "$valid_out" && record_pass "valid no go/no-go decision guard" || record_fail "valid no go/no-go decision guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" THRESHOLD_FILE="$THRESHOLD_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid UAT threshold fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "UAT_SUCCESS_THRESHOLD_STATUS=FAIL" "$invalid_out" && record_pass "invalid UAT threshold fixture FAIL guard" || { record_fail "invalid UAT threshold fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=UAT_THRESHOLD_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot UAT threshold mode guard" || record_fail "controlled pilot UAT threshold mode guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=CHAIN_DEPENDENCY_NOT_PASS:231_FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI" "$invalid_out" && record_pass "pilot KPI dependency guard" || record_fail "pilot KPI dependency guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=REQUIRED_THRESHOLD_ITEM_NOT_READY:UAT_THRESHOLD_KICKOFF" "$invalid_out" && record_pass "required threshold item ready guard" || record_fail "required threshold item ready guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=REQUIRED_EVIDENCE_MISSING:UAT_THRESHOLD_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=REQUIRED_THRESHOLD_ITEMS_MISSING" "$invalid_out" && record_pass "missing required threshold items guard" || record_fail "missing required threshold items guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=DUPLICATE_THRESHOLD_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate threshold item guard" || record_fail "duplicate threshold item guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=PILOT_KPI_STATUS_NOT_PASS" "$invalid_out" && record_pass "pilot KPI PASS guard" || record_fail "pilot KPI PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=MANAGEMENT_PANEL_UAT_STATUS_NOT_PASS" "$invalid_out" && record_pass "management panel UAT PASS guard" || record_fail "management panel UAT PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=POS_UAT_STATUS_NOT_PASS" "$invalid_out" && record_pass "POS UAT PASS guard" || record_fail "POS UAT PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=ACCOUNTING_UAT_STATUS_NOT_PASS" "$invalid_out" && record_pass "accounting UAT PASS guard" || record_fail "accounting UAT PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=ACCOUNTANT_PORTAL_UAT_STATUS_NOT_PASS" "$invalid_out" && record_pass "accountant portal UAT PASS guard" || record_fail "accountant portal UAT PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=EDOCUMENT_EXPORT_UAT_STATUS_NOT_PASS" "$invalid_out" && record_pass "e-document export UAT PASS guard" || record_fail "e-document export UAT PASS guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=REQUIRED_CASE_PASS_RATE_BELOW_MIN" "$invalid_out" && record_pass "required case pass rate guard" || record_fail "required case pass rate guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=EVIDENCE_COMPLETENESS_RATE_BELOW_MIN" "$invalid_out" && record_pass "evidence completeness guard" || record_fail "evidence completeness guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=SIGNOFF_COMPLETENESS_RATE_BELOW_MIN" "$invalid_out" && record_pass "signoff completeness guard" || record_fail "signoff completeness guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=GO_NO_GO_DECISION_NOT_DISABLED" "$invalid_out" && record_pass "go/no-go decision disabled guard" || record_fail "go/no-go decision disabled guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=THRESHOLD_BELOW_MIN_COUNT_NOT_ZERO" "$invalid_out" && record_pass "threshold below min count zero guard" || record_fail "threshold below min count zero guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=GO_NO_GO_DECISION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "go/no-go decision count zero guard" || record_fail "go/no-go decision count zero guard"
  grep -Fq "UAT_SUCCESS_THRESHOLD_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 232 — FAZ 4-16.8.2 UAT BASARI ESIGI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "UAT threshold file exists" "$THRESHOLD_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "UAT threshold kickoff doc exists" "docs/faz4r/uat_success_threshold/uat_threshold_kickoff.md"
  check_file "management panel threshold doc exists" "docs/faz4r/uat_success_threshold/management_panel_uat_threshold.md"
  check_file "POS threshold doc exists" "docs/faz4r/uat_success_threshold/pos_uat_threshold.md"
  check_file "final UAT threshold report doc exists" "docs/faz4r/uat_success_threshold/final_uat_threshold_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.8.2 UAT Başarı Eşiği"
  check_contains "doc threshold kickoff marker" "$DOC_FILE" "UAT threshold kickoff"
  check_contains "doc no go/no-go marker" "$DOC_FILE" "no_go_no_go_decision = true"
  check_contains "doc no launch marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 232"
  check_contains "config dependency 231 marker" "$CONFIG_FILE" "231_FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"uat_threshold_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config required case threshold marker" "$CONFIG_FILE" "\"required_case_pass_rate_min\": 100"
  check_contains "config evidence threshold marker" "$CONFIG_FILE" "\"evidence_completeness_rate_min\": 100"
  check_contains "config signoff threshold marker" "$CONFIG_FILE" "\"signoff_completeness_rate_min\": 100"
  check_contains "config no go/no-go marker" "$CONFIG_FILE" "\"no_go_no_go_decision_required\": true"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "threshold status ready marker" "$THRESHOLD_FILE" "\"uat_threshold_status\": \"READY\""
  check_contains "threshold controlled pilot marker" "$THRESHOLD_FILE" "\"uat_threshold_mode\": \"CONTROLLED_PILOT\""
  check_contains "threshold kickoff marker" "$THRESHOLD_FILE" "UAT_THRESHOLD_KICKOFF"
  check_contains "pilot KPI link marker" "$THRESHOLD_FILE" "PILOT_KPI_EVALUATION_LINK"
  check_contains "management panel UAT marker" "$THRESHOLD_FILE" "MANAGEMENT_PANEL_UAT_THRESHOLD"
  check_contains "POS UAT marker" "$THRESHOLD_FILE" "POS_UAT_THRESHOLD"
  check_contains "accounting UAT marker" "$THRESHOLD_FILE" "ACCOUNTING_UAT_THRESHOLD"
  check_contains "accountant portal UAT marker" "$THRESHOLD_FILE" "ACCOUNTANT_PORTAL_UAT_THRESHOLD"
  check_contains "e-document UAT marker" "$THRESHOLD_FILE" "EDOCUMENT_EXPORT_UAT_THRESHOLD"
  check_contains "required case threshold marker" "$THRESHOLD_FILE" "\"required_case_pass_rate\": 100"
  check_contains "evidence completeness marker" "$THRESHOLD_FILE" "\"evidence_completeness_rate\": 100"
  check_contains "signoff completeness marker" "$THRESHOLD_FILE" "\"signoff_completeness_rate\": 100"
  check_contains "threshold no go/no-go marker" "$THRESHOLD_FILE" "\"no_go_no_go_decision\": true"
  check_contains "threshold no production marker" "$THRESHOLD_FILE" "\"no_production_launch\": true"
  check_contains "threshold closed policy reference marker" "$THRESHOLD_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime threshold file guard marker" "$RUNTIME_SCRIPT" "THRESHOLD_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "UAT_THRESHOLD_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_THRESHOLD_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_THRESHOLD_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no go/no-go guard marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_NOT_DISABLED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "UAT_SUCCESS_THRESHOLD_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "UAT_SUCCESS_THRESHOLD_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test threshold items marker" "$TEST_FILE" "\"threshold_items\""
  check_contains "test threshold values marker" "$TEST_FILE" "\"threshold_values\""
  check_contains "test threshold controls marker" "$TEST_FILE" "\"threshold_controls\""
  check_contains "test threshold metrics marker" "$TEST_FILE" "\"threshold_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 232 — FAZ 4-16.8.2 UAT BASARI ESIGI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_DOC_STATUS=READY"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_TEST_STATUS=PASS"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_8_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_8_2_UAT_BASARI_ESIGI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_8_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
