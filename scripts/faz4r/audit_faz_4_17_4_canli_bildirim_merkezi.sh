#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI.md"
CONFIG_FILE="configs/faz4r/faz_4_17_4_canli_bildirim_merkezi.v1.json"
CENTER_FILE="configs/faz4r/notification_center.controlled_pilot.v1.json"
WEB_FILE="web/faz4r/notification-center/index.html"
RUNTIME_SCRIPT="scripts/faz4r/validate_notification_center.sh"
TEST_FILE="tests/faz4r/faz_4_17_4_canli_bildirim_merkezi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_17_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_17_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_17_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_17_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CENTER_FILE="$CENTER_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$CENTER_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "NOTIFICATION_CENTER_STATUS=PASS" "$valid_out" && record_pass "main notification center artifact PASS" || { record_fail "main notification center artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main notification center artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" CENTER_FILE="$CENTER_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "NOTIFICATION_CENTER_STATUS=PASS" "$valid_out" && record_pass "valid notification center fixture PASS" || { record_fail "valid notification center fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid notification center fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "NOTIFICATION_CENTER_TOTAL_ITEM_COUNT=21" "$valid_out" && record_pass "valid notification center total item count" || record_fail "valid notification center total item count"
  grep -Fq "NOTIFICATION_CENTER_READY_ITEM_COUNT=21" "$valid_out" && record_pass "valid notification center ready item count" || record_fail "valid notification center ready item count"
  grep -Fq "TENANT_SCOPE=SINGLE_TENANT" "$valid_out" && record_pass "valid tenant scope guard" || record_fail "valid tenant scope guard"
  grep -Fq "REALTIME_EVENT_FEED_STATUS=PASS" "$valid_out" && record_pass "valid realtime event feed dependency guard" || record_fail "valid realtime event feed dependency guard"
  grep -Fq "NOTIFICATION_LIST_STATUS=READY" "$valid_out" && record_pass "valid notification list guard" || record_fail "valid notification list guard"
  grep -Fq "UNREAD_COUNTER_STATUS=READY" "$valid_out" && record_pass "valid unread counter guard" || record_fail "valid unread counter guard"
  grep -Fq "READ_STATE_PLACEHOLDER_STATUS=READY" "$valid_out" && record_pass "valid read state placeholder guard" || record_fail "valid read state placeholder guard"
  grep -Fq "PUSH_DELIVERY_COUNT=0" "$valid_out" && record_pass "valid push delivery zero guard" || record_fail "valid push delivery zero guard"
  grep -Fq "EMAIL_DELIVERY_COUNT=0" "$valid_out" && record_pass "valid email delivery zero guard" || record_fail "valid email delivery zero guard"
  grep -Fq "SMS_DELIVERY_COUNT=0" "$valid_out" && record_pass "valid SMS delivery zero guard" || record_fail "valid SMS delivery zero guard"
  grep -Fq "NO_PUSH_DELIVERY=true" "$valid_out" && record_pass "valid no push delivery guard" || record_fail "valid no push delivery guard"
  grep -Fq "NO_EMAIL_DELIVERY=true" "$valid_out" && record_pass "valid no email delivery guard" || record_fail "valid no email delivery guard"
  grep -Fq "NO_SMS_DELIVERY=true" "$valid_out" && record_pass "valid no SMS delivery guard" || record_fail "valid no SMS delivery guard"
  grep -Fq "NO_NOTIFICATION_MUTATION=true" "$valid_out" && record_pass "valid no notification mutation guard" || record_fail "valid no notification mutation guard"

  if CONFIG_FILE="$CONFIG_FILE" CENTER_FILE="$CENTER_FILE" WEB_FILE="$WEB_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid notification center fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "NOTIFICATION_CENTER_STATUS=FAIL" "$invalid_out" && record_pass "invalid notification center fixture FAIL guard" || { record_fail "invalid notification center fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_CENTER_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot notification center mode guard" || record_fail "controlled pilot notification center mode guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=TENANT_SCOPE_INVALID" "$invalid_out" && record_pass "tenant scope guard" || record_fail "tenant scope guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=CHAIN_DEPENDENCY_NOT_PASS:240_FAZ_4_17_3_REALTIME_EVENT_FEED" "$invalid_out" && record_pass "realtime event feed dependency guard" || record_fail "realtime event feed dependency guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=REQUIRED_NOTIFICATION_ITEM_NOT_READY:NOTIFICATION_CENTER_SHELL" "$invalid_out" && record_pass "required notification item ready guard" || record_fail "required notification item ready guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=REQUIRED_EVIDENCE_MISSING:NOTIFICATION_CENTER_SHELL" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=REQUIRED_NOTIFICATION_ITEMS_MISSING" "$invalid_out" && record_pass "missing required notification items guard" || record_fail "missing required notification items guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=DUPLICATE_NOTIFICATION_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate notification item guard" || record_fail "duplicate notification item guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=REALTIME_EVENT_FEED_STATUS_NOT_PASS" "$invalid_out" && record_pass "realtime event feed PASS guard" || record_fail "realtime event feed PASS guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_LIST_STATUS_NOT_READY" "$invalid_out" && record_pass "notification list ready guard" || record_fail "notification list ready guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=UNREAD_COUNTER_STATUS_NOT_READY" "$invalid_out" && record_pass "unread counter ready guard" || record_fail "unread counter ready guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=PUSH_DELIVERY_NOT_DISABLED" "$invalid_out" && record_pass "push delivery disabled guard" || record_fail "push delivery disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=EMAIL_DELIVERY_NOT_DISABLED" "$invalid_out" && record_pass "email delivery disabled guard" || record_fail "email delivery disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=SMS_DELIVERY_NOT_DISABLED" "$invalid_out" && record_pass "SMS delivery disabled guard" || record_fail "SMS delivery disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=LIVE_WEBSOCKET_CONNECTION_NOT_DISABLED" "$invalid_out" && record_pass "live websocket disabled guard" || record_fail "live websocket disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=EVENT_STREAM_SUBSCRIBE_NOT_DISABLED" "$invalid_out" && record_pass "event stream subscribe disabled guard" || record_fail "event stream subscribe disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_MUTATION_NOT_DISABLED" "$invalid_out" && record_pass "notification mutation disabled guard" || record_fail "notification mutation disabled guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=PUSH_DELIVERY_COUNT_NOT_ZERO" "$invalid_out" && record_pass "push delivery count zero guard" || record_fail "push delivery count zero guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=EMAIL_DELIVERY_COUNT_NOT_ZERO" "$invalid_out" && record_pass "email delivery count zero guard" || record_fail "email delivery count zero guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=SMS_DELIVERY_COUNT_NOT_ZERO" "$invalid_out" && record_pass "SMS delivery count zero guard" || record_fail "SMS delivery count zero guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_SAMPLE_1_TENANT_MISMATCH" "$invalid_out" && record_pass "notification sample tenant guard" || record_fail "notification sample tenant guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_SAMPLE_1_DELIVERY_NOT_PREVIEW_ONLY" "$invalid_out" && record_pass "notification sample delivery preview guard" || record_fail "notification sample delivery preview guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_SAMPLE_1_SEVERITY_INVALID" "$invalid_out" && record_pass "notification sample severity guard" || record_fail "notification sample severity guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=NOTIFICATION_SAMPLE_1_CHANNEL_INVALID" "$invalid_out" && record_pass "notification sample channel guard" || record_fail "notification sample channel guard"
  grep -Fq "NOTIFICATION_CENTER_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 241 — FAZ 4-17.4 CANLI BILDIRIM MERKEZI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "notification center file exists" "$CENTER_FILE"
  check_file "web checkpoint file exists" "$WEB_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-17.4 Canlı Bildirim Merkezi"
  check_contains "doc notification list marker" "$DOC_FILE" "Notification list"
  check_contains "doc no push marker" "$DOC_FILE" "no_push_delivery = true"
  check_contains "doc no email marker" "$DOC_FILE" "no_email_delivery = true"
  check_contains "doc no SMS marker" "$DOC_FILE" "no_sms_delivery = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 241"
  check_contains "config dependency 240 marker" "$CONFIG_FILE" "240_FAZ_4_17_3_REALTIME_EVENT_FEED"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"notification_center_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config tenant scope marker" "$CONFIG_FILE" "\"tenant_scope_required\": \"SINGLE_TENANT\""
  check_contains "config no push marker" "$CONFIG_FILE" "\"no_push_delivery_required\": true"
  check_contains "config no email marker" "$CONFIG_FILE" "\"no_email_delivery_required\": true"
  check_contains "config no SMS marker" "$CONFIG_FILE" "\"no_sms_delivery_required\": true"
  check_contains "config no mutation marker" "$CONFIG_FILE" "\"no_notification_mutation_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"

  check_contains "center status ready marker" "$CENTER_FILE" "\"notification_center_status\": \"READY\""
  check_contains "center controlled pilot marker" "$CENTER_FILE" "\"notification_center_mode\": \"CONTROLLED_PILOT\""
  check_contains "center tenant scope marker" "$CENTER_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "notification list marker" "$CENTER_FILE" "NOTIFICATION_LIST"
  check_contains "unread counter marker" "$CENTER_FILE" "UNREAD_COUNTER_MODEL"
  check_contains "read state marker" "$CENTER_FILE" "READ_STATE_PLACEHOLDER"
  check_contains "severity badge marker" "$CENTER_FILE" "SEVERITY_BADGE_MODEL"
  check_contains "channel badge marker" "$CENTER_FILE" "CHANNEL_BADGE_MODEL"
  check_contains "no push marker" "$CENTER_FILE" "\"no_push_delivery\": true"
  check_contains "no email marker" "$CENTER_FILE" "\"no_email_delivery\": true"
  check_contains "no SMS marker" "$CENTER_FILE" "\"no_sms_delivery\": true"
  check_contains "no mutation marker" "$CENTER_FILE" "\"no_notification_mutation\": true"
  check_contains "center closed policy reference marker" "$CENTER_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "web checkpoint marker" "$WEB_FILE" "FAZ_4_17_4_NOTIFICATION_CENTER_UI_CHECKPOINT"
  check_contains "web title marker" "$WEB_FILE" "Canlı Bildirim Merkezi"
  check_contains "web no push marker" "$WEB_FILE" "NO_PUSH_DELIVERY"
  check_contains "web no email marker" "$WEB_FILE" "NO_EMAIL_DELIVERY"
  check_contains "web no SMS marker" "$WEB_FILE" "NO_SMS_DELIVERY"
  check_contains "web no websocket marker" "$WEB_FILE" "NO_LIVE_WEBSOCKET_CONNECTION"
  check_contains "web no SSE marker" "$WEB_FILE" "NO_LIVE_SSE_CONNECTION"
  check_contains "web no subscribe marker" "$WEB_FILE" "NO_EVENT_STREAM_SUBSCRIBE"
  check_contains "web no publish marker" "$WEB_FILE" "NO_EVENT_STREAM_PUBLISH"
  check_contains "web no mutation marker" "$WEB_FILE" "NO_NOTIFICATION_MUTATION"
  check_contains "web unread marker" "$WEB_FILE" "UNREAD_PLACEHOLDER"
  check_contains "web read marker" "$WEB_FILE" "READ_PLACEHOLDER"
  check_contains "web not delivered marker" "$WEB_FILE" "NOT_DELIVERED_PREVIEW_ONLY"
  check_contains "web empty state marker" "$WEB_FILE" "Empty state ready"
  check_contains "web error state marker" "$WEB_FILE" "Error state ready"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime center file guard marker" "$RUNTIME_SCRIPT" "CENTER_FILE_NOT_FOUND"
  check_contains "runtime web file guard marker" "$RUNTIME_SCRIPT" "WEB_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "NOTIFICATION_CENTER_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_NOTIFICATION_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_NOTIFICATION_ITEM_CODE_FOUND"
  check_contains "runtime push disabled guard marker" "$RUNTIME_SCRIPT" "PUSH_DELIVERY_NOT_DISABLED"
  check_contains "runtime email disabled guard marker" "$RUNTIME_SCRIPT" "EMAIL_DELIVERY_NOT_DISABLED"
  check_contains "runtime SMS disabled guard marker" "$RUNTIME_SCRIPT" "SMS_DELIVERY_NOT_DISABLED"
  check_contains "runtime mutation disabled guard marker" "$RUNTIME_SCRIPT" "NOTIFICATION_MUTATION_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "NOTIFICATION_CENTER_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "NOTIFICATION_CENTER_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test notification items marker" "$TEST_FILE" "\"notification_items\""
  check_contains "test notification samples marker" "$TEST_FILE" "\"notification_samples\""
  check_contains "test notification controls marker" "$TEST_FILE" "\"notification_controls\""
  check_contains "test notification metrics marker" "$TEST_FILE" "\"notification_metrics\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 241 — FAZ 4-17.4 CANLI BILDIRIM MERKEZI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_DOC_STATUS=READY"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_CONFIG_STATUS=READY"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_WEB_STATUS=READY"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_RUNTIME_STATUS=READY"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_TEST_STATUS=PASS"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_FINAL_STATUS=PASS"
    echo "WEB_L7_WORKFLOW_REALTIME_UI_COMPLETE=YES"
    echo "FAZ_4_R_PRIORITY_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_TEST_STATUS=FAIL"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_17_4_CANLI_BILDIRIM_MERKEZI_FINAL_STATUS=FAIL"
    echo "WEB_L7_WORKFLOW_REALTIME_UI_COMPLETE=NO"
    echo "FAZ_4_R_PRIORITY_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
