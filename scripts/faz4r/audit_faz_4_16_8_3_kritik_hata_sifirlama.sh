#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA.md"
CONFIG_FILE="configs/faz4r/faz_4_16_8_3_kritik_hata_sifirlama.v1.json"
RESET_FILE="configs/faz4r/critical_issue_reset.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_critical_issue_reset.sh"
TEST_FILE="tests/faz4r/faz_4_16_8_3_kritik_hata_sifirlama_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_8_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_8_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_8_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_8_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" RESET_FILE="$RESET_FILE" INPUT_FILE="$RESET_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "CRITICAL_ISSUE_RESET_STATUS=PASS" "$valid_out" && record_pass "main critical issue reset artifact PASS" || { record_fail "main critical issue reset artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main critical issue reset artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" RESET_FILE="$RESET_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "CRITICAL_ISSUE_RESET_STATUS=PASS" "$valid_out" && record_pass "valid critical issue reset fixture PASS" || { record_fail "valid critical issue reset fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid critical issue reset fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "CRITICAL_ISSUE_RESET_TOTAL_ITEM_COUNT=15" "$valid_out" && record_pass "valid critical reset total item count" || record_fail "valid critical reset total item count"
  grep -Fq "CRITICAL_ISSUE_RESET_READY_ITEM_COUNT=15" "$valid_out" && record_pass "valid critical reset ready item count" || record_fail "valid critical reset ready item count"
  grep -Fq "CRITICAL_ISSUE_RESET_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid critical reset missing item zero" || record_fail "valid critical reset missing item zero"
  grep -Fq "CRITICAL_ISSUE_COUNT=0" "$valid_out" && record_pass "valid critical issue zero guard" || record_fail "valid critical issue zero guard"
  grep -Fq "P0_ISSUE_COUNT=0" "$valid_out" && record_pass "valid P0 issue zero guard" || record_fail "valid P0 issue zero guard"
  grep -Fq "P1_ISSUE_COUNT=0" "$valid_out" && record_pass "valid P1 issue zero guard" || record_fail "valid P1 issue zero guard"
  grep -Fq "OPEN_BLOCKER_COUNT=0" "$valid_out" && record_pass "valid open blocker zero guard" || record_fail "valid open blocker zero guard"
  grep -Fq "OPEN_INCIDENT_COUNT=0" "$valid_out" && record_pass "valid open incident zero guard" || record_fail "valid open incident zero guard"
  grep -Fq "REGRESSION_FAIL_COUNT=0" "$valid_out" && record_pass "valid regression fail zero guard" || record_fail "valid regression fail zero guard"
  grep -Fq "NO_GO_NO_GO_DECISION=true" "$valid_out" && record_pass "valid no go/no-go decision guard" || record_fail "valid no go/no-go decision guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" RESET_FILE="$RESET_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid critical issue reset fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "CRITICAL_ISSUE_RESET_STATUS=FAIL" "$invalid_out" && record_pass "invalid critical issue reset fixture FAIL guard" || { record_fail "invalid critical issue reset fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=CRITICAL_ISSUE_RESET_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot critical reset mode guard" || record_fail "controlled pilot critical reset mode guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=CHAIN_DEPENDENCY_NOT_PASS:232_FAZ_4_16_8_2_UAT_BASARI_ESIGI" "$invalid_out" && record_pass "UAT threshold dependency guard" || record_fail "UAT threshold dependency guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=REQUIRED_RESET_ITEM_NOT_READY:CRITICAL_RESET_KICKOFF" "$invalid_out" && record_pass "required reset item ready guard" || record_fail "required reset item ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=REQUIRED_EVIDENCE_MISSING:CRITICAL_RESET_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=REQUIRED_RESET_ITEMS_MISSING" "$invalid_out" && record_pass "missing required reset items guard" || record_fail "missing required reset items guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=DUPLICATE_RESET_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate reset item guard" || record_fail "duplicate reset item guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary critical issue zero guard" || record_fail "summary critical issue zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_P0_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P0 zero guard" || record_fail "summary P0 zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_P1_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary P1 zero guard" || record_fail "summary P1 zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary open blocker zero guard" || record_fail "summary open blocker zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_OPEN_INCIDENT_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary open incident zero guard" || record_fail "summary open incident zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUMMARY_REGRESSION_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "summary regression fail zero guard" || record_fail "summary regression fail zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=VALUE_UNRESOLVED_CRITICAL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "unresolved critical zero guard" || record_fail "unresolved critical zero guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=UAT_THRESHOLD_STATUS_NOT_PASS" "$invalid_out" && record_pass "UAT threshold PASS guard" || record_fail "UAT threshold PASS guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=RESOLUTION_EVIDENCE_STATUS_NOT_READY" "$invalid_out" && record_pass "resolution evidence ready guard" || record_fail "resolution evidence ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=REGRESSION_EVIDENCE_STATUS_NOT_READY" "$invalid_out" && record_pass "regression evidence ready guard" || record_fail "regression evidence ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=OWNER_SIGNOFF_STATUS_NOT_READY" "$invalid_out" && record_pass "owner signoff ready guard" || record_fail "owner signoff ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=SUPPORT_CONFIRMATION_STATUS_NOT_READY" "$invalid_out" && record_pass "support confirmation ready guard" || record_fail "support confirmation ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=TENANT_CONFIRMATION_STATUS_NOT_READY" "$invalid_out" && record_pass "tenant confirmation ready guard" || record_fail "tenant confirmation ready guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=GO_NO_GO_DECISION_NOT_DISABLED" "$invalid_out" && record_pass "go/no-go decision disabled guard" || record_fail "go/no-go decision disabled guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "CRITICAL_ISSUE_RESET_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 233 — FAZ 4-16.8.3 KRITIK HATA SIFIRLAMA REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "critical issue reset file exists" "$RESET_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "critical reset kickoff doc exists" "docs/faz4r/critical_issue_reset/critical_reset_kickoff.md"
  check_file "critical issue inventory doc exists" "docs/faz4r/critical_issue_reset/critical_issue_inventory.md"
  check_file "regression test evidence doc exists" "docs/faz4r/critical_issue_reset/regression_test_evidence.md"
  check_file "final critical reset report doc exists" "docs/faz4r/critical_issue_reset/final_critical_reset_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.8.3 Kritik Hata Sıfırlama"
  check_contains "doc critical reset kickoff marker" "$DOC_FILE" "Critical reset kickoff"
  check_contains "doc P0 P1 zero marker" "$DOC_FILE" "p0_issue_count = 0"
  check_contains "doc no go/no-go marker" "$DOC_FILE" "no_go_no_go_decision = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 233"
  check_contains "config dependency 232 marker" "$CONFIG_FILE" "232_FAZ_4_16_8_2_UAT_BASARI_ESIGI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"critical_issue_reset_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config P0 zero marker" "$CONFIG_FILE" "\"p0_issue_count_required\": 0"
  check_contains "config P1 zero marker" "$CONFIG_FILE" "\"p1_issue_count_required\": 0"
  check_contains "config regression zero marker" "$CONFIG_FILE" "\"regression_fail_count_required\": 0"
  check_contains "config no go/no-go marker" "$CONFIG_FILE" "\"no_go_no_go_decision_required\": true"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "reset status ready marker" "$RESET_FILE" "\"critical_issue_reset_status\": \"READY\""
  check_contains "reset controlled pilot marker" "$RESET_FILE" "\"critical_issue_reset_mode\": \"CONTROLLED_PILOT\""
  check_contains "critical reset kickoff marker" "$RESET_FILE" "CRITICAL_RESET_KICKOFF"
  check_contains "UAT threshold link marker" "$RESET_FILE" "UAT_THRESHOLD_LINK"
  check_contains "critical issue inventory marker" "$RESET_FILE" "CRITICAL_ISSUE_INVENTORY"
  check_contains "severity classification marker" "$RESET_FILE" "SEVERITY_CLASSIFICATION"
  check_contains "P0 P1 zero target marker" "$RESET_FILE" "P0_P1_ZERO_TARGET"
  check_contains "resolution evidence marker" "$RESET_FILE" "RESOLUTION_EVIDENCE_INDEX"
  check_contains "regression test marker" "$RESET_FILE" "REGRESSION_TEST_EVIDENCE"
  check_contains "owner signoff marker" "$RESET_FILE" "OWNER_SIGNOFF"
  check_contains "support confirmation marker" "$RESET_FILE" "SUPPORT_CONFIRMATION"
  check_contains "tenant confirmation marker" "$RESET_FILE" "PILOT_TENANT_CONFIRMATION"
  check_contains "incident backlog zero marker" "$RESET_FILE" "INCIDENT_BACKLOG_ZERO"
  check_contains "open blocker zero marker" "$RESET_FILE" "OPEN_BLOCKER_ZERO"
  check_contains "critical issue count zero marker" "$RESET_FILE" "\"critical_issue_count\": 0"
  check_contains "P0 issue count zero marker" "$RESET_FILE" "\"p0_issue_count\": 0"
  check_contains "P1 issue count zero marker" "$RESET_FILE" "\"p1_issue_count\": 0"
  check_contains "reset no go/no-go marker" "$RESET_FILE" "\"no_go_no_go_decision\": true"
  check_contains "reset no production marker" "$RESET_FILE" "\"no_production_launch\": true"
  check_contains "reset closed policy reference marker" "$RESET_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime reset file guard marker" "$RUNTIME_SCRIPT" "RESET_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_RESET_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_RESET_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_RESET_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime P0 guard marker" "$RUNTIME_SCRIPT" "P0_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime regression guard marker" "$RUNTIME_SCRIPT" "REGRESSION_FAIL_COUNT_NOT_ZERO"
  check_contains "runtime no go/no-go guard marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_NOT_DISABLED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_RESET_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_RESET_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test reset items marker" "$TEST_FILE" "\"reset_items\""
  check_contains "test issue values marker" "$TEST_FILE" "\"issue_values\""
  check_contains "test reset controls marker" "$TEST_FILE" "\"reset_controls\""
  check_contains "test reset metrics marker" "$TEST_FILE" "\"reset_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 233 — FAZ 4-16.8.3 KRITIK HATA SIFIRLAMA COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_DOC_STATUS=READY"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_CONFIG_STATUS=READY"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_TEST_STATUS=PASS"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_FINAL_STATUS=PASS"
    echo "FAZ_4_16_8_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_TEST_STATUS=FAIL"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_8_3_KRITIK_HATA_SIFIRLAMA_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_8_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
