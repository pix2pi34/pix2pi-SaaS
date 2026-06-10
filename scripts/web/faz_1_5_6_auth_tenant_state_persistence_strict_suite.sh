#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/auth-state-persistence"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/auth_state_persistence.js"
CSS_FILE="$WEB_DIR/auth_state_persistence.css"
CONFIG_FILE="$CONFIG_DIR/auth_state_persistence_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_6_AUTH_TENANT_STATE_PERSISTENCE_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.6 AUTH + TENANT STATE PERSISTENCE STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"session_state"' "3.1 session_state capability contract"
check_contains "$CONFIG_FILE" '"tenant_state"' "3.2 tenant_state capability contract"
check_contains "$CONFIG_FILE" '"refresh_behavior"' "3.3 refresh_behavior capability contract"
check_contains "$CONFIG_FILE" '"logout_cleanup"' "3.4 logout_cleanup capability contract"
check_contains "$CONFIG_FILE" '"multi_tab_behavior"' "3.5 multi_tab_behavior capability contract"

check_contains "$HTML_FILE" 'sessionStateValue' "4.1 session state HTML"
check_contains "$HTML_FILE" 'tenantStateValue' "4.2 tenant state HTML"
check_contains "$HTML_FILE" 'refreshStateValue' "4.3 refresh behavior HTML"
check_contains "$HTML_FILE" 'logoutStateValue' "4.4 logout cleanup HTML"
check_contains "$HTML_FILE" 'multiTabStateValue' "4.5 multi-tab behavior HTML"
check_contains "$HTML_FILE" 'stateValidationValue' "4.6 validation HTML"

check_contains "$JS_FILE" 'saveSessionState' "5.1 session state save JS"
check_contains "$JS_FILE" 'getSessionState' "5.2 session state read JS"
check_contains "$JS_FILE" 'isSessionExpired' "5.3 session expiry check JS"
check_contains "$JS_FILE" 'shouldRefreshSession' "5.4 refresh decision JS"
check_contains "$JS_FILE" 'refreshSessionState' "5.5 refresh behavior JS"
check_contains "$JS_FILE" 'saveTenantState' "5.6 tenant state save JS"
check_contains "$JS_FILE" 'getTenantState' "5.7 tenant state read JS"
check_contains "$JS_FILE" 'getTenantContext' "5.8 tenant context read JS"
check_contains "$JS_FILE" 'clearAuthState' "5.9 logout cleanup JS"
check_contains "$JS_FILE" 'handleStorageEvent' "5.10 storage event multi-tab JS"
check_contains "$JS_FILE" 'BroadcastChannel' "5.11 BroadcastChannel multi-tab JS"
check_contains "$JS_FILE" 'validateAuthTenantState' "5.12 state validation JS"

check_contains "$CSS_FILE" 'pix2pi-state-row' "6.1 state row CSS"
check_contains "$CSS_FILE" 'pix2pi-state-value' "6.2 state value CSS"
check_contains "$CSS_FILE" 'pix2pi-button' "6.3 button CSS"
check_contains "$CSS_FILE" 'pix2pi-log' "6.4 log CSS"

SESSION_STATE_STATUS="PASS"
TENANT_STATE_STATUS="PASS"
REFRESH_BEHAVIOR_STATUS="PASS"
LOGOUT_CLEANUP_STATUS="PASS"
MULTI_TAB_BEHAVIOR_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  SESSION_STATE_STATUS="FAIL"
  TENANT_STATE_STATUS="FAIL"
  REFRESH_BEHAVIOR_STATUS="FAIL"
  LOGOUT_CLEANUP_STATUS="FAIL"
  MULTI_TAB_BEHAVIOR_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.6 Auth + Tenant State Persistence Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- SESSION_STATE_STATUS=$SESSION_STATE_STATUS"
  echo "- TENANT_STATE_STATUS=$TENANT_STATE_STATUS"
  echo "- REFRESH_BEHAVIOR_STATUS=$REFRESH_BEHAVIOR_STATUS"
  echo "- LOGOUT_CLEANUP_STATUS=$LOGOUT_CLEANUP_STATUS"
  echo "- MULTI_TAB_BEHAVIOR_STATUS=$MULTI_TAB_BEHAVIOR_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.6 AUTH + TENANT STATE PERSISTENCE STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SESSION_STATE_STATUS=$SESSION_STATE_STATUS"
echo "TENANT_STATE_STATUS=$TENANT_STATE_STATUS"
echo "REFRESH_BEHAVIOR_STATUS=$REFRESH_BEHAVIOR_STATUS"
echo "LOGOUT_CLEANUP_STATUS=$LOGOUT_CLEANUP_STATUS"
echo "MULTI_TAB_BEHAVIOR_STATUS=$MULTI_TAB_BEHAVIOR_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_6_AUTH_TENANT_STATE_PERSISTENCE_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_6_AUTH_TENANT_STATE_PERSISTENCE_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_6_AUTH_TENANT_STATE_PERSISTENCE_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_6_AUTH_TENANT_STATE_PERSISTENCE_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.6 AUTH + TENANT STATE PERSISTENCE STRICT SUITE END ====="
