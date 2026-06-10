#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_1_pilot_health_dashboard.v1.json"
DASHBOARD_FILE="configs/faz4r/pilot_health_dashboard.controlled_pilot.v1.json"
HTML_FILE="docs/faz4r/pilot_health_dashboard/pilot_health_dashboard.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_health_dashboard.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_1_pilot_health_dashboard_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" DASHBOARD_FILE="$DASHBOARD_FILE" HTML_FILE="$HTML_FILE" INPUT_FILE="$DASHBOARD_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_HEALTH_DASHBOARD_STATUS=PASS" "$valid_out"; then
      record_pass "main pilot health dashboard artifact PASS"
    else
      record_fail "main pilot health dashboard artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main pilot health dashboard artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" DASHBOARD_FILE="$DASHBOARD_FILE" HTML_FILE="$HTML_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_HEALTH_DASHBOARD_STATUS=PASS" "$valid_out"; then
      record_pass "valid pilot health dashboard fixture PASS"
    else
      record_fail "valid pilot health dashboard fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid pilot health dashboard fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_TOTAL_WIDGET_COUNT=14" "$valid_out"; then
    record_pass "valid pilot health dashboard total widget count"
  else
    record_fail "valid pilot health dashboard total widget count"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_READY_WIDGET_COUNT=14" "$valid_out"; then
    record_pass "valid pilot health dashboard ready widget count"
  else
    record_fail "valid pilot health dashboard ready widget count"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_MISSING_WIDGET_COUNT=0" "$valid_out"; then
    record_pass "valid pilot health dashboard missing widget zero"
  else
    record_fail "valid pilot health dashboard missing widget zero"
  fi

  if grep -Fq "HTML_DASHBOARD_STATUS=READY" "$valid_out"; then
    record_pass "valid HTML dashboard ready"
  else
    record_fail "valid HTML dashboard ready"
  fi

  if CONFIG_FILE="$CONFIG_FILE" DASHBOARD_FILE="$DASHBOARD_FILE" HTML_FILE="$HTML_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot health dashboard fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PILOT_HEALTH_DASHBOARD_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid pilot health dashboard fixture FAIL guard"
    else
      record_fail "invalid pilot health dashboard fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=DASHBOARD_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot dashboard mode guard"
  else
    record_fail "controlled pilot dashboard mode guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=CHAIN_DEPENDENCY_NOT_PASS:217_FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI" "$invalid_out"; then
    record_pass "pilot operations dependency guard"
  else
    record_fail "pilot operations dependency guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=REQUIRED_WIDGET_NOT_READY:PILOT_TENANT_HEALTH_SUMMARY" "$invalid_out"; then
    record_pass "required widget ready guard"
  else
    record_fail "required widget ready guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=REQUIRED_EVIDENCE_MISSING:PILOT_TENANT_HEALTH_SUMMARY" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=REQUIRED_WIDGETS_MISSING" "$invalid_out"; then
    record_pass "missing required widgets guard"
  else
    record_fail "missing required widgets guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=DUPLICATE_WIDGET_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate widget guard"
  else
    record_fail "duplicate widget guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=TOTAL_WIDGET_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total widget count reconciliation guard"
  else
    record_fail "total widget count reconciliation guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=MISSING_WIDGET_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing widget zero guard"
  else
    record_fail "missing widget zero guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=ROLLBACK_SIGNAL_STATUS_NOT_CLEAR" "$invalid_out"; then
    record_pass "rollback signal clear guard"
  else
    record_fail "rollback signal clear guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=HTML_DASHBOARD_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "HTML dashboard ready guard"
  else
    record_fail "HTML dashboard ready guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out"; then
    record_pass "live external provider activation disabled guard"
  else
    record_fail "live external provider activation disabled guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "live external provider closed guard"
  else
    record_fail "live external provider closed guard"
  fi

  if grep -Fq "PILOT_HEALTH_DASHBOARD_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed guard"
  else
    record_fail "production launch closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 218 — FAZ 4-16.5.1 PILOT HEALTH DASHBOARD REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "dashboard file exists" "$DASHBOARD_FILE"
  check_file "html dashboard file exists" "$HTML_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.1 Pilot Health Dashboard"
  check_contains "doc tenant health marker" "$DOC_FILE" "Pilot tenant health summary"
  check_contains "doc rollback clear marker" "$DOC_FILE" "rollback_signal_status = CLEAR"
  check_contains "doc html status marker" "$DOC_FILE" "html_dashboard_status = READY"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 218"
  check_contains "config dependency 217 marker" "$CONFIG_FILE" "217_FAZ_4_16_5_6_PILOT_OPERATIONS_TESTLERI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"dashboard_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required widget marker" "$CONFIG_FILE" "\"required_widget_status_required\": \"READY\""
  check_contains "config missing widget zero marker" "$CONFIG_FILE" "\"missing_widget_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config html dashboard marker" "$CONFIG_FILE" "\"html_dashboard_status_required\": \"READY\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "dashboard status ready marker" "$DASHBOARD_FILE" "\"dashboard_status\": \"READY\""
  check_contains "dashboard controlled pilot marker" "$DASHBOARD_FILE" "\"dashboard_mode\": \"CONTROLLED_PILOT\""
  check_contains "dashboard tenant summary marker" "$DASHBOARD_FILE" "PILOT_TENANT_HEALTH_SUMMARY"
  check_contains "dashboard service health marker" "$DASHBOARD_FILE" "SERVICE_HEALTH_WIDGET"
  check_contains "dashboard import marker" "$DASHBOARD_FILE" "IMPORT_PIPELINE_HEALTH_WIDGET"
  check_contains "dashboard readmodel marker" "$DASHBOARD_FILE" "READMODEL_REPORTING_HEALTH_WIDGET"
  check_contains "dashboard UAT marker" "$DASHBOARD_FILE" "UAT_STATUS_WIDGET"
  check_contains "dashboard support marker" "$DASHBOARD_FILE" "TRAINING_SUPPORT_HEALTH_WIDGET"
  check_contains "dashboard rollback marker" "$DASHBOARD_FILE" "ROLLBACK_SIGNAL_HEALTH_WIDGET"
  check_contains "dashboard closed policy marker" "$DASHBOARD_FILE" "CLOSED_PROVIDER_POLICY_WIDGET"
  check_contains "dashboard handoff marker" "$DASHBOARD_FILE" "OPERATIONS_HANDOFF_WIDGET"
  check_contains "dashboard html ready marker" "$DASHBOARD_FILE" "\"html_dashboard_status\": \"READY\""
  check_contains "dashboard closed policy reference marker" "$DASHBOARD_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "html title marker" "$HTML_FILE" "Pix2pi FAZ 4-R Pilot Health Dashboard"
  check_contains "html tenant widget marker" "$HTML_FILE" "pilot-tenant-health-summary"
  check_contains "html service widget marker" "$HTML_FILE" "service-health-widget"
  check_contains "html import widget marker" "$HTML_FILE" "import-pipeline-health-widget"
  check_contains "html readmodel widget marker" "$HTML_FILE" "readmodel-reporting-health-widget"
  check_contains "html rollback widget marker" "$HTML_FILE" "rollback-signal-health-widget"
  check_contains "html closed policy widget marker" "$HTML_FILE" "closed-provider-policy-widget"
  check_contains "html handoff widget marker" "$HTML_FILE" "operations-handoff-widget"
  check_contains "html closed policy marker" "$HTML_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime dashboard file guard marker" "$RUNTIME_SCRIPT" "DASHBOARD_FILE_NOT_FOUND"
  check_contains "runtime html file guard marker" "$RUNTIME_SCRIPT" "HTML_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "DASHBOARD_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required widget guard marker" "$RUNTIME_SCRIPT" "REQUIRED_WIDGET_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_WIDGET_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_WIDGET_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime html marker guard marker" "$RUNTIME_SCRIPT" "HTML_MARKER_MISSING"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_HEALTH_DASHBOARD_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_HEALTH_DASHBOARD_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test widgets marker" "$TEST_FILE" "\"widgets\""
  check_contains "test dashboard controls marker" "$TEST_FILE" "\"dashboard_controls\""
  check_contains "test dashboard metrics marker" "$TEST_FILE" "\"dashboard_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 218 — FAZ 4-16.5.1 PILOT HEALTH DASHBOARD COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_DOC_STATUS=READY"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_HTML_STATUS=READY"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
