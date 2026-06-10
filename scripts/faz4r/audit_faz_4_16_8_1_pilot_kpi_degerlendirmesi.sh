#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_8_1_pilot_kpi_degerlendirmesi.v1.json"
KPI_FILE="configs/faz4r/pilot_kpi_evaluation.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_kpi_evaluation.sh"
TEST_FILE="tests/faz4r/faz_4_16_8_1_pilot_kpi_degerlendirmesi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_8_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_8_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_8_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_8_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" KPI_FILE="$KPI_FILE" INPUT_FILE="$KPI_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "PILOT_KPI_EVALUATION_STATUS=PASS" "$valid_out" && record_pass "main pilot KPI artifact PASS" || { record_fail "main pilot KPI artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main pilot KPI artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" KPI_FILE="$KPI_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "PILOT_KPI_EVALUATION_STATUS=PASS" "$valid_out" && record_pass "valid pilot KPI fixture PASS" || { record_fail "valid pilot KPI fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid pilot KPI fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "PILOT_KPI_EVALUATION_TOTAL_ITEM_COUNT=15" "$valid_out" && record_pass "valid pilot KPI total item count" || record_fail "valid pilot KPI total item count"
  grep -Fq "PILOT_KPI_EVALUATION_READY_ITEM_COUNT=15" "$valid_out" && record_pass "valid pilot KPI ready item count" || record_fail "valid pilot KPI ready item count"
  grep -Fq "PILOT_KPI_EVALUATION_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid pilot KPI missing item zero" || record_fail "valid pilot KPI missing item zero"
  grep -Fq "IMPORT_SUCCESS_STATUS=PASS" "$valid_out" && record_pass "valid import success PASS guard" || record_fail "valid import success PASS guard"
  grep -Fq "UAT_PASS_STATUS=PASS" "$valid_out" && record_pass "valid UAT pass guard" || record_fail "valid UAT pass guard"
  grep -Fq "NO_GO_NO_GO_DECISION=true" "$valid_out" && record_pass "valid no go/no-go decision guard" || record_fail "valid no go/no-go decision guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"

  if CONFIG_FILE="$CONFIG_FILE" KPI_FILE="$KPI_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot KPI fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "PILOT_KPI_EVALUATION_STATUS=FAIL" "$invalid_out" && record_pass "invalid pilot KPI fixture FAIL guard" || { record_fail "invalid pilot KPI fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "PILOT_KPI_EVALUATION_FAIL=PILOT_KPI_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot KPI mode guard" || record_fail "controlled pilot KPI mode guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:230_FAZ_4_16_7_5_REHEARSAL_RAPORU" "$invalid_out" && record_pass "rehearsal report dependency guard" || record_fail "rehearsal report dependency guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=REQUIRED_KPI_ITEM_NOT_READY:KPI_EVALUATION_KICKOFF" "$invalid_out" && record_pass "required KPI item ready guard" || record_fail "required KPI item ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=REQUIRED_EVIDENCE_MISSING:KPI_EVALUATION_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=REQUIRED_KPI_ITEMS_MISSING" "$invalid_out" && record_pass "missing required KPI items guard" || record_fail "missing required KPI items guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=DUPLICATE_KPI_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate KPI item guard" || record_fail "duplicate KPI item guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=REHEARSAL_REPORT_STATUS_NOT_PASS" "$invalid_out" && record_pass "rehearsal report PASS guard" || record_fail "rehearsal report PASS guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=IMPORT_SUCCESS_STATUS_NOT_PASS" "$invalid_out" && record_pass "import success PASS guard" || record_fail "import success PASS guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=UAT_PASS_STATUS_NOT_PASS" "$invalid_out" && record_pass "UAT pass guard" || record_fail "UAT pass guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=SUPPORT_RESPONSE_STATUS_NOT_READY" "$invalid_out" && record_pass "support response ready guard" || record_fail "support response ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=FEEDBACK_CLOSURE_STATUS_NOT_PASS" "$invalid_out" && record_pass "feedback closure PASS guard" || record_fail "feedback closure PASS guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=RUNTIME_HEALTH_STATUS_NOT_READY" "$invalid_out" && record_pass "runtime health ready guard" || record_fail "runtime health ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=INCIDENT_COUNT_STATUS_NOT_READY" "$invalid_out" && record_pass "incident count ready guard" || record_fail "incident count ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=ROLLBACK_READINESS_STATUS_NOT_READY" "$invalid_out" && record_pass "rollback readiness ready guard" || record_fail "rollback readiness ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=COMMUNICATION_READINESS_STATUS_NOT_READY" "$invalid_out" && record_pass "communication readiness ready guard" || record_fail "communication readiness ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=KPI_EVIDENCE_INDEX_STATUS_NOT_READY" "$invalid_out" && record_pass "KPI evidence index ready guard" || record_fail "KPI evidence index ready guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=GO_NO_GO_DECISION_NOT_DISABLED" "$invalid_out" && record_pass "go/no-go decision disabled guard" || record_fail "go/no-go decision disabled guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "provider activation disabled guard" || record_fail "provider activation disabled guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=KPI_BELOW_THRESHOLD_COUNT_NOT_ZERO" "$invalid_out" && record_pass "KPI below threshold count zero guard" || record_fail "KPI below threshold count zero guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=GO_NO_GO_DECISION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "go/no-go decision count zero guard" || record_fail "go/no-go decision count zero guard"
  grep -Fq "PILOT_KPI_EVALUATION_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 231 — FAZ 4-16.8.1 PILOT KPI DEGERLENDIRMESI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "pilot KPI file exists" "$KPI_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "KPI kickoff doc exists" "docs/faz4r/pilot_kpi/kpi_evaluation_kickoff.md"
  check_file "import success KPI doc exists" "docs/faz4r/pilot_kpi/import_success_kpi.md"
  check_file "UAT pass KPI doc exists" "docs/faz4r/pilot_kpi/uat_pass_kpi.md"
  check_file "final KPI evaluation report doc exists" "docs/faz4r/pilot_kpi/final_kpi_evaluation_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.8.1 Pilot KPI Değerlendirmesi"
  check_contains "doc KPI kickoff marker" "$DOC_FILE" "KPI evaluation kickoff"
  check_contains "doc no go/no-go marker" "$DOC_FILE" "no_go_no_go_decision = true"
  check_contains "doc no launch marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 231"
  check_contains "config dependency 230 marker" "$CONFIG_FILE" "230_FAZ_4_16_7_5_REHEARSAL_RAPORU"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"pilot_kpi_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config no go/no-go marker" "$CONFIG_FILE" "\"no_go_no_go_decision_required\": true"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no provider marker" "$CONFIG_FILE" "\"no_live_external_provider_activation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "KPI status ready marker" "$KPI_FILE" "\"pilot_kpi_status\": \"READY\""
  check_contains "KPI controlled pilot marker" "$KPI_FILE" "\"pilot_kpi_mode\": \"CONTROLLED_PILOT\""
  check_contains "KPI kickoff marker" "$KPI_FILE" "KPI_EVALUATION_KICKOFF"
  check_contains "rehearsal link marker" "$KPI_FILE" "REHEARSAL_REPORT_LINK"
  check_contains "tenant readiness KPI marker" "$KPI_FILE" "TENANT_READINESS_KPI"
  check_contains "import success KPI marker" "$KPI_FILE" "IMPORT_SUCCESS_KPI"
  check_contains "UAT pass KPI marker" "$KPI_FILE" "UAT_PASS_KPI"
  check_contains "support response KPI marker" "$KPI_FILE" "SUPPORT_RESPONSE_KPI"
  check_contains "feedback closure KPI marker" "$KPI_FILE" "FEEDBACK_CLOSURE_KPI"
  check_contains "runtime health KPI marker" "$KPI_FILE" "RUNTIME_HEALTH_KPI"
  check_contains "incident count KPI marker" "$KPI_FILE" "INCIDENT_COUNT_KPI"
  check_contains "critical issue zero KPI marker" "$KPI_FILE" "CRITICAL_ISSUE_ZERO_KPI"
  check_contains "rollback readiness KPI marker" "$KPI_FILE" "ROLLBACK_READINESS_KPI"
  check_contains "communication readiness KPI marker" "$KPI_FILE" "COMMUNICATION_READINESS_KPI"
  check_contains "KPI evidence index marker" "$KPI_FILE" "KPI_EVIDENCE_INDEX"
  check_contains "KPI no go/no-go marker" "$KPI_FILE" "\"no_go_no_go_decision\": true"
  check_contains "KPI no production marker" "$KPI_FILE" "\"no_production_launch\": true"
  check_contains "KPI closed policy reference marker" "$KPI_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime KPI file guard marker" "$RUNTIME_SCRIPT" "KPI_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "PILOT_KPI_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_KPI_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_KPI_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no go/no-go guard marker" "$RUNTIME_SCRIPT" "GO_NO_GO_DECISION_NOT_DISABLED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no provider guard marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_KPI_EVALUATION_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_KPI_EVALUATION_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test KPI items marker" "$TEST_FILE" "\"kpi_items\""
  check_contains "test KPI values marker" "$TEST_FILE" "\"kpi_values\""
  check_contains "test KPI controls marker" "$TEST_FILE" "\"kpi_controls\""
  check_contains "test KPI metrics marker" "$TEST_FILE" "\"kpi_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 231 — FAZ 4-16.8.1 PILOT KPI DEGERLENDIRMESI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_DOC_STATUS=READY"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_TEST_STATUS=PASS"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_8_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_8_1_PILOT_KPI_DEGERLENDIRMESI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_8_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
