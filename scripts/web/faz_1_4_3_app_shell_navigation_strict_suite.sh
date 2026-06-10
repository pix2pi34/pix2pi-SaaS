#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/app-shell"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/app_shell.js"
CSS_FILE="$WEB_DIR/app_shell.css"
CONFIG_FILE="$CONFIG_DIR/app_shell_navigation_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"app_shell"' "3.1 app_shell capability contract"
check_contains "$CONFIG_FILE" '"sidebar"' "3.2 sidebar capability contract"
check_contains "$CONFIG_FILE" '"topbar"' "3.3 topbar capability contract"
check_contains "$CONFIG_FILE" '"breadcrumb"' "3.4 breadcrumb capability contract"
check_contains "$CONFIG_FILE" '"tenant_indicator"' "3.5 tenant_indicator capability contract"
check_contains "$CONFIG_FILE" '"responsive_shell"' "3.6 responsive_shell capability contract"

check_contains "$HTML_FILE" 'pix2piAppShell' "4.1 app shell HTML"
check_contains "$HTML_FILE" 'pix2piSidebar' "4.2 sidebar HTML"
check_contains "$HTML_FILE" 'pix2piTopbar' "4.3 topbar HTML"
check_contains "$HTML_FILE" 'pix2piBreadcrumb' "4.4 breadcrumb HTML"
check_contains "$HTML_FILE" 'pix2piTenantIndicator' "4.5 tenant indicator HTML"
check_contains "$HTML_FILE" 'pix2piSidebarToggle' "4.6 mobile sidebar toggle HTML"

check_contains "$JS_FILE" 'renderSidebarNavigation' "5.1 sidebar navigation JS"
check_contains "$JS_FILE" 'renderBreadcrumb' "5.2 breadcrumb JS"
check_contains "$JS_FILE" 'renderTenantIndicator' "5.3 tenant indicator JS"
check_contains "$JS_FILE" 'toggleSidebar' "5.4 responsive sidebar JS"
check_contains "$JS_FILE" 'setActiveRoute' "5.5 route switch JS"
check_contains "$JS_FILE" 'bootstrapAppShellNavigation' "5.6 bootstrap JS"

check_contains "$CSS_FILE" 'pix2pi-app-shell' "6.1 app shell CSS"
check_contains "$CSS_FILE" 'pix2pi-sidebar' "6.2 sidebar CSS"
check_contains "$CSS_FILE" 'pix2pi-topbar' "6.3 topbar CSS"
check_contains "$CSS_FILE" 'pix2pi-breadcrumb' "6.4 breadcrumb CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-indicator' "6.5 tenant indicator CSS"
check_contains "$CSS_FILE" '@media' "6.6 responsive media CSS"

APP_SHELL_STATUS="PASS"
SIDEBAR_STATUS="PASS"
TOPBAR_STATUS="PASS"
BREADCRUMB_STATUS="PASS"
TENANT_INDICATOR_STATUS="PASS"
RESPONSIVE_SHELL_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  APP_SHELL_STATUS="FAIL"
  SIDEBAR_STATUS="FAIL"
  TOPBAR_STATUS="FAIL"
  BREADCRUMB_STATUS="FAIL"
  TENANT_INDICATOR_STATUS="FAIL"
  RESPONSIVE_SHELL_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.3 App Shell / Navigation Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- APP_SHELL_STATUS=$APP_SHELL_STATUS"
  echo "- SIDEBAR_STATUS=$SIDEBAR_STATUS"
  echo "- TOPBAR_STATUS=$TOPBAR_STATUS"
  echo "- BREADCRUMB_STATUS=$BREADCRUMB_STATUS"
  echo "- TENANT_INDICATOR_STATUS=$TENANT_INDICATOR_STATUS"
  echo "- RESPONSIVE_SHELL_STATUS=$RESPONSIVE_SHELL_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "APP_SHELL_STATUS=$APP_SHELL_STATUS"
echo "SIDEBAR_STATUS=$SIDEBAR_STATUS"
echo "TOPBAR_STATUS=$TOPBAR_STATUS"
echo "BREADCRUMB_STATUS=$BREADCRUMB_STATUS"
echo "TENANT_INDICATOR_STATUS=$TENANT_INDICATOR_STATUS"
echo "RESPONSIVE_SHELL_STATUS=$RESPONSIVE_SHELL_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE END ====="
