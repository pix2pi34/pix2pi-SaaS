#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_5_tenant_bazli_durum_raporu.v1.json"
REPORT_FILE="configs/faz4r/tenant_status_report.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_tenant_status_report.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_5_tenant_bazli_durum_raporu_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$REPORT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TENANT_STATUS_REPORT_STATUS=PASS" "$valid_out"; then
      record_pass "main tenant status report artifact PASS"
    else
      record_fail "main tenant status report artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main tenant status report artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TENANT_STATUS_REPORT_STATUS=PASS" "$valid_out"; then
      record_pass "valid tenant status report fixture PASS"
    else
      record_fail "valid tenant status report fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid tenant status report fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "TENANT_STATUS_REPORT_TOTAL_SECTION_COUNT=15" "$valid_out"; then
    record_pass "valid tenant status report total section count"
  else
    record_fail "valid tenant status report total section count"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_READY_SECTION_COUNT=15" "$valid_out"; then
    record_pass "valid tenant status report ready section count"
  else
    record_fail "valid tenant status report ready section count"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_MISSING_SECTION_COUNT=0" "$valid_out"; then
    record_pass "valid tenant status report missing section zero"
  else
    record_fail "valid tenant status report missing section zero"
  fi

  if grep -Fq "OPERATIONS_HANDOFF_READY=YES" "$valid_out"; then
    record_pass "valid operations handoff ready"
  else
    record_fail "valid operations handoff ready"
  fi

  if CONFIG_FILE="$CONFIG_FILE" REPORT_FILE="$REPORT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid tenant status report fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "TENANT_STATUS_REPORT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid tenant status report fixture FAIL guard"
    else
      record_fail "invalid tenant status report fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REPORT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot report mode guard"
  else
    record_fail "controlled pilot report mode guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:219_FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI" "$invalid_out"; then
    record_pass "pilot incident dependency guard"
  else
    record_fail "pilot incident dependency guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REQUIRED_REPORT_SECTION_NOT_READY:TENANT_IDENTITY_SUMMARY" "$invalid_out"; then
    record_pass "required report section ready guard"
  else
    record_fail "required report section ready guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REQUIRED_REPORT_SECTION_RESULT_NOT_PASS:TENANT_IDENTITY_SUMMARY" "$invalid_out"; then
    record_pass "required report section result pass guard"
  else
    record_fail "required report section result pass guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REQUIRED_EVIDENCE_MISSING:TENANT_IDENTITY_SUMMARY" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REQUIRED_REPORT_SECTIONS_MISSING" "$invalid_out"; then
    record_pass "missing required report sections guard"
  else
    record_fail "missing required report sections guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=DUPLICATE_REPORT_SECTION_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate report section guard"
  else
    record_fail "duplicate report section guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=TOTAL_SECTION_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total section count reconciliation guard"
  else
    record_fail "total section count reconciliation guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=MISSING_SECTION_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing section zero guard"
  else
    record_fail "missing section zero guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=ROLLBACK_SIGNAL_STATUS_NOT_CLEAR" "$invalid_out"; then
    record_pass "rollback signal clear guard"
  else
    record_fail "rollback signal clear guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=OPERATIONS_HANDOFF_NOT_READY" "$invalid_out"; then
    record_pass "operations handoff ready guard"
  else
    record_fail "operations handoff ready guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REAL_TICKET_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real ticket system disabled guard"
  else
    record_fail "real ticket system disabled guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=REAL_EMAIL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real email dispatch disabled guard"
  else
    record_fail "real email dispatch disabled guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out"; then
    record_pass "live external provider activation disabled guard"
  else
    record_fail "live external provider activation disabled guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "live external provider closed guard"
  else
    record_fail "live external provider closed guard"
  fi

  if grep -Fq "TENANT_STATUS_REPORT_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed guard"
  else
    record_fail "production launch closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 220 — FAZ 4-16.5.5 TENANT BAZLI DURUM RAPORU REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "tenant status report file exists" "$REPORT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "tenant identity summary doc exists" "docs/faz4r/tenant_status_report/tenant_identity_summary.md"
  check_file "pilot health summary doc exists" "docs/faz4r/tenant_status_report/pilot_health_summary.md"
  check_file "incident summary doc exists" "docs/faz4r/tenant_status_report/pilot_incident_management_summary.md"
  check_file "report closure checklist doc exists" "docs/faz4r/tenant_status_report/report_closure_checklist.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.5 Tenant Bazlı Durum Raporu"
  check_contains "doc tenant identity marker" "$DOC_FILE" "Tenant identity summary"
  check_contains "doc report result marker" "$DOC_FILE" "report_result = PASS"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 220"
  check_contains "config dependency 218 marker" "$CONFIG_FILE" "218_FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD"
  check_contains "config dependency 219 marker" "$CONFIG_FILE" "219_FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"report_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required section marker" "$CONFIG_FILE" "\"required_section_status_required\": \"READY\""
  check_contains "config missing section zero marker" "$CONFIG_FILE" "\"missing_section_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config report result marker" "$CONFIG_FILE" "\"report_result_required\": \"PASS\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "report status ready marker" "$REPORT_FILE" "\"report_status\": \"READY\""
  check_contains "report controlled pilot marker" "$REPORT_FILE" "\"report_mode\": \"CONTROLLED_PILOT\""
  check_contains "report tenant identity marker" "$REPORT_FILE" "TENANT_IDENTITY_SUMMARY"
  check_contains "report pilot health marker" "$REPORT_FILE" "PILOT_HEALTH_SUMMARY"
  check_contains "report incident marker" "$REPORT_FILE" "PILOT_INCIDENT_MANAGEMENT_SUMMARY"
  check_contains "report rollback marker" "$REPORT_FILE" "ROLLBACK_DECISION_SUMMARY"
  check_contains "report kpi marker" "$REPORT_FILE" "KPI_SNAPSHOT_SUMMARY"
  check_contains "report closed policy marker" "$REPORT_FILE" "CLOSED_PROVIDER_POLICY_SUMMARY"
  check_contains "report handoff marker" "$REPORT_FILE" "OPERATIONS_HANDOFF_SUMMARY"
  check_contains "report closure marker" "$REPORT_FILE" "REPORT_CLOSURE_CHECKLIST"
  check_contains "report no real ticket marker" "$REPORT_FILE" "\"no_real_ticket_system\": true"
  check_contains "report no real email marker" "$REPORT_FILE" "\"no_real_email_dispatch\": true"
  check_contains "report closed policy reference marker" "$REPORT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime report file guard marker" "$RUNTIME_SCRIPT" "REPORT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "REPORT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required section guard marker" "$RUNTIME_SCRIPT" "REQUIRED_REPORT_SECTION_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_REPORT_SECTION_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_SECTION_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime ticket disabled guard marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_DISABLED"
  check_contains "runtime email disabled guard marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "TENANT_STATUS_REPORT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "TENANT_STATUS_REPORT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test report sections marker" "$TEST_FILE" "\"report_sections\""
  check_contains "test report controls marker" "$TEST_FILE" "\"report_controls\""
  check_contains "test tenant metrics marker" "$TEST_FILE" "\"tenant_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 220 — FAZ 4-16.5.5 TENANT BAZLI DURUM RAPORU COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_DOC_STATUS=READY"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_FINAL_STATUS=PASS"
    echo "FAZ_4_16_6_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_6_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
