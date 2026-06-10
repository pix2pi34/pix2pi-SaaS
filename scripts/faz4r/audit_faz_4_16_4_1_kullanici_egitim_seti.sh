#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_4_1_KULLANICI_EGITIM_SETI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_4_1_kullanici_egitim_seti.v1.json"
TRAINING_FILE="configs/faz4r/user_training_set.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_user_training_set.sh"
TEST_FILE="tests/faz4r/faz_4_16_4_1_kullanici_egitim_seti_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_4_1_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_4_1_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_4_1_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_4_1_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" TRAINING_FILE="$TRAINING_FILE" INPUT_FILE="$TRAINING_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "USER_TRAINING_SET_STATUS=PASS" "$valid_out"; then
      record_pass "main user training set artifact PASS"
    else
      record_fail "main user training set artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main user training set artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" TRAINING_FILE="$TRAINING_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "USER_TRAINING_SET_STATUS=PASS" "$valid_out"; then
      record_pass "valid user training set fixture PASS"
    else
      record_fail "valid user training set fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid user training set fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "USER_TRAINING_SET_TOTAL_MODULE_COUNT=15" "$valid_out"; then
    record_pass "valid user training set total module count"
  else
    record_fail "valid user training set total module count"
  fi

  if grep -Fq "USER_TRAINING_SET_READY_MODULE_COUNT=15" "$valid_out"; then
    record_pass "valid user training set ready module count"
  else
    record_fail "valid user training set ready module count"
  fi

  if grep -Fq "USER_TRAINING_SET_MISSING_MODULE_COUNT=0" "$valid_out"; then
    record_pass "valid user training set missing module zero"
  else
    record_fail "valid user training set missing module zero"
  fi

  if grep -Fq "UAT_SIGNOFF_STATUS=PASS" "$valid_out"; then
    record_pass "valid user training set UAT signoff pass"
  else
    record_fail "valid user training set UAT signoff pass"
  fi

  if CONFIG_FILE="$CONFIG_FILE" TRAINING_FILE="$TRAINING_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid user training set fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "USER_TRAINING_SET_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid user training set fixture FAIL guard"
    else
      record_fail "invalid user training set fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=TRAINING_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot training mode guard"
  else
    record_fail "controlled pilot training mode guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=CHAIN_DEPENDENCY_NOT_PASS:209_FAZ_4_16_3_6_UAT_SIGN_OFF" "$invalid_out"; then
    record_pass "UAT signoff dependency guard"
  else
    record_fail "UAT signoff dependency guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=REQUIRED_TRAINING_MODULE_NOT_READY:FIRST_LOGIN_GUIDE" "$invalid_out"; then
    record_pass "required training module ready guard"
  else
    record_fail "required training module ready guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=REQUIRED_EVIDENCE_MISSING:FIRST_LOGIN_GUIDE" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=REQUIRED_TRAINING_MODULES_MISSING" "$invalid_out"; then
    record_pass "missing required training modules guard"
  else
    record_fail "missing required training modules guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=DUPLICATE_TRAINING_MODULE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate training module guard"
  else
    record_fail "duplicate training module guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=TOTAL_MODULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total module count reconciliation guard"
  else
    record_fail "total module count reconciliation guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=MISSING_MODULE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing module zero guard"
  else
    record_fail "missing module zero guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "USER_TRAINING_SET_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 210 — FAZ 4-16.4.1 KULLANICI EGITIM SETI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "training file exists" "$TRAINING_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "training first login doc exists" "docs/faz4r/training/first_login_guide.md"
  check_file "training tenant context doc exists" "docs/faz4r/training/tenant_context_guide.md"
  check_file "training POS basic doc exists" "docs/faz4r/training/pos_basic_guide.md"
  check_file "training completion checklist doc exists" "docs/faz4r/training/training_completion_checklist.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.4.1 Kullanıcı Eğitim Seti"
  check_contains "doc first login marker" "$DOC_FILE" "Giriş / ilk kullanım"
  check_contains "doc support marker" "$DOC_FILE" "Hata bildirme"
  check_contains "doc required fail zero marker" "$DOC_FILE" "required_fail_count = 0"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc UAT signoff marker" "$DOC_FILE" "uat_signoff_status = PASS"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 210"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 209 marker" "$CONFIG_FILE" "209_FAZ_4_16_3_6_UAT_SIGN_OFF"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"training_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config module ready marker" "$CONFIG_FILE" "\"required_module_status_required\": \"READY\""
  check_contains "config missing module zero marker" "$CONFIG_FILE" "\"missing_module_count_required\": 0"
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config UAT signoff marker" "$CONFIG_FILE" "\"uat_signoff_status_required\": \"PASS\""
  check_contains "config support handoff marker" "$CONFIG_FILE" "\"support_handoff_ready_required\": \"YES\""
  check_contains "config completion checklist marker" "$CONFIG_FILE" "\"completion_checklist_status_required\": \"READY\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "training status ready marker" "$TRAINING_FILE" "\"training_set_status\": \"READY\""
  check_contains "training controlled pilot marker" "$TRAINING_FILE" "\"training_mode\": \"CONTROLLED_PILOT\""
  check_contains "training first login marker" "$TRAINING_FILE" "FIRST_LOGIN_GUIDE"
  check_contains "training tenant context marker" "$TRAINING_FILE" "TENANT_CONTEXT_GUIDE"
  check_contains "training management panel marker" "$TRAINING_FILE" "MANAGEMENT_PANEL_BASIC_GUIDE"
  check_contains "training POS marker" "$TRAINING_FILE" "POS_BASIC_GUIDE"
  check_contains "training import validation marker" "$TRAINING_FILE" "IMPORT_VALIDATION_REPORT_GUIDE"
  check_contains "training accounting marker" "$TRAINING_FILE" "ACCOUNTING_BASIC_GUIDE"
  check_contains "training accountant portal marker" "$TRAINING_FILE" "ACCOUNTANT_PORTAL_READONLY_GUIDE"
  check_contains "training e-document marker" "$TRAINING_FILE" "E_DOCUMENT_EXPORT_PREVIEW_GUIDE"
  check_contains "training support marker" "$TRAINING_FILE" "SUPPORT_ISSUE_REPORTING_GUIDE"
  check_contains "training completion checklist marker" "$TRAINING_FILE" "TRAINING_COMPLETION_CHECKLIST"
  check_contains "training missing module zero marker" "$TRAINING_FILE" "\"missing_module_count\": 0"
  check_contains "training closed policy marker" "$TRAINING_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime training guard marker" "$RUNTIME_SCRIPT" "TRAINING_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "TRAINING_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required module guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TRAINING_MODULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime missing module guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TRAINING_MODULES_MISSING"
  check_contains "runtime duplicate module guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_TRAINING_MODULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_MODULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime production closed marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "USER_TRAINING_SET_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "USER_TRAINING_SET_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test training modules marker" "$TEST_FILE" "\"training_modules\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 210 — FAZ 4-16.4.1 KULLANICI EGITIM SETI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_DOC_STATUS=READY"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_TEST_STATUS=PASS"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_4_2_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_4_1_KULLANICI_EGITIM_SETI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_4_2_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
