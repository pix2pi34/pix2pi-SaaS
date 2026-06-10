#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI.md"
CONFIG_FILE="configs/faz4r/faz_4_17_6_workflow_realtime_ui_testleri.v1.json"
UI_TEST_FILE="configs/faz4r/workflow_realtime_ui_tests.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_workflow_realtime_ui_tests.sh"
TEST_FILE="tests/faz4r/faz_4_17_6_workflow_realtime_ui_testleri_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"
APPROVAL_WEB="web/faz4r/approval-inbox/index.html"
MONITOR_WEB="web/faz4r/workflow-monitor/index.html"
REALTIME_WEB="web/faz4r/realtime-health/index.html"

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
  local valid_file="/tmp/faz_4_17_6_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_6_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_6_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_6_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" UI_TEST_FILE="$UI_TEST_FILE" APPROVAL_WEB="$APPROVAL_WEB" MONITOR_WEB="$MONITOR_WEB" REALTIME_WEB="$REALTIME_WEB" INPUT_FILE="$UI_TEST_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "WORKFLOW_REALTIME_UI_TEST_STATUS=PASS" "$valid_out" && record_pass "main workflow realtime UI test artifact PASS" || { record_fail "main workflow realtime UI test artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main workflow realtime UI test artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" UI_TEST_FILE="$UI_TEST_FILE" APPROVAL_WEB="$APPROVAL_WEB" MONITOR_WEB="$MONITOR_WEB" REALTIME_WEB="$REALTIME_WEB" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "WORKFLOW_REALTIME_UI_TEST_STATUS=PASS" "$valid_out" && record_pass "valid workflow realtime UI test fixture PASS" || { record_fail "valid workflow realtime UI test fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid workflow realtime UI test fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "WORKFLOW_REALTIME_UI_TEST_TOTAL_ITEM_COUNT=16" "$valid_out" && record_pass "valid UI test total item count" || record_fail "valid UI test total item count"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_READY_ITEM_COUNT=16" "$valid_out" && record_pass "valid UI test ready item count" || record_fail "valid UI test ready item count"
  grep -Fq "APPROVAL_INBOX_STATUS=PASS" "$valid_out" && record_pass "valid approval inbox PASS guard" || record_fail "valid approval inbox PASS guard"
  grep -Fq "WORKFLOW_MONITOR_STATUS=PASS" "$valid_out" && record_pass "valid workflow monitor PASS guard" || record_fail "valid workflow monitor PASS guard"
  grep -Fq "REALTIME_HEALTH_STATUS=PASS" "$valid_out" && record_pass "valid realtime health PASS guard" || record_fail "valid realtime health PASS guard"
  grep -Fq "APPROVAL_WEB_CHECKPOINT_STATUS=PASS" "$valid_out" && record_pass "valid approval web checkpoint guard" || record_fail "valid approval web checkpoint guard"
  grep -Fq "WORKFLOW_WEB_CHECKPOINT_STATUS=PASS" "$valid_out" && record_pass "valid workflow web checkpoint guard" || record_fail "valid workflow web checkpoint guard"
  grep -Fq "REALTIME_WEB_CHECKPOINT_STATUS=PASS" "$valid_out" && record_pass "valid realtime web checkpoint guard" || record_fail "valid realtime web checkpoint guard"
  grep -Fq "NO_WORKFLOW_MUTATION=true" "$valid_out" && record_pass "valid no workflow mutation guard" || record_fail "valid no workflow mutation guard"
  grep -Fq "NO_REAL_APPROVAL_EXECUTION=true" "$valid_out" && record_pass "valid no real approval execution guard" || record_fail "valid no real approval execution guard"
  grep -Fq "NO_REAL_WORKFLOW_EXECUTION=true" "$valid_out" && record_pass "valid no real workflow execution guard" || record_fail "valid no real workflow execution guard"
  grep -Fq "NO_LIVE_WEBSOCKET_CONNECTION=true" "$valid_out" && record_pass "valid no live websocket guard" || record_fail "valid no live websocket guard"
  grep -Fq "NO_LIVE_SSE_CONNECTION=true" "$valid_out" && record_pass "valid no live SSE guard" || record_fail "valid no live SSE guard"
  grep -Fq "NO_EVENT_STREAM_PUBLISH=true" "$valid_out" && record_pass "valid no event stream publish guard" || record_fail "valid no event stream publish guard"

  if CONFIG_FILE="$CONFIG_FILE" UI_TEST_FILE="$UI_TEST_FILE" APPROVAL_WEB="$APPROVAL_WEB" MONITOR_WEB="$MONITOR_WEB" REALTIME_WEB="$REALTIME_WEB" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid workflow realtime UI test fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "WORKFLOW_REALTIME_UI_TEST_STATUS=FAIL" "$invalid_out" && record_pass "invalid workflow realtime UI test fixture FAIL guard" || { record_fail "invalid workflow realtime UI test fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=WORKFLOW_REALTIME_UI_TEST_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot UI test mode guard" || record_fail "controlled pilot UI test mode guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=CHAIN_DEPENDENCY_NOT_PASS:236_FAZ_4_17_1_APPROVAL_INBOX" "$invalid_out" && record_pass "approval inbox dependency guard" || record_fail "approval inbox dependency guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=CHAIN_DEPENDENCY_NOT_PASS:237_FAZ_4_17_2_WORKFLOW_MONITOR" "$invalid_out" && record_pass "workflow monitor dependency guard" || record_fail "workflow monitor dependency guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=CHAIN_DEPENDENCY_NOT_PASS:238_FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU" "$invalid_out" && record_pass "realtime health dependency guard" || record_fail "realtime health dependency guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REQUIRED_TEST_ITEM_NOT_READY:APPROVAL_INBOX_UI_TEST" "$invalid_out" && record_pass "required test item ready guard" || record_fail "required test item ready guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REQUIRED_EVIDENCE_MISSING:APPROVAL_INBOX_UI_TEST" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REQUIRED_TEST_ITEMS_MISSING" "$invalid_out" && record_pass "missing required test items guard" || record_fail "missing required test items guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=DUPLICATE_TEST_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate test item guard" || record_fail "duplicate test item guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=APPROVAL_INBOX_STATUS_NOT_PASS" "$invalid_out" && record_pass "approval inbox PASS guard" || record_fail "approval inbox PASS guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=WORKFLOW_MONITOR_STATUS_NOT_PASS" "$invalid_out" && record_pass "workflow monitor PASS guard" || record_fail "workflow monitor PASS guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REALTIME_HEALTH_STATUS_NOT_PASS" "$invalid_out" && record_pass "realtime health PASS guard" || record_fail "realtime health PASS guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=WORKFLOW_MUTATION_NOT_DISABLED" "$invalid_out" && record_pass "workflow mutation disabled guard" || record_fail "workflow mutation disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REAL_APPROVAL_EXECUTION_NOT_DISABLED" "$invalid_out" && record_pass "real approval execution disabled guard" || record_fail "real approval execution disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=REAL_WORKFLOW_EXECUTION_NOT_DISABLED" "$invalid_out" && record_pass "real workflow execution disabled guard" || record_fail "real workflow execution disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live websocket disabled guard" || record_fail "live websocket disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=LIVE_SSE_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live SSE disabled guard" || record_fail "live SSE disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=EVENT_STREAM_PUBLISH_NOT_DISABLED" "$invalid_out" && record_pass "event stream publish disabled guard" || record_fail "event stream publish disabled guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=UI_SURFACE_PASS_COUNT_INVALID" "$invalid_out" && record_pass "UI surface pass count guard" || record_fail "UI surface pass count guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 239 — FAZ 4-17.6 WORKFLOW / REALTIME UI TESTLERI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "workflow realtime UI test file exists" "$UI_TEST_FILE"
  check_file "approval inbox web exists" "$APPROVAL_WEB"
  check_file "workflow monitor web exists" "$MONITOR_WEB"
  check_file "realtime health web exists" "$REALTIME_WEB"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.6 Workflow / Realtime UI Testleri"
  check_contains "doc approval UI marker" "$DOC_FILE" "Approval Inbox UI test"
  check_contains "doc workflow UI marker" "$DOC_FILE" "Workflow Monitor UI test"
  check_contains "doc realtime UI marker" "$DOC_FILE" "Realtime Health UI test"
  check_contains "doc no socket marker" "$DOC_FILE" "Gerçek WebSocket/SSE bağlantısı açmaz"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 239"
  check_contains "config dependency 236 marker" "$CONFIG_FILE" "236_FAZ_4_17_1_APPROVAL_INBOX"
  check_contains "config dependency 237 marker" "$CONFIG_FILE" "237_FAZ_4_17_2_WORKFLOW_MONITOR"
  check_contains "config dependency 238 marker" "$CONFIG_FILE" "238_FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"workflow_realtime_ui_test_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config no mutation marker" "$CONFIG_FILE" "\"no_workflow_mutation_required\": true"
  check_contains "config no websocket marker" "$CONFIG_FILE" "\"no_live_websocket_connection_required\": true"
  check_contains "config no SSE marker" "$CONFIG_FILE" "\"no_live_sse_connection_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config next step marker" "$CONFIG_FILE" "240_FAZ_4_17_3_REALTIME_EVENT_FEED"

  check_contains "UI test status ready marker" "$UI_TEST_FILE" "\"workflow_realtime_ui_test_status\": \"READY\""
  check_contains "UI test controlled pilot marker" "$UI_TEST_FILE" "\"workflow_realtime_ui_test_mode\": \"CONTROLLED_PILOT\""
  check_contains "UI test tenant scope marker" "$UI_TEST_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "approval UI test marker" "$UI_TEST_FILE" "APPROVAL_INBOX_UI_TEST"
  check_contains "workflow monitor UI test marker" "$UI_TEST_FILE" "WORKFLOW_MONITOR_UI_TEST"
  check_contains "realtime health UI test marker" "$UI_TEST_FILE" "REALTIME_HEALTH_UI_TEST"
  check_contains "no mutation test marker" "$UI_TEST_FILE" "NO_WORKFLOW_MUTATION_TEST"
  check_contains "no live websocket test marker" "$UI_TEST_FILE" "NO_LIVE_WEBSOCKET_TEST"
  check_contains "no live SSE test marker" "$UI_TEST_FILE" "NO_LIVE_SSE_TEST"
  check_contains "no event publish test marker" "$UI_TEST_FILE" "NO_EVENT_STREAM_PUBLISH_TEST"
  check_contains "UI test closed policy reference marker" "$UI_TEST_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "approval web checkpoint marker" "$APPROVAL_WEB" "FAZ_4_17_1_APPROVAL_INBOX_UI_CHECKPOINT"
  check_contains "workflow web checkpoint marker" "$MONITOR_WEB" "FAZ_4_17_2_WORKFLOW_MONITOR_UI_CHECKPOINT"
  check_contains "realtime web checkpoint marker" "$REALTIME_WEB" "FAZ_4_17_5_WEBSOCKET_SSE_HEALTH_UI_CHECKPOINT"
  check_contains "approval web no approval marker" "$APPROVAL_WEB" "NO_REAL_APPROVAL_EXECUTION"
  check_contains "workflow web no execution marker" "$MONITOR_WEB" "NO_REAL_WORKFLOW_EXECUTION"
  check_contains "realtime web no websocket marker" "$REALTIME_WEB" "NO_LIVE_WEBSOCKET_CONNECTION"
  check_contains "realtime web no SSE marker" "$REALTIME_WEB" "NO_LIVE_SSE_CONNECTION"
  check_contains "realtime web no event publish marker" "$REALTIME_WEB" "NO_EVENT_STREAM_PUBLISH"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime UI test file guard marker" "$RUNTIME_SCRIPT" "UI_TEST_FILE_NOT_FOUND"
  check_contains "runtime approval web guard marker" "$RUNTIME_SCRIPT" "APPROVAL_WEB_NOT_FOUND"
  check_contains "runtime monitor web guard marker" "$RUNTIME_SCRIPT" "MONITOR_WEB_NOT_FOUND"
  check_contains "runtime realtime web guard marker" "$RUNTIME_SCRIPT" "REALTIME_WEB_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "WORKFLOW_REALTIME_UI_TEST_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TEST_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_TEST_ITEM_CODE_FOUND"
  check_contains "runtime no websocket guard marker" "$RUNTIME_SCRIPT" "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED"
  check_contains "runtime no SSE guard marker" "$RUNTIME_SCRIPT" "LIVE_SSE_CONNECTION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "WORKFLOW_REALTIME_UI_TEST_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "WORKFLOW_REALTIME_UI_TEST_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test items marker" "$TEST_FILE" "\"test_items\""
  check_contains "test UI surfaces marker" "$TEST_FILE" "\"ui_surfaces\""
  check_contains "test UI controls marker" "$TEST_FILE" "\"ui_test_controls\""
  check_contains "test UI metrics marker" "$TEST_FILE" "\"ui_test_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 239 — FAZ 4-17.6 WORKFLOW / REALTIME UI TESTLERI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_DOC_STATUS=READY"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_CONFIG_STATUS=READY"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_TEST_STATUS=PASS"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_FINAL_STATUS=PASS"
    echo "FAZ_4_17_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_TEST_STATUS=FAIL"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
