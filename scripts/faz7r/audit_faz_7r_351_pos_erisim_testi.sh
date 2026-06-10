#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="pos.pix2pi.com.tr"
POS_WEB_ROOT="/var/www/pix2pi/pos"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_351_POS_ERISIM_TESTI.md"
test -f "configs/faz7r/faz_7r_351_pos_erisim_testi.v1.json"
test -f "web/pos/pos-access-test/index.html"
test -f "web/pos/assets/pos-access-test/pos-access-test-runtime.js"
test -f "tests/faz7r/faz_7r_351_pos_erisim_testi_smoke_test.json"
test -f "$POS_WEB_ROOT/pos-access-test/index.html"
test -f "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_351_pos_erisim_testi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_351_pos_erisim_testi_smoke_test.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_351_POS_ACCESS_TEST_RUNTIME_START" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "posAccessScopeHeaders" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "validatePosAccessScope" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "fetchPosAccessSnapshot" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "buildPosRouteAccessPreview" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "buildPosDeniedPreview" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "buildPosNavigationHandoff" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "buildPosAccessRuntimeContract" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "realPosLoginEnabled: false" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "realSaleEnabled: false" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "realPaymentEnabled: false" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "realOfflineQueueEnabled: false" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"
grep -Fq "readyForStep352: true" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"

grep -Fq "PIX2PI_351_POS_ACCESS_TEST_APP_SHELL_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_AUTH_SESSION_SIMULATION_CONTEXT_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_TENANT_STORE_REGISTER_CONTEXT_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_CASHIER_OWNER_ROLE_ACCESS_PREVIEW_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_ROUTE_AVAILABILITY_CHECKLIST_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_CASHIER_LOGIN_ACCESS_CHECK_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_SALES_SCREEN_ACCESS_CHECK_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_CART_PAYMENT_FLOW_ACCESS_CHECK_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_OFFLINE_READY_PWA_ASSET_ACCESS_CHECK_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_MOBILE_VIEWPORT_TOUCH_READINESS_CHECK_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_UNAUTHORIZED_FORBIDDEN_PREVIEW_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_SESSION_TIMEOUT_PREVIEW_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_NAVIGATION_HANDOFF_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_ACCESS_AUDIT_TIMELINE_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_TENANT_USER_STORE_REGISTER_SCOPE_GUARD_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_POS_ACCESS_RUNTIME_DATA_CONTRACT_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_I18N_READY_POS_ACCESS_MARKER_START" "$POS_WEB_ROOT/pos-access-test/index.html"
grep -Fq "PIX2PI_351_SEO_OPENGRAPH_POS_ACCESS_PLACEHOLDER_START" "$POS_WEB_ROOT/pos-access-test/index.html"

cmp -s "web/pos/pos-access-test/index.html" "$POS_WEB_ROOT/pos-access-test/index.html"
cmp -s "web/pos/assets/pos-access-test/pos-access-test-runtime.js" "$POS_WEB_ROOT/assets/pos-access-test/pos-access-test-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${POS_DOMAIN};"

check_http_200_contains_not_panel_or_market() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${POS_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${POS_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "PIX2PI_350_PANEL_ACCESS_TEST_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_panel_or_market "/pos-access-test/" "PIX2PI_351_POS_ACCESS_TEST_APP_SHELL_START"
check_http_200_contains_not_panel_or_market "/assets/pos-access-test/pos-access-test-runtime.js" "PIX2PI_351_POS_ACCESS_TEST_RUNTIME_START"
