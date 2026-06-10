#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_324_URUN_STOK_EKRANI.md"
CONFIG_FILE="configs/faz7r/faz_7r_324_urun_stok_ekrani.v1.json"
RUNTIME_FILE="web/panel/assets/products/products-runtime.js"
PRODUCTS_HTML="web/panel/products/index.html"
SMOKE_FILE="tests/faz7r/faz_7r_324_urun_stok_ekrani_smoke_test.json"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$RUNTIME_FILE"
test -f "$PRODUCTS_HTML"
test -f "$SMOKE_FILE"
test -f "$PANEL_WEB_ROOT/products/index.html"
test -f "$PANEL_WEB_ROOT/assets/products/products-runtime.js"

python3 -m json.tool "$CONFIG_FILE" >/dev/null
python3 -m json.tool "$SMOKE_FILE" >/dev/null

grep -Fq "PIX2PI_324_PRODUCTS_RUNTIME_START" "$RUNTIME_FILE"
grep -Fq "tenantScopedHeaders" "$RUNTIME_FILE"
grep -Fq "validateProductPayload" "$RUNTIME_FILE"
grep -Fq "buildProductPayload" "$RUNTIME_FILE"
grep -Fq "buildStockPayload" "$RUNTIME_FILE"
grep -Fq "buildStockSummary" "$RUNTIME_FILE"
grep -Fq "validateVatRate" "$RUNTIME_FILE"
grep -Fq "X-Tenant-ID" "$RUNTIME_FILE"

grep -Fq "PIX2PI_324_PRODUCTS_APP_SHELL_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_PRODUCT_LIST_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_PRODUCT_CREATE_EDIT_FORM_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_SKU_BARCODE_PRODUCT_CODE_FIELDS_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_CATEGORY_BRAND_UNIT_FIELDS_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_VAT_PRICE_FIELDS_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_STOCK_WAREHOUSE_FIELDS_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_PRODUCT_STATUS_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_TENANT_SCOPED_PRODUCT_GUARD_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_PRODUCT_VALIDATION_CONTRACT_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_AUTO_SPARE_PART_COMPATIBILITY_PLACEHOLDER_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_IMPORT_EXPORT_PLACEHOLDER_START" "$PRODUCTS_HTML"
grep -Fq "PIX2PI_324_I18N_READY_MARKERS_START" "$PRODUCTS_HTML"

cmp -s "$PRODUCTS_HTML" "$PANEL_WEB_ROOT/products/index.html"
cmp -s "$RUNTIME_FILE" "$PANEL_WEB_ROOT/assets/products/products-runtime.js"

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

check_http_200_contains "/products/" "PIX2PI_324_PRODUCTS_APP_SHELL_START"
check_http_200_contains "/assets/products/products-runtime.js" "PIX2PI_324_PRODUCTS_RUNTIME_START"
