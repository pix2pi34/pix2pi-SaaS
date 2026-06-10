#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_331_POS_SATIS_EKRANI.md"
test -f "configs/faz7r/faz_7r_331_pos_satis_ekrani.v1.json"
test -f "web/pos/assets/sale/pos-sale-runtime.js"
test -f "web/pos/sale/index.html"
test -f "tests/faz7r/faz_7r_331_pos_satis_ekrani_smoke_test.json"

test -f "$POS_WEB_ROOT/assets/sale/pos-sale-runtime.js"
test -f "$POS_WEB_ROOT/sale/index.html"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_331_pos_satis_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_331_pos_satis_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_331_POS_SALE_RUNTIME_START" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "tenantDeviceCashierHeaders" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "verifySessionGuard" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "searchProducts" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "findProductByBarcode" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "addToCart" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "incrementLine" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "decrementLine" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "removeLine" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "calculateCartTotals" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "buildSaleDraftPayload" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "persistSaleDraft" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "realSaleEnabled: false" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "readyForStep332: true" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "X-Tenant-ID" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "X-POS-Device-ID" "web/pos/assets/sale/pos-sale-runtime.js"
grep -Fq "X-POS-Cashier-Code" "web/pos/assets/sale/pos-sale-runtime.js"

grep -Fq "PIX2PI_331_POS_SALE_APP_SHELL_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_CASHIER_SESSION_GUARD_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_PRODUCT_SEARCH_BARCODE_INPUT_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_QUICK_PRODUCT_GRID_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_CART_PREVIEW_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_CART_QUANTITY_REMOVE_BEHAVIOR_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_VAT_TOTAL_CALCULATION_CONTRACT_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_SALE_DRAFT_PAYLOAD_CONTRACT_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_PAYMENT_STEP_REDIRECT_PLACEHOLDER_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_OFFLINE_QUEUE_PLACEHOLDER_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_TENANT_DEVICE_CASHIER_GUARD_START" "web/pos/sale/index.html"
grep -Fq "PIX2PI_331_I18N_READY_MARKERS_START" "web/pos/sale/index.html"

cmp -s "web/pos/sale/index.html" "$POS_WEB_ROOT/sale/index.html"
cmp -s "web/pos/assets/sale/pos-sale-runtime.js" "$POS_WEB_ROOT/assets/sale/pos-sale-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${POS_DOMAIN};"

check_http_200_contains() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${POS_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${POS_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains "/sale/" "PIX2PI_331_POS_SALE_APP_SHELL_START"
check_http_200_contains "/assets/sale/pos-sale-runtime.js" "PIX2PI_331_POS_SALE_RUNTIME_START"
