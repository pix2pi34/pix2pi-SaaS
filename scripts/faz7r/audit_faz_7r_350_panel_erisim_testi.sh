#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_350_PANEL_ERISIM_TESTI.md"
test -f "configs/faz7r/faz_7r_350_panel_erisim_testi.v1.json"
test -f "web/panel/panel-access-test/index.html"
test -f "web/panel/assets/panel-access-test/panel-access-test-runtime.js"
test -f "tests/faz7r/faz_7r_350_panel_erisim_testi_smoke_test.json"
test -f "$PANEL_WEB_ROOT/panel-access-test/index.html"
test -f "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_350_panel_erisim_testi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_350_panel_erisim_testi_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_350_PANEL_ACCESS_TEST_RUNTIME_START" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "panelAccessScopeHeaders" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "validatePanelAccessScope" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "fetchPanelAccessSnapshot" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "buildRouteAccessPreview" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "buildUnauthorizedPreview" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "buildPanelNavigationHandoff" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "buildPanelAccessRuntimeContract" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "realJwtVerifyEnabled: false" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "realSessionCreateEnabled: false" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "realRbacBackendEnforcementEnabled: false" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "readyForStep351: true" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "X-User-Session" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "X-User-Role" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"
grep -Fq "X-Route-Scope" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"

grep -Fq "PIX2PI_350_PANEL_ACCESS_TEST_APP_SHELL_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_AUTH_SESSION_SIMULATION_CONTEXT_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_TENANT_SELECTED_CONTEXT_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_OWNER_ADMIN_ROLE_ACCESS_PREVIEW_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_PANEL_ROUTE_AVAILABILITY_CHECKLIST_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_DASHBOARD_ACCESS_CHECK_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_USERS_ROLES_ACCESS_CHECK_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_PRODUCTS_STOCK_ACCESS_CHECK_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_BILLING_ENTITLEMENTS_ACCESS_CHECK_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_UNAUTHORIZED_FORBIDDEN_PREVIEW_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_SESSION_TIMEOUT_PREVIEW_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_PANEL_NAVIGATION_HANDOFF_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_ACCESS_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_TENANT_USER_ROLE_ROUTE_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_PANEL_ACCESS_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_I18N_READY_PANEL_ACCESS_MARKER_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"
grep -Fq "PIX2PI_350_SEO_OPENGRAPH_PANEL_ACCESS_PLACEHOLDER_START" "$PANEL_WEB_ROOT/panel-access-test/index.html"

cmp -s "web/panel/panel-access-test/index.html" "$PANEL_WEB_ROOT/panel-access-test/index.html"
cmp -s "web/panel/assets/panel-access-test/panel-access-test-runtime.js" "$PANEL_WEB_ROOT/assets/panel-access-test/panel-access-test-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

check_http_200_contains_not_market() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_market "/panel-access-test/" "PIX2PI_350_PANEL_ACCESS_TEST_APP_SHELL_START"
check_http_200_contains_not_market "/assets/panel-access-test/panel-access-test-runtime.js" "PIX2PI_350_PANEL_ACCESS_TEST_RUNTIME_START"
