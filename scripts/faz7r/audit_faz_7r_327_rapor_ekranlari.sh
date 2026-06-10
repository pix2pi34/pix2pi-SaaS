#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_327_RAPOR_EKRANLARI.md"
test -f "configs/faz7r/faz_7r_327_rapor_ekranlari.v1.json"
test -f "web/panel/assets/reports/reports-runtime.js"
test -f "web/panel/reports/index.html"
test -f "tests/faz7r/faz_7r_327_rapor_ekranlari_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/reports/reports-runtime.js"
test -f "$PANEL_WEB_ROOT/reports/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_327_rapor_ekranlari.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_327_rapor_ekranlari_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_327_REPORTS_RUNTIME_START" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "validateReportFilters" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "fetchReportsSnapshot" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "buildExportPayload" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "readModelContract" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "fallbackSnapshot" "web/panel/assets/reports/reports-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/reports/reports-runtime.js"

grep -Fq "PIX2PI_327_REPORTS_APP_SHELL_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_KPI_SUMMARY_CARDS_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_SALES_REPORT_SURFACE_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_STOCK_REPORT_SURFACE_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_CUSTOMER_REPORT_SURFACE_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_DOCUMENT_REPORT_SURFACE_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_DATE_RANGE_FILTER_SURFACE_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_EXPORT_PLACEHOLDER_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_REPORTING_STORE_CONTRACT_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_TENANT_SCOPED_REPORT_GUARD_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_RUNTIME_FALLBACK_SNAPSHOT_START" "web/panel/reports/index.html"
grep -Fq "PIX2PI_327_I18N_READY_MARKERS_START" "web/panel/reports/index.html"

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

check_http_200_contains "/reports/" "PIX2PI_327_REPORTS_APP_SHELL_START"
check_http_200_contains "/assets/reports/reports-runtime.js" "PIX2PI_327_REPORTS_RUNTIME_START"
