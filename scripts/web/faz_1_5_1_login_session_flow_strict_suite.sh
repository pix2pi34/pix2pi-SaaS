#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/login-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/login_session.js"
CSS_FILE="$WEB_DIR/login_session.css"
CONFIG_FILE="$CONFIG_DIR/login_session_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"login_ui"' "3.1 login_ui capability contract"
check_contains "$CONFIG_FILE" '"token_persistence"' "3.2 token_persistence capability contract"
check_contains "$CONFIG_FILE" '"login_error_states"' "3.3 login_error_states capability contract"
check_contains "$CONFIG_FILE" '"session_validation"' "3.4 session_validation capability contract"
check_contains "$CONFIG_FILE" '"login_tests"' "3.5 login_tests capability contract"

check_contains "$HTML_FILE" 'loginForm' "4.1 login form HTML"
check_contains "$HTML_FILE" 'loginEmail' "4.2 login email HTML"
check_contains "$HTML_FILE" 'loginPassword' "4.3 login password HTML"
check_contains "$HTML_FILE" 'tenantHint' "4.4 tenant hint HTML"
check_contains "$HTML_FILE" 'loginErrorAlert' "4.5 login error alert HTML"
check_contains "$HTML_FILE" 'validateSessionButton' "4.6 session validation button HTML"

check_contains "$JS_FILE" 'validateCredentials' "5.1 credential validation JS"
check_contains "$JS_FILE" 'loginWithCredentials' "5.2 login flow JS"
check_contains "$JS_FILE" 'persistTokens' "5.3 token persistence JS"
check_contains "$JS_FILE" 'persistSession' "5.4 session persistence JS"
check_contains "$JS_FILE" 'persistTenantFromHint' "5.5 tenant persistence JS"
check_contains "$JS_FILE" 'setLoginError' "5.6 login error state JS"
check_contains "$JS_FILE" 'MISSING_CREDENTIALS' "5.7 missing credentials error JS"
check_contains "$JS_FILE" 'INVALID_CREDENTIALS' "5.8 invalid credentials error JS"
check_contains "$JS_FILE" 'TENANT_REQUIRED' "5.9 tenant required error JS"
check_contains "$JS_FILE" 'validateSession' "5.10 session validation JS"
check_contains "$JS_FILE" 'isSessionExpired' "5.11 session expiry JS"
check_contains "$JS_FILE" 'expireSessionForTest' "5.12 login test expiry JS"

check_contains "$CSS_FILE" 'pix2pi-form' "6.1 form CSS"
check_contains "$CSS_FILE" 'pix2pi-alert' "6.2 alert CSS"
check_contains "$CSS_FILE" 'pix2pi-state-row' "6.3 state row CSS"
check_contains "$CSS_FILE" 'pix2pi-button' "6.4 button CSS"

LOGIN_UI_STATUS="PASS"
TOKEN_PERSISTENCE_STATUS="PASS"
LOGIN_ERROR_STATES_STATUS="PASS"
SESSION_VALIDATION_STATUS="PASS"
LOGIN_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOGIN_UI_STATUS="FAIL"
  TOKEN_PERSISTENCE_STATUS="FAIL"
  LOGIN_ERROR_STATES_STATUS="FAIL"
  SESSION_VALIDATION_STATUS="FAIL"
  LOGIN_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.1 Login / Session Flow Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOGIN_UI_STATUS=$LOGIN_UI_STATUS"
  echo "- TOKEN_PERSISTENCE_STATUS=$TOKEN_PERSISTENCE_STATUS"
  echo "- LOGIN_ERROR_STATES_STATUS=$LOGIN_ERROR_STATES_STATUS"
  echo "- SESSION_VALIDATION_STATUS=$SESSION_VALIDATION_STATUS"
  echo "- LOGIN_TESTS_STATUS=$LOGIN_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOGIN_UI_STATUS=$LOGIN_UI_STATUS"
echo "TOKEN_PERSISTENCE_STATUS=$TOKEN_PERSISTENCE_STATUS"
echo "LOGIN_ERROR_STATES_STATUS=$LOGIN_ERROR_STATES_STATUS"
echo "SESSION_VALIDATION_STATUS=$SESSION_VALIDATION_STATUS"
echo "LOGIN_TESTS_STATUS=$LOGIN_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE END ====="
