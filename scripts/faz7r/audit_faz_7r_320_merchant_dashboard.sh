#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_320_MERCHANT_DASHBOARD.md"
test -f "configs/faz7r/faz_7r_320_merchant_dashboard.v1.json"
test -f "web/panel/assets/dashboard/merchant-dashboard-runtime.js"
test -f "web/panel/dashboard/index.html"
test -f "tests/faz7r/faz_7r_320_merchant_dashboard_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/dashboard/merchant-dashboard-runtime.js"
test -f "$PANEL_WEB_ROOT/dashboard/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_320_merchant_dashboard.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_320_merchant_dashboard_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_320_MERCHANT_DASHBOARD_RUNTIME_START" "web/panel/assets/dashboard/merchant-dashboard-runtime.js"
grep -Fq "fetchDashboardSnapshot" "web/panel/assets/dashboard/merchant-dashboard-runtime.js"
grep -Fq "renderDashboardSnapshot" "web/panel/assets/dashboard/merchant-dashboard-runtime.js"
grep -Fq "fallbackSnapshot" "web/panel/assets/dashboard/merchant-dashboard-runtime.js"

grep -Fq "PIX2PI_320_DASHBOARD_APP_SHELL_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_TENANT_SUMMARY_CARD_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_ONBOARDING_PROGRESS_WIDGET_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_KPI_CARDS_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_QUICK_ACTIONS_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_MODULE_STATUS_CARDS_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_ALERT_NOTIFICATION_PREVIEW_START" "web/panel/dashboard/index.html"
grep -Fq "PIX2PI_320_RUNTIME_DATA_CONTRACT_START" "web/panel/dashboard/index.html"
grep -Fq "data-i18n=\"panel.dashboard\"" "web/panel/dashboard/index.html"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name panel.pix2pi.com.tr;"

check_http_200_contains() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status
  status="$(curl --noproxy '*' -sS -o "$body_file" -w "%{http_code}" -H "Host: ${PANEL_DOMAIN}" "http://127.0.0.1${path}")"
  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains "/dashboard/" "PIX2PI_320_DASHBOARD_APP_SHELL_START"
check_http_200_contains "/assets/dashboard/merchant-dashboard-runtime.js" "PIX2PI_320_MERCHANT_DASHBOARD_RUNTIME_START"
