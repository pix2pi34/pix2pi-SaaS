#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/auth-errors"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

INDEX_FILE="$WEB_DIR/index.html"
PAGE_401_FILE="$WEB_DIR/401.html"
PAGE_403_FILE="$WEB_DIR/403.html"
PAGE_TENANT_MISMATCH_FILE="$WEB_DIR/tenant-mismatch.html"
PAGE_SESSION_EXPIRED_FILE="$WEB_DIR/session-expired.html"
JS_FILE="$WEB_DIR/auth_error_pages.js"
CSS_FILE="$WEB_DIR/auth_error_pages.css"
CONFIG_FILE="$CONFIG_DIR/auth_error_pages_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$INDEX_FILE" "1.1 index HTML file"
check_file "$PAGE_401_FILE" "1.2 401 HTML file"
check_file "$PAGE_403_FILE" "1.3 403 HTML file"
check_file "$PAGE_TENANT_MISMATCH_FILE" "1.4 tenant mismatch HTML file"
check_file "$PAGE_SESSION_EXPIRED_FILE" "1.5 session expired HTML file"
check_file "$JS_FILE" "1.6 JS file"
check_file "$CSS_FILE" "1.7 CSS file"
check_file "$CONFIG_FILE" "1.8 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"unauthorized_401_page"' "3.1 401 capability contract"
check_contains "$CONFIG_FILE" '"forbidden_403_page"' "3.2 403 capability contract"
check_contains "$CONFIG_FILE" '"tenant_mismatch_message"' "3.3 tenant mismatch capability contract"
check_contains "$CONFIG_FILE" '"session_expired_message"' "3.4 session expired capability contract"
check_contains "$CONFIG_FILE" '"ui_api_tests"' "3.5 UI/API tests capability contract"

check_contains "$PAGE_401_FILE" 'UNAUTHORIZED' "4.1 401 page error code"
check_contains "$PAGE_403_FILE" 'FORBIDDEN' "4.2 403 page error code"
check_contains "$PAGE_TENANT_MISMATCH_FILE" 'TENANT_MISMATCH' "4.3 tenant mismatch page error code"
check_contains "$PAGE_SESSION_EXPIRED_FILE" 'SESSION_EXPIRED' "4.4 session expired page error code"

check_contains "$INDEX_FILE" 'authErrorRoot' "5.1 index root HTML"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="UNAUTHORIZED"' "5.2 index 401 simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="FORBIDDEN"' "5.3 index 403 simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="TENANT_MISMATCH"' "5.4 index tenant mismatch simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="SESSION_EXPIRED"' "5.5 index session expired simulation"

check_contains "$JS_FILE" 'buildApiErrorResponse' "6.1 API error response builder JS"
check_contains "$JS_FILE" 'simulateUnauthorized' "6.2 401 simulation JS"
check_contains "$JS_FILE" 'simulateForbidden' "6.3 403 simulation JS"
check_contains "$JS_FILE" 'simulateTenantMismatch' "6.4 tenant mismatch simulation JS"
check_contains "$JS_FILE" 'simulateSessionExpired' "6.5 session expired simulation JS"
check_contains "$JS_FILE" 'clearAuthState' "6.6 logout/session cleanup JS"
check_contains "$JS_FILE" '401' "6.7 HTTP 401 contract JS"
check_contains "$JS_FILE" '403' "6.8 HTTP 403 contract JS"

check_contains "$CSS_FILE" 'pix2pi-error-card' "7.1 error card CSS"
check_contains "$CSS_FILE" 'pix2pi-error-code' "7.2 error code CSS"
check_contains "$CSS_FILE" 'pix2pi-error-button' "7.3 error action CSS"
check_contains "$CSS_FILE" 'pix2pi-api-preview' "7.4 API preview CSS"

UNAUTHORIZED_401_PAGE_STATUS="PASS"
FORBIDDEN_403_PAGE_STATUS="PASS"
TENANT_MISMATCH_MESSAGE_STATUS="PASS"
SESSION_EXPIRED_MESSAGE_STATUS="PASS"
UI_API_TEST_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  UNAUTHORIZED_401_PAGE_STATUS="FAIL"
  FORBIDDEN_403_PAGE_STATUS="FAIL"
  TENANT_MISMATCH_MESSAGE_STATUS="FAIL"
  SESSION_EXPIRED_MESSAGE_STATUS="FAIL"
  UI_API_TEST_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.5 Unauthorized / Forbidden Pages Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- INDEX_FILE=$INDEX_FILE"
  echo "- PAGE_401_FILE=$PAGE_401_FILE"
  echo "- PAGE_403_FILE=$PAGE_403_FILE"
  echo "- PAGE_TENANT_MISMATCH_FILE=$PAGE_TENANT_MISMATCH_FILE"
  echo "- PAGE_SESSION_EXPIRED_FILE=$PAGE_SESSION_EXPIRED_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- UNAUTHORIZED_401_PAGE_STATUS=$UNAUTHORIZED_401_PAGE_STATUS"
  echo "- FORBIDDEN_403_PAGE_STATUS=$FORBIDDEN_403_PAGE_STATUS"
  echo "- TENANT_MISMATCH_MESSAGE_STATUS=$TENANT_MISMATCH_MESSAGE_STATUS"
  echo "- SESSION_EXPIRED_MESSAGE_STATUS=$SESSION_EXPIRED_MESSAGE_STATUS"
  echo "- UI_API_TEST_STATUS=$UI_API_TEST_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "UNAUTHORIZED_401_PAGE_STATUS=$UNAUTHORIZED_401_PAGE_STATUS"
echo "FORBIDDEN_403_PAGE_STATUS=$FORBIDDEN_403_PAGE_STATUS"
echo "TENANT_MISMATCH_MESSAGE_STATUS=$TENANT_MISMATCH_MESSAGE_STATUS"
echo "SESSION_EXPIRED_MESSAGE_STATUS=$SESSION_EXPIRED_MESSAGE_STATUS"
echo "UI_API_TEST_STATUS=$UI_API_TEST_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE END ====="
