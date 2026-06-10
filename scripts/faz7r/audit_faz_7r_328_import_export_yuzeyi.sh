#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_328_IMPORT_EXPORT_YUZEYI.md"
test -f "configs/faz7r/faz_7r_328_import_export_yuzeyi.v1.json"
test -f "web/panel/assets/import-export/import-export-runtime.js"
test -f "web/panel/import-export/index.html"
test -f "tests/faz7r/faz_7r_328_import_export_yuzeyi_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/import-export/import-export-runtime.js"
test -f "$PANEL_WEB_ROOT/import-export/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_328_import_export_yuzeyi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_328_import_export_yuzeyi_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_328_IMPORT_EXPORT_RUNTIME_START" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "validateImportPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "validateExportPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "buildTemplateRequestPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "buildImportValidationPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "buildImportStartPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "buildExportPayload" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "realFileProcessingEnabled: false" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "productionAccountingExportEnabled: false" "web/panel/assets/import-export/import-export-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/import-export/import-export-runtime.js"

grep -Fq "PIX2PI_328_IMPORT_EXPORT_APP_SHELL_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_CUSTOMER_IMPORT_EXPORT_SURFACE_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_PRODUCT_IMPORT_EXPORT_SURFACE_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_DOCUMENT_EXPORT_SURFACE_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_ACCOUNTING_EXPORT_FORMATS_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_IMPORT_FORM_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_EXPORT_FORM_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_TEMPLATE_DOWNLOAD_PLACEHOLDER_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_STAGING_PREVIEW_PLACEHOLDER_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_MAPPING_VALIDATION_PREVIEW_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_IMPORT_JOB_STATUS_LIST_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_EXPORT_HISTORY_LIST_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_TENANT_SCOPED_IMPORT_EXPORT_GUARD_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_RUNTIME_CONTRACT_START" "web/panel/import-export/index.html"
grep -Fq "PIX2PI_328_I18N_READY_MARKERS_START" "web/panel/import-export/index.html"

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

check_http_200_contains "/import-export/" "PIX2PI_328_IMPORT_EXPORT_APP_SHELL_START"
check_http_200_contains "/assets/import-export/import-export-runtime.js" "PIX2PI_328_IMPORT_EXPORT_RUNTIME_START"
