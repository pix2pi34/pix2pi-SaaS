#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_339_SATICI_YONETIM_EKRANI.md"
test -f "configs/faz7r/faz_7r_339_satici_yonetim_ekrani.v1.json"
test -f "web/market/seller/index.html"
test -f "web/market/assets/seller/market-seller-runtime.js"
test -f "tests/faz7r/faz_7r_339_satici_yonetim_ekrani_smoke_test.json"
test -f "$MARKET_WEB_ROOT/seller/index.html"
test -f "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_339_satici_yonetim_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_339_satici_yonetim_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_339_MARKET_SELLER_RUNTIME_START" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "sellerScopeHeaders" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "validateSellerScope" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "fetchSellerDashboardSnapshot" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "buildSellerRuntimeContract" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "buildDisabledSellerAction" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "realOrderActionEnabled: false" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "realStockUpdateEnabled: false" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "realCampaignPublishEnabled: false" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "realDeliveryOpsEnabled: false" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "readyForStep340: true" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "X-Tenant-ID" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "X-Store-Slug" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"
grep -Fq "X-Market-Seller-Session" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"

grep -Fq "PIX2PI_339_SELLER_MANAGEMENT_APP_SHELL_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_STORE_SELLER_SESSION_CONTEXT_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_STORE_PROFILE_MANAGEMENT_PLACEHOLDER_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_PRODUCT_MANAGEMENT_QUICK_ACTIONS_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_ORDER_MANAGEMENT_PREVIEW_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_ORDER_STATUS_ACTIONS_DISABLED_GATE_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_STOCK_AVAILABILITY_MANAGEMENT_PLACEHOLDER_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_DELIVERY_PICKUP_OPS_CARD_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_CAMPAIGN_STOREFRONT_MANAGEMENT_PLACEHOLDER_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_SELLER_PERFORMANCE_KPI_CARDS_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_SELLER_NOTIFICATION_ALERT_PANEL_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_TENANT_SELLER_STORE_SCOPE_GUARD_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_SELLER_RUNTIME_DATA_CONTRACT_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_I18N_READY_SELLER_MARKERS_START" "$MARKET_WEB_ROOT/seller/index.html"
grep -Fq "PIX2PI_339_SEO_OPENGRAPH_SELLER_PLACEHOLDER_START" "$MARKET_WEB_ROOT/seller/index.html"

cmp -s "web/market/seller/index.html" "$MARKET_WEB_ROOT/seller/index.html"
cmp -s "web/market/assets/seller/market-seller-runtime.js" "$MARKET_WEB_ROOT/assets/seller/market-seller-runtime.js"

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

check_http_200_contains_not_panel "/seller/" "PIX2PI_339_SELLER_MANAGEMENT_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/seller/market-seller-runtime.js" "PIX2PI_339_MARKET_SELLER_RUNTIME_START"
