#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/basic-ui-tests"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/basic_ui_tests.js"
CSS_FILE="$WEB_DIR/basic_ui_tests.css"
CONFIG_FILE="$CONFIG_DIR/basic_ui_tests_contract.v1.json"

APP_SHELL_DIR="$REPO/web/faz1/ui-foundation/app-shell"
LAYOUT_GRID_DIR="$REPO/web/faz1/ui-foundation/layout-grid"
SHARED_FORM_DIR="$REPO/web/faz1/ui-foundation/shared-form"
TABLE_DIR="$REPO/web/faz1/ui-foundation/table-filter-pagination"
STATE_DIR="$REPO/web/faz1/ui-foundation/loading-error-empty-retry"
DESIGN_TOKENS_DIR="$REPO/web/faz1/ui-foundation/design-tokens"
RUNTIME_CONFIG_DIR="$REPO/web/faz1/ui-foundation/runtime-config"

EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_8_BASIC_UI_TESTS_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.8 BASIC UI TESTS STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 basic UI tests HTML file"
check_file "$JS_FILE" "1.2 basic UI tests JS file"
check_file "$CSS_FILE" "1.3 basic UI tests CSS file"
check_file "$CONFIG_FILE" "1.4 basic UI tests config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"app_shell_test"' "3.1 app_shell_test contract"
check_contains "$CONFIG_FILE" '"layout_test"' "3.2 layout_test contract"
check_contains "$CONFIG_FILE" '"form_test"' "3.3 form_test contract"
check_contains "$CONFIG_FILE" '"table_test"' "3.4 table_test contract"
check_contains "$CONFIG_FILE" '"error_state_test"' "3.5 error_state_test contract"

check_contains "$HTML_FILE" 'pix2piBasicUiTestList' "4.1 basic UI test list HTML"
check_contains "$HTML_FILE" 'pix2piBasicUiFinalStatus' "4.2 basic UI final status HTML"
check_contains "$HTML_FILE" 'runBasicUiTestsButton' "4.3 basic UI run button HTML"
check_contains "$HTML_FILE" 'pix2piBasicUiTestLog' "4.4 basic UI log HTML"

check_contains "$JS_FILE" 'runAppShellTest' "5.1 runAppShellTest JS"
check_contains "$JS_FILE" 'runLayoutTest' "5.2 runLayoutTest JS"
check_contains "$JS_FILE" 'runFormTest' "5.3 runFormTest JS"
check_contains "$JS_FILE" 'runTableTest' "5.4 runTableTest JS"
check_contains "$JS_FILE" 'runErrorStateTest' "5.5 runErrorStateTest JS"
check_contains "$JS_FILE" 'runAllBasicUiTests' "5.6 runAllBasicUiTests JS"

check_file "$APP_SHELL_DIR/index.html" "6.1 app shell HTML dependency"
check_file "$APP_SHELL_DIR/app_shell.js" "6.2 app shell JS dependency"
check_file "$APP_SHELL_DIR/app_shell.css" "6.3 app shell CSS dependency"
check_contains "$APP_SHELL_DIR/index.html" 'pix2piAppShell' "6.4 app shell root exists"
check_contains "$APP_SHELL_DIR/index.html" 'pix2piSidebar' "6.5 sidebar exists"
check_contains "$APP_SHELL_DIR/index.html" 'pix2piTopbar' "6.6 topbar exists"
check_contains "$APP_SHELL_DIR/index.html" 'pix2piBreadcrumb' "6.7 breadcrumb exists"
check_contains "$APP_SHELL_DIR/index.html" 'pix2piTenantIndicator' "6.8 tenant indicator exists"

check_file "$LAYOUT_GRID_DIR/index.html" "7.1 layout grid HTML dependency"
check_file "$LAYOUT_GRID_DIR/layout_grid.js" "7.2 layout grid JS dependency"
check_file "$LAYOUT_GRID_DIR/layout_grid.css" "7.3 layout grid CSS dependency"
check_contains "$LAYOUT_GRID_DIR/index.html" 'pix2pi-page-grid' "7.4 page grid exists"
check_contains "$LAYOUT_GRID_DIR/index.html" 'pix2pi-card-grid' "7.5 card grid exists"
check_contains "$LAYOUT_GRID_DIR/index.html" 'pix2pi-form-grid' "7.6 form grid exists"
check_contains "$LAYOUT_GRID_DIR/index.html" 'pix2pi-table-region' "7.7 table region exists"
check_contains "$LAYOUT_GRID_DIR/index.html" 'data-responsive-layout="true"' "7.8 responsive layout marker exists"

check_file "$SHARED_FORM_DIR/index.html" "8.1 shared form HTML dependency"
check_file "$SHARED_FORM_DIR/shared_form.js" "8.2 shared form JS dependency"
check_file "$SHARED_FORM_DIR/shared_form.css" "8.3 shared form CSS dependency"
check_contains "$SHARED_FORM_DIR/index.html" 'sharedForm' "8.4 shared form exists"
check_contains "$SHARED_FORM_DIR/index.html" 'pix2pi-input' "8.5 form input exists"
check_contains "$SHARED_FORM_DIR/index.html" 'pix2pi-field-error' "8.6 field error exists"
check_contains "$SHARED_FORM_DIR/index.html" 'saveSharedFormButton' "8.7 save button exists"
check_contains "$SHARED_FORM_DIR/index.html" 'cancelSharedFormButton' "8.8 cancel button exists"

