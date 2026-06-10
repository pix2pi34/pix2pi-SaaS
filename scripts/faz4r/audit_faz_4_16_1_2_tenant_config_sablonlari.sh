#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_1_2_tenant_config_sablonlari.v1.json"
TEMPLATE_FILE="configs/faz4r/tenant_config_template.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_tenant_config_template.sh"
TEST_FILE="tests/faz4r/faz_4_16_1_2_tenant_config_sablonlari_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_REAL_IMPLEMENTATION_AUDIT.md"

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

run_fixture_tests() {
  local valid_file="/tmp/faz_4_16_1_2_valid_fixture_$$.json"
  local invalid_file="/tmp/faz_4_16_1_2_invalid_fixture_$$.json"
  local valid_out="/tmp/faz_4_16_1_2_valid_fixture_$$.out"
  local invalid_out="/tmp/faz_4_16_1_2_invalid_fixture_$$.out"

  python3 - "$TEST_FILE" "$valid_file" "$invalid_file" <<'PY_EOF'
import json
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
valid_file = Path(sys.argv[2])
invalid_file = Path(sys.argv[3])

payload = json.loads(test_file.read_text())
valid_file.write_text(json.dumps(payload["valid_fixture"], ensure_ascii=False, indent=2))
invalid_file.write_text(json.dumps(payload["invalid_fixture"], ensure_ascii=False, indent=2))
PY_EOF

  if CONFIG_FILE="$CONFIG_FILE" TEMPLATE_FILE="$TEMPLATE_FILE" INPUT_FILE="$TEMPLATE_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TENANT_CONFIG_TEMPLATE_STATUS=PASS" "$valid_out"; then
      record_pass "main tenant config template PASS"
    else
      record_fail "main tenant config template PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main tenant config template execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TEMPLATE_FILE="$TEMPLATE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "TENANT_CONFIG_TEMPLATE_STATUS=PASS" "$valid_out"; then
      record_pass "valid tenant config fixture PASS"
    else
      record_fail "valid tenant config fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid tenant config fixture execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TEMPLATE_FILE="$TEMPLATE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid tenant config fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "TENANT_CONFIG_TEMPLATE_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid tenant config fixture FAIL guard"
    else
      record_fail "invalid tenant config fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "TENANT_CONFIG_TEMPLATE_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider config guard"
  else
    record_fail "closed external provider config guard"
  fi

  if grep -Fq "TENANT_CONFIG_TEMPLATE_FAIL=CRITICAL_ISSUE_LIMIT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue limit zero config guard"
  else
    record_fail "critical issue limit zero config guard"
  fi

  if grep -Fq "TENANT_CONFIG_TEMPLATE_FAIL=LIVE_MODULE_FLAG_NOT_CLOSED:payment_live_enabled" "$invalid_out"; then
    record_pass "payment live flag closed guard"
  else
    record_fail "payment live flag closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 196 — FAZ 4-16.1.2 TENANT CONFIG SABLONLARI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "tenant template file exists" "$TEMPLATE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.1.2 Tenant Config Şablonları"
  check_contains "doc controlled pilot marker" "$DOC_FILE" "CONTROLLED_PILOT"
  check_contains "doc TRY marker" "$DOC_FILE" "default_currency = TRY"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 196"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 195 marker" "$CONFIG_FILE" "195_FAZ_4_16_1_1_PILOT_TENANT_ACILIS_AKISI"
  check_contains "config template artifact marker" "$CONFIG_FILE" "tenant_config_template.controlled_pilot.v1.json"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_limit_required\": 0"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "template status ready marker" "$TEMPLATE_FILE" "\"template_status\": \"READY\""
  check_contains "template tenant scope marker" "$TEMPLATE_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "template pilot mode marker" "$TEMPLATE_FILE" "\"pilot_mode\": \"CONTROLLED_PILOT\""
  check_contains "template timezone marker" "$TEMPLATE_FILE" "\"timezone\": \"Europe/Istanbul\""
  check_contains "template currency marker" "$TEMPLATE_FILE" "\"default_currency\": \"TRY\""
  check_contains "template critical issue zero marker" "$TEMPLATE_FILE" "\"max_critical_issue_count\": 0"
  check_contains "template payment live disabled marker" "$TEMPLATE_FILE" "\"payment_live_enabled\": false"
  check_contains "template edoc live disabled marker" "$TEMPLATE_FILE" "\"e_document_live_enabled\": false"
  check_contains "template bank live disabled marker" "$TEMPLATE_FILE" "\"bank_live_enabled\": false"
  check_contains "template pos live disabled marker" "$TEMPLATE_FILE" "\"pos_provider_live_enabled\": false"
  check_contains "template closed policy marker" "$TEMPLATE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime input file marker" "$RUNTIME_SCRIPT" "INPUT_FILE"
  check_contains "runtime template file guard marker" "$RUNTIME_SCRIPT" "TEMPLATE_FILE_NOT_FOUND"
  check_contains "runtime tenant scope guard marker" "$RUNTIME_SCRIPT" "TENANT_SCOPE_INVALID"
  check_contains "runtime currency guard marker" "$RUNTIME_SCRIPT" "DEFAULT_CURRENCY_INVALID"
  check_contains "runtime live module guard marker" "$RUNTIME_SCRIPT" "LIVE_MODULE_FLAG_NOT_CLOSED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_LIMIT_NOT_ZERO"
  check_contains "runtime closed external marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "TENANT_CONFIG_TEMPLATE_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "TENANT_CONFIG_TEMPLATE_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test module flags marker" "$TEST_FILE" "\"module_flags\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 196 — FAZ 4-16.1.2 TENANT CONFIG SABLONLARI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_DOC_STATUS=READY"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_TEMPLATE_STATUS=READY"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_TEST_STATUS=PASS"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_1_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_1_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
