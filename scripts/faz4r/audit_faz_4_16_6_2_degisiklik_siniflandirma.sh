#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA.md"
CONFIG_FILE="configs/faz4r/faz_4_16_6_2_degisiklik_siniflandirma.v1.json"
CHANGE_FILE="configs/faz4r/change_classification.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_change_classification.sh"
TEST_FILE="tests/faz4r/faz_4_16_6_2_degisiklik_siniflandirma_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_6_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_6_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_6_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_6_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CHANGE_FILE="$CHANGE_FILE" INPUT_FILE="$CHANGE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "CHANGE_CLASSIFICATION_STATUS=PASS" "$valid_out"; then
      record_pass "main change classification artifact PASS"
    else
      record_fail "main change classification artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main change classification artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" CHANGE_FILE="$CHANGE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "CHANGE_CLASSIFICATION_STATUS=PASS" "$valid_out"; then
      record_pass "valid change classification fixture PASS"
    else
      record_fail "valid change classification fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid change classification fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_TOTAL_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid classification total rule count"
  else
    record_fail "valid classification total rule count"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_READY_RULE_COUNT=15" "$valid_out"; then
    record_pass "valid classification ready rule count"
  else
    record_fail "valid classification ready rule count"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_MISSING_RULE_COUNT=0" "$valid_out"; then
    record_pass "valid classification missing rule zero"
  else
    record_fail "valid classification missing rule zero"
  fi

  if grep -Fq "NO_AUTO_APPLY_CHANGE=true" "$valid_out"; then
    record_pass "valid no auto apply change guard"
  else
    record_fail "valid no auto apply change guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" CHANGE_FILE="$CHANGE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid change classification fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "CHANGE_CLASSIFICATION_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid change classification fixture FAIL guard"
    else
      record_fail "invalid change classification fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=CLASSIFICATION_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot classification mode guard"
  else
    record_fail "controlled pilot classification mode guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=CHAIN_DEPENDENCY_NOT_PASS:221_FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI" "$invalid_out"; then
    record_pass "feedback channel dependency guard"
  else
    record_fail "feedback channel dependency guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REQUIRED_CLASSIFICATION_RULE_NOT_READY:FEEDBACK_INTAKE_CLASSIFICATION" "$invalid_out"; then
    record_pass "required classification rule ready guard"
  else
    record_fail "required classification rule ready guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REQUIRED_EVIDENCE_MISSING:FEEDBACK_INTAKE_CLASSIFICATION" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REQUIRED_CLASSIFICATION_RULES_MISSING" "$invalid_out"; then
    record_pass "missing required classification rules guard"
  else
    record_fail "missing required classification rules guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=DUPLICATE_CLASSIFICATION_RULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate classification rule guard"
  else
    record_fail "duplicate classification rule guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total rule count reconciliation guard"
  else
    record_fail "total rule count reconciliation guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing rule zero guard"
  else
    record_fail "missing rule zero guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=PRIORITY_MAPPING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "priority mapping ready guard"
  else
    record_fail "priority mapping ready guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=SEVERITY_MAPPING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "severity mapping ready guard"
  else
    record_fail "severity mapping ready guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=OWNER_ROUTING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "owner routing ready guard"
  else
    record_fail "owner routing ready guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=AUTO_APPLY_CHANGE_NOT_DISABLED" "$invalid_out"; then
    record_pass "auto apply change disabled guard"
  else
    record_fail "auto apply change disabled guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=HOTFIX_DEPLOY_NOT_DISABLED" "$invalid_out"; then
    record_pass "hotfix deploy disabled guard"
  else
    record_fail "hotfix deploy disabled guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REAL_CRM_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real CRM system disabled guard"
  else
    record_fail "real CRM system disabled guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REAL_TICKET_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real ticket system disabled guard"
  else
    record_fail "real ticket system disabled guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=AUTO_APPLY_CHANGE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "auto apply change count zero guard"
  else
    record_fail "auto apply change count zero guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=HOTFIX_DEPLOY_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "hotfix deploy count zero guard"
  else
    record_fail "hotfix deploy count zero guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=REAL_CRM_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real CRM system closed guard"
  else
    record_fail "real CRM system closed guard"
  fi

  if grep -Fq "CHANGE_CLASSIFICATION_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "live external provider closed guard"
  else
    record_fail "live external provider closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 222 — FAZ 4-16.6.2 DEGISIKLIK SINIFLANDIRMA REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "change classification file exists" "$CHANGE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "feedback intake classification doc exists" "docs/faz4r/change_classification/feedback_intake_classification.md"
  check_file "priority mapping doc exists" "docs/faz4r/change_classification/priority_mapping.md"
  check_file "quick fix candidate doc exists" "docs/faz4r/change_classification/quick_fix_candidate_marker.md"
  check_file "out of scope marker doc exists" "docs/faz4r/change_classification/rejection_out_of_scope_marker.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.6.2 Değişiklik Sınıflandırma"
  check_contains "doc feedback intake marker" "$DOC_FILE" "Feedback intake classification"
  check_contains "doc no auto apply marker" "$DOC_FILE" "no_auto_apply_change = true"
  check_contains "doc no hotfix marker" "$DOC_FILE" "no_hotfix_deploy = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 222"
  check_contains "config dependency 221 marker" "$CONFIG_FILE" "221_FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"classification_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config priority mapping marker" "$CONFIG_FILE" "\"priority_mapping_status_required\": \"READY\""
  check_contains "config no auto apply marker" "$CONFIG_FILE" "\"no_auto_apply_change_required\": true"
  check_contains "config no hotfix marker" "$CONFIG_FILE" "\"no_hotfix_deploy_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "classification status ready marker" "$CHANGE_FILE" "\"classification_status\": \"READY\""
  check_contains "classification controlled pilot marker" "$CHANGE_FILE" "\"classification_mode\": \"CONTROLLED_PILOT\""
  check_contains "classification feedback intake marker" "$CHANGE_FILE" "FEEDBACK_INTAKE_CLASSIFICATION"
  check_contains "classification bug marker" "$CHANGE_FILE" "BUG_DEFECT_CLASSIFICATION"
  check_contains "classification UX marker" "$CHANGE_FILE" "UX_IMPROVEMENT_CLASSIFICATION"
  check_contains "classification training marker" "$CHANGE_FILE" "TRAINING_GAP_CLASSIFICATION"
  check_contains "classification priority marker" "$CHANGE_FILE" "PRIORITY_MAPPING"
  check_contains "classification severity marker" "$CHANGE_FILE" "SEVERITY_MAPPING"
  check_contains "classification owner routing marker" "$CHANGE_FILE" "OWNER_ROUTING"
  check_contains "classification quick fix marker" "$CHANGE_FILE" "QUICK_FIX_CANDIDATE_MARKER"
  check_contains "classification product decision marker" "$CHANGE_FILE" "PRODUCT_DECISION_CANDIDATE_MARKER"
  check_contains "classification no auto apply marker" "$CHANGE_FILE" "\"no_auto_apply_change\": true"
  check_contains "classification closed policy reference marker" "$CHANGE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime change file guard marker" "$RUNTIME_SCRIPT" "CHANGE_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "CLASSIFICATION_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_CLASSIFICATION_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_CLASSIFICATION_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime priority guard marker" "$RUNTIME_SCRIPT" "PRIORITY_MAPPING_STATUS_NOT_READY"
  check_contains "runtime no auto apply guard marker" "$RUNTIME_SCRIPT" "AUTO_APPLY_CHANGE_NOT_DISABLED"
  check_contains "runtime no hotfix guard marker" "$RUNTIME_SCRIPT" "HOTFIX_DEPLOY_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "CHANGE_CLASSIFICATION_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "CHANGE_CLASSIFICATION_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test classification rules marker" "$TEST_FILE" "\"classification_rules\""
  check_contains "test classification controls marker" "$TEST_FILE" "\"classification_controls\""
  check_contains "test classification metrics marker" "$TEST_FILE" "\"classification_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 222 — FAZ 4-16.6.2 DEGISIKLIK SINIFLANDIRMA COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_DOC_STATUS=READY"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_CONFIG_STATUS=READY"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_TEST_STATUS=PASS"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_FINAL_STATUS=PASS"
    echo "FAZ_4_16_6_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_TEST_STATUS=FAIL"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_6_2_DEGISIKLIK_SINIFLANDIRMA_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_6_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
