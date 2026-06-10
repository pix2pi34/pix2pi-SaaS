#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/tenant-switcher"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/tenant_switcher.js"
CSS_FILE="$WEB_DIR/tenant_switcher.css"
CONFIG_FILE="$CONFIG_DIR/tenant_switcher_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"tenant_list"' "3.1 tenant_list capability contract"
check_contains "$CONFIG_FILE" '"active_tenant_indicator"' "3.2 active_tenant_indicator capability contract"
check_contains "$CONFIG_FILE" '"tenant_switch"' "3.3 tenant_switch capability contract"
check_contains "$CONFIG_FILE" '"role_aware_tenant_list"' "3.4 role_aware_tenant_list capability contract"
check_contains "$CONFIG_FILE" '"wrong_tenant_guard"' "3.5 wrong_tenant_guard capability contract"

check_contains "$HTML_FILE" 'activeTenantIndicator' "4.1 active tenant indicator HTML"
check_contains "$HTML_FILE" 'tenantList' "4.2 tenant list HTML"
check_contains "$HTML_FILE" 'tenantSearch' "4.3 tenant search HTML"
check_contains "$HTML_FILE" 'wrongTenantGuard' "4.4 wrong tenant guard HTML"
check_contains "$HTML_FILE" 'simulateWrongTenantButton' "4.5 wrong tenant simulation button HTML"

check_contains "$JS_FILE" 'getTenantList' "5.1 tenant list JS"
check_contains "$JS_FILE" 'getActiveTenant' "5.2 active tenant JS"
check_contains "$JS_FILE" 'setActiveTenant' "5.3 tenant switch JS"
check_contains "$JS_FILE" 'getRoleAwareTenantList' "5.4 role-aware tenant list JS"
check_contains "$JS_FILE" 'canAccessTenant' "5.5 tenant access guard JS"
check_contains "$JS_FILE" 'guardWrongTenant' "5.6 wrong-tenant guard JS"
check_contains "$JS_FILE" 'assertRequestTenant' "5.7 request tenant assertion JS"
check_contains "$JS_FILE" 'pix2pi:tenant-switched' "5.8 tenant switched event JS"

check_contains "$CSS_FILE" 'pix2pi-active-tenant' "6.1 active tenant CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-list' "6.2 tenant list CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-item' "6.3 tenant item CSS"
check_contains "$CSS_FILE" 'pix2pi-guard' "6.4 guard CSS"

TENANT_LIST_STATUS="PASS"
ACTIVE_TENANT_INDICATOR_STATUS="PASS"
TENANT_SWITCH_STATUS="PASS"
ROLE_AWARE_TENANT_LIST_STATUS="PASS"
WRONG_TENANT_GUARD_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  TENANT_LIST_STATUS="FAIL"
  ACTIVE_TENANT_INDICATOR_STATUS="FAIL"
  TENANT_SWITCH_STATUS="FAIL"
  ROLE_AWARE_TENANT_LIST_STATUS="FAIL"
  WRONG_TENANT_GUARD_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.3 Tenant Switcher UX Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- TENANT_LIST_STATUS=$TENANT_LIST_STATUS"
  echo "- ACTIVE_TENANT_INDICATOR_STATUS=$ACTIVE_TENANT_INDICATOR_STATUS"
  echo "- TENANT_SWITCH_STATUS=$TENANT_SWITCH_STATUS"
  echo "- ROLE_AWARE_TENANT_LIST_STATUS=$ROLE_AWARE_TENANT_LIST_STATUS"
  echo "- WRONG_TENANT_GUARD_STATUS=$WRONG_TENANT_GUARD_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TENANT_LIST_STATUS=$TENANT_LIST_STATUS"
echo "ACTIVE_TENANT_INDICATOR_STATUS=$ACTIVE_TENANT_INDICATOR_STATUS"
echo "TENANT_SWITCH_STATUS=$TENANT_SWITCH_STATUS"
echo "ROLE_AWARE_TENANT_LIST_STATUS=$ROLE_AWARE_TENANT_LIST_STATUS"
echo "WRONG_TENANT_GUARD_STATUS=$WRONG_TENANT_GUARD_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE END ====="
