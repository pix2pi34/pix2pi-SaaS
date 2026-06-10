#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_6_3_hizli_duzeltme_hatti.v1.json"
QUICK_FIX_FILE="configs/faz4r/quick_fix_lane.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_quick_fix_lane.sh"
TEST_FILE="tests/faz4r/faz_4_16_6_3_hizli_duzeltme_hatti_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_6_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_6_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_6_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_6_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" QUICK_FIX_FILE="$QUICK_FIX_FILE" INPUT_FILE="$QUICK_FIX_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "QUICK_FIX_LANE_STATUS=PASS" "$valid_out"; then
      record_pass "main quick fix lane artifact PASS"
    else
      record_fail "main quick fix lane artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main quick fix lane artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" QUICK_FIX_FILE="$QUICK_FIX_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "QUICK_FIX_LANE_STATUS=PASS" "$valid_out"; then
      record_pass "valid quick fix lane fixture PASS"
    else
      record_fail "valid quick fix lane fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid quick fix lane fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "QUICK_FIX_LANE_TOTAL_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid quick fix total rule count"
  else
    record_fail "valid quick fix total rule count"
  fi

  if grep -Fq "QUICK_FIX_LANE_READY_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid quick fix ready rule count"
  else
    record_fail "valid quick fix ready rule count"
  fi

  if grep -Fq "QUICK_FIX_LANE_MISSING_RULE_COUNT=0" "$valid_out"; then
    record_pass "valid quick fix missing rule zero"
  else
    record_fail "valid quick fix missing rule zero"
  fi

  if grep -Fq "NO_AUTO_APPLY_CHANGE=true" "$valid_out"; then
    record_pass "valid no auto apply change guard"
  else
    record_fail "valid no auto apply change guard"
  fi

  if grep -Fq "NO_HOTFIX_DEPLOY=true" "$valid_out"; then
    record_pass "valid no hotfix deploy guard"
  else
    record_fail "valid no hotfix deploy guard"
  fi

  if grep -Fq "NO_REAL_ROLLBACK_EXECUTION=true" "$valid_out"; then
    record_pass "valid no real rollback execution guard"
  else
    record_fail "valid no real rollback execution guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" QUICK_FIX_FILE="$QUICK_FIX_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid quick fix lane fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "QUICK_FIX_LANE_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid quick fix lane fixture FAIL guard"
    else
      record_fail "invalid quick fix lane fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=QUICK_FIX_LANE_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot quick fix mode guard"
  else
    record_fail "controlled pilot quick fix mode guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:222_FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA" "$invalid_out"; then
    record_pass "change classification dependency guard"
  else
    record_fail "change classification dependency guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=REQUIRED_QUICK_FIX_RULE_NOT_READY:QUICK_FIX_INTAKE" "$invalid_out"; then
    record_pass "required quick fix rule ready guard"
  else
    record_fail "required quick fix rule ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=REQUIRED_EVIDENCE_MISSING:QUICK_FIX_INTAKE" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=REQUIRED_QUICK_FIX_RULES_MISSING" "$invalid_out"; then
    record_pass "missing required quick fix rules guard"
  else
    record_fail "missing required quick fix rules guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=DUPLICATE_QUICK_FIX_RULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate quick fix rule guard"
  else
    record_fail "duplicate quick fix rule guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rule count reconciliation guard"
  else
    record_fail "total rule count reconciliation guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing rule zero guard"
  else
    record_fail "missing rule zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=ELIGIBILITY_GATE_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "eligibility gate ready guard"
  else
    record_fail "eligibility gate ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=RISK_ASSESSMENT_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "risk assessment ready guard"
  else
    record_fail "risk assessment ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=TEST_PLAN_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "test plan ready guard"
  else
    record_fail "test plan ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=ROLLBACK_PLAN_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "rollback plan ready guard"
  else
    record_fail "rollback plan ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=APPROVAL_GATE_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "approval gate ready guard"
  else
    record_fail "approval gate ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=QA_VERIFICATION_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "QA verification ready guard"
  else
    record_fail "QA verification ready guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=AUTO_APPLY_CHANGE_NOT_DISABLED" "$invalid_out"; then
    record_pass "auto apply change disabled guard"
  else
    record_fail "auto apply change disabled guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=HOTFIX_DEPLOY_NOT_DISABLED" "$invalid_out"; then
    record_pass "hotfix deploy disabled guard"
  else
    record_fail "hotfix deploy disabled guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=REAL_ROLLBACK_EXECUTION_NOT_DISABLED" "$invalid_out"; then
    record_pass "real rollback execution disabled guard"
  else
    record_fail "real rollback execution disabled guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=AUTO_APPLY_CHANGE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "auto apply change count zero guard"
  else
    record_fail "auto apply change count zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=HOTFIX_DEPLOY_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "hotfix deploy count zero guard"
  else
    record_fail "hotfix deploy count zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=REAL_ROLLBACK_EXECUTION_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "real rollback execution count zero guard"
  else
    record_fail "real rollback execution count zero guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "QUICK_FIX_LANE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "live external provider closed guard"
  else
    record_fail "live external provider closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 223 — FAZ 4-16.6.3 HIZLI DUZELTME HATTI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "quick fix lane file exists" "$QUICK_FIX_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "quick fix intake doc exists" "docs/faz4r/quick_fix_lane/quick_fix_intake.md"
  check_file "eligibility gate doc exists" "docs/faz4r/quick_fix_lane/quick_fix_eligibility_gate.md"
  check_file "test plan gate doc exists" "docs/faz4r/quick_fix_lane/test_plan_gate.md"
  check_file "rollback plan gate doc exists" "docs/faz4r/quick_fix_lane/rollback_plan_gate.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.6.3 Hızlı Düzeltme Hattı"
  check_contains "doc quick fix intake marker" "$DOC_FILE" "Quick fix intake"
  check_contains "doc eligibility marker" "$DOC_FILE" "eligibility_gate_status = READY"
  check_contains "doc no auto apply marker" "$DOC_FILE" "no_auto_apply_change = true"
  check_contains "doc no hotfix marker" "$DOC_FILE" "no_hotfix_deploy = true"
  check_contains "doc no real rollback marker" "$DOC_FILE" "no_real_rollback_execution = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 223"
  check_contains "config dependency 222 marker" "$CONFIG_FILE" "222_FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"quick_fix_lane_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config eligibility ready marker" "$CONFIG_FILE" "\"eligibility_gate_status_required\": \"READY\""
  check_contains "config no auto apply marker" "$CONFIG_FILE" "\"no_auto_apply_change_required\": true"
  check_contains "config no hotfix marker" "$CONFIG_FILE" "\"no_hotfix_deploy_required\": true"
  check_contains "config no real rollback marker" "$CONFIG_FILE" "\"no_real_rollback_execution_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "quick fix status ready marker" "$QUICK_FIX_FILE" "\"quick_fix_lane_status\": \"READY\""
  check_contains "quick fix controlled pilot marker" "$QUICK_FIX_FILE" "\"quick_fix_lane_mode\": \"CONTROLLED_PILOT\""
  check_contains "quick fix intake marker" "$QUICK_FIX_FILE" "QUICK_FIX_INTAKE"
  check_contains "quick fix eligibility marker" "$QUICK_FIX_FILE" "QUICK_FIX_ELIGIBILITY_GATE"
  check_contains "quick fix priority marker" "$QUICK_FIX_FILE" "PRIORITY_SEVERITY_GATE"
  check_contains "quick fix risk marker" "$QUICK_FIX_FILE" "RISK_ASSESSMENT"
  check_contains "quick fix test plan marker" "$QUICK_FIX_FILE" "TEST_PLAN_GATE"
  check_contains "quick fix rollback plan marker" "$QUICK_FIX_FILE" "ROLLBACK_PLAN_GATE"
  check_contains "quick fix approval marker" "$QUICK_FIX_FILE" "APPROVAL_GATE"
  check_contains "quick fix QA marker" "$QUICK_FIX_FILE" "QA_VERIFICATION_GATE"
  check_contains "quick fix no auto apply marker" "$QUICK_FIX_FILE" "\"no_auto_apply_change\": true"
  check_contains "quick fix no hotfix marker" "$QUICK_FIX_FILE" "\"no_hotfix_deploy\": true"
  check_contains "quick fix closed policy reference marker" "$QUICK_FIX_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime quick fix file guard marker" "$RUNTIME_SCRIPT" "QUICK_FIX_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "QUICK_FIX_LANE_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_QUICK_FIX_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_QUICK_FIX_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime eligibility guard marker" "$RUNTIME_SCRIPT" "ELIGIBILITY_GATE_STATUS_NOT_READY"
  check_contains "runtime no auto apply guard marker" "$RUNTIME_SCRIPT" "AUTO_APPLY_CHANGE_NOT_DISABLED"
  check_contains "runtime no hotfix guard marker" "$RUNTIME_SCRIPT" "HOTFIX_DEPLOY_NOT_DISABLED"
  check_contains "runtime real rollback guard marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "QUICK_FIX_LANE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "QUICK_FIX_LANE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test quick fix rules marker" "$TEST_FILE" "\"quick_fix_rules\""
  check_contains "test quick fix controls marker" "$TEST_FILE" "\"quick_fix_controls\""
  check_contains "test quick fix metrics marker" "$TEST_FILE" "\"quick_fix_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 223 — FAZ 4-16.6.3 HIZLI DUZELTME HATTI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_DOC_STATUS=READY"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_TEST_STATUS=PASS"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_6_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_6_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
