#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU.md"
CONFIG_FILE="configs/faz4r/faz_4_17_5_websocket_sse_baglanti_sagligi_gorunumu.v1.json"
HEALTH_FILE="configs/faz4r/realtime_connection_health.controlled_pilot.v1.json"
WEB_FILE="web/faz4r/realtime-health/index.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_realtime_connection_health.sh"
TEST_FILE="tests/faz4r/faz_4_17_5_websocket_sse_baglanti_sagligi_gorunumu_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_17_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" HEALTH_FILE="$HEALTH_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$HEALTH_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REALTIME_CONNECTION_HEALTH_STATUS=PASS" "$valid_out" && record_pass "main realtime health artifact PASS" || { record_fail "main realtime health artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main realtime health artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" HEALTH_FILE="$HEALTH_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REALTIME_CONNECTION_HEALTH_STATUS=PASS" "$valid_out" && record_pass "valid realtime health fixture PASS" || { record_fail "valid realtime health fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid realtime health fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "REALTIME_CONNECTION_HEALTH_TOTAL_ITEM_COUNT=20" "$valid_out" && record_pass "valid realtime health total item count" || record_fail "valid realtime health total item count"
  grep -Fq "REALTIME_CONNECTION_HEALTH_READY_ITEM_COUNT=20" "$valid_out" && record_pass "valid realtime health ready item count" || record_fail "valid realtime health ready item count"
  grep -Fq "TENANT_SCOPE=SINGLE_TENANT" "$valid_out" && record_pass "valid tenant scope guard" || record_fail "valid tenant scope guard"
  grep -Fq "WORKFLOW_MONITOR_STATUS=PASS" "$valid_out" && record_pass "valid workflow monitor dependency guard" || record_fail "valid workflow monitor dependency guard"
  grep -Fq "WEBSOCKET_HEALTH_STATUS=READY" "$valid_out" && record_pass "valid websocket health guard" || record_fail "valid websocket health guard"
  grep -Fq "SSE_HEALTH_STATUS=READY" "$valid_out" && record_pass "valid SSE health guard" || record_fail "valid SSE health guard"
  grep -Fq "HEARTBEAT_INDICATOR_STATUS=READY" "$valid_out" && record_pass "valid heartbeat indicator guard" || record_fail "valid heartbeat indicator guard"
  grep -Fq "RECONNECT_INDICATOR_STATUS=READY" "$valid_out" && record_pass "valid reconnect indicator guard" || record_fail "valid reconnect indicator guard"
  grep -Fq "LATENCY_INDICATOR_STATUS=READY" "$valid_out" && record_pass "valid latency indicator guard" || record_fail "valid latency indicator guard"
  grep -Fq "ACTIVE_WEBSOCKET_CONNECTION_COUNT=0" "$valid_out" && record_pass "valid websocket active zero guard" || record_fail "valid websocket active zero guard"
  grep -Fq "ACTIVE_SSE_CONNECTION_COUNT=0" "$valid_out" && record_pass "valid SSE active zero guard" || record_fail "valid SSE active zero guard"
  grep -Fq "EVENT_STREAM_PUBLISH_COUNT=0" "$valid_out" && record_pass "valid event publish zero guard" || record_fail "valid event publish zero guard"
  grep -Fq "NO_LIVE_WEBSOCKET_CONNECTION=true" "$valid_out" && record_pass "valid no live websocket guard" || record_fail "valid no live websocket guard"
  grep -Fq "NO_LIVE_SSE_CONNECTION=true" "$valid_out" && record_pass "valid no live SSE guard" || record_fail "valid no live SSE guard"
  grep -Fq "NO_EVENT_STREAM_PUBLISH=true" "$valid_out" && record_pass "valid no event stream publish guard" || record_fail "valid no event stream publish guard"

  if CONFIG_FILE="$CONFIG_FILE" HEALTH_FILE="$HEALTH_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid realtime health fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "REALTIME_CONNECTION_HEALTH_STATUS=FAIL" "$invalid_out" && record_pass "invalid realtime health fixture FAIL guard" || { record_fail "invalid realtime health fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=REALTIME_HEALTH_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot realtime health mode guard" || record_fail "controlled pilot realtime health mode guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=CHAIN_DEPENDENCY_NOT_PASS:237_FAZ_4_17_2_WORKFLOW_MONITOR" "$invalid_out" && record_pass "workflow monitor dependency guard" || record_fail "workflow monitor dependency guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=REQUIRED_HEALTH_ITEM_NOT_READY:REALTIME_HEALTH_SHELL" "$invalid_out" && record_pass "required health item ready guard" || record_fail "required health item ready guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=REQUIRED_EVIDENCE_MISSING:REALTIME_HEALTH_SHELL" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=REQUIRED_HEALTH_ITEMS_MISSING" "$invalid_out" && record_pass "missing required health items guard" || record_fail "missing required health items guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=DUPLICATE_HEALTH_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate health item guard" || record_fail "duplicate health item guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=WORKFLOW_MONITOR_STATUS_NOT_PASS" "$invalid_out" && record_pass "workflow monitor PASS guard" || record_fail "workflow monitor PASS guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=WEBSOCKET_HEALTH_STATUS_NOT_READY" "$invalid_out" && record_pass "websocket health ready guard" || record_fail "websocket health ready guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=SSE_HEALTH_STATUS_NOT_READY" "$invalid_out" && record_pass "SSE health ready guard" || record_fail "SSE health ready guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live websocket disabled guard" || record_fail "live websocket disabled guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=LIVE_SSE_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live SSE disabled guard" || record_fail "live SSE disabled guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=EVENT_STREAM_PUBLISH_NOT_DISABLED" "$invalid_out" && record_pass "event stream publish disabled guard" || record_fail "event stream publish disabled guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=ACTIVE_WEBSOCKET_CONNECTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "active websocket zero guard" || record_fail "active websocket zero guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=ACTIVE_SSE_CONNECTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "active SSE zero guard" || record_fail "active SSE zero guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "event stream publish count zero guard" || record_fail "event stream publish count zero guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=CONNECTION_SAMPLE_1_TENANT_MISMATCH" "$invalid_out" && record_pass "connection sample tenant guard" || record_fail "connection sample tenant guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=CONNECTION_SAMPLE_1_TRANSPORT_INVALID" "$invalid_out" && record_pass "connection sample transport guard" || record_fail "connection sample transport guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=CONNECTION_SAMPLE_1_STATE_NOT_PREVIEW_ONLY" "$invalid_out" && record_pass "connection sample preview only guard" || record_fail "connection sample preview only guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=WEBSOCKET_SAMPLE_MISSING" "$invalid_out" && record_pass "websocket sample required guard" || record_fail "websocket sample required guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=SSE_SAMPLE_MISSING" "$invalid_out" && record_pass "SSE sample required guard" || record_fail "SSE sample required guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=CHANNEL_WORKFLOW_STATUS_MISSING" "$invalid_out" && record_pass "workflow channel guard" || record_fail "workflow channel guard"
  grep -Fq "REALTIME_CONNECTION_HEALTH_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 238 — FAZ 4-17.5 WEBSOCKET / SSE BAGLANTI SAGLIGI GORUNUMU REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "realtime health file exists" "$HEALTH_FILE"
  check_file "web checkpoint file exists" "$WEB_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.5 WebSocket / SSE Bağlantı Sağlığı Görünümü"
  check_contains "doc websocket marker" "$DOC_FILE" "WebSocket health placeholder"
  check_contains "doc SSE marker" "$DOC_FILE" "SSE health placeholder"
  check_contains "doc no live socket marker" "$DOC_FILE" "no_live_websocket_connection = true"
  check_contains "doc no live SSE marker" "$DOC_FILE" "no_live_sse_connection = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 238"
  check_contains "config dependency 237 marker" "$CONFIG_FILE" "237_FAZ_4_17_2_WORKFLOW_MONITOR"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"realtime_health_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config tenant scope marker" "$CONFIG_FILE" "\"tenant_scope_required\": \"SINGLE_TENANT\""
  check_contains "config no websocket marker" "$CONFIG_FILE" "\"no_live_websocket_connection_required\": true"
  check_contains "config no SSE marker" "$CONFIG_FILE" "\"no_live_sse_connection_required\": true"
  check_contains "config no event publish marker" "$CONFIG_FILE" "\"no_event_stream_publish_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config next step marker" "$CONFIG_FILE" "239_FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI"

  check_contains "health status ready marker" "$HEALTH_FILE" "\"realtime_health_status\": \"READY\""
  check_contains "health controlled pilot marker" "$HEALTH_FILE" "\"realtime_health_mode\": \"CONTROLLED_PILOT\""
  check_contains "health tenant scope marker" "$HEALTH_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "websocket health marker" "$HEALTH_FILE" "WEBSOCKET_HEALTH_PLACEHOLDER"
  check_contains "SSE health marker" "$HEALTH_FILE" "SSE_HEALTH_PLACEHOLDER"
  check_contains "heartbeat marker" "$HEALTH_FILE" "HEARTBEAT_AGE_INDICATOR"
  check_contains "reconnect marker" "$HEALTH_FILE" "RECONNECT_ATTEMPT_COUNTER"
  check_contains "latency marker" "$HEALTH_FILE" "LATENCY_INDICATOR"
  check_contains "channel list marker" "$HEALTH_FILE" "SUBSCRIPTION_CHANNEL_LIST"
  check_contains "no live websocket marker" "$HEALTH_FILE" "\"no_live_websocket_connection\": true"
  check_contains "no live SSE marker" "$HEALTH_FILE" "\"no_live_sse_connection\": true"
  check_contains "no event publish marker" "$HEALTH_FILE" "\"no_event_stream_publish\": true"
  check_contains "health closed policy reference marker" "$HEALTH_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "web checkpoint marker" "$WEB_FILE" "FAZ_4_17_5_WEBSOCKET_SSE_HEALTH_UI_CHECKPOINT"
  check_contains "web title marker" "$WEB_FILE" "WebSocket / SSE Health"
  check_contains "web no websocket marker" "$WEB_FILE" "NO_LIVE_WEBSOCKET_CONNECTION"
  check_contains "web no SSE marker" "$WEB_FILE" "NO_LIVE_SSE_CONNECTION"
  check_contains "web no event publish marker" "$WEB_FILE" "NO_EVENT_STREAM_PUBLISH"
  check_contains "web placeholder marker" "$WEB_FILE" "PLACEHOLDER READY"
  check_contains "web not connected marker" "$WEB_FILE" "NOT CONNECTED PREVIEW ONLY"
  check_contains "web workflow channel marker" "$WEB_FILE" "workflow.status"
  check_contains "web notification channel marker" "$WEB_FILE" "notification.center"
  check_contains "web empty state marker" "$WEB_FILE" "Empty state ready"
  check_contains "web error state marker" "$WEB_FILE" "Error state ready"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime health file guard marker" "$RUNTIME_SCRIPT" "HEALTH_FILE_NOT_FOUND"
  check_contains "runtime web file guard marker" "$RUNTIME_SCRIPT" "WEB_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "REALTIME_HEALTH_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_HEALTH_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_HEALTH_ITEM_CODE_FOUND"
  check_contains "runtime websocket disabled guard marker" "$RUNTIME_SCRIPT" "LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED"
  check_contains "runtime SSE disabled guard marker" "$RUNTIME_SCRIPT" "LIVE_SSE_CONNECTION_NOT_DISABLED"
  check_contains "runtime event publish guard marker" "$RUNTIME_SCRIPT" "EVENT_STREAM_PUBLISH_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "REALTIME_CONNECTION_HEALTH_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "REALTIME_CONNECTION_HEALTH_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test health items marker" "$TEST_FILE" "\"health_items\""
  check_contains "test connection samples marker" "$TEST_FILE" "\"connection_samples\""
  check_contains "test subscription channels marker" "$TEST_FILE" "\"subscription_channels\""
  check_contains "test health controls marker" "$TEST_FILE" "\"health_controls\""
  check_contains "test health metrics marker" "$TEST_FILE" "\"health_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 238 — FAZ 4-17.5 WEBSOCKET / SSE BAGLANTI SAGLIGI GORUNUMU COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_DOC_STATUS=READY"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_CONFIG_STATUS=READY"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_WEB_STATUS=READY"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_TEST_STATUS=PASS"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_FINAL_STATUS=PASS"
    echo "FAZ_4_17_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_TEST_STATUS=FAIL"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_5_WEBSOCKET_SSE_BAGLANTI_SAGLIGI_GORUNUMU_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
