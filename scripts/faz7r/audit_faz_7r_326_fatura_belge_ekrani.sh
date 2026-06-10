#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_326_FATURA_BELGE_EKRANI.md"
test -f "configs/faz7r/faz_7r_326_fatura_belge_ekrani.v1.json"
test -f "web/panel/assets/documents/documents-runtime.js"
test -f "web/panel/documents/index.html"
test -f "tests/faz7r/faz_7r_326_fatura_belge_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/documents/documents-runtime.js"
test -f "$PANEL_WEB_ROOT/documents/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_326_fatura_belge_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_326_fatura_belge_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_326_DOCUMENTS_RUNTIME_START" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "validateDocumentPayload" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "buildDocumentPayload" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "calculateLineTotals" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "providerLiveGate" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "realSendEnabled: false" "web/panel/assets/documents/documents-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/documents/documents-runtime.js"

grep -Fq "PIX2PI_326_DOCUMENTS_APP_SHELL_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_LIST_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_CREATE_EDIT_FORM_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_TYPE_SELECTION_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_CUSTOMER_TAX_PREVIEW_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_LINE_ITEMS_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_VAT_TOTAL_SUMMARY_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_LIFECYCLE_PREVIEW_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_PROVIDER_CLOSED_GATE_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_EXPORT_PLACEHOLDER_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_TENANT_SCOPED_DOCUMENT_GUARD_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_DOCUMENT_VALIDATION_CONTRACT_START" "web/panel/documents/index.html"
grep -Fq "PIX2PI_326_I18N_READY_MARKERS_START" "web/panel/documents/index.html"

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

check_http_200_contains "/documents/" "PIX2PI_326_DOCUMENTS_APP_SHELL_START"
check_http_200_contains "/assets/documents/documents-runtime.js" "PIX2PI_326_DOCUMENTS_RUNTIME_START"
