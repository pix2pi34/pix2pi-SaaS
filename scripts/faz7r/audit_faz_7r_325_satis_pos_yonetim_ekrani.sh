#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_325_SATIS_POS_YONETIM_EKRANI.md"
test -f "configs/faz7r/faz_7r_325_satis_pos_yonetim_ekrani.v1.json"
test -f "web/panel/assets/sales/sales-pos-runtime.js"
test -f "web/panel/sales/index.html"
test -f "tests/faz7r/faz_7r_325_satis_pos_yonetim_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/sales/sales-pos-runtime.js"
test -f "$PANEL_WEB_ROOT/sales/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_325_satis_pos_yonetim_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_325_satis_pos_yonetim_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_325_SALES_POS_RUNTIME_START" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "fetchSalesSnapshot" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "fetchPosTerminals" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "fetchShiftPolicy" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "buildSaleActionPayload" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "validateSaleAction" "web/panel/assets/sales/sales-pos-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/sales/sales-pos-runtime.js"

grep -Fq "PIX2PI_325_SALES_POS_APP_SHELL_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_SALES_SUMMARY_RECENT_SALES_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_POS_TERMINAL_STATUS_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_CASHIER_DEVICE_REGISTER_PLACEHOLDER_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_RECEIPT_DOCUMENT_FLOW_PREVIEW_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_PAYMENT_METHOD_SUMMARY_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_RETURN_CANCEL_VOID_GUARD_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_SHIFT_POLICY_PLACEHOLDER_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_TENANT_SCOPED_SALES_POS_GUARD_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_RUNTIME_DATA_CONTRACT_START" "web/panel/sales/index.html"
grep -Fq "PIX2PI_325_I18N_READY_MARKERS_START" "web/panel/sales/index.html"

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

check_http_200_contains "/sales/" "PIX2PI_325_SALES_POS_APP_SHELL_START"
check_http_200_contains "/assets/sales/sales-pos-runtime.js" "PIX2PI_325_SALES_POS_RUNTIME_START"
