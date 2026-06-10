#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS.md"
CONFIG_FILE="configs/faz4r/faz_4_16_7_1_dry_run_canliya_gecis.v1.json"
DRY_RUN_FILE="configs/faz4r/dry_run_go_live.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_dry_run_go_live.sh"
TEST_FILE="tests/faz4r/faz_4_16_7_1_dry_run_canliya_gecis_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_7_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_7_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_7_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_7_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" DRY_RUN_FILE="$DRY_RUN_FILE" INPUT_FILE="$DRY_RUN_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "DRY_RUN_GO_LIVE_STATUS=PASS" "$valid_out" && record_pass "main dry-run go-live artifact PASS" || { record_fail "main dry-run go-live artifact PASS"; cat "$valid_out" || true; }
  else
    record_fail "main dry-run go-live artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" DRY_RUN_FILE="$DRY_RUN_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    grep -Fq "DRY_RUN_GO_LIVE_STATUS=PASS" "$valid_out" && record_pass "valid dry-run go-live fixture PASS" || { record_fail "valid dry-run go-live fixture PASS"; cat "$valid_out" || true; }
  else
    record_fail "valid dry-run go-live fixture execution"
    cat "$valid_out" || true
  fi

  grep -Fq "DRY_RUN_GO_LIVE_TOTAL_RULE_COUNT=15" "$valid_out" && record_pass "valid dry-run total rule count" || record_fail "valid dry-run total rule count"
  grep -Fq "DRY_RUN_GO_LIVE_READY_RULE_COUNT=15" "$valid_out" && record_pass "valid dry-run ready rule count" || record_fail "valid dry-run ready rule count"
  grep -Fq "DRY_RUN_GO_LIVE_MISSING_RULE_COUNT=0" "$valid_out" && record_pass "valid dry-run missing rule zero" || record_fail "valid dry-run missing rule zero"
  grep -Fq "NO_PRODUCTION_LAUNCH=true" "$valid_out" && record_pass "valid no production launch guard" || record_fail "valid no production launch guard"
  grep -Fq "NO_DNS_CHANGE=true" "$valid_out" && record_pass "valid no DNS change guard" || record_fail "valid no DNS change guard"
  grep -Fq "NO_NGINX_CHANGE=true" "$valid_out" && record_pass "valid no Nginx change guard" || record_fail "valid no Nginx change guard"

  if CONFIG_FILE="$CONFIG_FILE" DRY_RUN_FILE="$DRY_RUN_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid dry-run go-live fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "DRY_RUN_GO_LIVE_STATUS=FAIL" "$invalid_out" && record_pass "invalid dry-run go-live fixture FAIL guard" || { record_fail "invalid dry-run go-live fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "DRY_RUN_GO_LIVE_FAIL=DRY_RUN_MODE_NOT_CONTROLLED_PILOT" "$invalid_out" && record_pass "controlled pilot dry-run mode guard" || record_fail "controlled pilot dry-run mode guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:225_FAZ_4_16_6_5_FEEDBACK_CLOSURE" "$invalid_out" && record_pass "feedback closure dependency guard" || record_fail "feedback closure dependency guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=REQUIRED_DRY_RUN_RULE_NOT_READY:DRY_RUN_KICKOFF" "$invalid_out" && record_pass "required dry-run rule ready guard" || record_fail "required dry-run rule ready guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=REQUIRED_EVIDENCE_MISSING:DRY_RUN_KICKOFF" "$invalid_out" && record_pass "required evidence guard" || record_fail "required evidence guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=REQUIRED_DRY_RUN_RULES_MISSING" "$invalid_out" && record_pass "missing required dry-run rules guard" || record_fail "missing required dry-run rules guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=DUPLICATE_DRY_RUN_RULE_CODE_FOUND" "$invalid_out" && record_pass "duplicate dry-run rule guard" || record_fail "duplicate dry-run rule guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out" && record_pass "total rule count reconciliation guard" || record_fail "total rule count reconciliation guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "missing rule zero guard" || record_fail "missing rule zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "critical issue zero guard" || record_fail "critical issue zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out" && record_pass "open blocker zero guard" || record_fail "open blocker zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=TENANT_READINESS_STATUS_NOT_READY" "$invalid_out" && record_pass "tenant readiness guard" || record_fail "tenant readiness guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=IMPORT_CLOSURE_STATUS_NOT_READY" "$invalid_out" && record_pass "import closure guard" || record_fail "import closure guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=UAT_CLOSURE_STATUS_NOT_READY" "$invalid_out" && record_pass "UAT closure guard" || record_fail "UAT closure guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=BACKUP_SNAPSHOT_STATUS_NOT_READY" "$invalid_out" && record_pass "backup snapshot guard" || record_fail "backup snapshot guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=ROLLBACK_READINESS_STATUS_NOT_READY" "$invalid_out" && record_pass "rollback readiness guard" || record_fail "rollback readiness guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=MONITORING_STATUS_NOT_READY" "$invalid_out" && record_pass "monitoring readiness guard" || record_fail "monitoring readiness guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=PRODUCTION_LAUNCH_NOT_DISABLED" "$invalid_out" && record_pass "production launch disabled guard" || record_fail "production launch disabled guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=DNS_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "DNS change disabled guard" || record_fail "DNS change disabled guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=NGINX_CHANGE_NOT_DISABLED" "$invalid_out" && record_pass "Nginx change disabled guard" || record_fail "Nginx change disabled guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_NOT_DISABLED" "$invalid_out" && record_pass "external provider activation disabled guard" || record_fail "external provider activation disabled guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=PRODUCTION_LAUNCH_COUNT_NOT_ZERO" "$invalid_out" && record_pass "production launch count zero guard" || record_fail "production launch count zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=DNS_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "DNS change count zero guard" || record_fail "DNS change count zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=NGINX_CHANGE_COUNT_NOT_ZERO" "$invalid_out" && record_pass "Nginx change count zero guard" || record_fail "Nginx change count zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=LIVE_EXTERNAL_PROVIDER_ACTIVATION_COUNT_NOT_ZERO" "$invalid_out" && record_pass "external provider activation count zero guard" || record_fail "external provider activation count zero guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out" && record_pass "live external provider closed guard" || record_fail "live external provider closed guard"
  grep -Fq "DRY_RUN_GO_LIVE_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out" && record_pass "production launch closed guard" || record_fail "production launch closed guard"

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 226 — FAZ 4-16.7.1 DRY-RUN CANLIYA GECIS REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "dry-run go-live file exists" "$DRY_RUN_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "dry-run kickoff doc exists" "docs/faz4r/dry_run_go_live/dry_run_kickoff.md"
  check_file "tenant readiness gate doc exists" "docs/faz4r/dry_run_go_live/tenant_readiness_gate.md"
  check_file "rollback readiness doc exists" "docs/faz4r/dry_run_go_live/rollback_readiness.md"
  check_file "dry-run final report doc exists" "docs/faz4r/dry_run_go_live/dry_run_final_report.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.7.1 Dry-run Canlıya Geçiş"
  check_contains "doc dry-run marker" "$DOC_FILE" "Dry-run kickoff"
  check_contains "doc no production marker" "$DOC_FILE" "no_production_launch = true"
  check_contains "doc no DNS marker" "$DOC_FILE" "no_dns_change = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 226"
  check_contains "config dependency 225 marker" "$CONFIG_FILE" "225_FAZ_4_16_6_5_FEEDBACK_CLOSURE"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"dry_run_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config no production marker" "$CONFIG_FILE" "\"no_production_launch_required\": true"
  check_contains "config no DNS marker" "$CONFIG_FILE" "\"no_dns_change_required\": true"
  check_contains "config no Nginx marker" "$CONFIG_FILE" "\"no_nginx_change_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "dry-run status ready marker" "$DRY_RUN_FILE" "\"dry_run_status\": \"READY\""
  check_contains "dry-run controlled pilot marker" "$DRY_RUN_FILE" "\"dry_run_mode\": \"CONTROLLED_PILOT\""
  check_contains "dry-run kickoff marker" "$DRY_RUN_FILE" "DRY_RUN_KICKOFF"
  check_contains "tenant readiness marker" "$DRY_RUN_FILE" "TENANT_READINESS_GATE"
  check_contains "import closure marker" "$DRY_RUN_FILE" "IMPORT_CLOSURE_GATE"
  check_contains "readmodel readiness marker" "$DRY_RUN_FILE" "READMODEL_REPORTING_READINESS_GATE"
  check_contains "UAT closure marker" "$DRY_RUN_FILE" "UAT_CLOSURE_GATE"
  check_contains "backup snapshot marker" "$DRY_RUN_FILE" "BACKUP_SNAPSHOT_READINESS"
  check_contains "rollback readiness marker" "$DRY_RUN_FILE" "ROLLBACK_READINESS"
  check_contains "DNS Nginx marker" "$DRY_RUN_FILE" "DNS_NGINX_ROUTE_DRY_RUN_CHECK"
  check_contains "monitoring marker" "$DRY_RUN_FILE" "MONITORING_DASHBOARD_DRY_RUN_CHECK"
  check_contains "dry-run no production marker" "$DRY_RUN_FILE" "\"no_production_launch\": true"
  check_contains "dry-run no DNS marker" "$DRY_RUN_FILE" "\"no_dns_change\": true"
  check_contains "dry-run no Nginx marker" "$DRY_RUN_FILE" "\"no_nginx_change\": true"
  check_contains "dry-run closed policy reference marker" "$DRY_RUN_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime dry-run file guard marker" "$RUNTIME_SCRIPT" "DRY_RUN_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "DRY_RUN_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_DRY_RUN_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_DRY_RUN_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime no production guard marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_DISABLED"
  check_contains "runtime no DNS guard marker" "$RUNTIME_SCRIPT" "DNS_CHANGE_NOT_DISABLED"
  check_contains "runtime no Nginx guard marker" "$RUNTIME_SCRIPT" "NGINX_CHANGE_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "DRY_RUN_GO_LIVE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "DRY_RUN_GO_LIVE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test dry-run rules marker" "$TEST_FILE" "\"dry_run_rules\""
  check_contains "test dry-run controls marker" "$TEST_FILE" "\"dry_run_controls\""
  check_contains "test dry-run metrics marker" "$TEST_FILE" "\"dry_run_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 226 — FAZ 4-16.7.1 DRY-RUN CANLIYA GECIS COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_DOC_STATUS=READY"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_CONFIG_STATUS=READY"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_TEST_STATUS=PASS"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_FINAL_STATUS=PASS"
    echo "FAZ_4_16_7_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_TEST_STATUS=FAIL"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_7_1_DRY_RUN_CANLIYA_GECIS_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_7_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
