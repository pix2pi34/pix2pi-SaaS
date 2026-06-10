#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_353_KULLANICI_YETKI_KONTROLU.md"
test -f "configs/faz7r/faz_7r_353_kullanici_yetki_kontrolu.v1.json"
test -f "web/panel/user-permission-check/index.html"
test -f "web/panel/assets/user-permission-check/user-permission-check-runtime.js"
test -f "tests/faz7r/faz_7r_353_kullanici_yetki_kontrolu_smoke_test.json"
test -f "$PANEL_WEB_ROOT/user-permission-check/index.html"
test -f "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_353_kullanici_yetki_kontrolu.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_353_kullanici_yetki_kontrolu_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_353_USER_PERMISSION_CHECK_RUNTIME_START" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "permissionScopeHeaders" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "validatePermissionScope" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "fetchPermissionSnapshot" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "buildPermissionDecision" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "buildAdminOnlyDisabledGate" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "buildDenyByDefaultPreview" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "buildUserPermissionRuntimeContract" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "realRbacBackendEnforcementEnabled: false" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "realRoleMutationEnabled: false" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "realAdminOverrideEnabled: false" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"
grep -Fq "readyForStep354: true" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"

grep -Fq "PIX2PI_353_USER_PERMISSION_CHECK_APP_SHELL_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_TENANT_USER_ROLE_SESSION_CONTEXT_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_ROLE_PERMISSION_MATRIX_PREVIEW_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_PERMISSION_DECISION_CONTRACT_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_PANEL_ROUTE_PERMISSION_CHECKS_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_POS_ACTION_PERMISSION_CHECKS_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_MARKETPLACE_ACTION_PERMISSION_CHECKS_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_COMMERCIAL_BILLING_PERMISSION_CHECKS_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_ADMIN_ONLY_ACTION_DISABLED_GATE_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_LEAST_PRIVILEGE_DENY_BY_DEFAULT_PREVIEW_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_ROLE_SWITCH_REGRESSION_PREVIEW_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_UNAUTHORIZED_FORBIDDEN_PERMISSION_STATE_PREVIEW_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_PERMISSION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_TENANT_USER_ROLE_ACTION_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_PERMISSION_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_I18N_READY_PERMISSION_MARKER_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"
grep -Fq "PIX2PI_353_SEO_OPENGRAPH_PERMISSION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/user-permission-check/index.html"

cmp -s "web/panel/user-permission-check/index.html" "$PANEL_WEB_ROOT/user-permission-check/index.html"
cmp -s "web/panel/assets/user-permission-check/user-permission-check-runtime.js" "$PANEL_WEB_ROOT/assets/user-permission-check/user-permission-check-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

check_http_200_contains_not_pos_market() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "PIX2PI_351_POS_ACCESS_TEST_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_pos_market "/user-permission-check/" "PIX2PI_353_USER_PERMISSION_CHECK_APP_SHELL_START"
check_http_200_contains_not_pos_market "/assets/user-permission-check/user-permission-check-runtime.js" "PIX2PI_353_USER_PERMISSION_CHECK_RUNTIME_START"
