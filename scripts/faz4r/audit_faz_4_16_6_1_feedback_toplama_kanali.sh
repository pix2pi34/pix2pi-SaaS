#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_6_1_feedback_toplama_kanali.v1.json"
FEEDBACK_FILE="configs/faz4r/feedback_collection_channel.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_feedback_collection_channel.sh"
TEST_FILE="tests/faz4r/faz_4_16_6_1_feedback_toplama_kanali_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_6_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_6_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_6_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_6_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" FEEDBACK_FILE="$FEEDBACK_FILE" INPUT_FILE="$FEEDBACK_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_STATUS=PASS" "$valid_out"; then
      record_pass "main feedback collection channel artifact PASS"
    else
      record_fail "main feedback collection channel artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main feedback collection channel artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" FEEDBACK_FILE="$FEEDBACK_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_STATUS=PASS" "$valid_out"; then
      record_pass "valid feedback collection channel fixture PASS"
    else
      record_fail "valid feedback collection channel fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid feedback collection channel fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_TOTAL_CHANNEL_COUNT=14" "$valid_out"; then
    record_pass "valid feedback total channel count"
  else
    record_fail "valid feedback total channel count"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_READY_CHANNEL_COUNT=14" "$valid_out"; then
    record_pass "valid feedback ready channel count"
  else
    record_fail "valid feedback ready channel count"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_MISSING_CHANNEL_COUNT=0" "$valid_out"; then
    record_pass "valid feedback missing channel zero"
  else
    record_fail "valid feedback missing channel zero"
  fi

  if grep -Fq "NO_REAL_CRM_SYSTEM=true" "$valid_out"; then
    record_pass "valid no real CRM system guard"
  else
    record_fail "valid no real CRM system guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" FEEDBACK_FILE="$FEEDBACK_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid feedback collection channel fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid feedback collection channel fixture FAIL guard"
    else
      record_fail "invalid feedback collection channel fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=CHANNEL_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot feedback mode guard"
  else
    record_fail "controlled pilot feedback mode guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=CHAIN_DEPENDENCY_NOT_PASS:220_FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU" "$invalid_out"; then
    record_pass "tenant status report dependency guard"
  else
    record_fail "tenant status report dependency guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REQUIRED_FEEDBACK_CHANNEL_NOT_READY:PILOT_USER_FEEDBACK_FORM" "$invalid_out"; then
    record_pass "required feedback channel ready guard"
  else
    record_fail "required feedback channel ready guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REQUIRED_EVIDENCE_MISSING:PILOT_USER_FEEDBACK_FORM" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REQUIRED_FEEDBACK_CHANNELS_MISSING" "$invalid_out"; then
    record_pass "missing required feedback channels guard"
  else
    record_fail "missing required feedback channels guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=DUPLICATE_FEEDBACK_CHANNEL_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate feedback channel guard"
  else
    record_fail "duplicate feedback channel guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=TOTAL_CHANNEL_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total channel count reconciliation guard"
  else
    record_fail "total channel count reconciliation guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=MISSING_CHANNEL_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing channel zero guard"
  else
    record_fail "missing channel zero guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "open blocker zero guard"
  else
    record_fail "open blocker zero guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=FEEDBACK_PRIVACY_POLICY_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "feedback privacy policy ready guard"
  else
    record_fail "feedback privacy policy ready guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=FEEDBACK_CATEGORY_MAPPING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "feedback category mapping ready guard"
  else
    record_fail "feedback category mapping ready guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=FEEDBACK_PRIORITY_MAPPING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "feedback priority mapping ready guard"
  else
    record_fail "feedback priority mapping ready guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=FEEDBACK_OWNER_ROUTING_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "feedback owner routing ready guard"
  else
    record_fail "feedback owner routing ready guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REAL_CRM_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real CRM system disabled guard"
  else
    record_fail "real CRM system disabled guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REAL_TICKET_SYSTEM_NOT_DISABLED" "$invalid_out"; then
    record_pass "real ticket system disabled guard"
  else
    record_fail "real ticket system disabled guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REAL_EMAIL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real email dispatch disabled guard"
  else
    record_fail "real email dispatch disabled guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REAL_CRM_DISPATCH_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "real CRM dispatch count zero guard"
  else
    record_fail "real CRM dispatch count zero guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=REAL_CRM_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real CRM system closed guard"
  else
    record_fail "real CRM system closed guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "live external provider closed guard"
  else
    record_fail "live external provider closed guard"
  fi

  if grep -Fq "FEEDBACK_COLLECTION_CHANNEL_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed guard"
  else
    record_fail "production launch closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 221 — FAZ 4-16.6.1 FEEDBACK TOPLAMA KANALI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "feedback collection file exists" "$FEEDBACK_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "pilot user feedback doc exists" "docs/faz4r/feedback_collection/pilot_user_feedback_form.md"
  check_file "in-app feedback doc exists" "docs/faz4r/feedback_collection/in_app_feedback_entry.md"
  check_file "privacy policy guard doc exists" "docs/faz4r/feedback_collection/feedback_privacy_policy_guard.md"
  check_file "closure intake checklist doc exists" "docs/faz4r/feedback_collection/feedback_closure_intake_checklist.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.6.1 Feedback Toplama Kanalı"
  check_contains "doc pilot user marker" "$DOC_FILE" "Pilot kullanıcı feedback formu"
  check_contains "doc privacy marker" "$DOC_FILE" "Privacy/KVKK guard"
  check_contains "doc no real CRM marker" "$DOC_FILE" "no_real_crm_system = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 221"
  check_contains "config dependency 220 marker" "$CONFIG_FILE" "220_FAZ_4_16_5_5_TENANT_BAZLI_DURUM_RAPORU"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"feedback_channel_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required channel marker" "$CONFIG_FILE" "\"required_channel_status_required\": \"READY\""
  check_contains "config missing channel zero marker" "$CONFIG_FILE" "\"missing_channel_count_required\": 0"
  check_contains "config privacy ready marker" "$CONFIG_FILE" "\"feedback_privacy_policy_status_required\": \"READY\""
  check_contains "config no real CRM marker" "$CONFIG_FILE" "\"no_real_crm_system_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "feedback status ready marker" "$FEEDBACK_FILE" "\"feedback_channel_status\": \"READY\""
  check_contains "feedback controlled pilot marker" "$FEEDBACK_FILE" "\"feedback_channel_mode\": \"CONTROLLED_PILOT\""
  check_contains "feedback pilot user marker" "$FEEDBACK_FILE" "PILOT_USER_FEEDBACK_FORM"
  check_contains "feedback in app marker" "$FEEDBACK_FILE" "IN_APP_FEEDBACK_ENTRY"
  check_contains "feedback support triage marker" "$FEEDBACK_FILE" "SUPPORT_TRIAGE_FEEDBACK_CAPTURE"
  check_contains "feedback UAT marker" "$FEEDBACK_FILE" "UAT_FEEDBACK_CAPTURE"
  check_contains "feedback category marker" "$FEEDBACK_FILE" "FEEDBACK_CATEGORY_MAPPING"
  check_contains "feedback priority marker" "$FEEDBACK_FILE" "FEEDBACK_PRIORITY_MAPPING"
  check_contains "feedback owner routing marker" "$FEEDBACK_FILE" "FEEDBACK_OWNER_ROUTING"
  check_contains "feedback privacy marker" "$FEEDBACK_FILE" "FEEDBACK_PRIVACY_POLICY_GUARD"
  check_contains "feedback no real CRM marker" "$FEEDBACK_FILE" "\"no_real_crm_system\": true"
  check_contains "feedback closed policy reference marker" "$FEEDBACK_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime feedback file guard marker" "$RUNTIME_SCRIPT" "FEEDBACK_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "CHANNEL_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required channel guard marker" "$RUNTIME_SCRIPT" "REQUIRED_FEEDBACK_CHANNEL_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_FEEDBACK_CHANNEL_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_CHANNEL_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime privacy guard marker" "$RUNTIME_SCRIPT" "FEEDBACK_PRIVACY_POLICY_STATUS_NOT_READY"
  check_contains "runtime CRM disabled guard marker" "$RUNTIME_SCRIPT" "REAL_CRM_SYSTEM_NOT_DISABLED"
  check_contains "runtime ticket disabled guard marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_DISABLED"
  check_contains "runtime email disabled guard marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "FEEDBACK_COLLECTION_CHANNEL_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "FEEDBACK_COLLECTION_CHANNEL_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test feedback channels marker" "$TEST_FILE" "\"feedback_channels\""
  check_contains "test feedback controls marker" "$TEST_FILE" "\"feedback_controls\""
  check_contains "test feedback metrics marker" "$TEST_FILE" "\"feedback_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 221 — FAZ 4-16.6.1 FEEDBACK TOPLAMA KANALI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_DOC_STATUS=READY"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_TEST_STATUS=PASS"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_6_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_6_1_FEEDBACK_TOPLAMA_KANALI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_6_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
