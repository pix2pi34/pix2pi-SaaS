#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_337_MARKETPLACE_KESIF_EKRANI.md"
test -f "configs/faz7r/faz_7r_337_marketplace_kesif_ekrani.v1.json"
test -f "web/market/discover/index.html"
test -f "web/market/assets/discover/market-discovery-runtime.js"
test -f "tests/faz7r/faz_7r_337_marketplace_kesif_ekrani_smoke_test.json"
test -f "$MARKET_WEB_ROOT/discover/index.html"
test -f "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_337_marketplace_kesif_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_337_marketplace_kesif_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_337_MARKET_DISCOVERY_RUNTIME_START" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "marketRegionHeaders" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "validateStoreDiscoveryScope" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "fetchDiscoverySnapshot" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "applyDiscoveryFilters" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "sortStores" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "buildDiscoveryContract" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "buildStoreQuickPreview" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "renderStoreGrid" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "realOrderEnabled: false" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "readyForStep338: true" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "X-Market-Region" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"
grep -Fq "X-Market-Customer-Session" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"

grep -Fq "PIX2PI_337_MARKETPLACE_DISCOVERY_APP_SHELL_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_LOCATION_NEIGHBORHOOD_CONTEXT_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_STORE_SEARCH_BOX_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_CATEGORY_DISCOVERY_CARDS_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_NEARBY_STORE_GRID_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_CAMPAIGN_DEAL_STRIPS_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_DELIVERY_PICKUP_OPEN_STORE_FILTERS_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_SORT_OPTIONS_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_STORE_CARD_QUICK_PREVIEW_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_STOREFRONT_PRODUCTS_DEEPLINK_CONTRACT_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_CUSTOMER_SESSION_PLACEHOLDER_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_TENANT_MARKET_REGION_SCOPE_GUARD_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_DISCOVERY_RUNTIME_DATA_CONTRACT_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_I18N_READY_MARKERS_START" "$MARKET_WEB_ROOT/discover/index.html"
grep -Fq "PIX2PI_337_SEO_OPENGRAPH_DISCOVERY_PLACEHOLDER_START" "$MARKET_WEB_ROOT/discover/index.html"

cmp -s "web/market/discover/index.html" "$MARKET_WEB_ROOT/discover/index.html"
cmp -s "web/market/assets/discover/market-discovery-runtime.js" "$MARKET_WEB_ROOT/assets/discover/market-discovery-runtime.js"

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

check_http_200_contains_not_panel "/discover/" "PIX2PI_337_MARKETPLACE_DISCOVERY_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/discover/market-discovery-runtime.js" "PIX2PI_337_MARKET_DISCOVERY_RUNTIME_START"
