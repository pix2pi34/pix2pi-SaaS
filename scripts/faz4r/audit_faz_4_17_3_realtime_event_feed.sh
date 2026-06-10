#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_3_REALTIME_EVENT_FEED.md"
CONFIG_FILE="configs/faz4r/faz_4_17_3_realtime_event_feed.v1.json"
FEED_FILE="configs/faz4r/realtime_event_feed.controlled_pilot.v1.json"
WEB_FILE="web/faz4r/realtime-event-feed/index.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_realtime_event_feed.sh"
TEST_FILE="tests/faz4r/faz_4_17_3_realtime_event_feed_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_3_REALTIME_EVENT_FEED_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_17_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" FEED_FILE="$FEED_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$FEED_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REALTIME_EVENT_FEED_STATUS=PASS" "$valid_out" && record_pass "main realtime event feed artifact PASS" || { record_fail "main realtime event feed artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main realtime event feed artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" FEED_FILE="$FEED_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "REALTIME_EVENT_FEED_STATUS=PASS" "$valid_out" && record_pass "valid realtime event feed fixture PASS" || { record_fail "valid realtime event feed fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid realtime event feed fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "REALTIME_EVENT_FEED_TOTAL_ITEM_COUNT=19" "$valid_out" && record_pass "valid realtime event feed total item count" || record_fail "valid realtime event feed total item count"
  grep -Fq "REALTIME_EVENT_FEED_READY_ITEM_COUNT=19" "$valid_out" && record_pass "valid realtime event feed ready item count" || record_fail "valid realtime event feed ready item count"
  grep -Fq "TENANT_SCOPE=SINGLE_TENANT" "$valid_out" && record_pass "valid tenant scope guard" || record_fail "valid tenant scope guard"
  grep -Fq "WORKFLOW_REALTIME_UI_TEST_STATUS=PASS" "$valid_out" && record_pass "valid workflow realtime UI test dependency guard" || record_fail "valid workflow realtime UI test dependency guard"
  grep -Fq "EVENT_TIMELINE_STATUS=READY" "$valid_out" && record_pass "valid event timeline guard" || record_fail "valid event timeline guard"
  grep -Fq "SEVERITY_BADGE_STATUS=READY" "$valid_out" && record_pass "valid severity badge guard" || record_fail "valid severity badge guard"
  grep -Fq "CHANNEL_BADGE_STATUS=READY" "$valid_out" && record_pass "valid channel badge guard" || record_fail "valid channel badge guard"
  grep -Fq "EVENT_STREAM_PUBLISH_COUNT=0" "$valid_out" && record_pass "valid event publish zero guard" || record_fail "valid event publish zero guard"
  grep -Fq "EVENT_STREAM_SUBSCRIBE_COUNT=0" "$valid_out" && record_pass "valid event subscribe zero guard" || record_fail "valid event subscribe zero guard"
  grep -Fq "ACTIVE_WEBSOCKET_CONNECTION_COUNT=0" "$valid_out" && record_pass "valid websocket active zero guard" || record_fail "valid websocket active zero guard"
  grep -Fq "ACTIVE_SSE_CONNECTION_COUNT=0" "$valid_out" && record_pass "valid SSE active zero guard" || record_fail "valid SSE active zero guard"
  grep -Fq "NO_EVENT_STREAM_PUBLISH=true" "$valid_out" && record_pass "valid no event stream publish guard" || record_fail "valid no event stream publish guard"
  grep -Fq "NO_EVENT_STREAM_SUBSCRIBE=true" "$valid_out" && record_pass "valid no event stream subscribe guard" || record_fail "valid no event stream subscribe guard"
  grep -Fq "NO_LIVE_WEBSOCKET_CONNECTION=true" "$valid_out" && record_pass "valid no live websocket guard" || record_fail "valid no live websocket guard"
  grep -Fq "NO_LIVE_SSE_CONNECTION=true" "$valid_out" && record_pass "valid no live SSE guard" || record_fail "valid no live SSE guard"

  if CONFIG_FILE="$CONFIG_FILE" FEED_FILE="$FEED_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid realtime event feed fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "REALTIME_EVENT_FEED_STATUS=FAIL" "$invalid_out" && record_pass "invalid realtime event feed fixture FAIL guard" || { record_fail "invalid realtime event feed fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "REALTIME_EVENT_FEED_FAIL=REALTIME_EVENT_FEED_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot event feed mode guard" || record_fail "controlled pilot event feed mode guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=CHAIN_DEPENDENCY_NOT_PASS:239_FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI" "$invalid_out" && record_pass "workflow realtime UI dependency guard" || record_fail "workflow realtime UI dependency guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=REQUIRED_FEED_ITEM_NOT_READY:REALTIME_EVENT_FEED_SHELL" "$invalid_out" && record_pass "required feed item ready guard" || record_fail "required feed item ready guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=REQUIRED_EVIDENCE_MISSING:REALTIME_EVENT_FEED_SHELL" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=REQUIRED_FEED_ITEMS_MISSING" "$invalid_out" && record_pass "missing required feed items guard" || record_fail "missing required feed items guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=DUPLICATE_FEED_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate feed item guard" || record_fail "duplicate feed item guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=WORKFLOW_REALTIME_UI_TEST_STATUS_NOT_PASS" "$invalid_out" && record_pass "workflow realtime UI PASS guard" || record_fail "workflow realtime UI PASS guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_TIMELINE_STATUS_NOT_READY" "$invalid_out" && record_pass "event timeline ready guard" || record_fail "event timeline ready guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=SEVERITY_BADGE_STATUS_NOT_READY" "$invalid_out" && record_pass "severity badge ready guard" || record_fail "severity badge ready guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_STREAM_PUBLISH_NOT_DISABLED" "$invalid_out" && record_pass "event stream publish disabled guard" || record_fail "event stream publish disabled guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_STREAM_SUBSCRIBE_NOT_DISABLED" "$invalid_out" && record_pass "event stream subscribe disabled guard" || record_fail "event stream subscribe disabled guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live websocket disabled guard" || record_fail "live websocket disabled guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=LIVE_SSE_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live SSE disabled guard" || record_fail "live SSE disabled guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_STREAM_PUBLISH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "event publish count zero guard" || record_fail "event publish count zero guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_STREAM_SUBSCRIBE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "event subscribe count zero guard" || record_fail "event subscribe count zero guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_SAMPLE_1_TENANT_MISMATCH" "$invalid_out" && record_pass "event sample tenant guard" || record_fail "event sample tenant guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_SAMPLE_1_STATUS_NOT_READ_ONLY" "$invalid_out" && record_pass "event sample read-only guard" || record_fail "event sample read-only guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_SAMPLE_1_SEVERITY_INVALID" "$invalid_out" && record_pass "event sample severity guard" || record_fail "event sample severity guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=EVENT_SAMPLE_1_CHANNEL_INVALID" "$invalid_out" && record_pass "event sample channel guard" || record_fail "event sample channel guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=WORKFLOW_STATUS_CHANNEL_MISSING" "$invalid_out" && record_pass "workflow status channel required guard" || record_fail "workflow status channel required guard"
  grep -Fq "REALTIME_EVENT_FEED_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 240 — FAZ 4-17.3 REALTIME EVENT FEED REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "realtime event feed file exists" "$FEED_FILE"
  check_file "web checkpoint file exists" "$WEB_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.3 Realtime Event Feed"
  check_contains "doc event timeline marker" "$DOC_FILE" "Event timeline list"
  check_contains "doc no publish marker" "$DOC_FILE" "no_event_stream_publish = true"
  check_contains "doc no subscribe marker" "$DOC_FILE" "no_event_stream_subscribe = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 240"
  check_contains "config dependency 239 marker" "$CONFIG_FILE" "239_FAZ_4_17_6_WORKFLOW_REALTIME_UI_TESTLERI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"realtime_event_feed_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config tenant scope marker" "$CONFIG_FILE" "\"tenant_scope_required\": \"SINGLE_TENANT\""
  check_contains "config no publish marker" "$CONFIG_FILE" "\"no_event_stream_publish_required\": true"
  check_contains "config no subscribe marker" "$CONFIG_FILE" "\"no_event_stream_subscribe_required\": true"
  check_contains "config no websocket marker" "$CONFIG_FILE" "\"no_live_websocket_connection_required\": true"
  check_contains "config no SSE marker" "$CONFIG_FILE" "\"no_live_sse_connection_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config next step marker" "$CONFIG_FILE" "241_FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI"

  check_contains "feed status ready marker" "$FEED_FILE" "\"realtime_event_feed_status\": \"READY\""
  check_contains "feed controlled pilot marker" "$FEED_FILE" "\"realtime_event_feed_mode\": \"CONTROLLED_PILOT\""
  check_contains "feed tenant scope marker" "$FEED_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "event timeline marker" "$FEED_FILE" "EVENT_TIMELINE_LIST"
  check_contains "severity badge marker" "$FEED_FILE" "EVENT_SEVERITY_BADGE_MODEL"
  check_contains "channel badge marker" "$FEED_FILE" "EVENT_CHANNEL_BADGE_MODEL"
  check_contains "correlation marker" "$FEED_FILE" "CORRELATION_ID_PLACEHOLDER"
  check_contains "workflow monitor link marker" "$FEED_FILE" "WORKFLOW_MONITOR_LINK"
  check_contains "realtime health link marker" "$FEED_FILE" "REALTIME_HEALTH_LINK"
  check_contains "no publish marker" "$FEED_FILE" "\"no_event_stream_publish\": true"
  check_contains "no subscribe marker" "$FEED_FILE" "\"no_event_stream_subscribe\": true"
  check_contains "feed closed policy reference marker" "$FEED_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "web checkpoint marker" "$WEB_FILE" "FAZ_4_17_3_REALTIME_EVENT_FEED_UI_CHECKPOINT"
  check_contains "web title marker" "$WEB_FILE" "Realtime Event Feed"
  check_contains "web no publish marker" "$WEB_FILE" "NO_EVENT_STREAM_PUBLISH"
  check_contains "web no subscribe marker" "$WEB_FILE" "NO_EVENT_STREAM_SUBSCRIBE"
  check_contains "web no websocket marker" "$WEB_FILE" "NO_LIVE_WEBSOCKET_CONNECTION"
  check_contains "web no SSE marker" "$WEB_FILE" "NO_LIVE_SSE_CONNECTION"
  check_contains "web read-only marker" "$WEB_FILE" "READ_ONLY_SAMPLE"
  check_contains "web workflow channel marker" "$WEB_FILE" "workflow.status"
  check_contains "web approval channel marker" "$WEB_FILE" "approval.inbox"
  check_contains "web notification channel marker" "$WEB_FILE" "notification.center"
  check_contains "web empty state marker" "$WEB_FILE" "Empty state ready"
  check_contains "web error state marker" "$WEB_FILE" "Error state ready"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime feed file guard marker" "$RUNTIME_SCRIPT" "FEED_FILE_NOT_FOUND"
  check_contains "runtime web file guard marker" "$RUNTIME_SCRIPT" "WEB_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "REALTIME_EVENT_FEED_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_FEED_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_FEED_ITEM_CODE_FOUND"
  check_contains "runtime publish disabled guard marker" "$RUNTIME_SCRIPT" "EVENT_STREAM_PUBLISH_NOT_DISABLED"
  check_contains "runtime subscribe disabled guard marker" "$RUNTIME_SCRIPT" "EVENT_STREAM_SUBSCRIBE_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "REALTIME_EVENT_FEED_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "REALTIME_EVENT_FEED_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test feed items marker" "$TEST_FILE" "\"feed_items\""
  check_contains "test event samples marker" "$TEST_FILE" "\"event_samples\""
  check_contains "test feed controls marker" "$TEST_FILE" "\"feed_controls\""
  check_contains "test feed metrics marker" "$TEST_FILE" "\"feed_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 240 — FAZ 4-17.3 REALTIME EVENT FEED COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_DOC_STATUS=READY"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_CONFIG_STATUS=READY"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_WEB_STATUS=READY"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_TEST_STATUS=PASS"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_FINAL_STATUS=PASS"
    echo "FAZ_4_17_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_TEST_STATUS=FAIL"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_3_REALTIME_EVENT_FEED_FINAL_STATUS=FAIL"
    echo "FAZ_4_17_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
