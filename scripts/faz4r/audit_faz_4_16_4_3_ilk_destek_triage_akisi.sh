#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_4_3_ilk_destek_triage_akisi.v1.json"
TRIAGE_FILE="configs/faz4r/initial_support_triage_flow.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_initial_support_triage_flow.sh"
TEST_FILE="tests/faz4r/faz_4_16_4_3_ilk_destek_triage_akisi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_4_3_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_4_3_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_4_3_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_4_3_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" TRIAGE_FILE="$TRIAGE_FILE" INPUT_FILE="$TRIAGE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "INITIAL_SUPPORT_TRIAGE_STATUS=PASS" "$valid_out"; then
      record_pass "main initial support triage artifact PASS"
    else
      record_fail "main initial support triage artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main initial support triage artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TRIAGE_FILE="$TRIAGE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "INITIAL_SUPPORT_TRIAGE_STATUS=PASS" "$valid_out"; then
      record_pass "valid initial support triage fixture PASS"
    else
      record_fail "valid initial support triage fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid initial support triage fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_TOTAL_FLOW_COUNT=15" "$valid_out"; then
    record_pass "valid initial support triage total flow count"
  else
    record_fail "valid initial support triage total flow count"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_READY_FLOW_COUNT=15" "$valid_out"; then
    record_pass "valid initial support triage ready flow count"
  else
    record_fail "valid initial support triage ready flow count"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_MISSING_FLOW_COUNT=0" "$valid_out"; then
    record_pass "valid initial support triage missing flow zero"
  else
    record_fail "valid initial support triage missing flow zero"
  fi

  if grep -Fq "NO_REAL_EXTERNAL_DISPATCH=true" "$valid_out"; then
    record_pass "valid no real external dispatch guard"
  else
    record_fail "valid no real external dispatch guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" TRIAGE_FILE="$TRIAGE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid initial support triage fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "INITIAL_SUPPORT_TRIAGE_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid initial support triage fixture FAIL guard"
    else
      record_fail "invalid initial support triage fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=TRIAGE_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot triage mode guard"
  else
    record_fail "controlled pilot triage mode guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=CHAIN_DEPENDENCY_NOT_PASS:211_FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI" "$invalid_out"; then
    record_pass "help center dependency guard"
  else
    record_fail "help center dependency guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REQUIRED_TRIAGE_FLOW_NOT_READY:SUPPORT_INTAKE_FORM" "$invalid_out"; then
    record_pass "required triage flow ready guard"
  else
    record_fail "required triage flow ready guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REQUIRED_EVIDENCE_MISSING:SUPPORT_INTAKE_FORM" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REQUIRED_TRIAGE_FLOWS_MISSING" "$invalid_out"; then
    record_pass "missing required triage flows guard"
  else
    record_fail "missing required triage flows guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=DUPLICATE_TRIAGE_FLOW_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate triage flow guard"
  else
    record_fail "duplicate triage flow guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=TOTAL_FLOW_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total flow count reconciliation guard"
  else
    record_fail "total flow count reconciliation guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=MISSING_FLOW_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing flow zero guard"
  else
    record_fail "missing flow zero guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=INTAKE_CHANNEL_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "intake channel ready guard"
  else
    record_fail "intake channel ready guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=SEVERITY_MATRIX_MISSING_REQUIRED_LEVELS" "$invalid_out"; then
    record_pass "severity matrix required levels guard"
  else
    record_fail "severity matrix required levels guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REAL_EXTERNAL_DISPATCH_NOT_DISABLED" "$invalid_out"; then
    record_pass "real external dispatch disabled guard"
  else
    record_fail "real external dispatch disabled guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REAL_TICKET_SYSTEM_NOT_CLOSED" "$invalid_out"; then
    record_pass "real ticket system closed guard"
  else
    record_fail "real ticket system closed guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=REAL_EMAIL_DISPATCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "real email dispatch closed guard"
  else
    record_fail "real email dispatch closed guard"
  fi

  if grep -Fq "INITIAL_SUPPORT_TRIAGE_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 212 — FAZ 4-16.4.3 ILK DESTEK TRIAGE AKISI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "triage file exists" "$TRIAGE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "support intake form doc exists" "docs/faz4r/support_triage/support_intake_form.md"
  check_file "severity matrix doc exists" "docs/faz4r/support_triage/response_sla_matrix.md"
  check_file "evidence attachment rule doc exists" "docs/faz4r/support_triage/evidence_attachment_rule.md"
  check_file "closed provider policy route doc exists" "docs/faz4r/support_triage/closed_provider_policy_route.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.4.3 İlk Destek Triage Akışı"
  check_contains "doc support intake marker" "$DOC_FILE" "Destek intake formu"
  check_contains "doc severity marker" "$DOC_FILE" "P0 blocker"
  check_contains "doc SLA marker" "$DOC_FILE" "response_sla_status = READY"
  check_contains "doc no real dispatch marker" "$DOC_FILE" "no_real_external_dispatch = true"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 212"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 210 marker" "$CONFIG_FILE" "210_FAZ_4_16_4_1_KULLANICI_EGITIM_SETI"
  check_contains "config dependency 211 marker" "$CONFIG_FILE" "211_FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"triage_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config flow ready marker" "$CONFIG_FILE" "\"required_flow_status_required\": \"READY\""
  check_contains "config missing flow zero marker" "$CONFIG_FILE" "\"missing_flow_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config intake channel marker" "$CONFIG_FILE" "\"intake_channel_status_required\": \"READY\""
  check_contains "config severity matrix marker" "$CONFIG_FILE" "\"severity_matrix_status_required\": \"READY\""
  check_contains "config no real dispatch marker" "$CONFIG_FILE" "\"no_real_external_dispatch_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "triage status ready marker" "$TRIAGE_FILE" "\"triage_status\": \"READY\""
  check_contains "triage controlled pilot marker" "$TRIAGE_FILE" "\"triage_mode\": \"CONTROLLED_PILOT\""
  check_contains "triage support intake marker" "$TRIAGE_FILE" "SUPPORT_INTAKE_FORM"
  check_contains "triage issue classification marker" "$TRIAGE_FILE" "ISSUE_CLASSIFICATION"
  check_contains "triage P0 marker" "$TRIAGE_FILE" "SEVERITY_P0_BLOCKER"
  check_contains "triage P1 marker" "$TRIAGE_FILE" "SEVERITY_P1_CRITICAL"
  check_contains "triage product owner route marker" "$TRIAGE_FILE" "ROUTE_TO_PRODUCT_OWNER"
  check_contains "triage tech owner route marker" "$TRIAGE_FILE" "ROUTE_TO_TECH_OWNER"
  check_contains "triage support owner route marker" "$TRIAGE_FILE" "ROUTE_TO_SUPPORT_OWNER"
  check_contains "triage SLA marker" "$TRIAGE_FILE" "RESPONSE_SLA_MATRIX"
  check_contains "triage duplicate guard marker" "$TRIAGE_FILE" "DUPLICATE_ISSUE_GUARD"
  check_contains "triage closed policy route marker" "$TRIAGE_FILE" "CLOSED_PROVIDER_POLICY_ROUTE"
  check_contains "triage no real dispatch marker" "$TRIAGE_FILE" "\"no_real_external_dispatch\": true"
  check_contains "triage missing flow zero marker" "$TRIAGE_FILE" "\"missing_flow_count\": 0"
  check_contains "triage closed policy marker" "$TRIAGE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime triage guard marker" "$RUNTIME_SCRIPT" "TRIAGE_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "TRIAGE_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required flow guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TRIAGE_FLOW_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime missing flow guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TRIAGE_FLOWS_MISSING"
  check_contains "runtime duplicate flow guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_TRIAGE_FLOW_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_FLOW_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime intake channel guard marker" "$RUNTIME_SCRIPT" "INTAKE_CHANNEL_STATUS_NOT_READY"
  check_contains "runtime severity matrix guard marker" "$RUNTIME_SCRIPT" "SEVERITY_MATRIX_MISSING_REQUIRED_LEVELS"
  check_contains "runtime no real dispatch guard marker" "$RUNTIME_SCRIPT" "REAL_EXTERNAL_DISPATCH_NOT_DISABLED"
  check_contains "runtime real ticket closed marker" "$RUNTIME_SCRIPT" "REAL_TICKET_SYSTEM_NOT_CLOSED"
  check_contains "runtime real email closed marker" "$RUNTIME_SCRIPT" "REAL_EMAIL_DISPATCH_NOT_CLOSED"
  check_contains "runtime production closed marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "INITIAL_SUPPORT_TRIAGE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "INITIAL_SUPPORT_TRIAGE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test triage flows marker" "$TEST_FILE" "\"triage_flows\""
  check_contains "test support channels marker" "$TEST_FILE" "\"support_channels\""
  check_contains "test severity matrix marker" "$TEST_FILE" "\"severity_matrix\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 212 — FAZ 4-16.4.3 ILK DESTEK TRIAGE AKISI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_DOC_STATUS=READY"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_TEST_STATUS=PASS"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_4_4_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_4_3_ILK_DESTEK_TRIAGE_AKISI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_4_4_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
