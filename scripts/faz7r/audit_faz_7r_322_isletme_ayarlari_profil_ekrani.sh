#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_322_ISLETME_AYARLARI_PROFIL_EKRANI.md"
test -f "configs/faz7r/faz_7r_322_isletme_ayarlari_profil_ekrani.v1.json"
test -f "web/panel/assets/settings/business-settings-runtime.js"
test -f "web/panel/settings/index.html"
test -f "tests/faz7r/faz_7r_322_isletme_ayarlari_profil_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/settings/business-settings-runtime.js"
test -f "$PANEL_WEB_ROOT/settings/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_322_isletme_ayarlari_profil_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_322_isletme_ayarlari_profil_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_322_BUSINESS_SETTINGS_RUNTIME_START" "web/panel/assets/settings/business-settings-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/settings/business-settings-runtime.js"
grep -Fq "validateSettingsPayload" "web/panel/assets/settings/business-settings-runtime.js"
grep -Fq "buildSettingsPayload" "web/panel/assets/settings/business-settings-runtime.js"
grep -Fq "saveDraft" "web/panel/assets/settings/business-settings-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/settings/business-settings-runtime.js"

grep -Fq "PIX2PI_322_BUSINESS_SETTINGS_APP_SHELL_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_BUSINESS_PROFILE_CARD_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_TAX_COMMERCIAL_SETTINGS_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_ADDRESS_CONTACT_SETTINGS_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_TENANT_DEFAULT_LANGUAGE_SETTING_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_BRAND_LOGO_PLACEHOLDER_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_MODULE_VISIBILITY_SETTINGS_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_NOTIFICATION_PREFERENCES_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_TENANT_SCOPED_SETTINGS_GUARD_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_SETTINGS_VALIDATION_DRAFT_SAVE_START" "web/panel/settings/index.html"
grep -Fq "PIX2PI_322_I18N_READY_MARKERS_START" "web/panel/settings/index.html"

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

check_http_200_contains "/settings/" "PIX2PI_322_BUSINESS_SETTINGS_APP_SHELL_START"
check_http_200_contains "/assets/settings/business-settings-runtime.js" "PIX2PI_322_BUSINESS_SETTINGS_RUNTIME_START"
