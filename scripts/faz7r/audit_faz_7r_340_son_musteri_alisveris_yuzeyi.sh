#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_340_SON_MUSTERI_ALISVERIS_YUZEYI.md"
test -f "configs/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi.v1.json"
test -f "web/market/shop/index.html"
test -f "web/market/assets/shop/market-shop-runtime.js"
test -f "tests/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi_smoke_test.json"
test -f "$MARKET_WEB_ROOT/shop/index.html"
test -f "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi_smoke_test.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_340_MARKET_SHOP_RUNTIME_START" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "shoppingScopeHeaders" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "validateShoppingScope" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "fetchShoppingSnapshot" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "buildShoppingRuntimeContract" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "buildDisabledShoppingAction" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "realCustomerLoginEnabled: false" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "realBasketMutationEnabled: false" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "realOrderSubmitEnabled: false" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "realPaymentHandoffEnabled: false" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "readyForStep341: true" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "X-Market-Region" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"
grep -Fq "X-Market-Customer-Session" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"

grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_CUSTOMER_SESSION_ANONYMOUS_CONTEXT_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_REGION_NEIGHBORHOOD_CONTEXT_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_STORE_DISCOVERY_SHORTCUT_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_PRODUCT_DISCOVERY_SHORTCUT_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_BASKET_PREVIEW_WIDGET_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_STOREFRONT_PRODUCTS_ORDER_DEEPLINK_HUB_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_CAMPAIGN_RECOMMENDATION_STRIP_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_DELIVERY_PICKUP_PREFERENCE_SELECTOR_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_ADD_TO_BASKET_DISABLED_GUARD_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_CHECKOUT_ORDER_SUBMIT_DISABLED_GUARD_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_PAYMENT_DISABLED_GUARD_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_CUSTOMER_REGION_STORE_BASKET_SCOPE_GUARD_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_SHOPPING_RUNTIME_DATA_CONTRACT_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_I18N_READY_SHOPPING_MARKER_START" "$MARKET_WEB_ROOT/shop/index.html"
grep -Fq "PIX2PI_340_SEO_OPENGRAPH_SHOPPING_PLACEHOLDER_START" "$MARKET_WEB_ROOT/shop/index.html"

cmp -s "web/market/shop/index.html" "$MARKET_WEB_ROOT/shop/index.html"
cmp -s "web/market/assets/shop/market-shop-runtime.js" "$MARKET_WEB_ROOT/assets/shop/market-shop-runtime.js"

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

check_http_200_contains_not_panel "/shop/" "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/shop/market-shop-runtime.js" "PIX2PI_340_MARKET_SHOP_RUNTIME_START"
