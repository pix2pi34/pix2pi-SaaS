#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_336_URUN_LISTELEME_EKRANI.md"
test -f "configs/faz7r/faz_7r_336_urun_listeleme_ekrani.v1.json"
test -f "web/market/products/index.html"
test -f "web/market/assets/products/market-products-runtime.js"
test -f "tests/faz7r/faz_7r_336_urun_listeleme_ekrani_smoke_test.json"
test -f "$MARKET_WEB_ROOT/products/index.html"
test -f "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_336_urun_listeleme_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_336_urun_listeleme_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_336_MARKET_PRODUCTS_RUNTIME_START" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "tenantStoreHeaders" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "validateProductScope" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "fetchProductListingSnapshot" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "applyProductFilters" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "sortProducts" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "buildProductListingContract" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "buildQuickPreviewPayload" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "renderProductGrid" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "realBasketEnabled: false" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "readyForStep337: true" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "X-Tenant-ID" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"
grep -Fq "X-Store-Slug" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"

grep -Fq "PIX2PI_336_PRODUCT_LISTING_APP_SHELL_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_STOREFRONT_STORE_SLUG_CONTEXT_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_PRODUCT_SEARCH_BOX_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_CATEGORY_FILTER_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_BRAND_STOCK_PRICE_FILTERS_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_SORT_OPTIONS_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_PRODUCT_CARD_GRID_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_PRODUCT_QUICK_PREVIEW_PLACEHOLDER_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_ADD_TO_BASKET_DISABLED_GATE_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_PAGINATION_LOAD_MORE_PLACEHOLDER_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_TENANT_STORE_PRODUCT_SCOPE_GUARD_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_PRODUCT_LISTING_RUNTIME_DATA_CONTRACT_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_I18N_READY_MARKERS_START" "$MARKET_WEB_ROOT/products/index.html"
grep -Fq "PIX2PI_336_SEO_OPENGRAPH_PRODUCT_LISTING_PLACEHOLDER_START" "$MARKET_WEB_ROOT/products/index.html"

cmp -s "web/market/products/index.html" "$MARKET_WEB_ROOT/products/index.html"
cmp -s "web/market/assets/products/market-products-runtime.js" "$MARKET_WEB_ROOT/assets/products/market-products-runtime.js"

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

check_http_200_contains_not_panel "/products/" "PIX2PI_336_PRODUCT_LISTING_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/products/market-products-runtime.js" "PIX2PI_336_MARKET_PRODUCTS_RUNTIME_START"
