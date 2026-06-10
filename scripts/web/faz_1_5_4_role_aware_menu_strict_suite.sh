#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/role-aware-menu"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/role_aware_menu.js"
CSS_FILE="$WEB_DIR/role_aware_menu.css"
CONFIG_FILE="$CONFIG_DIR/role_aware_menu_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"role_based_menu"' "3.1 role_based_menu capability contract"
check_contains "$CONFIG_FILE" '"permission_based_menu"' "3.2 permission_based_menu capability contract"
check_contains "$CONFIG_FILE" '"feature_entitlement_menu"' "3.3 feature_entitlement_menu capability contract"
check_contains "$CONFIG_FILE" '"accountant_portal_menu"' "3.4 accountant_portal_menu capability contract"
check_contains "$CONFIG_FILE" '"admin_operator_separation"' "3.5 admin_operator_separation capability contract"

check_contains "$HTML_FILE" 'roleProfileSelect' "4.1 role profile selector HTML"
check_contains "$HTML_FILE" 'activeRoles' "4.2 active roles HTML"
check_contains "$HTML_FILE" 'activePermissions' "4.3 active permissions HTML"
check_contains "$HTML_FILE" 'activeEntitlements' "4.4 active entitlements HTML"
check_contains "$HTML_FILE" 'roleAwareMenu' "4.5 role aware menu HTML"
check_contains "$HTML_FILE" 'surfaceWarning' "4.6 surface warning HTML"

check_contains "$JS_FILE" 'hasRequiredRole' "5.1 role based menu JS"
check_contains "$JS_FILE" 'hasRequiredPermission' "5.2 permission based menu JS"
check_contains "$JS_FILE" 'hasRequiredEntitlement' "5.3 feature entitlement menu JS"
check_contains "$JS_FILE" 'accountant:portal' "5.4 accountant portal menu JS"
check_contains "$JS_FILE" 'isAdminSurface' "5.5 admin surface JS"
check_contains "$JS_FILE" 'isOperatorSurface' "5.6 operator surface JS"
check_contains "$JS_FILE" 'classifyMenuItem' "5.7 menu decision runtime JS"
check_contains "$JS_FILE" 'ENTITLEMENT_BLOCKED' "5.8 entitlement blocked decision JS"
check_contains "$JS_FILE" 'AUTH_BLOCKED' "5.9 auth blocked decision JS"

check_contains "$CSS_FILE" 'pix2pi-menu-group' "6.1 menu group CSS"
check_contains "$CSS_FILE" 'pix2pi-menu-item' "6.2 menu item CSS"
check_contains "$CSS_FILE" 'disabled-by-entitlement' "6.3 entitlement disabled CSS"
check_contains "$CSS_FILE" 'hidden-by-auth' "6.4 auth hidden CSS"
check_contains "$CSS_FILE" 'pix2pi-surface-warning' "6.5 surface warning CSS"

ROLE_BASED_MENU_STATUS="PASS"
PERMISSION_BASED_MENU_STATUS="PASS"
FEATURE_ENTITLEMENT_MENU_STATUS="PASS"
ACCOUNTANT_PORTAL_MENU_STATUS="PASS"
ADMIN_OPERATOR_SEPARATION_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  ROLE_BASED_MENU_STATUS="FAIL"
  PERMISSION_BASED_MENU_STATUS="FAIL"
  FEATURE_ENTITLEMENT_MENU_STATUS="FAIL"
  ACCOUNTANT_PORTAL_MENU_STATUS="FAIL"
  ADMIN_OPERATOR_SEPARATION_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.4 Role-aware Menu Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- ROLE_BASED_MENU_STATUS=$ROLE_BASED_MENU_STATUS"
  echo "- PERMISSION_BASED_MENU_STATUS=$PERMISSION_BASED_MENU_STATUS"
  echo "- FEATURE_ENTITLEMENT_MENU_STATUS=$FEATURE_ENTITLEMENT_MENU_STATUS"
  echo "- ACCOUNTANT_PORTAL_MENU_STATUS=$ACCOUNTANT_PORTAL_MENU_STATUS"
  echo "- ADMIN_OPERATOR_SEPARATION_STATUS=$ADMIN_OPERATOR_SEPARATION_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ROLE_BASED_MENU_STATUS=$ROLE_BASED_MENU_STATUS"
echo "PERMISSION_BASED_MENU_STATUS=$PERMISSION_BASED_MENU_STATUS"
echo "FEATURE_ENTITLEMENT_MENU_STATUS=$FEATURE_ENTITLEMENT_MENU_STATUS"
echo "ACCOUNTANT_PORTAL_MENU_STATUS=$ACCOUNTANT_PORTAL_MENU_STATUS"
echo "ADMIN_OPERATOR_SEPARATION_STATUS=$ADMIN_OPERATOR_SEPARATION_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE END ====="
