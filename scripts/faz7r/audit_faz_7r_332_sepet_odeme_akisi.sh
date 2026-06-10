#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_332_SEPET_ODEME_AKISI.md"
test -f "configs/faz7r/faz_7r_332_sepet_odeme_akisi.v1.json"
test -f "web/pos/assets/checkout/pos-checkout-runtime.js"
test -f "web/pos/checkout/index.html"
test -f "tests/faz7r/faz_7r_332_sepet_odeme_akisi_smoke_test.json"

test -f "$POS_WEB_ROOT/assets/checkout/pos-checkout-runtime.js"
test -f "$POS_WEB_ROOT/checkout/index.html"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_332_sepet_odeme_akisi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_332_sepet_odeme_akisi_smoke_test.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_332_POS_CHECKOUT_RUNTIME_START" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "tenantDeviceCashierHeaders" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "loadSaleDraft" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "calculateCartTotals" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "validatePaymentMethod" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "calculateTender" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "validateCheckoutPayload" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "buildCheckoutDraftPayload" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "buildReceiptDraftPayload" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "prepareCheckout" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "prepareReceiptDraft" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "realPaymentEnabled: false" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "realSaleFinalizeEnabled: false" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "readyForStep333: true" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "X-Tenant-ID" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "X-POS-Device-ID" "web/pos/assets/checkout/pos-checkout-runtime.js"
grep -Fq "X-POS-Cashier-Code" "web/pos/assets/checkout/pos-checkout-runtime.js"

grep -Fq "PIX2PI_332_CHECKOUT_APP_SHELL_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_CART_REVIEW_LINE_SUMMARY_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_PAYMENT_METHOD_SELECTION_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_CASH_CARD_QR_PLACEHOLDER_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_TENDER_CHANGE_CALCULATION_CONTRACT_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_RECEIPT_SALE_COMPLETION_DRAFT_PAYLOAD_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_PAYMENT_PROVIDER_DISABLED_GATE_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_REAL_SALE_FINALIZATION_DISABLED_GUARD_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_TENANT_DEVICE_CASHIER_PAYMENT_GUARD_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_OFFLINE_PAYMENT_QUEUE_PLACEHOLDER_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_CHECKOUT_SESSION_STORAGE_CONTRACT_START" "web/pos/checkout/index.html"
grep -Fq "PIX2PI_332_I18N_READY_MARKERS_START" "web/pos/checkout/index.html"

cmp -s "web/pos/checkout/index.html" "$POS_WEB_ROOT/checkout/index.html"
cmp -s "web/pos/assets/checkout/pos-checkout-runtime.js" "$POS_WEB_ROOT/assets/checkout/pos-checkout-runtime.js"

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

check_http_200_contains "/checkout/" "PIX2PI_332_CHECKOUT_APP_SHELL_START"
check_http_200_contains "/assets/checkout/pos-checkout-runtime.js" "PIX2PI_332_POS_CHECKOUT_RUNTIME_START"
