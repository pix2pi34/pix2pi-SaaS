#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU.md"
CONFIG_FILE="configs/faz4r/faz_4_16_1_3_kullanici_rol_ilk_kurulumu.v1.json"
TEMPLATE_FILE="configs/faz4r/user_role_initial_setup.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_user_role_initial_setup.sh"
TEST_FILE="tests/faz4r/faz_4_16_1_3_kullanici_rol_ilk_kurulumu_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_1_3_valid_fixture_$$.json"
  local invalid_file="/tmp/faz_4_16_1_3_invalid_fixture_$$.json"
  local valid_out="/tmp/faz_4_16_1_3_valid_fixture_$$.out"
  local invalid_out="/tmp/faz_4_16_1_3_invalid_fixture_$$.out"

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
    if grep -Fq "USER_ROLE_SETUP_STATUS=PASS" "$valid_out"; then
      record_pass "main user role setup template PASS"
    else
      record_fail "main user role setup template PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main user role setup template execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TEMPLATE_FILE="$TEMPLATE_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "USER_ROLE_SETUP_STATUS=PASS" "$valid_out"; then
      record_pass "valid user role setup fixture PASS"
    else
      record_fail "valid user role setup fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid user role setup fixture execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TEMPLATE_FILE="$TEMPLATE_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid user role setup fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "USER_ROLE_SETUP_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid user role setup fixture FAIL guard"
    else
      record_fail "invalid user role setup fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "USER_ROLE_SETUP_FAIL=REQUIRED_ROLES_MISSING" "$invalid_out"; then
    record_pass "required roles missing guard"
  else
    record_fail "required roles missing guard"
  fi

  if grep -Fq "USER_ROLE_SETUP_FAIL=REQUIRED_PERMISSIONS_MISSING" "$invalid_out"; then
    record_pass "required permissions missing guard"
  else
    record_fail "required permissions missing guard"
  fi

  if grep -Fq "USER_ROLE_SETUP_FAIL=TENANT_ADMIN_ASSIGNMENT_MISSING" "$invalid_out"; then
    record_pass "tenant admin assignment guard"
  else
    record_fail "tenant admin assignment guard"
  fi

  if grep -Fq "USER_ROLE_SETUP_FAIL=REAL_INVITE_EMAIL_NOT_ALLOWED" "$invalid_out"; then
    record_pass "real invite email forbidden guard"
  else
    record_fail "real invite email forbidden guard"
  fi

  if grep -Fq "USER_ROLE_SETUP_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider user role guard"
  else
    record_fail "closed external provider user role guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 197 — FAZ 4-16.1.3 KULLANICI / ROL ILK KURULUMU REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "user role template file exists" "$TEMPLATE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.1.3 Kullanıcı / Rol İlk Kurulumu"
  check_contains "doc role baseline marker" "$DOC_FILE" "TENANT_ADMIN"
  check_contains "doc permission baseline marker" "$DOC_FILE" "AUDIT_EVIDENCE_READ"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 197"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 196 marker" "$CONFIG_FILE" "196_FAZ_4_16_1_2_TENANT_CONFIG_SABLONLARI"
  check_contains "config required role admin marker" "$CONFIG_FILE" "TENANT_ADMIN"
  check_contains "config required role operator marker" "$CONFIG_FILE" "PILOT_OPERATOR"
  check_contains "config required permission invite marker" "$CONFIG_FILE" "USER_INVITE_MANAGE"
  check_contains "config required permission reporting marker" "$CONFIG_FILE" "REPORTING_READ"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "template setup ready marker" "$TEMPLATE_FILE" "\"setup_status\": \"READY\""
  check_contains "template tenant scope marker" "$TEMPLATE_FILE" "\"tenant_scope\": \"SINGLE_TENANT\""
  check_contains "template pilot mode marker" "$TEMPLATE_FILE" "\"pilot_mode\": \"CONTROLLED_PILOT\""
  check_contains "template admin user marker" "$TEMPLATE_FILE" "pilot_admin_001"
  check_contains "template role permissions marker" "$TEMPLATE_FILE" "\"role_permissions\""
  check_contains "template assignments marker" "$TEMPLATE_FILE" "\"assignments\""
  check_contains "template invite policy marker" "$TEMPLATE_FILE" "\"send_real_email\": false"
  check_contains "template mfa policy marker" "$TEMPLATE_FILE" "\"mfa_required_for_all_pilot_users\": true"
  check_contains "template closed policy marker" "$TEMPLATE_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime template file guard marker" "$RUNTIME_SCRIPT" "TEMPLATE_FILE_NOT_FOUND"
  check_contains "runtime setup ready guard marker" "$RUNTIME_SCRIPT" "SETUP_STATUS_NOT_READY"
  check_contains "runtime required roles guard marker" "$RUNTIME_SCRIPT" "REQUIRED_ROLES_MISSING"
  check_contains "runtime required permissions guard marker" "$RUNTIME_SCRIPT" "REQUIRED_PERMISSIONS_MISSING"
  check_contains "runtime tenant admin guard marker" "$RUNTIME_SCRIPT" "TENANT_ADMIN_ASSIGNMENT_MISSING"
  check_contains "runtime real email guard marker" "$RUNTIME_SCRIPT" "REAL_INVITE_EMAIL_NOT_ALLOWED"
  check_contains "runtime mfa guard marker" "$RUNTIME_SCRIPT" "MFA_REQUIRED_FOR_ALL_FALSE"
  check_contains "runtime closed external marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "USER_ROLE_SETUP_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "USER_ROLE_SETUP_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test roles marker" "$TEST_FILE" "\"roles\""
  check_contains "test permissions marker" "$TEST_FILE" "\"permissions\""
  check_contains "test assignments marker" "$TEST_FILE" "\"assignments\""

  run_fixture_tests

  echo "===== 197 — FAZ 4-16.1.3 KULLANICI / ROL ILK KURULUMU COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_DOC_STATUS=READY"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_CONFIG_STATUS=READY"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_TEMPLATE_STATUS=READY"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_TEST_STATUS=PASS"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_FINAL_STATUS=PASS"
    echo "FAZ_4_16_2_1_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_TEST_STATUS=FAIL"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_1_3_KULLANICI_ROL_ILK_KURULUMU_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_2_1_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
