#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_7_3_GERI_DONUS_PROVASI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_7_3_geri_donus_provasi.v1.json"
ROLLBACK_FILE="configs/faz4r/rollback_rehearsal.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_rollback_rehearsal.sh"
TEST_FILE="tests/faz4r/faz_4_16_7_3_geri_donus_provasi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_7_3_GERI_DONUS_PROVASI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_7_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_7_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_7_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_7_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$ROLLBACK_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "ROLLBACK_REHEARSAL_STATUS=PASS" "$valid_out" && record_pass "main rollback rehearsal artifact PASS" || { record_fail "main rollback rehearsal artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main rollback rehearsal artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "ROLLBACK_REHEARSAL_STATUS=PASS" "$valid_out" && record_pass "valid rollback rehearsal fixture PASS" || { record_fail "valid rollback rehearsal fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid rollback rehearsal fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "ROLLBACK_REHEARSAL_TOTAL_ITEM_COUNT=16" "$valid_out" && record_pass "valid rollback rehearsal total item count" || record_fail "valid rollback rehearsal total item count"
  grep -Fq "ROLLBACK_REHEARSAL_READY_ITEM_COUNT=16" "$valid_out" && record_pass "valid rollback rehearsal ready item count" || record_fail "valid rollback rehearsal ready item count"
  grep -Fq "ROLLBACK_REHEARSAL_MISSING_ITEM_COUNT=0" "$valid_out" && record_pass "valid rollback rehearsal missing item zero" || record_fail "valid rollback rehearsal missing item zero"
  grep -Fq "NO_REAL_ROLLBACK_EXECUTION=true" "$valid_out" && record_pass "valid no real rollback execution guard" || record_fail "valid no real rollback execution guard"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"
  grep -Fq "NO_DNS_CHANGE=true" "$valid_out" && record_pass "valid no DNS change guard" || record_fail "valid no DNS change guard"
  grep -Fq "NO_NGINX_CHANGE=true" "$valid_out" && record_pass "valid no Nginx change guard" || record_fail "valid no Nginx change guard"
  grep -Fq "NO_SSL_CHANGE=true" "$valid_out" && record_pass "valid no SSL change guard" || record_fail "valid no SSL change guard"

  if CONFIG_FILE="$CONFIG_FILE" ROLLBACK_FILE="$ROLLBACK_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid rollback rehearsal fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "ROLLBACK_REHEARSAL_STATUS=FAIL" "$invalid_out" && record_pass "invalid rollback rehearsal fixture FAIL guard" || { record_fail "invalid rollback rehearsal fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "ROLLBACK_REHEARSAL_FAIL=ROLLBACK_REHEARSAL_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot rollback rehearsal mode guard" || record_fail "controlled pilot rollback rehearsal mode guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=CHAIN_DEPENDENCY_NOT_PASS:227_FAZ_4_16_7_2_CUTOVER_CHECKLIST" "$invalid_out" && record_pass "cutover checklist dependency guard" || record_fail "cutover checklist dependency guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REQUIRED_REHEARSAL_ITEM_NOT_READY:ROLLBACK_REHEARSAL_KICKOFF" "$invalid_out" && record_pass "required rehearsal item ready guard" || record_fail "required rehearsal item ready guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REQUIRED_EVIDENCE_MISSING:ROLLBACK_REHEARSAL_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REQUIRED_REHEARSAL_ITEMS_MISSING" "$invalid_out" && record_pass "missing required rehearsal items guard" || record_fail "missing required rehearsal items guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=DUPLICATE_REHEARSAL_ITEM_CODE_FOUND" "$invalid_out" && record_pass "duplicate rehearsal item guard" || record_fail "duplicate rehearsal item guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=TOTAL_ITEM_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total item count reconciliation guard" || record_fail "total item count reconciliation guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=MISSING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing item zero guard" || record_fail "missing item zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=BACKUP_SNAPSHOT_STATUS_NOT_READY" "$invalid_out" && record_pass "backup snapshot guard" || record_fail "backup snapshot guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=ROLLBACK_PACKAGE_STATUS_NOT_READY" "$invalid_out" && record_pass "rollback package guard" || record_fail "rollback package guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=DATA_RESTORE_PLAN_STATUS_NOT_READY" "$invalid_out" && record_pass "data restore plan guard" || record_fail "data restore plan guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=APP_RESTORE_PLAN_STATUS_NOT_READY" "$invalid_out" && record_pass "app restore plan guard" || record_fail "app restore plan guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=ROUTE_ROLLBACK_PLAN_STATUS_NOT_READY" "$invalid_out" && record_pass "route rollback plan guard" || record_fail "route rollback plan guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=RUNTIME_HEALTH_AFTER_ROLLBACK_STATUS_NOT_READY" "$invalid_out" && record_pass "runtime health after rollback guard" || record_fail "runtime health after rollback guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=MONITORING_AFTER_ROLLBACK_STATUS_NOT_READY" "$invalid_out" && record_pass "monitoring after rollback guard" || record_fail "monitoring after rollback guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=SUPPORT_COMMUNICATION_STATUS_NOT_READY" "$invalid_out" && record_pass "support communication guard" || record_fail "support communication guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=APPROVAL_OWNER_STATUS_NOT_READY" "$invalid_out" && record_pass "approval owner guard" || record_fail "approval owner guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REAL_ROLLBACK_EXECUTION_NOT_DISABLED" "$invalid_out" && record_pass "real rollback execution disabled guard" || record_fail "real rollback execution disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=DNS_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "DNS change disabled guard" || record_fail "DNS change disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=NGINX_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "Nginx change disabled guard" || record_fail "Nginx change disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=SSL_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "SSL change disabled guard" || record_fail "SSL change disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "external provider activation disabled guard" || record_fail "external provider activation disabled guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REAL_ROLLBACK_EXECUTION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "real rollback execution count zero guard" || record_fail "real rollback execution count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=PRODUCTION_LAUNCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "production launch count zero guard" || record_fail "production launch count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=DNS_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "DNS change count zero guard" || record_fail "DNS change count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=NGINX_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "Nginx change count zero guard" || record_fail "Nginx change count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=SSL_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "SSL change count zero guard" || record_fail "SSL change count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "external provider activation count zero guard" || record_fail "external provider activation count zero guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"
  grep -Fq "ROLLBACK_REHEARSAL_FAIL=REAL_ROLLBACK_EXECUTION_NOT_CLOSED" "$invalid_out" && record_pass "real rollback execution closed guard" || record_fail "real rollback execution closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 228 — FAZ 4-16.7.3 GERI DONUS PROVASI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "rollback rehearsal file exists" "$ROLLBACK_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "rollback rehearsal kickoff doc exists" "docs/faz4r/rollback_rehearsal/rollback_rehearsal_kickoff.md"
  check_file "backup snapshot link doc exists" "docs/faz4r/rollback_rehearsal/backup_snapshot_link.md"
  check_file "rollback package link doc exists" "docs/faz4r/rollback_rehearsal/rollback_package_link.md"
  check_file "final rollback rehearsal report doc exists" "docs/faz4r/rollback_rehearsal/final_rollback_rehearsal_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.7.3 Geri Dönüş Provası"
  check_contains "doc rollback kickoff marker" "$DOC_FILE" "Rollback rehearsal kickoff"
  check_contains "doc no real rollback marker" "$DOC_FILE" "no_real_rollback_execution = true"
  check_contains "doc no production marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 228"
  check_contains "config dependency 227 marker" "$CONFIG_FILE" "227_FAZ_4_16_7_2_CUTOVER_CHECKLIST"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"rollback_rehearsal_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required item marker" "$CONFIG_FILE" "\"required_item_status_required\": \"READY\""
  check_contains "config missing item zero marker" "$CONFIG_FILE" "\"missing_item_count_required\": 0"
  check_contains "config no real rollback marker" "$CONFIG_FILE" "\"no_real_rollback_execution_required\": true"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no DNS marker" "$CONFIG_FILE" "\"no_dns_change_required\": true"
  check_contains "config no Nginx marker" "$CONFIG_FILE" "\"no_nginx_change_required\": true"
  check_contains "config no SSL marker" "$CONFIG_FILE" "\"no_ssl_change_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "rollback status ready marker" "$ROLLBACK_FILE" "\"rollback_rehearsal_status\": \"READY\""
  check_contains "rollback controlled pilot marker" "$ROLLBACK_FILE" "\"rollback_rehearsal_mode\": \"CONTROLLED_PILOT\""
  check_contains "rollback kickoff marker" "$ROLLBACK_FILE" "ROLLBACK_REHEARSAL_KICKOFF"
  check_contains "cutover checklist link marker" "$ROLLBACK_FILE" "CUTOVER_CHECKLIST_LINK"
  check_contains "backup snapshot marker" "$ROLLBACK_FILE" "BACKUP_SNAPSHOT_LINK"
  check_contains "rollback package marker" "$ROLLBACK_FILE" "ROLLBACK_PACKAGE_LINK"
  check_contains "data restore marker" "$ROLLBACK_FILE" "DATA_RESTORE_DRY_RUN_PLAN"
  check_contains "app restore marker" "$ROLLBACK_FILE" "APP_VERSION_RESTORE_DRY_RUN_PLAN"
  check_contains "route rollback marker" "$ROLLBACK_FILE" "ROUTE_DNS_NGINX_ROLLBACK_PLAN"
  check_contains "runtime health marker" "$ROLLBACK_FILE" "RUNTIME_HEALTH_AFTER_ROLLBACK_PLAN"
  check_contains "monitoring marker" "$ROLLBACK_FILE" "MONITORING_WATCH_AFTER_ROLLBACK_PLAN"
  check_contains "rollback no real rollback marker" "$ROLLBACK_FILE" "\"no_real_rollback_execution\": true"
  check_contains "rollback no production marker" "$ROLLBACK_FILE" "\"no_production_launch\": true"
  check_contains "rollback no DNS marker" "$ROLLBACK_FILE" "\"no_dns_change\": true"
  check_contains "rollback no Nginx marker" "$ROLLBACK_FILE" "\"no_nginx_change\": true"
  check_contains "rollback no SSL marker" "$ROLLBACK_FILE" "\"no_ssl_change\": true"
  check_contains "rollback closed policy reference marker" "$ROLLBACK_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime rollback file guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "ROLLBACK_REHEARSAL_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required item guard marker" "$RUNTIME_SCRIPT" "REQUIRED_REHEARSAL_ITEM_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_REHEARSAL_ITEM_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no real rollback guard marker" "$RUNTIME_SCRIPT" "REAL_ROLLBACK_EXECUTION_NOT_DISABLED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no DNS guard marker" "$RUNTIME_SCRIPT" "DNS_CHANGE_NOT_DISABLED"
  check_contains "runtime no Nginx guard marker" "$RUNTIME_SCRIPT" "NGINX_CHANGE_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "ROLLBACK_REHEARSAL_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "ROLLBACK_REHEARSAL_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test rehearsal items marker" "$TEST_FILE" "\"rehearsal_items\""
  check_contains "test rollback controls marker" "$TEST_FILE" "\"rollback_controls\""
  check_contains "test rollback metrics marker" "$TEST_FILE" "\"rollback_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 228 — FAZ 4-16.7.3 GERI DONUS PROVASI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_DOC_STATUS=READY"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_TEST_STATUS=PASS"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_7_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_7_3_GERI_DONUS_PROVASI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_7_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
