#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 133 — FAZ 3-10.1.6 TDHP LIVE TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/tdhp/livetests/tdhp_live_test_suite.go"
TEST_FILE="internal/erp/turkiye/tdhp/livetests/tdhp_live_test_suite_test.go"
CONFIG_FILE="configs/faz3/tdhp/tdhp_live_tests.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_6_TDHP_LIVE_TESTS.md"

check_file "133 TDHP live test suite file" "$SUITE_FILE"
check_file "133 TDHP live test file" "$TEST_FILE"
check_file "133 TDHP live test config file" "$CONFIG_FILE"
check_file "133 TDHP live test documentation file" "$DOC_FILE"

check_grep "133 suite constructor" "$SUITE_FILE" "NewTDHPLiveTestSuite"
check_grep "133 sales invoice E2E runtime" "$SUITE_FILE" "RunSalesInvoiceLiveE2E"
check_grep "133 purchase invoice E2E runtime" "$SUITE_FILE" "RunPurchaseInvoiceLiveE2E"
check_grep "133 difference scenario runtime" "$SUITE_FILE" "RunDifferenceScenario"
check_grep "133 audit export runtime" "$SUITE_FILE" "ExportPostingAuditTrace"

check_grep "133 account switch wired" "$SUITE_FILE" "AccountSwitch"
check_grep "133 voucher pipeline wired" "$SUITE_FILE" "Voucher"
check_grep "133 posting runtime wired" "$SUITE_FILE" "Posting"
check_grep "133 audit trace wired" "$SUITE_FILE" "AuditTrace"
check_grep "133 reconciliation wired" "$SUITE_FILE" "Reconcile"

check_grep "133 TDHP 391 output KDV resolve" "$SUITE_FILE" "391.01.20"
check_grep "133 TDHP 191 input KDV resolve" "$SUITE_FILE" "191.01.20"
check_grep "133 TDHP 120 trace" "$SUITE_FILE" "120.01"
check_grep "133 TDHP 600 trace" "$SUITE_FILE" "600.01"
check_grep "133 TDHP 320 trace" "$SUITE_FILE" "320.01"

check_grep "133 sales invoice test" "$TEST_FILE" "TestTDHPLiveSalesInvoiceEndToEnd"
check_grep "133 purchase invoice test" "$TEST_FILE" "TestTDHPLivePurchaseInvoiceEndToEnd"
check_grep "133 audit trace export test" "$TEST_FILE" "TestTDHPLiveAuditTraceExport"
check_grep "133 difference scenario test" "$TEST_FILE" "TestTDHPLiveDifferenceScenario"
check_grep "133 currency mismatch test" "$TEST_FILE" "TestTDHPLiveRejectsCurrencyMismatchAtVoucherPipeline"
check_grep "133 missing audit trace test" "$TEST_FILE" "TestTDHPLiveRejectsInvalidReconciliationWithoutAuditTrace"

check_grep "133 config live ready simulation mode" "$CONFIG_FILE" "LIVE_READY_SIMULATION"
check_grep "133 config real external false" "$CONFIG_FILE" "\"real_external_system_call\": false"
check_grep "133 config voucher pipeline coverage" "$CONFIG_FILE" "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE"
check_grep "133 config account switch coverage" "$CONFIG_FILE" "FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH"
check_grep "133 config posting coverage" "$CONFIG_FILE" "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME"
check_grep "133 config audit trace coverage" "$CONFIG_FILE" "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE"
check_grep "133 config reconciliation coverage" "$CONFIG_FILE" "FAZ_3_10_1_5_RECONCILIATION_RUNTIME"
check_grep "133 config next gate" "$CONFIG_FILE" "FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION"

if go test ./internal/erp/turkiye/tdhp/livetests; then
  pass "133 TDHP live tests Go test status"
else
  fail "133 TDHP live tests Go test status"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 133 — FAZ 3-10.1.6 — TDHP Live Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_6_TDHP_LIVE_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_6_TDHP_LIVE_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_4_4_READY=${NEXT_READY}

## Scope

- Account switch
- Account resolve
- Real voucher pipeline
- Document posting runtime
- Audit trace persistence
- Reconciliation runtime
- Sales invoice E2E
- Purchase invoice E2E
- Audit export
- Difference detection
- Currency mismatch rejection
- Missing audit trace rejection

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 133 — FAZ 3-10.1.6 TDHP LIVE TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_6_TDHP_LIVE_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_6_TDHP_LIVE_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_4_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
