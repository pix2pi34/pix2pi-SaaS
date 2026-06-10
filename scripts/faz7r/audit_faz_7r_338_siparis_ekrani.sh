#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_338_SIPARIS_EKRANI.md"
test -f "configs/faz7r/faz_7r_338_siparis_ekrani.v1.json"
test -f "web/market/orders/index.html"
test -f "web/market/assets/orders/market-orders-runtime.js"
test -f "tests/faz7r/faz_7r_338_siparis_ekrani_smoke_test.json"
test -f "$MARKET_WEB_ROOT/orders/index.html"
test -f "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_338_siparis_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_338_siparis_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_338_MARKET_ORDERS_RUNTIME_START" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "orderScopeHeaders" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "loadBasketDraft" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "calculateOrderTotals" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "validateOrderScope" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "buildOrderDraftPayload" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "buildPaymentHandoffDraft" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "submitOrderDisabledGuard" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "realOrderSubmitEnabled: false" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "realPaymentHandoffEnabled: false" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "readyForStep339: true" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "X-Tenant-ID" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "X-Store-Slug" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"
grep -Fq "X-Market-Customer-Session" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"

grep -Fq "PIX2PI_338_ORDER_APP_SHELL_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_STORE_CUSTOMER_SESSION_CONTEXT_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_BASKET_ORDER_DRAFT_CONTEXT_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_DELIVERY_PICKUP_SELECTION_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_ADDRESS_DELIVERY_NOTE_PLACEHOLDER_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_ORDER_LINE_ITEMS_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_ORDER_TOTALS_CONTRACT_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_ORDER_STATUS_TIMELINE_DRAFT_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_REAL_ORDER_SUBMIT_DISABLED_GATE_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_PAYMENT_HANDOFF_DISABLED_GATE_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_TENANT_STORE_CUSTOMER_ORDER_SCOPE_GUARD_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_ORDER_RUNTIME_DATA_CONTRACT_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_I18N_READY_ORDER_MARKERS_START" "$MARKET_WEB_ROOT/orders/index.html"
grep -Fq "PIX2PI_338_SEO_OPENGRAPH_ORDER_PLACEHOLDER_START" "$MARKET_WEB_ROOT/orders/index.html"

cmp -s "web/market/orders/index.html" "$MARKET_WEB_ROOT/orders/index.html"
cmp -s "web/market/assets/orders/market-orders-runtime.js" "$MARKET_WEB_ROOT/assets/orders/market-orders-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${MARKET_DOMAIN};"

check_http_200_contains_not_panel() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${MARKET_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${MARKET_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "Pix2pi Merchant Panel" "$body_file"
  ! grep -Fq '"service":"pix2pi-panel"' "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_panel "/orders/" "PIX2PI_338_ORDER_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/orders/market-orders-runtime.js" "PIX2PI_338_MARKET_ORDERS_RUNTIME_START"
