#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_7_4_ILETISIM_PLANI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_7_4_iletisim_plani.v1.json"
COMM_FILE="configs/faz4r/communication_plan.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_communication_plan.sh"
TEST_FILE="tests/faz4r/faz_4_16_7_4_iletisim_plani_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_7_4_ILETISIM_PLANI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_7_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_7_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_7_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_7_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" COMM_FILE="$COMM_FILE" INPUT_FILE="$COMM_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "COMMUNICATION_PLAN_STATUS=PASS" "$valid_out" && record_pass "main communication plan artifact PASS" || { record_fail "main communication plan artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main communication plan artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" COMM_FILE="$COMM_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "COMMUNICATION_PLAN_STATUS=PASS" "$valid_out" && record_pass "valid communication plan fixture PASS" || { record_fail "valid communication plan fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid communication plan fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "COMMUNICATION_PLAN_TOTAL_ITEM_COUNT=17" "$valid_out" && record_pass "valid communication total item count" || record_fail "valid communication total item count"
  grep -Fq "COMMUNICATION_PLAN_READY_ITEM_COUNT=17" "$valid_out" && record_pass "valid communication ready item count" || record_fail "valid communication ready item count"
  grep -Fq "COMMUNICATION_PLAN_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid communication missing item zero" || record_fail "valid communication missing item zero"
  grep -Fq "NO_REAL_EMAIL_DISPATCH=true" "$valid_out" && record_pass "valid no real email dispatch guard" || record_fail "valid no real email dispatch guard"
  grep -Fq "NO_REAL_SMS_DISPATCH=true" "$valid_out" && record_pass "valid no real SMS dispatch guard" || record_fail "valid no real SMS dispatch guard"
  grep -Fq "NO_REAL_WHATSAPP_DISPATCH=true" "$valid_out" && record_pass "valid no real WhatsApp dispatch guard" || record_fail "valid no real WhatsApp dispatch guard"
  grep -Fq "NO_PUBLIC_ANNOUNCEMENT=true" "$valid_out" && record_pass "valid no public announcement guard" || record_fail "valid no public announcement guard"

  if CONFIG_FILE="$CONFIG_FILE" COMM_FILE="$COMM_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid communication plan fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "COMMUNICATION_PLAN_STATUS=FAIL" "$invalid_out" && record_pass "invalid communication plan fixture FAIL guard" || { record_fail "invalid communication plan fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "COMMUNICATION_PLAN_FAIL=COMMUNICATION_PLAN_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot communication mode guard" || record_fail "controlled pilot communication mode guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=CHAIN_DEPENDENCY_NOT_PASS:228_FAZ_4_16_7_3_GERI_DONUS_PROVASI" "$invalid_out" && record_pass "rollback rehearsal dependency guard" || record_fail "rollback rehearsal dependency guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REQUIRED_COMMUNICATION_ITEM_NOT_READY:COMMUNICATION_KICKOFF" "$invalid_out" && record_pass "required communication item ready guard" || record_fail "required communication item ready guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REQUIRED_EVIDENCE_MISSING:COMMUNICATION_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REQUIRED_COMMUNICATION_ITEMS_MISSING" "$invalid_out" && record_pass "missing required communication items guard" || record_fail "missing required communication items guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=DUPLICATE_COMMUNICATION_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate communication item guard" || record_fail "duplicate communication item guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=AUDIENCE_MAP_STATUS_NOT_READY" "$invalid_out" && record_pass "audience map guard" || record_fail "audience map guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=CHANNEL_MAP_STATUS_NOT_READY" "$invalid_out" && record_pass "channel map guard" || record_fail "channel map guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=MESSAGE_DRAFT_STATUS_NOT_READY" "$invalid_out" && record_pass "message draft guard" || record_fail "message draft guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=SUPPORT_CONTACT_STATUS_NOT_READY" "$invalid_out" && record_pass "support contact guard" || record_fail "support contact guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=INCIDENT_ESCALATION_STATUS_NOT_READY" "$invalid_out" && record_pass "incident escalation guard" || record_fail "incident escalation guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=APPROVAL_OWNER_STATUS_NOT_READY" "$invalid_out" && record_pass "approval owner guard" || record_fail "approval owner guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_EMAIL_DISPATCH_NOT_DISABLED" "$invalid_out" && record_pass "real email dispatch disabled guard" || record_fail "real email dispatch disabled guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_SMS_DISPATCH_NOT_DISABLED" "$invalid_out" && record_pass "real SMS dispatch disabled guard" || record_fail "real SMS dispatch disabled guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_WHATSAPP_DISPATCH_NOT_DISABLED" "$invalid_out" && record_pass "real WhatsApp dispatch disabled guard" || record_fail "real WhatsApp dispatch disabled guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=PUBLIC_ANNOUNCEMENT_NOT_DISABLED" "$invalid_out" && record_pass "public announcement disabled guard" || record_fail "public announcement disabled guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_EMAIL_DISPATCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real email dispatch count zero guard" || record_fail "real email dispatch count zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_SMS_DISPATCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real SMS dispatch count zero guard" || record_fail "real SMS dispatch count zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_WHATSAPP_DISPATCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real WhatsApp dispatch count zero guard" || record_fail "real WhatsApp dispatch count zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=PUBLIC_ANNOUNCEMENT_COUNT_NOT_ZERO" "$invalid_out" && record_pass "public announcement count zero guard" || record_fail "public announcement count zero guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"
  grep -Fq "COMMUNICATION_PLAN_FAIL=REAL_EMAIL_DISPATCH_NOT_CLOSED" "$invalid_out" && record_pass "real email dispatch closed guard" || record_fail "real email dispatch closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 229 — FAZ 4-16.7.4 ILETISIM PLANI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "communication plan file exists" "$COMM_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "communication kickoff doc exists" "docs/faz4r/communication_plan/communication_kickoff.md"
  check_file "audience map doc exists" "docs/faz4r/communication_plan/audience_map.md"
  check_file "channel map doc exists" "docs/faz4r/communication_plan/channel_map.md"
  check_file "final communication report doc exists" "docs/faz4r/communication_plan/final_communication_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.7.4 İletişim Planı"
  check_contains "doc kickoff marker" "$DOC_FILE" "Communication kickoff"
  check_contains "doc no email marker" "$DOC_FILE" "no_real_email_dispatch = true"
  check_contains "doc no public announcement marker" "$DOC_FILE" "no_public_announcement = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 229"
  check_contains "config dependency 228 marker" "$CONFIG_FILE" "228_FAZ_4_16_7_3_GERI_DONUS_PROVASI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"communication_plan_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config no email marker" "$CONFIG_FILE" "\"no_real_email_dispatch_required\": true"
  check_contains "config no SMS marker" "$CONFIG_FILE" "\"no_real_sms_dispatch_required\": true"
  check_contains "config no WhatsApp marker" "$CONFIG_FILE" "\"no_real_whatsapp_dispatch_required\": true"
  check_contains "config no public marker" "$CONFIG_FILE" "\"no_public_announcement_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "communication status ready marker" "$COMM_FILE" "\"communication_plan_status\": \"READY\""
  check_contains "communication controlled pilot marker" "$COMM_FILE" "\"communication_plan_mode\": \"CONTROLLED_PILOT\""
  check_contains "communication kickoff marker" "$COMM_FILE" "COMMUNICATION_KICKOFF"
  check_contains "audience map marker" "$COMM_FILE" "AUDIENCE_MAP"
  check_contains "channel map marker" "$COMM_FILE" "CHANNEL_MAP"
  check_contains "message draft marker" "$COMM_FILE" "PRE_CUTOVER_MESSAGE_DRAFT"
  check_contains "rollback message marker" "$COMM_FILE" "ROLLBACK_MESSAGE_DRAFT"
  check_contains "support contact marker" "$COMM_FILE" "SUPPORT_CONTACT_NOTE"
  check_contains "incident escalation marker" "$COMM_FILE" "INCIDENT_ESCALATION_NOTE"
  check_contains "tenant admin notice marker" "$COMM_FILE" "TENANT_ADMIN_NOTICE"
  check_contains "status page draft marker" "$COMM_FILE" "STATUS_PAGE_DRAFT"
  check_contains "approval marker" "$COMM_FILE" "APPROVAL_OWNER_CONFIRMATION"
  check_contains "communication no email marker" "$COMM_FILE" "\"no_real_email_dispatch\": true"
  check_contains "communication no SMS marker" "$COMM_FILE" "\"no_real_sms_dispatch\": true"
  check_contains "communication no WhatsApp marker" "$COMM_FILE" "\"no_real_whatsapp_dispatch\": true"
  check_contains "communication no public marker" "$COMM_FILE" "\"no_public_announcement\": true"
  check_contains "communication closed policy reference marker" "$COMM_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime communication file guard marker" "$RUNTIME_SCRIPT" "COMM_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "COMMUNICATION_PLAN_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_COMMUNICATION_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_COMMUNICATION_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no email guard marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_DISABLED"
  check_contains "runtime no public guard marker" "$RUNTIME_SCRIPT" "PUBLIC_ANNOUNCEMENT_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "COMMUNICATION_PLAN_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "COMMUNICATION_PLAN_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test communication items marker" "$TEST_FILE" "\"communication_items\""
  check_contains "test communication controls marker" "$TEST_FILE" "\"communication_controls\""
  check_contains "test communication metrics marker" "$TEST_FILE" "\"communication_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 229 — FAZ 4-16.7.4 ILETISIM PLANI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_DOC_STATUS=READY"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_TEST_STATUS=PASS"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_7_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_7_4_ILETISIM_PLANI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_7_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
