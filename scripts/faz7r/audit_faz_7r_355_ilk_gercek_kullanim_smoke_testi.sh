#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_355_ILK_GERCEK_KULLANIM_SMOKE_TESTI.md"
test -f "configs/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.v1.json"
test -f "web/panel/first-real-usage-smoke/index.html"
test -f "web/panel/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
test -f "tests/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.json"
test -f "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
test -f "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_355_FIRST_REAL_USAGE_SMOKE_RUNTIME_START" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "firstUsageScopeHeaders" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "validateFirstUsageScope" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "fetchFirstUsageSnapshot" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "buildDependencyGate" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "buildCustomerJourneyChecklist" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "buildDataMutationDisabledGuard" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "buildFirstUsageDecision" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "buildFirstUsageRuntimeContract" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realCustomerGoLiveEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realSaleEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realPaymentEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realInvoiceIssueEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realStockDecrementEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "realDataMutationEnabled: false" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"
grep -Fq "readyForStep356: true" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"

grep -Fq "PIX2PI_355_FIRST_REAL_USAGE_SMOKE_APP_SHELL_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_PILOT_TENANT_OWNER_STORE_REGISTER_SCENARIO_CONTEXT_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_CUSTOMER_JOURNEY_CHECKLIST_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_PANEL_LOGIN_ACCESS_CHAIN_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_TENANT_ISOLATION_GATE_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_USER_PERMISSION_GATE_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_LOCALIZATION_CUSTOMER_SMOKE_DEPENDENCY_CHECK_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_POS_ACCESS_CHAIN_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_MARKETPLACE_STOREFRONT_AVAILABILITY_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_PRODUCT_STOCK_READ_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_CART_PAYMENT_DRY_RUN_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_INVOICE_BILLING_DISABLED_GATE_SMOKE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_AUDIT_CORRELATION_TIMELINE_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_DATA_MUTATION_DISABLED_SAFETY_GUARD_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_ROLLBACK_STOP_CRITERIA_PREVIEW_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_FIRST_USAGE_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_I18N_READY_FIRST_USAGE_MARKER_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
grep -Fq "PIX2PI_355_SEO_OPENGRAPH_FIRST_USAGE_PLACEHOLDER_START" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"

cmp -s "web/panel/first-real-usage-smoke/index.html" "$PANEL_WEB_ROOT/first-real-usage-smoke/index.html"
cmp -s "web/panel/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js" "$PANEL_WEB_ROOT/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js"

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

check_http_200_contains_not_pos_market "/first-real-usage-smoke/" "PIX2PI_355_FIRST_REAL_USAGE_SMOKE_APP_SHELL_START"
check_http_200_contains_not_pos_market "/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js" "PIX2PI_355_FIRST_REAL_USAGE_SMOKE_RUNTIME_START"
