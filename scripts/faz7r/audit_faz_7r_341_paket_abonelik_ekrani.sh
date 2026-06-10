#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_341_PAKET_ABONELIK_EKRANI.md"
test -f "configs/faz7r/faz_7r_341_paket_abonelik_ekrani.v1.json"
test -f "web/panel/plans/index.html"
test -f "web/panel/assets/plans/panel-plans-runtime.js"
test -f "tests/faz7r/faz_7r_341_paket_abonelik_ekrani_smoke_test.json"
test -f "$PANEL_WEB_ROOT/plans/index.html"
test -f "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_341_paket_abonelik_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_341_paket_abonelik_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_341_PANEL_PLANS_RUNTIME_START" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "commercialScopeHeaders" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "validatePlanScope" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "fetchPlanCatalog" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "buildPlanComparison" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "buildEntitlementPreview" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "buildPlanChangeDisabledGuard" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "buildPlanRuntimeContract" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "realPlanChangeEnabled: false" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "realPaymentCollectionEnabled: false" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "realInvoiceIssueEnabled: false" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "realEntitlementEnforcementEnabled: false" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "readyForStep342: true" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"
grep -Fq "X-Merchant-Session" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"

grep -Fq "PIX2PI_341_PLAN_SUBSCRIPTION_APP_SHELL_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_TENANT_MERCHANT_CONTEXT_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_PLAN_CARDS_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_FEATURE_MATRIX_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_MONTHLY_ANNUAL_PRICE_VIEW_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_CURRENT_PLAN_BADGE_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_UPGRADE_DOWNGRADE_DISABLED_GATE_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_TRIAL_PILOT_PLAN_PLACEHOLDER_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_TAX_VAT_PRICE_NOTE_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_COMMERCIAL_POLICY_NOTE_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_PLAN_COMPARISON_RUNTIME_CONTRACT_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_ENTITLEMENT_PREVIEW_HANDOFF_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_BILLING_HANDOFF_DISABLED_GATE_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_TENANT_PLAN_SUBSCRIPTION_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_I18N_READY_PLAN_MARKER_START" "$PANEL_WEB_ROOT/plans/index.html"
grep -Fq "PIX2PI_341_SEO_OPENGRAPH_PLAN_PLACEHOLDER_START" "$PANEL_WEB_ROOT/plans/index.html"

cmp -s "web/panel/plans/index.html" "$PANEL_WEB_ROOT/plans/index.html"
cmp -s "web/panel/assets/plans/panel-plans-runtime.js" "$PANEL_WEB_ROOT/assets/plans/panel-plans-runtime.js"

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
  ! grep -Fq '"service":"pix2pi-market-storefront"' "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_market "/plans/" "PIX2PI_341_PLAN_SUBSCRIPTION_APP_SHELL_START"
check_http_200_contains_not_market "/assets/plans/panel-plans-runtime.js" "PIX2PI_341_PANEL_PLANS_RUNTIME_START"
