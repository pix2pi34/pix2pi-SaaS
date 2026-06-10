#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_6_5_FEEDBACK_CLOSURE.md"
CONFIG_FILE="configs/faz4r/faz_4_16_6_5_feedback_closure.v1.json"
CLOSURE_FILE="configs/faz4r/feedback_closure.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_feedback_closure.sh"
TEST_FILE="tests/faz4r/faz_4_16_6_5_feedback_closure_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_6_5_FEEDBACK_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_6_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_6_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_6_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_6_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$CLOSURE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "FEEDBACK_CLOSURE_STATUS=PASS" "$valid_out" && record_pass "main feedback closure artifact PASS" || { record_fail "main feedback closure artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main feedback closure artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "FEEDBACK_CLOSURE_STATUS=PASS" "$valid_out" && record_pass "valid feedback closure fixture PASS" || { record_fail "valid feedback closure fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid feedback closure fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "FEEDBACK_CLOSURE_TOTAL_RULE_COUNT=15" "$valid_out" && record_pass "valid feedback closure total rule count" || record_fail "valid feedback closure total rule count"
  grep -Fq "FEEDBACK_CLOSURE_READY_RULE_COUNT=15" "$valid_out" && record_pass "valid feedback closure ready rule count" || record_fail "valid feedback closure ready rule count"
  grep -Fq "FEEDBACK_CLOSURE_MISSING_RULE_COUNT=0" "$valid_out" && record_pass "valid feedback closure missing rule zero" || record_fail "valid feedback closure missing rule zero"
  grep -Fq "NO_AUTO_DELETE_FEEDBACK=true" "$valid_out" && record_pass "valid no auto delete feedback guard" || record_fail "valid no auto delete feedback guard"
  grep -Fq "NO_REAL_EMAIL_DISPATCH=true" "$valid_out" && record_pass "valid no real email dispatch guard" || record_fail "valid no real email dispatch guard"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid feedback closure fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "FEEDBACK_CLOSURE_STATUS=FAIL" "$invalid_out" && record_pass "invalid feedback closure fixture FAIL guard" || { record_fail "invalid feedback closure fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "FEEDBACK_CLOSURE_FAIL=FEEDBACK_CLOSURE_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot closure mode guard" || record_fail "controlled pilot closure mode guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:224_FAZ_4_16_6_4_URUN_KARAR_DEFTERI" "$invalid_out" && record_pass "product decision dependency guard" || record_fail "product decision dependency guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REQUIRED_CLOSURE_RULE_NOT_READY:FEEDBACK_CLOSURE_INTAKE" "$invalid_out" && record_pass "required closure rule ready guard" || record_fail "required closure rule ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REQUIRED_EVIDENCE_MISSING:FEEDBACK_CLOSURE_INTAKE" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REQUIRED_CLOSURE_RULES_MISSING" "$invalid_out" && record_pass "missing required closure rules guard" || record_fail "missing required closure rules guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=DUPLICATE_CLOSURE_RULE_CODE_FOUND" "$invalid_out" && record_pass "duplicate closure rule guard" || record_fail "duplicate closure rule guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total rule count reconciliation guard" || record_fail "total rule count reconciliation guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing rule zero guard" || record_fail "missing rule zero guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=CLOSURE_OUTCOME_TAXONOMY_STATUS_NOT_READY" "$invalid_out" && record_pass "closure taxonomy ready guard" || record_fail "closure taxonomy ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=OWNER_CONFIRMATION_STATUS_NOT_READY" "$invalid_out" && record_pass "owner confirmation ready guard" || record_fail "owner confirmation ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=EVIDENCE_COMPLETION_STATUS_NOT_READY" "$invalid_out" && record_pass "evidence completion ready guard" || record_fail "evidence completion ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=USER_COMMUNICATION_NOTE_STATUS_NOT_READY" "$invalid_out" && record_pass "user communication note ready guard" || record_fail "user communication note ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REOPEN_GUARD_STATUS_NOT_READY" "$invalid_out" && record_pass "reopen guard ready guard" || record_fail "reopen guard ready guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=AUTO_DELETE_FEEDBACK_NOT_DISABLED" "$invalid_out" && record_pass "auto delete feedback disabled guard" || record_fail "auto delete feedback disabled guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=AUTO_APPLY_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "auto apply change disabled guard" || record_fail "auto apply change disabled guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REAL_CRM_SYSTEM_NOT_DISABLED" "$invalid_out" && record_pass "real CRM system disabled guard" || record_fail "real CRM system disabled guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REAL_TICKET_SYSTEM_NOT_DISABLED" "$invalid_out" && record_pass "real ticket system disabled guard" || record_fail "real ticket system disabled guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REAL_EMAIL_DISPATCH_NOT_DISABLED" "$invalid_out" && record_pass "real email dispatch disabled guard" || record_fail "real email dispatch disabled guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=AUTO_DELETE_FEEDBACK_COUNT_NOT_ZERO" "$invalid_out" && record_pass "auto delete feedback count zero guard" || record_fail "auto delete feedback count zero guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real email dispatch count zero guard" || record_fail "real email dispatch count zero guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"
  grep -Fq "FEEDBACK_CLOSURE_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out" && record_pass "production launch closed guard" || record_fail "production launch closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 225 — FAZ 4-16.6.5 FEEDBACK CLOSURE REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "feedback closure file exists" "$CLOSURE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "closure intake doc exists" "docs/faz4r/feedback_closure/feedback_closure_intake.md"
  check_file "closure outcome taxonomy doc exists" "docs/faz4r/feedback_closure/closure_outcome_taxonomy.md"
  check_file "owner confirmation doc exists" "docs/faz4r/feedback_closure/owner_confirmation.md"
  check_file "reopen guard doc exists" "docs/faz4r/feedback_closure/reopen_guard.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.6.5 Feedback Closure"
  check_contains "doc closure intake marker" "$DOC_FILE" "Feedback closure intake"
  check_contains "doc no auto delete marker" "$DOC_FILE" "no_auto_delete_feedback = true"
  check_contains "doc no email marker" "$DOC_FILE" "no_real_email_dispatch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 225"
  check_contains "config dependency 224 marker" "$CONFIG_FILE" "224_FAZ_4_16_6_4_URUN_KARAR_DEFTERI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"feedback_closure_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config closure taxonomy ready marker" "$CONFIG_FILE" "\"closure_outcome_taxonomy_status_required\": \"READY\""
  check_contains "config no auto delete marker" "$CONFIG_FILE" "\"no_auto_delete_feedback_required\": true"
  check_contains "config no real email marker" "$CONFIG_FILE" "\"no_real_email_dispatch_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "closure status ready marker" "$CLOSURE_FILE" "\"feedback_closure_status\": \"READY\""
  check_contains "closure controlled pilot marker" "$CLOSURE_FILE" "\"feedback_closure_mode\": \"CONTROLLED_PILOT\""
  check_contains "closure intake marker" "$CLOSURE_FILE" "FEEDBACK_CLOSURE_INTAKE"
  check_contains "closure taxonomy marker" "$CLOSURE_FILE" "CLOSURE_OUTCOME_TAXONOMY"
  check_contains "closure product decision marker" "$CLOSURE_FILE" "PRODUCT_DECISION_LINK"
  check_contains "closure quick fix marker" "$CLOSURE_FILE" "QUICK_FIX_LINK"
  check_contains "closure reopen marker" "$CLOSURE_FILE" "REOPEN_GUARD"
  check_contains "closure no auto delete marker" "$CLOSURE_FILE" "\"no_auto_delete_feedback\": true"
  check_contains "closure no email marker" "$CLOSURE_FILE" "\"no_real_email_dispatch\": true"
  check_contains "closure closed policy reference marker" "$CLOSURE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime closure file guard marker" "$RUNTIME_SCRIPT" "CLOSURE_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "FEEDBACK_CLOSURE_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_CLOSURE_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_CLOSURE_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime closure taxonomy guard marker" "$RUNTIME_SCRIPT" "CLOSURE_OUTCOME_TAXONOMY_STATUS_NOT_READY"
  check_contains "runtime no auto delete guard marker" "$RUNTIME_SCRIPT" "AUTO_DELETE_FEEDBACK_NOT_DISABLED"
  check_contains "runtime email disabled guard marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "FEEDBACK_CLOSURE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "FEEDBACK_CLOSURE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test closure rules marker" "$TEST_FILE" "\"closure_rules\""
  check_contains "test closure controls marker" "$TEST_FILE" "\"closure_controls\""
  check_contains "test closure metrics marker" "$TEST_FILE" "\"closure_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 225 — FAZ 4-16.6.5 FEEDBACK CLOSURE COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_DOC_STATUS=READY"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_CONFIG_STATUS=READY"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_TEST_STATUS=PASS"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_FINAL_STATUS=PASS"
    echo "FAZ_4_16_7_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_TEST_STATUS=FAIL"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_6_5_FEEDBACK_CLOSURE_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_7_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
