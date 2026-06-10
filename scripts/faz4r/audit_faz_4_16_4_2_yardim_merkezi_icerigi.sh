#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_4_2_yardim_merkezi_icerigi.v1.json"
HELP_FILE="configs/faz4r/help_center_content.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_help_center_content.sh"
TEST_FILE="tests/faz4r/faz_4_16_4_2_yardim_merkezi_icerigi_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_4_2_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_4_2_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_4_2_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_4_2_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" HELP_FILE="$HELP_FILE" INPUT_FILE="$HELP_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "HELP_CENTER_CONTENT_STATUS=PASS" "$valid_out"; then
      record_pass "main help center content artifact PASS"
    else
      record_fail "main help center content artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main help center content artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" HELP_FILE="$HELP_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "HELP_CENTER_CONTENT_STATUS=PASS" "$valid_out"; then
      record_pass "valid help center content fixture PASS"
    else
      record_fail "valid help center content fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid help center content fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "HELP_CENTER_CONTENT_TOTAL_ARTICLE_COUNT=15" "$valid_out"; then
    record_pass "valid help center content total article count"
  else
    record_fail "valid help center content total article count"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_READY_ARTICLE_COUNT=15" "$valid_out"; then
    record_pass "valid help center content ready article count"
  else
    record_fail "valid help center content ready article count"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_MISSING_ARTICLE_COUNT=0" "$valid_out"; then
    record_pass "valid help center content missing article zero"
  else
    record_fail "valid help center content missing article zero"
  fi

  if grep -Fq "SEARCHABLE_INDEX_STATUS=READY" "$valid_out"; then
    record_pass "valid help center searchable index ready"
  else
    record_fail "valid help center searchable index ready"
  fi

  if CONFIG_FILE="$CONFIG_FILE" HELP_FILE="$HELP_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid help center content fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "HELP_CENTER_CONTENT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid help center content fixture FAIL guard"
    else
      record_fail "invalid help center content fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=HELP_CENTER_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then
    record_pass "controlled pilot help center mode guard"
  else
    record_fail "controlled pilot help center mode guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=CHAIN_DEPENDENCY_NOT_PASS:210_FAZ_4_16_4_1_KULLANICI_EGITIM_SETI" "$invalid_out"; then
    record_pass "training set dependency guard"
  else
    record_fail "training set dependency guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=REQUIRED_ARTICLE_NOT_READY:HELP_FIRST_LOGIN" "$invalid_out"; then
    record_pass "required article ready guard"
  else
    record_fail "required article ready guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=REQUIRED_EVIDENCE_MISSING:HELP_FIRST_LOGIN" "$invalid_out"; then
    record_pass "required evidence guard"
  else
    record_fail "required evidence guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=REQUIRED_ARTICLES_MISSING" "$invalid_out"; then
    record_pass "missing required articles guard"
  else
    record_fail "missing required articles guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=DUPLICATE_ARTICLE_CODE_FOUND" "$invalid_out"; then
    record_pass "duplicate article guard"
  else
    record_fail "duplicate article guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=TOTAL_ARTICLE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then
    record_pass "total article count reconciliation guard"
  else
    record_fail "total article count reconciliation guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=MISSING_ARTICLE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "missing article zero guard"
  else
    record_fail "missing article zero guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=SEARCHABLE_INDEX_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "searchable index ready guard"
  else
    record_fail "searchable index ready guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=SUPPORT_ROUTE_STATUS_NOT_READY" "$invalid_out"; then
    record_pass "support route ready guard"
  else
    record_fail "support route ready guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then
    record_pass "critical issue zero guard"
  else
    record_fail "critical issue zero guard"
  fi

  if grep -Fq "HELP_CENTER_CONTENT_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out"; then
    record_pass "production launch closed policy guard"
  else
    record_fail "production launch closed policy guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 211 — FAZ 4-16.4.2 YARDIM MERKEZI ICERIGI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "help center file exists" "$HELP_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "help first login article exists" "docs/faz4r/help_center/help_first_login.md"
  check_file "help tenant context article exists" "docs/faz4r/help_center/help_tenant_context.md"
  check_file "help POS article exists" "docs/faz4r/help_center/help_pos_basic.md"
  check_file "help closed provider policy article exists" "docs/faz4r/help_center/help_closed_provider_policy.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.4.2 Yardım Merkezi İçeriği"
  check_contains "doc first login marker" "$DOC_FILE" "İlk giriş"
  check_contains "doc support marker" "$DOC_FILE" "Hata bildirimi"
  check_contains "doc searchable index marker" "$DOC_FILE" "searchable_index_status = READY"
  check_contains "doc required fail zero marker" "$DOC_FILE" "required_fail_count = 0"
  check_contains "doc critical issue zero marker" "$DOC_FILE" "critical_issue_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 211"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 210 marker" "$CONFIG_FILE" "210_FAZ_4_16_4_1_KULLANICI_EGITIM_SETI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"help_center_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config article ready marker" "$CONFIG_FILE" "\"required_article_status_required\": \"READY\""
  check_contains "config missing article zero marker" "$CONFIG_FILE" "\"missing_article_count_required\": 0"
  check_contains "config required fail zero marker" "$CONFIG_FILE" "\"required_fail_count_required\": 0"
  check_contains "config critical issue zero marker" "$CONFIG_FILE" "\"critical_issue_count_required\": 0"
  check_contains "config training set marker" "$CONFIG_FILE" "\"training_set_status_required\": \"PASS\""
  check_contains "config searchable index marker" "$CONFIG_FILE" "\"searchable_index_status_required\": \"READY\""
  check_contains "config support route marker" "$CONFIG_FILE" "\"support_route_status_required\": \"READY\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "help status ready marker" "$HELP_FILE" "\"help_center_status\": \"READY\""
  check_contains "help controlled pilot marker" "$HELP_FILE" "\"help_center_mode\": \"CONTROLLED_PILOT\""
  check_contains "help first login marker" "$HELP_FILE" "HELP_FIRST_LOGIN"
  check_contains "help tenant context marker" "$HELP_FILE" "HELP_TENANT_CONTEXT"
  check_contains "help management panel marker" "$HELP_FILE" "HELP_MANAGEMENT_PANEL"
  check_contains "help POS marker" "$HELP_FILE" "HELP_POS_BASIC"
  check_contains "help import validation marker" "$HELP_FILE" "HELP_IMPORT_VALIDATION_REPORT"
  check_contains "help accounting marker" "$HELP_FILE" "HELP_ACCOUNTING_PREVIEW"
  check_contains "help e-document marker" "$HELP_FILE" "HELP_E_DOCUMENT_EXPORT_PREVIEW"
  check_contains "help support marker" "$HELP_FILE" "HELP_SUPPORT_ISSUE_REPORTING"
  check_contains "help closed provider marker" "$HELP_FILE" "HELP_CLOSED_PROVIDER_POLICY"
  check_contains "help searchable index marker" "$HELP_FILE" "\"searchable_index_status\": \"READY\""
  check_contains "help missing article zero marker" "$HELP_FILE" "\"missing_article_count\": 0"
  check_contains "help closed policy marker" "$HELP_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime help guard marker" "$RUNTIME_SCRIPT" "HELP_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "HELP_CENTER_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required article guard marker" "$RUNTIME_SCRIPT" "REQUIRED_ARTICLE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime missing article guard marker" "$RUNTIME_SCRIPT" "REQUIRED_ARTICLES_MISSING"
  check_contains "runtime duplicate article guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_ARTICLE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_ARTICLE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime searchable index guard marker" "$RUNTIME_SCRIPT" "SEARCHABLE_INDEX_STATUS_NOT_READY"
  check_contains "runtime support route guard marker" "$RUNTIME_SCRIPT" "SUPPORT_ROUTE_STATUS_NOT_READY"
  check_contains "runtime critical issue guard marker" "$RUNTIME_SCRIPT" "CRITICAL_ISSUE_COUNT_NOT_ZERO"
  check_contains "runtime production closed marker" "$RUNTIME_SCRIPT" "PRODUCTION_LAUNCH_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "HELP_CENTER_CONTENT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "HELP_CENTER_CONTENT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test chain dependencies marker" "$TEST_FILE" "\"chain_dependencies\""
  check_contains "test articles marker" "$TEST_FILE" "\"articles\""
  check_contains "test navigation marker" "$TEST_FILE" "\"navigation\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 211 — FAZ 4-16.4.2 YARDIM MERKEZI ICERIGI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_DOC_STATUS=READY"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_TEST_STATUS=PASS"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_4_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_4_2_YARDIM_MERKEZI_ICERIGI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_4_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
