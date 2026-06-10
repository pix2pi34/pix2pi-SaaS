#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
MARKET_DOMAIN="market.pix2pi.com.tr"
MARKET_WEB_ROOT="/var/www/pix2pi/market"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_market.conf"

cd "$REPO"

test -f "web/market/storefront/index.html"
test -f "web/market/assets/storefront/market-storefront-runtime.js"
test -f "web/market/health.json"
test -f "infra/nginx/00_pix2pi_market.conf"
test -f "$MARKET_WEB_ROOT/storefront/index.html"
test -f "$MARKET_WEB_ROOT/assets/storefront/market-storefront-runtime.js"
test -f "$MARKET_WEB_ROOT/health.json"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "web/market/health.json" >/dev/null
python3 -m json.tool "$MARKET_WEB_ROOT/health.json" >/dev/null
python3 -m json.tool "configs/faz7r/faz_7r_335_isletme_magaza_vitrini.v1.json" >/dev/null

grep -Fq "server_name ${MARKET_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${MARKET_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "FIX_V2_MARKET_DOMAIN_ISOLATION" "$ACTIVE_NGINX_ROUTE"
grep -Fq "PIX2PI_335_MARKET_NGINX_ROUTE_START" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$MARKET_WEB_ROOT/storefront/index.html"
grep -Fq "PIX2PI_335_MARKET_STOREFRONT_RUNTIME_START" "$MARKET_WEB_ROOT/assets/storefront/market-storefront-runtime.js"

cmp -s "web/market/storefront/index.html" "$MARKET_WEB_ROOT/storefront/index.html"
cmp -s "web/market/assets/storefront/market-storefront-runtime.js" "$MARKET_WEB_ROOT/assets/storefront/market-storefront-runtime.js"
cmp -s "web/market/health.json" "$MARKET_WEB_ROOT/health.json"
cmp -s "infra/nginx/00_pix2pi_market.conf" "$ACTIVE_NGINX_ROUTE"

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
  ! grep -Fq '"surface":"panel"' "$body_file"
  ! grep -Fq '"service":"pix2pi-panel"' "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_panel "/storefront/" "PIX2PI_335_STOREFRONT_APP_SHELL_START"
check_http_200_contains_not_panel "/assets/storefront/market-storefront-runtime.js" "PIX2PI_335_MARKET_STOREFRONT_RUNTIME_START"
check_http_200_contains_not_panel "/health" "pix2pi-market-storefront"
