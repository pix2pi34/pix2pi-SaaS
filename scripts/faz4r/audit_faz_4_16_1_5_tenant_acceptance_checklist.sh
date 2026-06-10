#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST.md"
CONFIG_FILE="configs/faz4r/faz_4_16_1_5_tenant_acceptance_checklist.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_tenant_acceptance_checklist.sh"
TEST_FILE="tests/faz4r/faz_4_16_1_5_tenant_acceptance_checklist_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_REAL_IMPLEMENTATION_AUDIT.md"

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

run_fixture_tests() {
  local valid_file="/tmp/faz_4_16_1_5_valid_fixture_$$.json"
  local invalid_file="/tmp/faz_4_16_1_5_invalid_fixture_$$.json"
  local valid_out="/tmp/faz_4_16_1_5_valid_fixture_$$.out"
  local invalid_out="/tmp/faz_4_16_1_5_invalid_fixture_$$.out"

  python3 - "$TEST_FILE" "$valid_file" "$invalid_file" <<'PY_EOF'
import json
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
valid_file = Path(sys.argv[2])
invalid_file = Path(sys.argv[3])

payload = json.loads(test_file.read_text())
valid_file.write_text(json.dumps(payload["valid_fixture"], ensure_ascii=False, indent=2))
invalid_file.write_text(json.dumps(payload["invalid_fixture"], ensure_ascii=False, indent=2))
PY_EOF

  if CONFIG_FILE="$CONFIG_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TENANT_ACCEPTANCE_CHECKLIST_STATUS=PASS" "$valid_out"; then
      record_pass "valid tenant acceptance fixture PASS"
    else
      record_fail "valid tenant acceptance fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid tenant acceptance fixture execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid tenant acceptance fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "TENANT_ACCEPTANCE_CHECKLIST_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid tenant acceptance fixture FAIL guard"
    else
      record_fail "invalid tenant acceptance fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "ACCEPTANCE_FAIL=CRITICAL_ISSUE_COUNT_MUST_BE_ZERO" "$invalid_out"; then
    record_pass "critical issue zero acceptance guard"
  else
    record_fail "critical issue zero acceptance guard"
  fi

  if grep -Fq "ACCEPTANCE_FAIL=REQUIRED_CHECKLIST_ITEMS_MISSING" "$invalid_out"; then
    record_pass "required checklist missing guard"
  else
    record_fail "required checklist missing guard"
  fi

  if grep -Fq "ACCEPTANCE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider acceptance guard"
  else
    record_fail "closed external provider acceptance guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 193 — FAZ 4-16.1.5 TENANT ACCEPTANCE CHECKLIST REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.1.5 Tenant Acceptance Checklist"
  check_contains "doc required evidence marker" "$DOC_FILE" "Her required item için evidence_ref dolu olmalıdır."
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 193"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 192 marker" "$CONFIG_FILE" "192_FAZ_4_16_1_4_PILOT_VERI_SINIRLARI_TANIMI"
  check_contains "config all required marker" "$CONFIG_FILE" "\"all_required_items_must_pass\": true"
  check_contains "config evidence required marker" "$CONFIG_FILE" "\"required_evidence_ref\": true"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_must_be_zero\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""
  check_contains "config required item tenant marker" "$CONFIG_FILE" "TENANT_ID_ASSIGNED"
  check_contains "config required item readmodel marker" "$CONFIG_FILE" "READMODEL_REPORTING_READY"
  check_contains "config required item external policy marker" "$CONFIG_FILE" "CLOSED_EXTERNAL_POLICY_GATE"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "runtime input guard marker" "$RUNTIME_SCRIPT" "INPUT_FILE_REQUIRED"
  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime tenant id guard marker" "$RUNTIME_SCRIPT" "TENANT_ID_REQUIRED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_MUST_BE_ZERO"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime closed external policy marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "TENANT_ACCEPTANCE_CHECKLIST_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "TENANT_ACCEPTANCE_CHECKLIST_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test checklist marker" "$TEST_FILE" "\"checklist\""
  check_contains "test evidence ref marker" "$TEST_FILE" "\"evidence_ref\""

  run_fixture_tests

  echo "===== 193 — FAZ 4-16.1.5 TENANT ACCEPTANCE CHECKLIST COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_DOC_STATUS=READY"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_CONFIG_STATUS=READY"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_TEST_STATUS=PASS"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_FINAL_STATUS=PASS"
    echo "FAZ_4_16_1_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_TEST_STATUS=FAIL"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_1_5_TENANT_ACCEPTANCE_CHECKLIST_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_1_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
