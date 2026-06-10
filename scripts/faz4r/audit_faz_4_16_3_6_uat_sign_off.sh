#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_3_6_UAT_SIGN_OFF.md"
CONFIG_FILE="configs/faz4r/faz_4_16_3_6_uat_sign_off.v1.json"
SIGNOFF_FILE="configs/faz4r/uat_sign_off.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_uat_sign_off.sh"
TEST_FILE="tests/faz4r/faz_4_16_3_6_uat_sign_off_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_3_6_UAT_SIGN_OFF_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_3_6_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_3_6_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_3_6_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_3_6_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" SIGNOFF_FILE="$SIGNOFF_FILE" INPUT_FILE="$SIGNOFF_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "UAT_SIGN_OFF_STATUS=PASS" "$valid_out"; then
      record_pass "main UAT sign-off artifact PASS"
    else
      record_fail "main UAT sign-off artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main UAT sign-off artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" SIGNOFF_FILE="$SIGNOFF_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "UAT_SIGN_OFF_STATUS=PASS" "$valid_out"; then
      record_pass "valid UAT sign-off fixture PASS"
    else
      record_fail "valid UAT sign-off fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid UAT sign-off fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "UAT_SIGN_OFF_TOTAL_UAT_AREA_COUNT=5" "$valid_out"; then
    record_pass "valid UAT sign-off total area count"
  else
    record_fail "valid UAT sign-off total area count"
  fi

  if grep -Fq "UAT_SIGN_OFF_REQUIRED_FAIL_COUNT=0" "$valid_out"; then
    record_pass "valid UAT sign-off required fail zero"
  else
    record_fail "valid UAT sign-off required fail zero"
  fi

  if grep -Fq "UAT_SIGN_OFF_OPEN_BLOCKER_COUNT=0" "$valid_out"; then
    record_pass "valid UAT sign-off open blocker zero"
  else
    record_fail "valid UAT sign-off open blocker zero"
  fi

  if grep -Fq "NEXT_PHASE_READY=FAZ_4_16_4_1_READY" "$valid_out"; then
    record_pass "valid UAT sign-off next phase ready"
  else
    record_fail "valid UAT sign-off next phase ready"
  fi

  if CONFIG_FILE="$CONFIG_FILE" SIGNOFF_FILE="$SIGNOFF_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid UAT sign-off fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "UAT_SIGN_OFF_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid UAT sign-off fixture FAIL guard"
    else
      record_fail "invalid UAT sign-off fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=SIGNOFF_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot sign-off mode guard"
  else
    record_fail "controlled pilot sign-off mode guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=CHAIN_DEPENDENCY_NOT_PASS:208_FAZ_4_16_3_5_E_BELGE_EXPORT_UAT" "$invalid_out"; then
    record_pass "chain dependency guard"
  else
    record_fail "chain dependency guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=REQUIRED_UAT_AREA_NOT_PASS:MANAGEMENT_PANEL_UAT" "$invalid_out"; then
    record_pass "required UAT area pass guard"
  else
    record_fail "required UAT area pass guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=REQUIRED_EVIDENCE_MISSING:MANAGEMENT_PANEL_UAT" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=REQUIRED_UAT_AREAS_MISSING" "$invalid_out"; then
    record_pass "missing UAT areas guard"
  else
    record_fail "missing UAT areas guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=TOTAL_UAT_AREA_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total UAT area count reconciliation guard"
  else
    record_fail "total UAT area count reconciliation guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=REQUIRED_FAIL_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "required fail zero guard"
  else
    record_fail "required fail zero guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=BUSINESS_OWNER_SIGNOFF_NOT_READY" "$invalid_out"; then
    record_pass "business owner signoff guard"
  else
    record_fail "business owner signoff guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=SUPPORT_HANDOFF_NOT_READY" "$invalid_out"; then
    record_pass "support handoff ready guard"
  else
    record_fail "support handoff ready guard"
  fi

  if grep -Fq "UAT_SIGN_OFF_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 209 — FAZ 4-16.3.6 UAT SIGN-OFF REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "sign-off file exists" "$SIGNOFF_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.3.6 UAT Sign-off"
  check_contains "doc management panel UAT marker" "$DOC_FILE" "Yönetim paneli UAT sonucu"
  check_contains "doc required fail zero marker" "$DOC_FILE" "required_fail_count = 0"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc owner signoff marker" "$DOC_FILE" "business_owner_signoff = READY"
  check_contains "doc next phase marker" "$DOC_FILE" "next_phase_ready = FAZ_4_16_4_1_READY"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 209"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 208 marker" "$CONFIG_FILE" "208_FAZ_4_16_3_5_E_BELGE_EXPORT_UAT"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"signoff_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config all UAT pass marker" "$CONFIG_FILE" "\"all_uat_status_required\": \"PASS\""
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config open blocker zero marker" "$CONFIG_FILE" "\"open_blocker_count_required\": 0"
  check_contains "config owner signoff marker" "$CONFIG_FILE" "\"business_owner_signoff_required\": \"READY\""
  check_contains "config support handoff marker" "$CONFIG_FILE" "\"support_handoff_ready_required\": \"YES\""
  check_contains "config next phase marker" "$CONFIG_FILE" "\"next_phase_ready_required\": \"FAZ_4_16_4_1_READY\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "signoff status ready marker" "$SIGNOFF_FILE" "\"signoff_status\": \"READY\""
  check_contains "signoff controlled pilot marker" "$SIGNOFF_FILE" "\"signoff_mode\": \"CONTROLLED_PILOT\""
  check_contains "signoff management panel marker" "$SIGNOFF_FILE" "MANAGEMENT_PANEL_UAT"
  check_contains "signoff POS marker" "$SIGNOFF_FILE" "POS_UAT"
  check_contains "signoff accounting marker" "$SIGNOFF_FILE" "ACCOUNTING_UAT"
  check_contains "signoff accountant portal marker" "$SIGNOFF_FILE" "ACCOUNTANT_PORTAL_UAT"
  check_contains "signoff e-document marker" "$SIGNOFF_FILE" "E_DOCUMENT_EXPORT_UAT"
  check_contains "signoff owner marker" "$SIGNOFF_FILE" "\"business_owner_signoff\": \"READY\""
  check_contains "signoff open blocker zero marker" "$SIGNOFF_FILE" "\"open_blocker_count\": 0"
  check_contains "signoff next phase marker" "$SIGNOFF_FILE" "\"next_phase_ready\": \"FAZ_4_16_4_1_READY\""
  check_contains "signoff closed policy marker" "$SIGNOFF_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime signoff guard marker" "$RUNTIME_SCRIPT" "SIGNOFF_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "SIGNOFF_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required area guard marker" "$RUNTIME_SCRIPT" "REQUIRED_UAT_AREA_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_UAT_AREA_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime required fail guard marker" "$RUNTIME_SCRIPT" "REQUIRED_FAIL_COUNT_NOT_ZERO"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime open blocker guard marker" "$RUNTIME_SCRIPT" "OPEN_BLOCKER_COUNT_NOT_ZERO"
  check_contains "runtime owner signoff guard marker" "$RUNTIME_SCRIPT" "BUSINESS_OWNER_SIGNOFF_NOT_READY"
  check_contains "runtime support handoff marker" "$RUNTIME_SCRIPT" "SUPPORT_HANDOFF_NOT_READY"
  check_contains "runtime production closed marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "UAT_SIGN_OFF_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "UAT_SIGN_OFF_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test UAT areas marker" "$TEST_FILE" "\"uat_areas\""
  check_contains "test owner signoffs marker" "$TEST_FILE" "\"owner_signoffs\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 209 — FAZ 4-16.3.6 UAT SIGN-OFF COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_DOC_STATUS=READY"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_CONFIG_STATUS=READY"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_TEST_STATUS=PASS"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_FINAL_STATUS=PASS"
    echo "FAZ_4_16_4_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_TEST_STATUS=FAIL"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_3_6_UAT_SIGN_OFF_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_4_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
