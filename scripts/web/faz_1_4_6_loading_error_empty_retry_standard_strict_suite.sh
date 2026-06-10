#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/loading-error-empty-retry"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/loading_error_empty_retry.js"
CSS_FILE="$WEB_DIR/loading_error_empty_retry.css"
CONFIG_FILE="$CONFIG_DIR/loading_error_empty_retry_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"loading_state"' "3.1 loading_state capability contract"
check_contains "$CONFIG_FILE" '"error_state"' "3.2 error_state capability contract"
check_contains "$CONFIG_FILE" '"empty_state"' "3.3 empty_state capability contract"
check_contains "$CONFIG_FILE" '"retry_action"' "3.4 retry_action capability contract"
check_contains "$CONFIG_FILE" '"ui_tests"' "3.5 ui_tests capability contract"

check_contains "$HTML_FILE" 'pix2piLoadingState' "4.1 loading state HTML"
check_contains "$HTML_FILE" 'pix2piErrorState' "4.2 error state HTML"
check_contains "$HTML_FILE" 'pix2piEmptyState' "4.3 empty state HTML"
check_contains "$HTML_FILE" 'pix2piRetryButton' "4.4 retry action HTML"
check_contains "$HTML_FILE" 'runUiStateTestsButton' "4.5 UI tests HTML"

check_contains "$JS_FILE" 'showLoadingState' "5.1 loading state JS"
check_contains "$JS_FILE" 'showErrorState' "5.2 error state JS"
check_contains "$JS_FILE" 'showEmptyState' "5.3 empty state JS"
check_contains "$JS_FILE" 'retryLastAction' "5.4 retry action JS"
check_contains "$JS_FILE" 'runUiStateTests' "5.5 UI tests JS"

check_contains "$CSS_FILE" 'pix2pi-loading-state' "6.1 loading state CSS"
check_contains "$CSS_FILE" 'pix2pi-error-state' "6.2 error state CSS"
check_contains "$CSS_FILE" 'pix2pi-empty-state' "6.3 empty state CSS"
check_contains "$CSS_FILE" 'pix2pi-spinner' "6.4 spinner CSS"
check_contains "$CSS_FILE" 'pix2pi-skeleton' "6.5 skeleton CSS"

LOADING_STATE_STATUS="PASS"
ERROR_STATE_STATUS="PASS"
EMPTY_STATE_STATUS="PASS"
RETRY_ACTION_STATUS="PASS"
UI_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOADING_STATE_STATUS="FAIL"
  ERROR_STATE_STATUS="FAIL"
  EMPTY_STATE_STATUS="FAIL"
  RETRY_ACTION_STATUS="FAIL"
  UI_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.6 Loading / Error / Empty / Retry Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOADING_STATE_STATUS=$LOADING_STATE_STATUS"
  echo "- ERROR_STATE_STATUS=$ERROR_STATE_STATUS"
  echo "- EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
  echo "- RETRY_ACTION_STATUS=$RETRY_ACTION_STATUS"
  echo "- UI_TESTS_STATUS=$UI_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOADING_STATE_STATUS=$LOADING_STATE_STATUS"
echo "ERROR_STATE_STATUS=$ERROR_STATE_STATUS"
echo "EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
echo "RETRY_ACTION_STATUS=$RETRY_ACTION_STATUS"
echo "UI_TESTS_STATUS=$UI_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE END ====="
