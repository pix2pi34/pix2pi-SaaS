#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_343_ODEME_BILLING_EKRANI.md"
test -f "configs/faz7r/faz_7r_343_odeme_billing_ekrani.v1.json"
test -f "web/panel/billing/index.html"
test -f "web/panel/assets/billing/panel-billing-runtime.js"
test -f "tests/faz7r/faz_7r_343_odeme_billing_ekrani_smoke_test.json"
test -f "$PANEL_WEB_ROOT/billing/index.html"
test -f "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_343_odeme_billing_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_343_odeme_billing_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_343_PANEL_BILLING_RUNTIME_START" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "billingScopeHeaders" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "calculateVatBreakdown" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "validateBillingScope" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "fetchBillingSnapshot" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "buildInvoiceDraftPreview" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "buildPaymentAttemptDisabledGuard" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "buildBillingRuntimeContract" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "realPaymentCollectionEnabled: false" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "realCardStorageEnabled: false" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "realProviderTransactionEnabled: false" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "realInvoiceIssueEnabled: false" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "readyForStep344: true" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "X-Merchant-Session" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"
grep -Fq "X-Billing-Scope" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"

grep -Fq "PIX2PI_343_BILLING_APP_SHELL_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_TENANT_MERCHANT_SUBSCRIPTION_CONTEXT_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_BILLING_SUMMARY_CARDS_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_PLAN_PRICE_VAT_TOTAL_BREAKDOWN_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_PAYMENT_METHOD_PLACEHOLDER_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_CARD_STORAGE_PROVIDER_TOKEN_DISABLED_GATE_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_PAYMENT_PROVIDER_SELECTION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_INVOICE_DRAFT_PREVIEW_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_COLLECTION_START_DISABLED_GATE_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_PAYMENT_ATTEMPT_DISABLED_GATE_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_BILLING_APPROVAL_GATES_PANEL_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_FINANCIAL_TAX_LEGAL_APPROVAL_STATUS_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_TENANT_BILLING_PAYMENT_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_BILLING_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_I18N_READY_BILLING_MARKER_START" "$PANEL_WEB_ROOT/billing/index.html"
grep -Fq "PIX2PI_343_SEO_OPENGRAPH_BILLING_PLACEHOLDER_START" "$PANEL_WEB_ROOT/billing/index.html"

cmp -s "web/panel/billing/index.html" "$PANEL_WEB_ROOT/billing/index.html"
cmp -s "web/panel/assets/billing/panel-billing-runtime.js" "$PANEL_WEB_ROOT/assets/billing/panel-billing-runtime.js"

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

check_http_200_contains_not_market "/billing/" "PIX2PI_343_BILLING_APP_SHELL_START"
check_http_200_contains_not_market "/assets/billing/panel-billing-runtime.js" "PIX2PI_343_PANEL_BILLING_RUNTIME_START"
