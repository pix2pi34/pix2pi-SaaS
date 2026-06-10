#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION.md"
CONFIG_FILE="configs/faz4r/faz_4_16_4_4_pilot_issue_escalation.v1.json"
ESCALATION_FILE="configs/faz4r/pilot_issue_escalation.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_pilot_issue_escalation.sh"
TEST_FILE="tests/faz4r/faz_4_16_4_4_pilot_issue_escalation_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_4_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_4_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_4_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_4_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" ESCALATION_FILE="$ESCALATION_FILE" INPUT_FILE="$ESCALATION_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_ISSUE_ESCALATION_STATUS=PASS" "$valid_out"; then
      record_pass "main pilot issue escalation artifact PASS"
    else
      record_fail "main pilot issue escalation artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main pilot issue escalation artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" ESCALATION_FILE="$ESCALATION_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PILOT_ISSUE_ESCALATION_STATUS=PASS" "$valid_out"; then
      record_pass "valid pilot issue escalation fixture PASS"
    else
      record_fail "valid pilot issue escalation fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid pilot issue escalation fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_TOTAL_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid pilot issue escalation total rule count"
  else
    record_fail "valid pilot issue escalation total rule count"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_READY_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid pilot issue escalation ready rule count"
  else
    record_fail "valid pilot issue escalation ready rule count"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_MISSING_RULE_COUNT=0" "$valid_out"; then
    record_pass "valid pilot issue escalation missing rule zero"
  else
    record_fail "valid pilot issue escalation missing rule zero"
  fi

  if grep -Fq "OWNER_MATRIX_STATUS=READY" "$valid_out"; then
    record_pass "valid owner matrix ready"
  else
    record_fail "valid owner matrix ready"
  fi

  if grep -Fq "NO_REAL_EXTERNAL_DISPATCH=true" "$valid_out"; then
    record_pass "valid no real external dispatch guard"
  else
    record_fail "valid no real external dispatch guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" ESCALATION_FILE="$ESCALATION_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid pilot issue escalation fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PILOT_ISSUE_ESCALATION_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid pilot issue escalation fixture FAIL guard"
    else
      record_fail "invalid pilot issue escalation fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=ESCALATION_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot escalation mode guard"
  else
    record_fail "controlled pilot escalation mode guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:212_FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI" "$invalid_out"; then
    record_pass "triage dependency guard"
  else
    record_fail "triage dependency guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=REQUIRED_ESCALATION_RULE_NOT_READY:ESCALATE_P0_BLOCKER" "$invalid_out"; then
    record_pass "required escalation rule ready guard"
  else
    record_fail "required escalation rule ready guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=REQUIRED_EVIDENCE_MISSING:ESCALATE_P0_BLOCKER" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=REQUIRED_ESCALATION_RULES_MISSING" "$invalid_out"; then
    record_pass "missing required escalation rules guard"
  else
    record_fail "missing required escalation rules guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=DUPLICATE_ESCALATION_RULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate escalation rule guard"
  else
    record_fail "duplicate escalation rule guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rule count reconciliation guard"
  else
    record_fail "total rule count reconciliation guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing rule zero guard"
  else
    record_fail "missing rule zero guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=OWNER_MATRIX_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "owner matrix ready guard"
  else
    record_fail "owner matrix ready guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=ESCALATION_SLA_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "escalation SLA ready guard"
  else
    record_fail "escalation SLA ready guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=DECISION_LOG_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "decision log ready guard"
  else
    record_fail "decision log ready guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=REAL_EXTERNAL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real external dispatch disabled guard"
  else
    record_fail "real external dispatch disabled guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=REAL_TICKET_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ticket system closed guard"
  else
    record_fail "real ticket system closed guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=HOTFIX_DEPLOY_NOT_CLOSED" "$invalid_out"; then
    record_pass "hotfix deploy closed guard"
  else
    record_fail "hotfix deploy closed guard"
  fi

  if grep -Fq "PILOT_ISSUE_ESCALATION_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 213 — FAZ 4-16.4.4 PILOT ISSUE ESCALATION REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "escalation file exists" "$ESCALATION_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "P0 escalation doc exists" "docs/faz4r/support_escalation/escalate_p0_blocker.md"
  check_file "owner matrix route doc exists" "docs/faz4r/support_escalation/product_owner_escalation.md"
  check_file "decision log doc exists" "docs/faz4r/support_escalation/decision_log_link.md"
  check_file "policy only route doc exists" "docs/faz4r/support_escalation/policy_only_issue_route.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.4.4 Pilot Issue Escalation"
  check_contains "doc P0 marker" "$DOC_FILE" "P0 blocker escalation"
  check_contains "doc owner matrix marker" "$DOC_FILE" "owner_matrix_status = READY"
  check_contains "doc SLA marker" "$DOC_FILE" "escalation_sla_status = READY"
  check_contains "doc decision log marker" "$DOC_FILE" "decision_log_status = READY"
  check_contains "doc no real dispatch marker" "$DOC_FILE" "no_real_external_dispatch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 213"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 212 marker" "$CONFIG_FILE" "212_FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"escalation_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config rule ready marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config owner matrix marker" "$CONFIG_FILE" "\"owner_matrix_status_required\": \"READY\""
  check_contains "config escalation SLA marker" "$CONFIG_FILE" "\"escalation_sla_status_required\": \"READY\""
  check_contains "config decision log marker" "$CONFIG_FILE" "\"decision_log_status_required\": \"READY\""
  check_contains "config no real dispatch marker" "$CONFIG_FILE" "\"no_real_external_dispatch_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "escalation status ready marker" "$ESCALATION_FILE" "\"escalation_status\": \"READY\""
  check_contains "escalation controlled pilot marker" "$ESCALATION_FILE" "\"escalation_mode\": \"CONTROLLED_PILOT\""
  check_contains "escalation P0 marker" "$ESCALATION_FILE" "ESCALATE_P0_BLOCKER"
  check_contains "escalation P1 marker" "$ESCALATION_FILE" "ESCALATE_P1_CRITICAL"
  check_contains "escalation product owner marker" "$ESCALATION_FILE" "PRODUCT_OWNER_ESCALATION"
  check_contains "escalation tech owner marker" "$ESCALATION_FILE" "TECH_OWNER_ESCALATION"
  check_contains "escalation support owner marker" "$ESCALATION_FILE" "SUPPORT_OWNER_ESCALATION"
  check_contains "escalation business owner marker" "$ESCALATION_FILE" "BUSINESS_OWNER_VISIBILITY"
  check_contains "escalation SLA marker" "$ESCALATION_FILE" "ESCALATION_SLA_MATRIX"
  check_contains "escalation evidence guard marker" "$ESCALATION_FILE" "EVIDENCE_COMPLETENESS_GUARD"
  check_contains "escalation decision log marker" "$ESCALATION_FILE" "DECISION_LOG_LINK"
  check_contains "escalation hotfix marker" "$ESCALATION_FILE" "HOTFIX_CANDIDATE_MARKER"
  check_contains "escalation policy route marker" "$ESCALATION_FILE" "POLICY_ONLY_ISSUE_ROUTE"
  check_contains "escalation no real dispatch marker" "$ESCALATION_FILE" "\"no_real_external_dispatch\": true"
  check_contains "escalation missing rule zero marker" "$ESCALATION_FILE" "\"missing_rule_count\": 0"
  check_contains "escalation closed policy marker" "$ESCALATION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime escalation guard marker" "$RUNTIME_SCRIPT" "ESCALATION_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "ESCALATION_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_ESCALATION_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime missing rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_ESCALATION_RULES_MISSING"
  check_contains "runtime duplicate rule guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_ESCALATION_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime owner matrix guard marker" "$RUNTIME_SCRIPT" "OWNER_MATRIX_STATUS_NOT_READY"
  check_contains "runtime escalation SLA guard marker" "$RUNTIME_SCRIPT" "ESCALATION_SLA_STATUS_NOT_READY"
  check_contains "runtime decision log guard marker" "$RUNTIME_SCRIPT" "DECISION_LOG_STATUS_NOT_READY"
  check_contains "runtime no real dispatch guard marker" "$RUNTIME_SCRIPT" "REAL_EXTERNAL_DISPATCH_NOT_DISABLED"
  check_contains "runtime real ticket closed marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_CLOSED"
  check_contains "runtime hotfix deploy closed marker" "$RUNTIME_SCRIPT" "HOTFIX_DEPLOY_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PILOT_ISSUE_ESCALATION_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PILOT_ISSUE_ESCALATION_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test escalation rules marker" "$TEST_FILE" "\"escalation_rules\""
  check_contains "test owner matrix marker" "$TEST_FILE" "\"owner_matrix\""
  check_contains "test controls marker" "$TEST_FILE" "\"escalation_controls\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 213 — FAZ 4-16.4.4 PILOT ISSUE ESCALATION COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_DOC_STATUS=READY"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_CONFIG_STATUS=READY"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_TEST_STATUS=PASS"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_FINAL_STATUS=PASS"
    echo "FAZ_4_16_4_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_TEST_STATUS=FAIL"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_4_4_PILOT_ISSUE_ESCALATION_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_4_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
