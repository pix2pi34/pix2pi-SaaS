#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_344_FATURA_GECMISI_EKRANI.md"
test -f "configs/faz7r/faz_7r_344_fatura_gecmisi_ekrani.v1.json"
test -f "web/panel/invoices/index.html"
test -f "web/panel/assets/invoices/panel-invoices-runtime.js"
test -f "tests/faz7r/faz_7r_344_fatura_gecmisi_ekrani_smoke_test.json"
test -f "$PANEL_WEB_ROOT/invoices/index.html"
test -f "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_344_fatura_gecmisi_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_344_fatura_gecmisi_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_344_PANEL_INVOICES_RUNTIME_START" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "invoiceScopeHeaders" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "validateInvoiceScope" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "fetchInvoiceHistorySnapshot" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "applyInvoiceFilters" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "buildInvoiceDetailPreview" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "buildInvoiceDisabledAction" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "buildInvoiceRuntimeContract" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "realInvoiceIssueEnabled: false" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "realInvoicePdfEnabled: false" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "realEbelgeSendEnabled: false" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "realAccountingExportEnabled: false" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "readyForStep345: true" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "X-Merchant-Session" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"
grep -Fq "X-Invoice-Scope" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"

grep -Fq "PIX2PI_344_INVOICE_HISTORY_APP_SHELL_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_TENANT_MERCHANT_BILLING_CONTEXT_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_INVOICE_LIST_TABLE_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_INVOICE_STATUS_FILTERS_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_DATE_PERIOD_FILTER_PLACEHOLDER_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_INVOICE_DETAIL_PREVIEW_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_AMOUNT_VAT_TOTAL_DISPLAY_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_PAYMENT_STATUS_BADGE_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_PDF_DOWNLOAD_DISABLED_GATE_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_EINVOICE_EARCHIVE_SEND_DISABLED_GATE_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_ACCOUNTING_EXPORT_DISABLED_GATE_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_PAYMENT_RECEIPT_PLACEHOLDER_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_TENANT_INVOICE_BILLING_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_INVOICE_HISTORY_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_I18N_READY_INVOICE_MARKER_START" "$PANEL_WEB_ROOT/invoices/index.html"
grep -Fq "PIX2PI_344_SEO_OPENGRAPH_INVOICE_PLACEHOLDER_START" "$PANEL_WEB_ROOT/invoices/index.html"

cmp -s "web/panel/invoices/index.html" "$PANEL_WEB_ROOT/invoices/index.html"
cmp -s "web/panel/assets/invoices/panel-invoices-runtime.js" "$PANEL_WEB_ROOT/assets/invoices/panel-invoices-runtime.js"

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

check_http_200_contains_not_market "/invoices/" "PIX2PI_344_INVOICE_HISTORY_APP_SHELL_START"
check_http_200_contains_not_market "/assets/invoices/panel-invoices-runtime.js" "PIX2PI_344_PANEL_INVOICES_RUNTIME_START"
