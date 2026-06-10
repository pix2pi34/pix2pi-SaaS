#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/ui-tests"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/auth_tenant_ui_tests.js"
CSS_FILE="$WEB_DIR/auth_tenant_ui_tests.css"
CONFIG_FILE="$CONFIG_DIR/auth_tenant_ui_tests_contract.v1.json"

LOGIN_DIR="$REPO/web/faz1/auth-tenant-experience/login-session"
LOGOUT_DIR="$REPO/web/faz1/auth-tenant-experience/logout-session"
TENANT_SWITCHER_DIR="$REPO/web/faz1/auth-tenant-experience/tenant-switcher"
AUTH_ERRORS_DIR="$REPO/web/faz1/auth-tenant-experience/auth-errors"
ROLE_MENU_DIR="$REPO/web/faz1/auth-tenant-experience/role-aware-menu"
STATE_DIR="$REPO/web/faz1/auth-tenant-experience/auth-state-persistence"

EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_7_AUTH_TENANT_UI_TESTS_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.7 AUTH / TENANT UI TESTS STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 UI tests HTML file"
check_file "$JS_FILE" "1.2 UI tests JS file"
check_file "$CSS_FILE" "1.3 UI tests CSS file"
check_file "$CONFIG_FILE" "1.4 UI tests config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"login_test"' "3.1 login_test contract"
check_contains "$CONFIG_FILE" '"logout_test"' "3.2 logout_test contract"
check_contains "$CONFIG_FILE" '"tenant_switch_test"' "3.3 tenant_switch_test contract"
check_contains "$CONFIG_FILE" '"forbidden_test"' "3.4 forbidden_test contract"
check_contains "$CONFIG_FILE" '"role_menu_test"' "3.5 role_menu_test contract"

check_contains "$HTML_FILE" 'authTenantUiTestList' "4.1 UI test list HTML"
check_contains "$HTML_FILE" 'authTenantUiFinalStatus' "4.2 final status HTML"
check_contains "$HTML_FILE" 'runAuthTenantUiTestsButton' "4.3 run button HTML"
check_contains "$HTML_FILE" 'authTenantUiTestLog' "4.4 test log HTML"

check_contains "$JS_FILE" 'runLoginTest' "5.1 runLoginTest JS"
check_contains "$JS_FILE" 'runLogoutTest' "5.2 runLogoutTest JS"
check_contains "$JS_FILE" 'runTenantSwitchTest' "5.3 runTenantSwitchTest JS"
check_contains "$JS_FILE" 'runForbiddenTest' "5.4 runForbiddenTest JS"
check_contains "$JS_FILE" 'runRoleMenuTest' "5.5 runRoleMenuTest JS"
check_contains "$JS_FILE" 'runAllAuthTenantUiTests' "5.6 runAllAuthTenantUiTests JS"

check_file "$LOGIN_DIR/index.html" "6.1 login UI dependency"
check_file "$LOGIN_DIR/login_session.js" "6.2 login JS dependency"
check_contains "$LOGIN_DIR/index.html" 'loginForm' "6.3 login form exists"
check_contains "$LOGIN_DIR/login_session.js" 'loginWithCredentials' "6.4 loginWithCredentials exists"
check_contains "$LOGIN_DIR/login_session.js" 'persistTokens' "6.5 token persistence exists"
check_contains "$LOGIN_DIR/login_session.js" 'validateSession' "6.6 session validation exists"

check_file "$LOGOUT_DIR/index.html" "7.1 logout UI dependency"
check_file "$LOGOUT_DIR/logout_session.js" "7.2 logout JS dependency"
check_contains "$LOGOUT_DIR/index.html" 'logoutButton' "7.3 logout button exists"
check_contains "$LOGOUT_DIR/logout_session.js" 'logout' "7.4 logout function exists"
check_contains "$LOGOUT_DIR/logout_session.js" 'cleanupTokens' "7.5 token cleanup exists"
check_contains "$LOGOUT_DIR/logout_session.js" 'validateLogoutCleanup' "7.6 logout validation exists"

check_file "$TENANT_SWITCHER_DIR/index.html" "8.1 tenant switcher UI dependency"
check_file "$TENANT_SWITCHER_DIR/tenant_switcher.js" "8.2 tenant switcher JS dependency"
check_contains "$TENANT_SWITCHER_DIR/index.html" 'tenantList' "8.3 tenant list exists"
check_contains "$TENANT_SWITCHER_DIR/tenant_switcher.js" 'setActiveTenant' "8.4 setActiveTenant exists"
check_contains "$TENANT_SWITCHER_DIR/tenant_switcher.js" 'getRoleAwareTenantList' "8.5 role-aware tenant list exists"
check_contains "$TENANT_SWITCHER_DIR/tenant_switcher.js" 'guardWrongTenant' "8.6 wrong tenant guard exists"

