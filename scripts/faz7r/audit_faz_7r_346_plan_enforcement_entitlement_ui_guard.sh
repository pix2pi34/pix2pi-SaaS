#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_346_PLAN_ENFORCEMENT_ENTITLEMENT_UI_GUARD.md"
test -f "configs/faz7r/faz_7r_346_plan_enforcement_entitlement_ui_guard.v1.json"
test -f "web/panel/entitlements/index.html"
test -f "web/panel/assets/entitlements/panel-entitlements-runtime.js"
test -f "tests/faz7r/faz_7r_346_plan_enforcement_entitlement_ui_guard_smoke_test.json"
test -f "$PANEL_WEB_ROOT/entitlements/index.html"
test -f "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_346_plan_enforcement_entitlement_ui_guard.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_346_plan_enforcement_entitlement_ui_guard_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_346_PANEL_ENTITLEMENTS_RUNTIME_START" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "entitlementGuardScopeHeaders" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "validateEntitlementScope" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "fetchEntitlementSnapshot" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "decideEntitlement" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "buildRouteAccessDecision" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "buildDisabledUiAction" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "buildEnforcementDryRunResult" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "buildGuardRuntimeContract" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "realBackendEnforcementEnabled: false" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "uiGuardEnabled: true" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "dryRunEnforcementEnabled: true" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "readyForStep347: true" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "X-User-Session" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"
grep -Fq "X-Entitlement-Scope" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"

grep -Fq "PIX2PI_346_ENTITLEMENT_UI_GUARD_APP_SHELL_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_TENANT_USER_ROLE_PLAN_CONTEXT_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_FEATURE_ENTITLEMENT_MATRIX_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_UI_ROUTE_ACCESS_GUARD_PREVIEW_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_POS_ENTITLEMENT_GUARD_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_MARKETPLACE_ENTITLEMENT_GUARD_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_PRODUCT_USER_STORE_QUOTA_GUARD_BRIDGE_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_DISABLED_ACTION_BUTTONS_BY_ENTITLEMENT_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_UPGRADE_REQUIRED_BANNER_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_PLAN_ENFORCEMENT_DRY_RUN_MODE_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_ENFORCEMENT_AUDIT_EVENT_PREVIEW_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_PERMISSION_ENTITLEMENT_DECISION_CONTRACT_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_TENANT_USER_ACTION_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_FRONTEND_GUARD_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_I18N_READY_ENTITLEMENT_MARKER_START" "$PANEL_WEB_ROOT/entitlements/index.html"
grep -Fq "PIX2PI_346_SEO_OPENGRAPH_ENTITLEMENT_PLACEHOLDER_START" "$PANEL_WEB_ROOT/entitlements/index.html"

cmp -s "web/panel/entitlements/index.html" "$PANEL_WEB_ROOT/entitlements/index.html"
cmp -s "web/panel/assets/entitlements/panel-entitlements-runtime.js" "$PANEL_WEB_ROOT/assets/entitlements/panel-entitlements-runtime.js"

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

check_http_200_contains_not_market "/entitlements/" "PIX2PI_346_ENTITLEMENT_UI_GUARD_APP_SHELL_START"
check_http_200_contains_not_market "/assets/entitlements/panel-entitlements-runtime.js" "PIX2PI_346_PANEL_ENTITLEMENTS_RUNTIME_START"
