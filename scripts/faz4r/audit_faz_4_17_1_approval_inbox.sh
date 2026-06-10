#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_1_APPROVAL_INBOX.md"
CONFIG_FILE="configs/faz4r/faz_4_17_1_approval_inbox.v1.json"
INBOX_FILE="configs/faz4r/approval_inbox.controlled_pilot.v1.json"
WEB_FILE="web/faz4r/approval-inbox/index.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_approval_inbox.sh"
TEST_FILE="tests/faz4r/faz_4_17_1_approval_inbox_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_1_APPROVAL_INBOX_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_17_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" INBOX_FILE="$INBOX_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$INBOX_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "APPROVAL_INBOX_STATUS=PASS" "$valid_out" && record_pass "main approval inbox artifact PASS" || { record_fail "main approval inbox artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main approval inbox artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" INBOX_FILE="$INBOX_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "APPROVAL_INBOX_STATUS=PASS" "$valid_out" && record_pass "valid approval inbox fixture PASS" || { record_fail "valid approval inbox fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid approval inbox fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "APPROVAL_INBOX_TOTAL_ITEM_COUNT=17" "$valid_out" && record_pass "valid approval inbox total item count" || record_fail "valid approval inbox total item count"
  grep -Fq "APPROVAL_INBOX_READY_ITEM_COUNT=17" "$valid_out" && record_pass "valid approval inbox ready item count" || record_fail "valid approval inbox ready item count"
  grep -Fq "TENANT_SCOPE=SINGLE_TENANT" "$valid_out" && record_pass "valid tenant scope guard" || record_fail "valid tenant scope guard"
  grep -Fq "ROLE_VISIBILITY_STATUS=READY" "$valid_out" && record_pass "valid role visibility guard" || record_fail "valid role visibility guard"
  grep -Fq "ACTION_STATE_STATUS=READY" "$valid_out" && record_pass "valid action state guard" || record_fail "valid action state guard"
  grep -Fq "WEB_CHECKPOINT_STATUS=READY" "$valid_out" && record_pass "valid web checkpoint guard" || record_fail "valid web checkpoint guard"
  grep -Fq "NO_WORKFLOW_MUTATION=true" "$valid_out" && record_pass "valid no workflow mutation guard" || record_fail "valid no workflow mutation guard"
  grep -Fq "NO_REAL_APPROVAL_EXECUTION=true" "$valid_out" && record_pass "valid no real approval execution guard" || record_fail "valid no real approval execution guard"
  grep -Fq "NO_REALTIME_SOCKET_CONNECTION=true" "$valid_out" && record_pass "valid no realtime socket guard" || record_fail "valid no realtime socket guard"

  if CONFIG_FILE="$CONFIG_FILE" INBOX_FILE="$INBOX_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid approval inbox fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "APPROVAL_INBOX_STATUS=FAIL" "$invalid_out" && record_pass "invalid approval inbox fixture FAIL guard" || { record_fail "invalid approval inbox fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "APPROVAL_INBOX_FAIL=APPROVAL_INBOX_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot inbox mode guard" || record_fail "controlled pilot inbox mode guard"
  grep -Fq "APPROVAL_INBOX_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "APPROVAL_INBOX_FAIL=CHAIN_DEPENDENCY_NOT_PASS:235_FAZ_4_16_8_5_PILOT_CLOSURE_REPORT" "$invalid_out" && record_pass "pilot closure dependency guard" || record_fail "pilot closure dependency guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REQUIRED_INBOX_ITEM_NOT_READY:APPROVAL_INBOX_SHELL" "$invalid_out" && record_pass "required inbox item ready guard" || record_fail "required inbox item ready guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REQUIRED_EVIDENCE_MISSING:APPROVAL_INBOX_SHELL" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REQUIRED_INBOX_ITEMS_MISSING" "$invalid_out" && record_pass "missing required inbox items guard" || record_fail "missing required inbox items guard"
  grep -Fq "APPROVAL_INBOX_FAIL=DUPLICATE_INBOX_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate inbox item guard" || record_fail "duplicate inbox item guard"
  grep -Fq "APPROVAL_INBOX_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "APPROVAL_INBOX_FAIL=ROLE_VISIBILITY_STATUS_NOT_READY" "$invalid_out" && record_pass "role visibility ready guard" || record_fail "role visibility ready guard"
  grep -Fq "APPROVAL_INBOX_FAIL=ACTION_STATE_STATUS_NOT_READY" "$invalid_out" && record_pass "action state ready guard" || record_fail "action state ready guard"
  grep -Fq "APPROVAL_INBOX_FAIL=WEB_CHECKPOINT_STATUS_NOT_READY" "$invalid_out" && record_pass "web checkpoint ready guard" || record_fail "web checkpoint ready guard"
  grep -Fq "APPROVAL_INBOX_FAIL=PILOT_CLOSURE_STATUS_NOT_PASS" "$invalid_out" && record_pass "pilot closure PASS guard" || record_fail "pilot closure PASS guard"
  grep -Fq "APPROVAL_INBOX_FAIL=WORKFLOW_MUTATION_NOT_DISABLED" "$invalid_out" && record_pass "workflow mutation disabled guard" || record_fail "workflow mutation disabled guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REAL_APPROVAL_EXECUTION_NOT_DISABLED" "$invalid_out" && record_pass "real approval execution disabled guard" || record_fail "real approval execution disabled guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REALTIME_SOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "realtime socket disabled guard" || record_fail "realtime socket disabled guard"
  grep -Fq "APPROVAL_INBOX_FAIL=ENABLED_ACTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "enabled action count zero guard" || record_fail "enabled action count zero guard"
  grep -Fq "APPROVAL_INBOX_FAIL=WORKFLOW_MUTATION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "workflow mutation count zero guard" || record_fail "workflow mutation count zero guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REAL_APPROVAL_EXECUTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real approval execution count zero guard" || record_fail "real approval execution count zero guard"
  grep -Fq "APPROVAL_INBOX_FAIL=REALTIME_SOCKET_CONNECTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "realtime socket count zero guard" || record_fail "realtime socket count zero guard"
  grep -Fq "APPROVAL_INBOX_FAIL=APPROVAL_SAMPLE_1_TENANT_MISMATCH" "$invalid_out" && record_pass "approval sample tenant guard" || record_fail "approval sample tenant guard"
  grep -Fq "APPROVAL_INBOX_FAIL=APPROVAL_SAMPLE_1_STATUS_NOT_PENDING" "$invalid_out" && record_pass "approval sample pending guard" || record_fail "approval sample pending guard"
  grep -Fq "APPROVAL_INBOX_FAIL=APPROVAL_SAMPLE_1_ACTION_NOT_DISABLED" "$invalid_out" && record_pass "approval sample action disabled guard" || record_fail "approval sample action disabled guard"
  grep -Fq "APPROVAL_INBOX_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 236 — FAZ 4-17.1 APPROVAL INBOX REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "approval inbox file exists" "$INBOX_FILE"
  check_file "web checkpoint file exists" "$WEB_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.1 Approval Inbox"
  check_contains "doc tenant scoped marker" "$DOC_FILE" "Tenant scoped inbox"
  check_contains "doc no mutation marker" "$DOC_FILE" "no_workflow_mutation = true"
  check_contains "doc no realtime marker" "$DOC_FILE" "no_realtime_socket_connection = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 236"
  check_contains "config dependency 235 marker" "$CONFIG_FILE" "235_FAZ_4_16_8_5_PILOT_CLOSURE_REPORT"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"approval_inbox_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config tenant scope marker" "$CONFIG_FILE" "\"tenant_scope_required\": \"SINGLE_TENANT\""
  check_contains "config no mutation marker" "$CONFIG_FILE" "\"no_workflow_mutation_required\": true"
  check_contains "config no approval execution marker" "$CONFIG_FILE" "\"no_real_approval_execution_required\": true"
  check_contains "config no socket marker" "$CONFIG_FILE" "\"no_realtime_socket_connection_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config next step marker" "$CONFIG_FILE" "237_FAZ_4_17_2_WORKFLOW_MONITOR"

  check_contains "inbox status ready marker" "$INBOX_FILE" "\"approval_inbox_status\": \"READY\""
  check_contains "inbox controlled pilot marker" "$INBOX_FILE" "\"approval_inbox_mode\": \"CONTROLLED_PILOT\""
  check_contains "inbox tenant scope marker" "$INBOX_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "inbox shell marker" "$INBOX_FILE" "APPROVAL_INBOX_SHELL"
  check_contains "pending approval list marker" "$INBOX_FILE" "PENDING_APPROVAL_LIST"
  check_contains "role visibility marker" "$INBOX_FILE" "ACTOR_ROLE_VISIBILITY"
  check_contains "action state marker" "$INBOX_FILE" "ACTION_BUTTON_STATE_MODEL"
  check_contains "no mutation marker" "$INBOX_FILE" "\"no_workflow_mutation\": true"
  check_contains "no approval execution marker" "$INBOX_FILE" "\"no_real_approval_execution\": true"
  check_contains "no realtime socket marker" "$INBOX_FILE" "\"no_realtime_socket_connection\": true"
  check_contains "inbox closed policy reference marker" "$INBOX_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "web checkpoint marker" "$WEB_FILE" "FAZ_4_17_1_APPROVAL_INBOX_UI_CHECKPOINT"
  check_contains "web title marker" "$WEB_FILE" "Approval Inbox"
  check_contains "web no mutation marker" "$WEB_FILE" "NO_WORKFLOW_MUTATION"
  check_contains "web no approval execution marker" "$WEB_FILE" "NO_REAL_APPROVAL_EXECUTION"
  check_contains "web no realtime marker" "$WEB_FILE" "NO_REALTIME_SOCKET_CONNECTION"
  check_contains "web approve disabled marker" "$WEB_FILE" "Approve disabled"
  check_contains "web reject disabled marker" "$WEB_FILE" "Reject disabled"
  check_contains "web empty state marker" "$WEB_FILE" "Empty state ready"
  check_contains "web error state marker" "$WEB_FILE" "Error state ready"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime inbox file guard marker" "$RUNTIME_SCRIPT" "INBOX_FILE_NOT_FOUND"
  check_contains "runtime web file guard marker" "$RUNTIME_SCRIPT" "WEB_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "APPROVAL_INBOX_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_INBOX_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_INBOX_ITEM_CODE_FOUND"
  check_contains "runtime mutation guard marker" "$RUNTIME_SCRIPT" "WORKFLOW_MUTATION_NOT_DISABLED"
  check_contains "runtime approval guard marker" "$RUNTIME_SCRIPT" "REAL_APPROVAL_EXECUTION_NOT_DISABLED"
  check_contains "runtime realtime guard marker" "$RUNTIME_SCRIPT" "REALTIME_SOCKET_CONNECTION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "APPROVAL_INBOX_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "APPROVAL_INBOX_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test inbox items marker" "$TEST_FILE" "\"inbox_items\""
  check_contains "test approval samples marker" "$TEST_FILE" "\"approval_samples\""
  check_contains "test inbox controls marker" "$TEST_FILE" "\"inbox_controls\""
  check_contains "test inbox metrics marker" "$TEST_FILE" "\"inbox_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 236 — FAZ 4-17.1 APPROVAL INBOX COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_1_APPROVAL_INBOX_DOC_STATUS=READY"
    echo "FAZ_4_17_1_APPROVAL_INBOX_CONFIG_STATUS=READY"
    echo "FAZ_4_17_1_APPROVAL_INBOX_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_1_APPROVAL_INBOX_WEB_STATUS=READY"
    echo "FAZ_4_17_1_APPROVAL_INBOX_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_1_APPROVAL_INBOX_TEST_STATUS=PASS"
    echo "FAZ_4_17_1_APPROVAL_INBOX_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_1_APPROVAL_INBOX_FINAL_STATUS=PASS"
    echo "FAZ_4_17_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_1_APPROVAL_INBOX_TEST_STATUS=FAIL"
    echo "FAZ_4_17_1_APPROVAL_INBOX_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_1_APPROVAL_INBOX_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
