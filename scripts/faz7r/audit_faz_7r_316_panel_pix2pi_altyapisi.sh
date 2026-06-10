#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_316_PANEL_PIX2PI_ALTYAPISI.md"
test -f "configs/faz7r/faz_7r_316_panel_pix2pi_altyapisi.v1.json"
test -f "web/panel/index.html"
test -f "web/panel/health.json"
test -f "tests/faz7r/faz_7r_316_panel_smoke_test.json"
test -f "infra/nginx/00_pix2pi_panel.conf"
test -f "$PANEL_WEB_ROOT/index.html"
test -f "$PANEL_WEB_ROOT/health.json"

python3 -m json.tool "configs/faz7r/faz_7r_316_panel_pix2pi_altyapisi.v1.json" >/dev/null
python3 -m json.tool "web/panel/health.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_316_panel_smoke_test.json" >/dev/null

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "PIX2PI_PANEL_316_ROUTE_START"
nginx -T 2>/dev/null | grep -Fq "server_name panel.pix2pi.com.tr;"
nginx -T 2>/dev/null | grep -Fq "root /var/www/pix2pi/panel;"

grep -Fq "PIX2PI_PANEL_APP_SHELL_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_SIDEBAR_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_TOPBAR_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_BREADCRUMB_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_TENANT_INDICATOR_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_RESPONSIVE_SHELL_CSS_START" "web/panel/index.html"
grep -Fq "PIX2PI_PANEL_HEALTH_CHECK_CLIENT_START" "web/panel/index.html"

HEALTH_BODY_FILE="$(mktemp)"
INDEX_BODY_FILE="$(mktemp)"
HEALTH_STATUS="$(curl --noproxy '*' -sS -o "$HEALTH_BODY_FILE" -w "%{http_code}" -H "Host: ${PANEL_DOMAIN}" "http://127.0.0.1/health")"
INDEX_STATUS="$(curl --noproxy '*' -sS -o "$INDEX_BODY_FILE" -w "%{http_code}" -H "Host: ${PANEL_DOMAIN}" "http://127.0.0.1/")"

test "$HEALTH_STATUS" = "200"
test "$INDEX_STATUS" = "200"

grep -Fq '"status":"ok"' "$HEALTH_BODY_FILE"
grep -Fq '"surface":"panel"' "$HEALTH_BODY_FILE"
grep -Fq '"service":"pix2pi-panel"' "$HEALTH_BODY_FILE"

grep -Fq "Pix2pi Merchant Panel" "$INDEX_BODY_FILE"
grep -Fq "PIX2PI_PANEL_APP_SHELL_START" "$INDEX_BODY_FILE"
grep -Fq "tenant-indicator" "$INDEX_BODY_FILE"

rm -f "$HEALTH_BODY_FILE" "$INDEX_BODY_FILE"
