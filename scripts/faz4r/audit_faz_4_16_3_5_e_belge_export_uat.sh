#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_3_5_E_BELGE_EXPORT_UAT.md"
CONFIG_FILE="configs/faz4r/faz_4_16_3_5_e_belge_export_uat.v1.json"
UAT_FILE="configs/faz4r/e_document_export_uat.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_e_document_export_uat.sh"
TEST_FILE="tests/faz4r/faz_4_16_3_5_e_belge_export_uat_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_3_5_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_3_5_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_3_5_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_3_5_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$UAT_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "E_DOCUMENT_EXPORT_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "main e-document export UAT artifact PASS"
    else
      record_fail "main e-document export UAT artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main e-document export UAT artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "E_DOCUMENT_EXPORT_UAT_STATUS=PASS" "$valid_out"; then
      record_pass "valid e-document export UAT fixture PASS"
    else
      record_fail "valid e-document export UAT fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid e-document export UAT fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_TOTAL_CASE_COUNT=18" "$valid_out"; then
    record_pass "valid e-document export UAT total case count"
  else
    record_fail "valid e-document export UAT total case count"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_REQUIRED_FAIL_COUNT=0" "$valid_out"; then
    record_pass "valid e-document export UAT required fail zero"
  else
    record_fail "valid e-document export UAT required fail zero"
  fi

  if grep -Fq "E_DOCUMENT_XML_PREVIEW=PASS" "$valid_out"; then
    record_pass "valid XML preview pass"
  else
    record_fail "valid XML preview pass"
  fi

  if grep -Fq "E_DOCUMENT_PDF_PREVIEW=PASS" "$valid_out"; then
    record_pass "valid PDF preview pass"
  else
    record_fail "valid PDF preview pass"
  fi

  if grep -Fq "PACKAGE_EXPORT_PREVIEW=PASS" "$valid_out"; then
    record_pass "valid package export preview pass"
  else
    record_fail "valid package export preview pass"
  fi

  if grep -Fq "GIB_LIVE_STATUS=CLOSED" "$valid_out"; then
    record_pass "valid GIB live status closed"
  else
    record_fail "valid GIB live status closed"
  fi

  if grep -Fq "REAL_EXPORT_STATUS=CLOSED" "$valid_out"; then
    record_pass "valid real export status closed"
  else
    record_fail "valid real export status closed"
  fi

  if CONFIG_FILE="$CONFIG_FILE" UAT_FILE="$UAT_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid e-document export UAT fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "E_DOCUMENT_EXPORT_UAT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid e-document export UAT fixture FAIL guard"
    else
      record_fail "invalid e-document export UAT fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=UAT_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot e-document export UAT mode guard"
  else
    record_fail "controlled pilot e-document export UAT mode guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=EXPORT_MODE_NOT_PREVIEW" "$invalid_out"; then
    record_pass "export preview mode guard"
  else
    record_fail "export preview mode guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:207_FAZ_4_16_3_4_MUHASEBECI_PORTALI_UAT" "$invalid_out"; then
    record_pass "chain dependency guard"
  else
    record_fail "chain dependency guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=REQUIRED_UAT_CASE_NOT_PASS:E_DOCUMENT_EXPORT_ACCESS" "$invalid_out"; then
    record_pass "required e-document export UAT case pass guard"
  else
    record_fail "required e-document export UAT case pass guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=REQUIRED_EVIDENCE_MISSING:E_DOCUMENT_EXPORT_ACCESS" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=REQUIRED_UAT_CASES_MISSING" "$invalid_out"; then
    record_pass "missing e-document export UAT cases guard"
  else
    record_fail "missing e-document export UAT cases guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=TOTAL_CASE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total case count reconciliation guard"
  else
    record_fail "total case count reconciliation guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=FILE_PREVIEW_TYPES_MISSING" "$invalid_out"; then
    record_pass "file preview types guard"
  else
    record_fail "file preview types guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=PACKAGE_EXPORT_TYPES_MISSING" "$invalid_out"; then
    record_pass "package export types guard"
  else
    record_fail "package export types guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=GIB_LIVE_STATUS_NOT_CLOSED" "$invalid_out"; then
    record_pass "GIB live status closed guard"
  else
    record_fail "GIB live status closed guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=REAL_EXPORT_STATUS_NOT_CLOSED" "$invalid_out"; then
    record_pass "real export status closed guard"
  else
    record_fail "real export status closed guard"
  fi

  if grep -Fq "E_DOCUMENT_EXPORT_UAT_FAIL=REAL_GIB_SUBMISSION_NOT_CLOSED" "$invalid_out"; then
    record_pass "real GIB submission external closed guard"
  else
    record_fail "real GIB submission external closed guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 208 — FAZ 4-16.3.5 E-BELGE / EXPORT UAT REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "UAT file exists" "$UAT_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.3.5 e-Belge / Export UAT"
  check_contains "doc e-Fatura marker" "$DOC_FILE" "e-Fatura"
  check_contains "doc export preview marker" "$DOC_FILE" "export_mode = PREVIEW"
  check_contains "doc GIB closed marker" "$DOC_FILE" "gib_live_status = CLOSED"
  check_contains "doc real export closed marker" "$DOC_FILE" "real_export_status = CLOSED"
  check_contains "doc critical zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 208"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 207 marker" "$CONFIG_FILE" "207_FAZ_4_16_3_4_MUHASEBECI_PORTALI_UAT"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"uat_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config export preview marker" "$CONFIG_FILE" "\"export_mode_required\": \"PREVIEW\""
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config XML preview marker" "$CONFIG_FILE" "\"xml_preview_status_required\": \"PASS\""
  check_contains "config PDF preview marker" "$CONFIG_FILE" "\"pdf_preview_status_required\": \"PASS\""
  check_contains "config package export marker" "$CONFIG_FILE" "\"package_export_preview_status_required\": \"PASS\""
  check_contains "config GIB closed marker" "$CONFIG_FILE" "\"gib_live_status_required\": \"CLOSED\""
  check_contains "config real export closed marker" "$CONFIG_FILE" "\"real_export_status_required\": \"CLOSED\""
  check_contains "config evidence marker" "$CONFIG_FILE" "\"required_evidence_ref\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "UAT status ready marker" "$UAT_FILE" "\"uat_status\": \"READY\""
  check_contains "UAT controlled pilot marker" "$UAT_FILE" "\"uat_mode\": \"CONTROLLED_PILOT\""
  check_contains "UAT export preview marker" "$UAT_FILE" "\"export_mode\": \"PREVIEW\""
  check_contains "UAT e-invoice marker" "$UAT_FILE" "E_INVOICE_PREVIEW"
  check_contains "UAT e-archive marker" "$UAT_FILE" "E_ARCHIVE_PREVIEW"
  check_contains "UAT XML marker" "$UAT_FILE" "XML_PREVIEW"
  check_contains "UAT PDF marker" "$UAT_FILE" "PDF_PREVIEW"
  check_contains "UAT Logo marker" "$UAT_FILE" "LOGO_EXPORT_PREVIEW"
  check_contains "UAT Mikro marker" "$UAT_FILE" "MIKRO_EXPORT_PREVIEW"
  check_contains "UAT Zirve marker" "$UAT_FILE" "ZIRVE_EXPORT_PREVIEW"
  check_contains "UAT ETA marker" "$UAT_FILE" "ETA_EXPORT_PREVIEW"
  check_contains "UAT GIB closed marker" "$UAT_FILE" "GIB_LIVE_CLOSED_GATE"
  check_contains "UAT critical issue zero marker" "$UAT_FILE" "\"critical_issue_count\": 0"
  check_contains "UAT closed policy marker" "$UAT_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime UAT guard marker" "$RUNTIME_SCRIPT" "UAT_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "UAT_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime export preview guard marker" "$RUNTIME_SCRIPT" "EXPORT_MODE_NOT_PREVIEW"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required case guard marker" "$RUNTIME_SCRIPT" "REQUIRED_UAT_CASE_NOT_PASS"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_CASE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime file preview types marker" "$RUNTIME_SCRIPT" "FILE_PREVIEW_TYPES_MISSING"
  check_contains "runtime package export types marker" "$RUNTIME_SCRIPT" "PACKAGE_EXPORT_TYPES_MISSING"
  check_contains "runtime GIB live closed marker" "$RUNTIME_SCRIPT" "GIB_LIVE_STATUS_NOT_CLOSED"
  check_contains "runtime real export closed marker" "$RUNTIME_SCRIPT" "REAL_EXPORT_STATUS_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "E_DOCUMENT_EXPORT_UAT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "E_DOCUMENT_EXPORT_UAT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test UAT cases marker" "$TEST_FILE" "\"uat_cases\""
  check_contains "test export preview marker" "$TEST_FILE" "\"export_preview\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 208 — FAZ 4-16.3.5 E-BELGE / EXPORT UAT COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_DOC_STATUS=READY"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_CONFIG_STATUS=READY"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_CASE_STATUS=READY"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_TEST_STATUS=PASS"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_FINAL_STATUS=PASS"
    echo "FAZ_4_16_3_6_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_TEST_STATUS=FAIL"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_3_5_E_BELGE_EXPORT_UAT_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_3_6_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
