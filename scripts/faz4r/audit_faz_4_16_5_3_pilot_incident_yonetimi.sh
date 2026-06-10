#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_5_3_pilot_incident_yonetimi.v1.json"
INCIDENT_FILE="configs/faz4r/pilot_incident_management.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_incident_management.sh"
TEST_FILE="tests/faz4r/faz_4_16_5_3_pilot_incident_yonetimi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_5_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_5_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_5_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_5_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" INCIDENT_FILE="$INCIDENT_FILE" INPUT_FILE="$INCIDENT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_INCIDENT_MANAGEMENT_STATUS=PASS" "$valid_out"; then
      record_pass "main pilot incident management artifact PASS"
    else
      record_fail "main pilot incident management artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main pilot incident management artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" INCIDENT_FILE="$INCIDENT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_INCIDENT_MANAGEMENT_STATUS=PASS" "$valid_out"; then
      record_pass "valid pilot incident management fixture PASS"
    else
      record_fail "valid pilot incident management fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid pilot incident management fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_TOTAL_RULE_COUNT=14" "$valid_out"; then
    record_pass "valid incident total rule count"
  else
    record_fail "valid incident total rule count"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_READY_RULE_COUNT=14" "$valid_out"; then
    record_pass "valid incident ready rule count"
  else
    record_fail "valid incident ready rule count"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_MISSING_RULE_COUNT=0" "$valid_out"; then
    record_pass "valid incident missing rule zero"
  else
    record_fail "valid incident missing rule zero"
  fi

  if grep -Fq "NO_REAL_TICKET_SYSTEM=true" "$valid_out"; then
    record_pass "valid no real ticket system guard"
  else
    record_fail "valid no real ticket system guard"
  fi

  if grep -Fq "NO_REAL_EMAIL_DISPATCH=true" "$valid_out"; then
    record_pass "valid no real email dispatch guard"
  else
    record_fail "valid no real email dispatch guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" INCIDENT_FILE="$INCIDENT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot incident management fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PILOT_INCIDENT_MANAGEMENT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid pilot incident management fixture FAIL guard"
    else
      record_fail "invalid pilot incident management fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=INCIDENT_MANAGEMENT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot incident mode guard"
  else
    record_fail "controlled pilot incident mode guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:218_FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD" "$invalid_out"; then
    record_pass "pilot health dashboard dependency guard"
  else
    record_fail "pilot health dashboard dependency guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REQUIRED_INCIDENT_RULE_NOT_READY:INCIDENT_INTAKE" "$invalid_out"; then
    record_pass "required incident rule ready guard"
  else
    record_fail "required incident rule ready guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REQUIRED_EVIDENCE_MISSING:INCIDENT_INTAKE" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REQUIRED_INCIDENT_RULES_MISSING" "$invalid_out"; then
    record_pass "missing required incident rules guard"
  else
    record_fail "missing required incident rules guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=DUPLICATE_INCIDENT_RULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate incident rule guard"
  else
    record_fail "duplicate incident rule guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rule count reconciliation guard"
  else
    record_fail "total rule count reconciliation guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing rule zero guard"
  else
    record_fail "missing rule zero guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=INCIDENT_STATUS_LIFECYCLE_NOT_READY" "$invalid_out"; then
    record_pass "incident status lifecycle ready guard"
  else
    record_fail "incident status lifecycle ready guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=ESCALATION_LINK_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "escalation link ready guard"
  else
    record_fail "escalation link ready guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=ROLLBACK_SIGNAL_LINK_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "rollback signal link ready guard"
  else
    record_fail "rollback signal link ready guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REAL_TICKET_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real ticket system disabled guard"
  else
    record_fail "real ticket system disabled guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REAL_EMAIL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real email dispatch disabled guard"
  else
    record_fail "real email dispatch disabled guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REAL_TICKET_DISPATCH_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "real ticket dispatch count zero guard"
  else
    record_fail "real ticket dispatch count zero guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "real email dispatch count zero guard"
  else
    record_fail "real email dispatch count zero guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=REAL_TICKET_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ticket system closed guard"
  else
    record_fail "real ticket system closed guard"
  fi

  if grep -Fq "PILOT_INCIDENT_MANAGEMENT_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 219 — FAZ 4-16.5.3 PILOT INCIDENT YONETIMI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "incident management file exists" "$INCIDENT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "incident intake doc exists" "docs/faz4r/pilot_incident_management/incident_intake.md"
  check_file "incident lifecycle doc exists" "docs/faz4r/pilot_incident_management/incident_status_lifecycle.md"
  check_file "rollback signal link doc exists" "docs/faz4r/pilot_incident_management/rollback_signal_link.md"
  check_file "incident closure checklist doc exists" "docs/faz4r/pilot_incident_management/incident_closure_checklist.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.5.3 Pilot Incident Yönetimi"
  check_contains "doc incident intake marker" "$DOC_FILE" "Incident intake"
  check_contains "doc lifecycle marker" "$DOC_FILE" "incident_status_lifecycle = READY"
  check_contains "doc no real ticket marker" "$DOC_FILE" "no_real_ticket_system = true"
  check_contains "doc no real email marker" "$DOC_FILE" "no_real_email_dispatch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 219"
  check_contains "config dependency 218 marker" "$CONFIG_FILE" "218_FAZ_4_16_5_1_PILOT_HEALTH_DASHBOARD"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"incident_management_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config no real ticket marker" "$CONFIG_FILE" "\"no_real_ticket_system_required\": true"
  check_contains "config no real email marker" "$CONFIG_FILE" "\"no_real_email_dispatch_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "incident status ready marker" "$INCIDENT_FILE" "\"incident_management_status\": \"READY\""
  check_contains "incident controlled pilot marker" "$INCIDENT_FILE" "\"incident_management_mode\": \"CONTROLLED_PILOT\""
  check_contains "incident intake marker" "$INCIDENT_FILE" "INCIDENT_INTAKE"
  check_contains "incident classification marker" "$INCIDENT_FILE" "INCIDENT_CLASSIFICATION"
  check_contains "incident severity mapping marker" "$INCIDENT_FILE" "SEVERITY_P0_P1_P2_P3_MAPPING"
  check_contains "incident owner assignment marker" "$INCIDENT_FILE" "INCIDENT_OWNER_ASSIGNMENT"
  check_contains "incident timeline marker" "$INCIDENT_FILE" "INCIDENT_TIMELINE_RECORD"
  check_contains "incident lifecycle marker" "$INCIDENT_FILE" "INCIDENT_STATUS_LIFECYCLE"
  check_contains "incident escalation link marker" "$INCIDENT_FILE" "ESCALATION_LINK"
  check_contains "incident rollback signal marker" "$INCIDENT_FILE" "ROLLBACK_SIGNAL_LINK"
  check_contains "incident closure checklist marker" "$INCIDENT_FILE" "INCIDENT_CLOSURE_CHECKLIST"
  check_contains "incident no real ticket marker" "$INCIDENT_FILE" "\"no_real_ticket_system\": true"
  check_contains "incident no real email marker" "$INCIDENT_FILE" "\"no_real_email_dispatch\": true"
  check_contains "incident closed policy marker" "$INCIDENT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime incident file guard marker" "$RUNTIME_SCRIPT" "INCIDENT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "INCIDENT_MANAGEMENT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_INCIDENT_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_INCIDENT_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime ticket disabled guard marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_DISABLED"
  check_contains "runtime email disabled guard marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_DISABLED"
  check_contains "runtime ticket dispatch zero marker" "$RUNTIME_SCRIPT" "REAL_TICKET_DISPATCH_COUNT_NOT_ZERO"
  check_contains "runtime email dispatch zero marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_INCIDENT_MANAGEMENT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_INCIDENT_MANAGEMENT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test incident rules marker" "$TEST_FILE" "\"incident_rules\""
  check_contains "test incident controls marker" "$TEST_FILE" "\"incident_controls\""
  check_contains "test incident metrics marker" "$TEST_FILE" "\"incident_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 219 — FAZ 4-16.5.3 PILOT INCIDENT YONETIMI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_DOC_STATUS=READY"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_TEST_STATUS=PASS"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_5_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_5_3_PILOT_INCIDENT_YONETIMI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_5_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
