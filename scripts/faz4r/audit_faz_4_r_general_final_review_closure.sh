#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_R_GENERAL_FINAL_REVIEW_CLOSURE.md"
CONFIG_FILE="configs/faz4r/faz_4_r_general_final_review_closure.v1.json"
CLOSURE_FILE="configs/faz4r/faz_4_r_general_final_review_closure_manifest.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_faz_4_r_general_final_review_closure.sh"
TEST_FILE="tests/faz4r/faz_4_r_general_final_review_closure_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_R_GENERAL_FINAL_REVIEW_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"
LIVE_HTML_EVIDENCE="docs/faz4r/evidence/FAZ_4_R_LIVE_HTML_PUBLISH_AUDIT.md"
LIVE_HTML_MANIFEST="configs/faz4r/faz4r_live_html_publish_manifest.json"

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
Path(sys.argv[3]).write_text(json.dumps(payload[sys.argv[2]], ensure_ascii=False, indent=2) + "\n")
PY_EOF
}

run_fixture_tests() {
  local invalid_file="/tmp/faz_4_r_closure_invalid_$$.json"
  local invalid_out="/tmp/faz_4_r_closure_invalid_$$.out"
  local main_out="/tmp/faz_4_r_closure_main_$$.out"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" LIVE_HTML_EVIDENCE="$LIVE_HTML_EVIDENCE" LIVE_HTML_MANIFEST="$LIVE_HTML_MANIFEST" INPUT_FILE="$CLOSURE_FILE" "$RUNTIME_SCRIPT" > "$main_out" 2>&1; then
    grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=PASS" "$main_out" && record_pass "main closure manifest PASS" || { record_fail "main closure manifest PASS"; cat "$main_out" || true; }
  else
    record_fail "main closure manifest execution"
    cat "$main_out" || true
  fi

  grep -Fq "FAZ_4_R_TOTAL_ITEM_COUNT=62" "$main_out" && record_pass "main total item count 62" || record_fail "main total item count 62"
  grep -Fq "FAZ_4_R_SEALED_ITEM_COUNT=62" "$main_out" && record_pass "main sealed item count 62" || record_fail "main sealed item count 62"
  grep -Fq "FAZ_4_R_PARTIAL_REMAINING=NO" "$main_out" && record_pass "main partial remaining NO" || record_fail "main partial remaining NO"
  grep -Fq "FAZ_4_R_PENDING_REMAINING=NO" "$main_out" && record_pass "main pending remaining NO" || record_fail "main pending remaining NO"
  grep -Fq "FAZ_4_R_FAIL_REMAINING=NO" "$main_out" && record_pass "main fail remaining NO" || record_fail "main fail remaining NO"
  grep -Fq "FAZ_4_R_READY_FOR_NEXT_PHASE=YES" "$main_out" && record_pass "main next phase ready YES" || record_fail "main next phase ready YES"

  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" CLOSURE_FILE="$CLOSURE_FILE" LIVE_HTML_EVIDENCE="$LIVE_HTML_EVIDENCE" LIVE_HTML_MANIFEST="$LIVE_HTML_MANIFEST" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid closure fixture must fail"
    cat "$invalid_out" || true
  else
    grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=FAIL" "$invalid_out" && record_pass "invalid closure fixture FAIL guard" || { record_fail "invalid closure fixture FAIL guard"; cat "$invalid_out" || true; }
  fi

  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=CLOSURE_STATUS_NOT_SEALED" "$invalid_out" && record_pass "closure status sealed guard" || record_fail "closure status sealed guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=PRIORITY_GROUP_COUNT_INVALID" "$invalid_out" && record_pass "priority group count guard" || record_fail "priority group count guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=ITEM_NOT_SEALED:180_FAZ_4_14_3" "$invalid_out" && record_pass "item sealed guard" || record_fail "item sealed guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=TOTAL_ITEM_COUNT_INVALID" "$invalid_out" && record_pass "total item count guard" || record_fail "total item count guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=SUMMARY_SEALED_ITEM_COUNT_INVALID" "$invalid_out" && record_pass "sealed item count guard" || record_fail "sealed item count guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=PARTIAL_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "partial item zero guard" || record_fail "partial item zero guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=PENDING_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "pending item zero guard" || record_fail "pending item zero guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=FAIL_ITEM_COUNT_NOT_ZERO" "$invalid_out" && record_pass "fail item zero guard" || record_fail "fail item zero guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=REQUIRED_FAIL_COUNT_NOT_ZERO" "$invalid_out" && record_pass "required fail zero guard" || record_fail "required fail zero guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=LIVE_HTML_PUBLISH_STATUS_NOT_PASS" "$invalid_out" && record_pass "live html pass guard" || record_fail "live html pass guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=CLOSED_POLICY_REFERENCE_INVALID" "$invalid_out" && record_pass "closed policy guard" || record_fail "closed policy guard"
  grep -Fq "FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL=PRODUCTION_LAUNCH_NOT_CLOSED" "$invalid_out" && record_pass "production launch closed guard" || record_fail "production launch closed guard"

  rm -f "$invalid_file" "$invalid_out" "$main_out"
}

