#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/logout-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/logout_session.js"
CSS_FILE="$WEB_DIR/logout_session.css"
CONFIG_FILE="$CONFIG_DIR/logout_session_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"logout"' "3.1 logout capability contract"
check_contains "$CONFIG_FILE" '"token_cleanup"' "3.2 token_cleanup capability contract"
check_contains "$CONFIG_FILE" '"expired_session_redirect"' "3.3 expired_session_redirect capability contract"
check_contains "$CONFIG_FILE" '"session_timeout"' "3.4 session_timeout capability contract"
check_contains "$CONFIG_FILE" '"logout_tests"' "3.5 logout_tests capability contract"

check_contains "$HTML_FILE" 'logoutButton' "4.1 logout button HTML"
check_contains "$HTML_FILE" 'tokenCleanupButton' "4.2 token cleanup button HTML"
check_contains "$HTML_FILE" 'createExpiredSessionButton' "4.3 expired session button HTML"
check_contains "$HTML_FILE" 'enforceExpiredRedirectButton' "4.4 expired redirect button HTML"
check_contains "$HTML_FILE" 'startSessionTimeoutButton' "4.5 session timeout button HTML"
check_contains "$HTML_FILE" 'validateLogoutCleanupButton' "4.6 logout tests validation button HTML"

check_contains "$JS_FILE" 'logout' "5.1 logout JS"
check_contains "$JS_FILE" 'cleanupTokens' "5.2 token cleanup JS"
check_contains "$JS_FILE" 'clearSessionAndTenantState' "5.3 clear session and tenant JS"
check_contains "$JS_FILE" 'markSessionExpired' "5.4 session expired signal JS"
check_contains "$JS_FILE" 'redirectExpiredSession' "5.5 expired session redirect JS"
check_contains "$JS_FILE" 'enforceSessionExpiryRedirect' "5.6 expiry enforcement JS"
check_contains "$JS_FILE" 'startSessionTimeoutWatcher' "5.7 session timeout watcher JS"
check_contains "$JS_FILE" 'stopSessionTimeoutWatcher' "5.8 stop timeout watcher JS"
check_contains "$JS_FILE" 'validateLogoutCleanup' "5.9 logout tests validation JS"
check_contains "$JS_FILE" 'session-expired.html' "5.10 session expired redirect target JS"

check_contains "$CSS_FILE" 'pix2pi-button' "6.1 button CSS"
check_contains "$CSS_FILE" 'pix2pi-alert' "6.2 alert CSS"
check_contains "$CSS_FILE" 'pix2pi-state-row' "6.3 state row CSS"
check_contains "$CSS_FILE" 'pix2pi-log' "6.4 log CSS"

LOGOUT_STATUS="PASS"
TOKEN_CLEANUP_STATUS="PASS"
EXPIRED_SESSION_REDIRECT_STATUS="PASS"
SESSION_TIMEOUT_STATUS="PASS"
LOGOUT_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOGOUT_STATUS="FAIL"
  TOKEN_CLEANUP_STATUS="FAIL"
  EXPIRED_SESSION_REDIRECT_STATUS="FAIL"
  SESSION_TIMEOUT_STATUS="FAIL"
  LOGOUT_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.2 Logout / Session Expiry Flow Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOGOUT_STATUS=$LOGOUT_STATUS"
  echo "- TOKEN_CLEANUP_STATUS=$TOKEN_CLEANUP_STATUS"
  echo "- EXPIRED_SESSION_REDIRECT_STATUS=$EXPIRED_SESSION_REDIRECT_STATUS"
  echo "- SESSION_TIMEOUT_STATUS=$SESSION_TIMEOUT_STATUS"
  echo "- LOGOUT_TESTS_STATUS=$LOGOUT_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOGOUT_STATUS=$LOGOUT_STATUS"
echo "TOKEN_CLEANUP_STATUS=$TOKEN_CLEANUP_STATUS"
echo "EXPIRED_SESSION_REDIRECT_STATUS=$EXPIRED_SESSION_REDIRECT_STATUS"
echo "SESSION_TIMEOUT_STATUS=$SESSION_TIMEOUT_STATUS"
echo "LOGOUT_TESTS_STATUS=$LOGOUT_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE END ====="