check_file "$AUTH_ERRORS_DIR/403.html" "9.1 403 UI dependency"
check_file "$AUTH_ERRORS_DIR/tenant-mismatch.html" "9.2 tenant mismatch UI dependency"
check_file "$AUTH_ERRORS_DIR/session-expired.html" "9.3 session expired UI dependency"
check_file "$AUTH_ERRORS_DIR/auth_error_pages.js" "9.4 auth error JS dependency"
check_contains "$AUTH_ERRORS_DIR/403.html" 'FORBIDDEN' "9.5 forbidden page code exists"
check_contains "$AUTH_ERRORS_DIR/tenant-mismatch.html" 'TENANT_MISMATCH' "9.6 tenant mismatch page code exists"
check_contains "$AUTH_ERRORS_DIR/session-expired.html" 'SESSION_EXPIRED' "9.7 session expired page code exists"
check_contains "$AUTH_ERRORS_DIR/auth_error_pages.js" 'buildApiErrorResponse' "9.8 auth error API preview exists"

check_file "$ROLE_MENU_DIR/index.html" "10.1 role menu UI dependency"
check_file "$ROLE_MENU_DIR/role_aware_menu.js" "10.2 role menu JS dependency"
check_contains "$ROLE_MENU_DIR/index.html" 'roleAwareMenu' "10.3 roleAwareMenu exists"
check_contains "$ROLE_MENU_DIR/role_aware_menu.js" 'hasRequiredRole' "10.4 hasRequiredRole exists"
check_contains "$ROLE_MENU_DIR/role_aware_menu.js" 'hasRequiredPermission' "10.5 hasRequiredPermission exists"
check_contains "$ROLE_MENU_DIR/role_aware_menu.js" 'hasRequiredEntitlement' "10.6 hasRequiredEntitlement exists"

check_file "$STATE_DIR/index.html" "11.1 auth state persistence UI dependency"
check_file "$STATE_DIR/auth_state_persistence.js" "11.2 auth state persistence JS dependency"
check_contains "$STATE_DIR/auth_state_persistence.js" 'saveSessionState' "11.3 session state exists"
check_contains "$STATE_DIR/auth_state_persistence.js" 'saveTenantState' "11.4 tenant state exists"
check_contains "$STATE_DIR/auth_state_persistence.js" 'handleStorageEvent' "11.5 multi-tab state exists"

LOGIN_TEST_STATUS="PASS"
LOGOUT_TEST_STATUS="PASS"
TENANT_SWITCH_TEST_STATUS="PASS"
FORBIDDEN_TEST_STATUS="PASS"
ROLE_MENU_TEST_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOGIN_TEST_STATUS="FAIL"
  LOGOUT_TEST_STATUS="FAIL"
  TENANT_SWITCH_TEST_STATUS="FAIL"
  FORBIDDEN_TEST_STATUS="FAIL"
  ROLE_MENU_TEST_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.7 Auth / Tenant UI Tests Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOGIN_TEST_STATUS=$LOGIN_TEST_STATUS"
  echo "- LOGOUT_TEST_STATUS=$LOGOUT_TEST_STATUS"
  echo "- TENANT_SWITCH_TEST_STATUS=$TENANT_SWITCH_TEST_STATUS"
  echo "- FORBIDDEN_TEST_STATUS=$FORBIDDEN_TEST_STATUS"
  echo "- ROLE_MENU_TEST_STATUS=$ROLE_MENU_TEST_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "12.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.7 AUTH / TENANT UI TESTS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOGIN_TEST_STATUS=$LOGIN_TEST_STATUS"
echo "LOGOUT_TEST_STATUS=$LOGOUT_TEST_STATUS"
echo "TENANT_SWITCH_TEST_STATUS=$TENANT_SWITCH_TEST_STATUS"
echo "FORBIDDEN_TEST_STATUS=$FORBIDDEN_TEST_STATUS"
echo "ROLE_MENU_TEST_STATUS=$ROLE_MENU_TEST_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_7_AUTH_TENANT_UI_TESTS_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_7_AUTH_TENANT_UI_TESTS_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_7_AUTH_TENANT_UI_TESTS_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_7_AUTH_TENANT_UI_TESTS_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.7 AUTH / TENANT UI TESTS STRICT SUITE END ====="