{
  echo "===== FAZ 4-R GENERAL FINAL REVIEW / CLOSURE REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "closure manifest exists" "$CLOSURE_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"
  check_file "live html evidence exists" "$LIVE_HTML_EVIDENCE"
  check_file "live html manifest exists" "$LIVE_HTML_MANIFEST"

  check_contains "doc title marker" "$DOC_FILE" "FAZ 4-R — General Final Review / Closure"
  check_contains "doc total item marker" "$DOC_FILE" "total_item_count = 62"
  check_contains "doc sealed marker" "$DOC_FILE" "sealed_item_count = 62"
  check_contains "doc no partial marker" "$DOC_FILE" "partial_item_count = 0"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config step marker" "$CONFIG_FILE" "GENERAL_FINAL_REVIEW_CLOSURE"
  check_contains "config total count marker" "$CONFIG_FILE" "\"total_item_count_required\": 62"
  check_contains "config sealed count marker" "$CONFIG_FILE" "\"sealed_item_count_required\": 62"
  check_contains "config live html marker" "$CONFIG_FILE" "\"live_html_publish_status_required\": \"PASS\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"

  check_contains "closure status sealed marker" "$CLOSURE_FILE" "\"closure_status\": \"SEALED\""
  check_contains "closure total item count marker" "$CLOSURE_FILE" "\"total_item_count\": 62"
  check_contains "closure sealed item count marker" "$CLOSURE_FILE" "\"sealed_item_count\": 62"
  check_contains "closure partial count zero marker" "$CLOSURE_FILE" "\"partial_item_count\": 0"
  check_contains "closure pending count zero marker" "$CLOSURE_FILE" "\"pending_item_count\": 0"
  check_contains "closure fail count zero marker" "$CLOSURE_FILE" "\"fail_item_count\": 0"
  check_contains "closure live html pass marker" "$CLOSURE_FILE" "\"publish_status\": \"PASS\""
  check_contains "closure next ready marker" "$CLOSURE_FILE" "\"faz_4_r_ready_for_next_phase\": \"YES\""

  check_contains "live html publish evidence PASS marker" "$LIVE_HTML_EVIDENCE" "FAZ_4_R_LIVE_HTML_PUBLISH_STATUS=PASS"
  check_contains "live html ready evidence marker" "$LIVE_HTML_EVIDENCE" "FAZ_4_R_HTML_LIVE_READY=YES"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime closure guard marker" "$RUNTIME_SCRIPT" "CLOSURE_FILE_NOT_FOUND"
  check_contains "runtime total count guard marker" "$RUNTIME_SCRIPT" "TOTAL_ITEM_COUNT_INVALID"
  check_contains "runtime item sealed guard marker" "$RUNTIME_SCRIPT" "ITEM_NOT_SEALED"
  check_contains "runtime no partial guard marker" "$RUNTIME_SCRIPT" "PARTIAL_ITEM_COUNT_NOT_ZERO"
  check_contains "runtime live html guard marker" "$RUNTIME_SCRIPT" "LIVE_HTML_PUBLISH_STATUS_NOT_PASS"
  check_contains "runtime closed policy guard marker" "$RUNTIME_SCRIPT" "CLOSED_POLICY_REFERENCE_INVALID"
  check_contains "runtime PASS marker" "$RUNTIME_SCRIPT" "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=PASS"
  check_contains "runtime FAIL marker" "$RUNTIME_SCRIPT" "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""

  run_fixture_tests

  echo "===== FAZ 4-R GENERAL FINAL REVIEW / CLOSURE COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_DOC_STATUS=READY"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_CONFIG_STATUS=READY"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_CLOSURE_MANIFEST_STATUS=READY"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_RUNTIME_STATUS=READY"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_TEST_STATUS=PASS"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=PASS"
    echo "FAZ_4_R_FINAL_CLOSURE_STATUS=SEALED"
    echo "FAZ_4_R_PARTIAL_REMAINING=NO"
    echo "FAZ_4_R_PENDING_REMAINING=NO"
    echo "FAZ_4_R_FAIL_REMAINING=NO"
    echo "FAZ_4_R_READY_FOR_NEXT_PHASE=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=FAIL"
    echo "FAZ_4_R_FINAL_CLOSURE_STATUS=OPEN"
    echo "FAZ_4_R_READY_FOR_NEXT_PHASE=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
