#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_323_CARI_EKRANI.md"
test -f "configs/faz7r/faz_7r_323_cari_ekrani.v1.json"
test -f "web/panel/assets/customers/customers-runtime.js"
test -f "web/panel/customers/index.html"
test -f "tests/faz7r/faz_7r_323_cari_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/customers/customers-runtime.js"
test -f "$PANEL_WEB_ROOT/customers/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_323_cari_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_323_cari_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_323_CUSTOMERS_RUNTIME_START" "web/panel/assets/customers/customers-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/customers/customers-runtime.js"
grep -Fq "validateCustomerPayload" "web/panel/assets/customers/customers-runtime.js"
grep -Fq "buildCustomerPayload" "web/panel/assets/customers/customers-runtime.js"
grep -Fq "buildBalanceSummary" "web/panel/assets/customers/customers-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/customers/customers-runtime.js"

grep -Fq "PIX2PI_323_CUSTOMERS_APP_SHELL_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_LIST_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_CREATE_EDIT_FORM_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_SUPPLIER_TYPE_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_TAX_ADDRESS_REQUIRED_FIELDS_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_PHONE_EMAIL_FIELDS_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_BALANCE_SUMMARY_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_STATUS_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_TENANT_SCOPED_CUSTOMER_GUARD_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_CUSTOMER_VALIDATION_CONTRACT_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_IMPORT_EXPORT_PLACEHOLDER_START" "web/panel/customers/index.html"
grep -Fq "PIX2PI_323_I18N_READY_MARKERS_START" "web/panel/customers/index.html"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name panel.pix2pi.com.tr;"

check_http_200_contains() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status
  status="$(curl --noproxy '*' -sS -o "$body_file" -w "%{http_code}" -H "Host: ${PANEL_DOMAIN}" "http://127.0.0.1${path}")"
  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains "/customers/" "PIX2PI_323_CUSTOMERS_APP_SHELL_START"
check_http_200_contains "/assets/customers/customers-runtime.js" "PIX2PI_323_CUSTOMERS_RUNTIME_START"
