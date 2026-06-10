#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_334_MOBILE_READY_PWA_YUZEYI.md"
test -f "configs/faz7r/faz_7r_334_mobile_ready_pwa_yuzeyi.v1.json"
test -f "web/pos/pwa/index.html"
test -f "web/pos/assets/pwa/pos-pwa-runtime.js"
test -f "web/pos/manifest.json"
test -f "web/pos/sw.js"
test -f "web/pos/offline-fallback.html"

test -f "$POS_WEB_ROOT/pwa/index.html"
test -f "$POS_WEB_ROOT/assets/pwa/pos-pwa-runtime.js"
test -f "$POS_WEB_ROOT/manifest.json"
test -f "$POS_WEB_ROOT/sw.js"
test -f "$POS_WEB_ROOT/offline-fallback.html"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_334_mobile_ready_pwa_yuzeyi.v1.json" >/dev/null
python3 -m json.tool "web/pos/manifest.json" >/dev/null
python3 -m json.tool "$POS_WEB_ROOT/manifest.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_334_MOBILE_READY_PWA_APP_SHELL_START" "$POS_WEB_ROOT/pwa/index.html"
grep -Fq "PIX2PI_334_PWA_MANIFEST_START" "$POS_WEB_ROOT/pwa/index.html"
grep -Fq "PIX2PI_334_SERVICE_WORKER_PLACEHOLDER_START" "$POS_WEB_ROOT/pwa/index.html"
grep -Fq "PIX2PI_334_CACHE_STRATEGY_PLACEHOLDER_START" "$POS_WEB_ROOT/pwa/index.html"
grep -Fq "PIX2PI_334_POS_ROUTE_CACHE_ALLOWLIST_START" "$POS_WEB_ROOT/pwa/index.html"
grep -Fq "PIX2PI_334_I18N_READY_MARKERS_START" "$POS_WEB_ROOT/pwa/index.html"

grep -Fq "PIX2PI_334_POS_PWA_RUNTIME_START" "$POS_WEB_ROOT/assets/pwa/pos-pwa-runtime.js"
grep -Fq "registerServiceWorker" "$POS_WEB_ROOT/assets/pwa/pos-pwa-runtime.js"
grep -Fq "buildSessionPreservationSnapshot" "$POS_WEB_ROOT/assets/pwa/pos-pwa-runtime.js"
grep -Fq "readyForStep335: true" "$POS_WEB_ROOT/assets/pwa/pos-pwa-runtime.js"

grep -Fq "PIX2PI_334_POS_SERVICE_WORKER_START" "$POS_WEB_ROOT/sw.js"
grep -Fq "PIX2PI_PWA_CACHE_ALLOWLIST" "$POS_WEB_ROOT/sw.js"
grep -Fq "PIX2PI_PWA_CACHE_STRATEGY" "$POS_WEB_ROOT/sw.js"
grep -Fq "CACHE_FIRST_STATIC_NETWORK_FALLBACK" "$POS_WEB_ROOT/sw.js"
grep -Fq "/offline-fallback.html" "$POS_WEB_ROOT/sw.js"

grep -Fq "PIX2PI_334_OFFLINE_FALLBACK_PAGE_START" "$POS_WEB_ROOT/offline-fallback.html"

cmp -s "web/pos/sw.js" "$POS_WEB_ROOT/sw.js"

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

check_http_200_contains "/pwa/" "PIX2PI_334_MOBILE_READY_PWA_APP_SHELL_START"
check_http_200_contains "/assets/pwa/pos-pwa-runtime.js" "PIX2PI_334_POS_PWA_RUNTIME_START"
check_http_200_contains "/manifest.json" "\"display\": \"standalone\""
check_http_200_contains "/sw.js" "CACHE_FIRST_STATIC_NETWORK_FALLBACK"
check_http_200_contains "/offline-fallback.html" "PIX2PI_334_OFFLINE_FALLBACK_PAGE_START"
