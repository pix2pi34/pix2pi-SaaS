#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_7_2_CUTOVER_CHECKLIST.md"
CONFIG_FILE="configs/faz4r/faz_4_16_7_2_cutover_checklist.v1.json"
CUTOVER_FILE="configs/faz4r/cutover_checklist.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_cutover_checklist.sh"
TEST_FILE="tests/faz4r/faz_4_16_7_2_cutover_checklist_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_7_2_CUTOVER_CHECKLIST_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_7_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_7_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_7_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_7_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CUTOVER_FILE="$CUTOVER_FILE" INPUT_FILE="$CUTOVER_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "CUTOVER_CHECKLIST_STATUS=PASS" "$valid_out" && record_pass "main cutover checklist artifact PASS" || { record_fail "main cutover checklist artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main cutover checklist artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" CUTOVER_FILE="$CUTOVER_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "CUTOVER_CHECKLIST_STATUS=PASS" "$valid_out" && record_pass "valid cutover checklist fixture PASS" || { record_fail "valid cutover checklist fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid cutover checklist fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "CUTOVER_CHECKLIST_TOTAL_ITEM_COUNT=16" "$valid_out" && record_pass "valid cutover total item count" || record_fail "valid cutover total item count"
  grep -Fq "CUTOVER_CHECKLIST_READY_ITEM_COUNT=16" "$valid_out" && record_pass "valid cutover ready item count" || record_fail "valid cutover ready item count"
  grep -Fq "CUTOVER_CHECKLIST_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid cutover missing item zero" || record_fail "valid cutover missing item zero"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"
  grep -Fq "NO_DNS_CHANGE=true" "$valid_out" && record_pass "valid no DNS change guard" || record_fail "valid no DNS change guard"
  grep -Fq "NO_NGINX_CHANGE=true" "$valid_out" && record_pass "valid no Nginx change guard" || record_fail "valid no Nginx change guard"
  grep -Fq "NO_SSL_CHANGE=true" "$valid_out" && record_pass "valid no SSL change guard" || record_fail "valid no SSL change guard"

  if CONFIG_FILE="$CONFIG_FILE" CUTOVER_FILE="$CUTOVER_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid cutover checklist fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "CUTOVER_CHECKLIST_STATUS=FAIL" "$invalid_out" && record_pass "invalid cutover checklist fixture FAIL guard" || { record_fail "invalid cutover checklist fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "CUTOVER_CHECKLIST_FAIL=CUTOVER_CHECKLIST_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot cutover mode guard" || record_fail "controlled pilot cutover mode guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=CHAIN_DEPENDENCY_NOT_PASS:226_FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS" "$invalid_out" && record_pass "dry-run dependency guard" || record_fail "dry-run dependency guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=REQUIRED_CUTOVER_ITEM_NOT_READY:CUTOVER_KICKOFF_CHECKLIST" "$invalid_out" && record_pass "required cutover item ready guard" || record_fail "required cutover item ready guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=REQUIRED_EVIDENCE_MISSING:CUTOVER_KICKOFF_CHECKLIST" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=REQUIRED_CUTOVER_ITEMS_MISSING" "$invalid_out" && record_pass "missing required cutover items guard" || record_fail "missing required cutover items guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=DUPLICATE_CUTOVER_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate cutover item guard" || record_fail "duplicate cutover item guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=BACKUP_SNAPSHOT_STATUS_NOT_READY" "$invalid_out" && record_pass "backup snapshot guard" || record_fail "backup snapshot guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=ROLLBACK_PACKAGE_STATUS_NOT_READY" "$invalid_out" && record_pass "rollback package guard" || record_fail "rollback package guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=ROUTE_PLAN_STATUS_NOT_READY" "$invalid_out" && record_pass "route plan guard" || record_fail "route plan guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=RUNTIME_HEALTH_STATUS_NOT_READY" "$invalid_out" && record_pass "runtime health guard" || record_fail "runtime health guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=MONITORING_WATCH_STATUS_NOT_READY" "$invalid_out" && record_pass "monitoring watch guard" || record_fail "monitoring watch guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=SUPPORT_WATCH_STATUS_NOT_READY" "$invalid_out" && record_pass "support watch guard" || record_fail "support watch guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=COMMUNICATION_PLAN_STATUS_NOT_READY" "$invalid_out" && record_pass "communication plan guard" || record_fail "communication plan guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=APPROVAL_OWNER_STATUS_NOT_READY" "$invalid_out" && record_pass "approval owner guard" || record_fail "approval owner guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=DNS_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "DNS change disabled guard" || record_fail "DNS change disabled guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=NGINX_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "Nginx change disabled guard" || record_fail "Nginx change disabled guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=SSL_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "SSL change disabled guard" || record_fail "SSL change disabled guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "external provider activation disabled guard" || record_fail "external provider activation disabled guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=PRODUCTION_LAUNCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "production launch count zero guard" || record_fail "production launch count zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=DNS_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "DNS change count zero guard" || record_fail "DNS change count zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=NGINX_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "Nginx change count zero guard" || record_fail "Nginx change count zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=SSL_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "SSL change count zero guard" || record_fail "SSL change count zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "external provider activation count zero guard" || record_fail "external provider activation count zero guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"
  grep -Fq "CUTOVER_CHECKLIST_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out" && record_pass "production launch closed guard" || record_fail "production launch closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 227 — FAZ 4-16.7.2 CUTOVER CHECKLIST REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "cutover checklist file exists" "$CUTOVER_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "cutover kickoff doc exists" "docs/faz4r/cutover_checklist/cutover_kickoff_checklist.md"
  check_file "backup snapshot doc exists" "docs/faz4r/cutover_checklist/backup_snapshot_confirmation.md"
  check_file "rollback package doc exists" "docs/faz4r/cutover_checklist/rollback_package_confirmation.md"
  check_file "final checklist report doc exists" "docs/faz4r/cutover_checklist/final_checklist_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.7.2 Cutover Checklist"
  check_contains "doc kickoff marker" "$DOC_FILE" "Cutover kickoff checklist"
  check_contains "doc no production marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc no DNS marker" "$DOC_FILE" "no_dns_change = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 227"
  check_contains "config dependency 226 marker" "$CONFIG_FILE" "226_FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"cutover_checklist_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no DNS marker" "$CONFIG_FILE" "\"no_dns_change_required\": true"
  check_contains "config no Nginx marker" "$CONFIG_FILE" "\"no_nginx_change_required\": true"
  check_contains "config no SSL marker" "$CONFIG_FILE" "\"no_ssl_change_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "cutover status ready marker" "$CUTOVER_FILE" "\"cutover_checklist_status\": \"READY\""
  check_contains "cutover controlled pilot marker" "$CUTOVER_FILE" "\"cutover_checklist_mode\": \"CONTROLLED_PILOT\""
  check_contains "cutover kickoff marker" "$CUTOVER_FILE" "CUTOVER_KICKOFF_CHECKLIST"
  check_contains "dry-run result link marker" "$CUTOVER_FILE" "DRY_RUN_RESULT_LINK"
  check_contains "tenant readiness marker" "$CUTOVER_FILE" "TENANT_READINESS_CONFIRMATION"
  check_contains "backup marker" "$CUTOVER_FILE" "BACKUP_SNAPSHOT_CONFIRMATION"
  check_contains "rollback marker" "$CUTOVER_FILE" "ROLLBACK_PACKAGE_CONFIRMATION"
  check_contains "route marker" "$CUTOVER_FILE" "ROUTE_DNS_NGINX_PLAN_CONFIRMATION"
  check_contains "monitoring marker" "$CUTOVER_FILE" "MONITORING_WATCH_CONFIRMATION"
  check_contains "support marker" "$CUTOVER_FILE" "SUPPORT_WATCH_CONFIRMATION"
  check_contains "approval marker" "$CUTOVER_FILE" "APPROVAL_OWNER_CONFIRMATION"
  check_contains "cutover no production marker" "$CUTOVER_FILE" "\"no_production_launch\": true"
  check_contains "cutover no DNS marker" "$CUTOVER_FILE" "\"no_dns_change\": true"
  check_contains "cutover no Nginx marker" "$CUTOVER_FILE" "\"no_nginx_change\": true"
  check_contains "cutover no SSL marker" "$CUTOVER_FILE" "\"no_ssl_change\": true"
  check_contains "cutover closed policy reference marker" "$CUTOVER_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime cutover file guard marker" "$RUNTIME_SCRIPT" "CUTOVER_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "CUTOVER_CHECKLIST_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_CUTOVER_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_CUTOVER_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no DNS guard marker" "$RUNTIME_SCRIPT" "DNS_CHANGE_NOT_DISABLED"
  check_contains "runtime no Nginx guard marker" "$RUNTIME_SCRIPT" "NGINX_CHANGE_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "CUTOVER_CHECKLIST_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "CUTOVER_CHECKLIST_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test cutover items marker" "$TEST_FILE" "\"cutover_items\""
  check_contains "test cutover controls marker" "$TEST_FILE" "\"cutover_controls\""
  check_contains "test cutover metrics marker" "$TEST_FILE" "\"cutover_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 227 — FAZ 4-16.7.2 CUTOVER CHECKLIST COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_DOC_STATUS=READY"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_CONFIG_STATUS=READY"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_TEST_STATUS=PASS"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_FINAL_STATUS=PASS"
    echo "FAZ_4_16_7_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_TEST_STATUS=FAIL"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_7_2_CUTOVER_CHECKLIST_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_7_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