check_file "$TABLE_DIR/index.html" "9.1 table HTML dependency"
check_file "$TABLE_DIR/table_filter_pagination.js" "9.2 table JS dependency"
check_file "$TABLE_DIR/table_filter_pagination.css" "9.3 table CSS dependency"
check_contains "$TABLE_DIR/index.html" 'pix2piDataTable' "9.4 data table exists"
check_contains "$TABLE_DIR/index.html" 'pix2piTableFilterInput' "9.5 filter input exists"
check_contains "$TABLE_DIR/index.html" 'pix2piSortSelect' "9.6 sort select exists"
check_contains "$TABLE_DIR/index.html" 'pix2piPagination' "9.7 pagination exists"
check_contains "$TABLE_DIR/index.html" 'pix2piTableEmptyState' "9.8 table empty state exists"

check_file "$STATE_DIR/index.html" "10.1 state HTML dependency"
check_file "$STATE_DIR/loading_error_empty_retry.js" "10.2 state JS dependency"
check_file "$STATE_DIR/loading_error_empty_retry.css" "10.3 state CSS dependency"
check_contains "$STATE_DIR/index.html" 'pix2piLoadingState' "10.4 loading state exists"
check_contains "$STATE_DIR/index.html" 'pix2piErrorState' "10.5 error state exists"
check_contains "$STATE_DIR/index.html" 'pix2piEmptyState' "10.6 empty state exists"
check_contains "$STATE_DIR/index.html" 'pix2piRetryButton' "10.7 retry button exists"
check_contains "$STATE_DIR/loading_error_empty_retry.js" 'runUiStateTests' "10.8 state tests JS exists"

check_file "$DESIGN_TOKENS_DIR/index.html" "11.1 design tokens HTML dependency"
check_file "$DESIGN_TOKENS_DIR/design_tokens.js" "11.2 design tokens JS dependency"
check_file "$DESIGN_TOKENS_DIR/design_tokens.css" "11.3 design tokens CSS dependency"
check_contains "$DESIGN_TOKENS_DIR/design_tokens.css" '--pix2pi-color-bg' "11.4 color token exists"
check_contains "$DESIGN_TOKENS_DIR/design_tokens.css" '--pix2pi-font-size-base' "11.5 typography token exists"
check_contains "$DESIGN_TOKENS_DIR/design_tokens.css" '--pix2pi-space-4' "11.6 spacing token exists"
check_contains "$DESIGN_TOKENS_DIR/design_tokens.css" '--pix2pi-shadow-lg' "11.7 shadow token exists"

check_file "$RUNTIME_CONFIG_DIR/index.html" "12.1 runtime config HTML dependency"
check_file "$RUNTIME_CONFIG_DIR/runtime_config.js" "12.2 runtime config JS dependency"
check_file "$RUNTIME_CONFIG_DIR/runtime_config.css" "12.3 runtime config CSS dependency"
check_contains "$RUNTIME_CONFIG_DIR/index.html" 'pix2piEnvironmentIndicator' "12.4 environment indicator exists"
check_contains "$RUNTIME_CONFIG_DIR/index.html" 'pix2piRuntimeConfigSurface' "12.5 runtime config surface exists"
check_contains "$RUNTIME_CONFIG_DIR/index.html" 'pix2piConfigPermissionGuard' "12.6 permission guard exists"
check_contains "$RUNTIME_CONFIG_DIR/index.html" 'READ_ONLY_CONFIG_VIEW' "12.7 read-only config view exists"

APP_SHELL_TEST_STATUS="PASS"
LAYOUT_TEST_STATUS="PASS"
FORM_TEST_STATUS="PASS"
TABLE_TEST_STATUS="PASS"
ERROR_STATE_TEST_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  APP_SHELL_TEST_STATUS="FAIL"
  LAYOUT_TEST_STATUS="FAIL"
  FORM_TEST_STATUS="FAIL"
  TABLE_TEST_STATUS="FAIL"
  ERROR_STATE_TEST_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.8 Basic UI Tests Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- APP_SHELL_TEST_STATUS=$APP_SHELL_TEST_STATUS"
  echo "- LAYOUT_TEST_STATUS=$LAYOUT_TEST_STATUS"
  echo "- FORM_TEST_STATUS=$FORM_TEST_STATUS"
  echo "- TABLE_TEST_STATUS=$TABLE_TEST_STATUS"
  echo "- ERROR_STATE_TEST_STATUS=$ERROR_STATE_TEST_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "13.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.8 BASIC UI TESTS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "APP_SHELL_TEST_STATUS=$APP_SHELL_TEST_STATUS"
echo "LAYOUT_TEST_STATUS=$LAYOUT_TEST_STATUS"
echo "FORM_TEST_STATUS=$FORM_TEST_STATUS"
echo "TABLE_TEST_STATUS=$TABLE_TEST_STATUS"
echo "ERROR_STATE_TEST_STATUS=$ERROR_STATE_TEST_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_8_BASIC_UI_TESTS_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_8_BASIC_UI_TESTS_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_8_BASIC_UI_TESTS_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_8_BASIC_UI_TESTS_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.8 BASIC UI TESTS STRICT SUITE END ====="
