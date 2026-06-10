#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_2_WORKFLOW_MONITOR.md"
CONFIG_FILE="configs/faz4r/faz_4_17_2_workflow_monitor.v1.json"
MONITOR_FILE="configs/faz4r/workflow_monitor.controlled_pilot.v1.json"
WEB_FILE="web/faz4r/workflow-monitor/index.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_workflow_monitor.sh"
TEST_FILE="tests/faz4r/faz_4_17_2_workflow_monitor_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_2_WORKFLOW_MONITOR_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_17_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" MONITOR_FILE="$MONITOR_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$MONITOR_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "WORKFLOW_MONITOR_STATUS=PASS" "$valid_out" && record_pass "main workflow monitor artifact PASS" || { record_fail "main workflow monitor artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main workflow monitor artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" MONITOR_FILE="$MONITOR_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "WORKFLOW_MONITOR_STATUS=PASS" "$valid_out" && record_pass "valid workflow monitor fixture PASS" || { record_fail "valid workflow monitor fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid workflow monitor fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "WORKFLOW_MONITOR_TOTAL_ITEM_COUNT=20" "$valid_out" && record_pass "valid workflow monitor total item count" || record_fail "valid workflow monitor total item count"
  grep -Fq "WORKFLOW_MONITOR_READY_ITEM_COUNT=20" "$valid_out" && record_pass "valid workflow monitor ready item count" || record_fail "valid workflow monitor ready item count"
  grep -Fq "TENANT_SCOPE=SINGLE_TENANT" "$valid_out" && record_pass "valid tenant scope guard" || record_fail "valid tenant scope guard"
  grep -Fq "APPROVAL_INBOX_STATUS=PASS" "$valid_out" && record_pass "valid approval inbox dependency guard" || record_fail "valid approval inbox dependency guard"
  grep -Fq "WORKFLOW_SUMMARY_STATUS=READY" "$valid_out" && record_pass "valid workflow summary guard" || record_fail "valid workflow summary guard"
  grep -Fq "STATUS_COUNTER_STATUS=READY" "$valid_out" && record_pass "valid status counter guard" || record_fail "valid status counter guard"
  grep -Fq "SLA_INDICATOR_STATUS=READY" "$valid_out" && record_pass "valid SLA indicator guard" || record_fail "valid SLA indicator guard"
  grep -Fq "FAILED_WORKFLOW_COUNT=0" "$valid_out" && record_pass "valid failed workflow zero guard" || record_fail "valid failed workflow zero guard"
  grep -Fq "SLA_BREACHED_COUNT=0" "$valid_out" && record_pass "valid SLA breached zero guard" || record_fail "valid SLA breached zero guard"
  grep -Fq "NO_WORKFLOW_MUTATION=true" "$valid_out" && record_pass "valid no workflow mutation guard" || record_fail "valid no workflow mutation guard"
  grep -Fq "NO_REAL_WORKFLOW_EXECUTION=true" "$valid_out" && record_pass "valid no real workflow execution guard" || record_fail "valid no real workflow execution guard"
  grep -Fq "NO_REALTIME_SOCKET_CONNECTION=true" "$valid_out" && record_pass "valid no realtime socket guard" || record_fail "valid no realtime socket guard"

  if CONFIG_FILE="$CONFIG_FILE" MONITOR_FILE="$MONITOR_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid workflow monitor fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "WORKFLOW_MONITOR_STATUS=FAIL" "$invalid_out" && record_pass "invalid workflow monitor fixture FAIL guard" || { record_fail "invalid workflow monitor fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_MONITOR_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot monitor mode guard" || record_fail "controlled pilot monitor mode guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=CHAIN_DEPENDENCY_NOT_PASS:236_FAZ_4_17_1_APPROVAL_INBOX" "$invalid_out" && record_pass "approval inbox dependency guard" || record_fail "approval inbox dependency guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REQUIRED_MONITOR_ITEM_NOT_READY:WORKFLOW_MONITOR_SHELL" "$invalid_out" && record_pass "required monitor item ready guard" || record_fail "required monitor item ready guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REQUIRED_EVIDENCE_MISSING:WORKFLOW_MONITOR_SHELL" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REQUIRED_MONITOR_ITEMS_MISSING" "$invalid_out" && record_pass "missing required monitor items guard" || record_fail "missing required monitor items guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=DUPLICATE_MONITOR_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate monitor item guard" || record_fail "duplicate monitor item guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=APPROVAL_INBOX_STATUS_NOT_PASS" "$invalid_out" && record_pass "approval inbox PASS guard" || record_fail "approval inbox PASS guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_SUMMARY_STATUS_NOT_READY" "$invalid_out" && record_pass "workflow summary ready guard" || record_fail "workflow summary ready guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=STATUS_COUNTER_STATUS_NOT_READY" "$invalid_out" && record_pass "status counter ready guard" || record_fail "status counter ready guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=SLA_INDICATOR_STATUS_NOT_READY" "$invalid_out" && record_pass "SLA indicator ready guard" || record_fail "SLA indicator ready guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_MUTATION_NOT_DISABLED" "$invalid_out" && record_pass "workflow mutation disabled guard" || record_fail "workflow mutation disabled guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REAL_WORKFLOW_EXECUTION_NOT_DISABLED" "$invalid_out" && record_pass "real workflow execution disabled guard" || record_fail "real workflow execution disabled guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REALTIME_SOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "realtime socket disabled guard" || record_fail "realtime socket disabled guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=ENABLED_ACTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "enabled action count zero guard" || record_fail "enabled action count zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_MUTATION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "workflow mutation count zero guard" || record_fail "workflow mutation count zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REAL_WORKFLOW_EXECUTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real workflow execution count zero guard" || record_fail "real workflow execution count zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=REALTIME_SOCKET_CONNECTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "realtime socket count zero guard" || record_fail "realtime socket count zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=TOTAL_WORKFLOW_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "workflow count reconciliation guard" || record_fail "workflow count reconciliation guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=FAILED_WORKFLOW_COUNT_NOT_ZERO" "$invalid_out" && record_pass "failed workflow zero guard" || record_fail "failed workflow zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=SLA_BREACHED_COUNT_NOT_ZERO" "$invalid_out" && record_pass "SLA breached zero guard" || record_fail "SLA breached zero guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_SAMPLE_1_TENANT_MISMATCH" "$invalid_out" && record_pass "workflow sample tenant guard" || record_fail "workflow sample tenant guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_SAMPLE_1_STATUS_INVALID" "$invalid_out" && record_pass "workflow sample status guard" || record_fail "workflow sample status guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_SAMPLE_1_ACTION_NOT_READ_ONLY" "$invalid_out" && record_pass "workflow sample action read-only guard" || record_fail "workflow sample action read-only guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=WORKFLOW_SAMPLE_1_SLA_NOT_ON_TRACK" "$invalid_out" && record_pass "workflow sample SLA guard" || record_fail "workflow sample SLA guard"
  grep -Fq "WORKFLOW_MONITOR_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 237 — FAZ 4-17.2 WORKFLOW MONITOR REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "workflow monitor file exists" "$MONITOR_FILE"
  check_file "web checkpoint file exists" "$WEB_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.2 Workflow Monitor"
  check_contains "doc tenant scoped marker" "$DOC_FILE" "Tenant scoped monitor"
  check_contains "doc no mutation marker" "$DOC_FILE" "no_workflow_mutation = true"
  check_contains "doc no realtime marker" "$DOC_FILE" "no_realtime_socket_connection = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 237"
  check_contains "config dependency 236 marker" "$CONFIG_FILE" "236_FAZ_4_17_1_APPROVAL_INBOX"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"workflow_monitor_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config tenant scope marker" "$CONFIG_FILE" "\"tenant_scope_required\": \"SINGLE_TENANT\""
  check_contains "config no mutation marker" "$CONFIG_FILE" "\"no_workflow_mutation_required\": true"
  check_contains "config no workflow execution marker" "$CONFIG_FILE" "\"no_real_workflow_execution_required\": true"
  check_contains "config no socket marker" "$CONFIG_FILE" "\"no_realtime_socket_connection_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config next step marker" "$CONFIG_FILE" "238_FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU"

  check_contains "monitor status ready marker" "$MONITOR_FILE" "\"workflow_monitor_status\": \"READY\""
  check_contains "monitor controlled pilot marker" "$MONITOR_FILE" "\"workflow_monitor_mode\": \"CONTROLLED_PILOT\""
  check_contains "monitor tenant scope marker" "$MONITOR_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "monitor shell marker" "$MONITOR_FILE" "WORKFLOW_MONITOR_SHELL"
  check_contains "workflow instance summary marker" "$MONITOR_FILE" "WORKFLOW_INSTANCE_SUMMARY"
  check_contains "pending approval counter marker" "$MONITOR_FILE" "PENDING_APPROVAL_COUNTER"
  check_contains "running workflow counter marker" "$MONITOR_FILE" "RUNNING_WORKFLOW_COUNTER"
  check_contains "failed workflow counter marker" "$MONITOR_FILE" "FAILED_WORKFLOW_COUNTER"
  check_contains "SLA indicator marker" "$MONITOR_FILE" "SLA_AGE_INDICATOR"
  check_contains "approval inbox link marker" "$MONITOR_FILE" "APPROVAL_INBOX_LINK"
  check_contains "no mutation marker" "$MONITOR_FILE" "\"no_workflow_mutation\": true"
  check_contains "no workflow execution marker" "$MONITOR_FILE" "\"no_real_workflow_execution\": true"
  check_contains "no realtime socket marker" "$MONITOR_FILE" "\"no_realtime_socket_connection\": true"
  check_contains "monitor closed policy reference marker" "$MONITOR_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "web checkpoint marker" "$WEB_FILE" "FAZ_4_17_2_WORKFLOW_MONITOR_UI_CHECKPOINT"
  check_contains "web title marker" "$WEB_FILE" "Workflow Monitor"
  check_contains "web no mutation marker" "$WEB_FILE" "NO_WORKFLOW_MUTATION"
  check_contains "web no workflow execution marker" "$WEB_FILE" "NO_REAL_WORKFLOW_EXECUTION"
  check_contains "web no realtime marker" "$WEB_FILE" "NO_REALTIME_SOCKET_CONNECTION"
  check_contains "web monitor only marker" "$WEB_FILE" "Monitor only"
  check_contains "web retry disabled marker" "$WEB_FILE" "Retry disabled"
  check_contains "web cancel disabled marker" "$WEB_FILE" "Cancel disabled"
  check_contains "web empty state marker" "$WEB_FILE" "Empty state ready"
  check_contains "web error state marker" "$WEB_FILE" "Error state ready"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime monitor file guard marker" "$RUNTIME_SCRIPT" "MONITOR_FILE_NOT_FOUND"
  check_contains "runtime web file guard marker" "$RUNTIME_SCRIPT" "WEB_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "WORKFLOW_MONITOR_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_MONITOR_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_MONITOR_ITEM_CODE_FOUND"
  check_contains "runtime mutation guard marker" "$RUNTIME_SCRIPT" "WORKFLOW_MUTATION_NOT_DISABLED"
  check_contains "runtime workflow execution guard marker" "$RUNTIME_SCRIPT" "REAL_WORKFLOW_EXECUTION_NOT_DISABLED"
  check_contains "runtime realtime guard marker" "$RUNTIME_SCRIPT" "REALTIME_SOCKET_CONNECTION_NOT_DISABLED"
  check_contains "runtime failed workflow guard marker" "$RUNTIME_SCRIPT" "FAILED_WORKFLOW_COUNT_NOT_ZERO"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "WORKFLOW_MONITOR_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "WORKFLOW_MONITOR_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test monitor items marker" "$TEST_FILE" "\"monitor_items\""
  check_contains "test workflow samples marker" "$TEST_FILE" "\"workflow_samples\""
  check_contains "test workflow counters marker" "$TEST_FILE" "\"workflow_counters\""
  check_contains "test monitor controls marker" "$TEST_FILE" "\"monitor_controls\""
  check_contains "test monitor metrics marker" "$TEST_FILE" "\"monitor_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 237 — FAZ 4-17.2 WORKFLOW MONITOR COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_DOC_STATUS=READY"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_CONFIG_STATUS=READY"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_WEB_STATUS=READY"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_TEST_STATUS=PASS"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_FINAL_STATUS=PASS"
    echo "FAZ_4_17_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_TEST_STATUS=FAIL"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_2_WORKFLOW_MONITOR_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
