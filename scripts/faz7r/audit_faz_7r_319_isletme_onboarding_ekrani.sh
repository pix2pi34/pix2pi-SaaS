#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_319_ISLETME_ONBOARDING_EKRANI.md"
test -f "configs/faz7r/faz_7r_319_isletme_onboarding_ekrani.v1.json"
test -f "web/panel/assets/onboarding/onboarding-runtime.js"
test -f "web/panel/onboarding/index.html"
test -f "tests/faz7r/faz_7r_319_isletme_onboarding_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/onboarding/onboarding-runtime.js"
test -f "$PANEL_WEB_ROOT/onboarding/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_319_isletme_onboarding_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_319_isletme_onboarding_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_319_ONBOARDING_RUNTIME_START" "web/panel/assets/onboarding/onboarding-runtime.js"
grep -Fq "validateOnboardingPayload" "web/panel/assets/onboarding/onboarding-runtime.js"
grep -Fq "buildTenantBootstrapPayload" "web/panel/assets/onboarding/onboarding-runtime.js"
grep -Fq "saveDraft" "web/panel/assets/onboarding/onboarding-runtime.js"
grep -Fq "submitOnboarding" "web/panel/assets/onboarding/onboarding-runtime.js"
grep -Fq "supportedDefaultLanguages" "web/panel/assets/onboarding/onboarding-runtime.js"

grep -Fq "PIX2PI_319_ONBOARDING_APP_SHELL_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_BUSINESS_IDENTITY_FORM_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_TAX_COMMERCIAL_FORM_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_ADDRESS_CONTACT_FORM_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_OWNER_ADMIN_FORM_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_TENANT_DEFAULT_LANGUAGE_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_ONBOARDING_VALIDATION_CONTRACT_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_TENANT_BOOTSTRAP_PAYLOAD_CONTRACT_START" "web/panel/onboarding/index.html"
grep -Fq "PIX2PI_319_DRAFT_SAVE_CONTINUE_LATER_START" "web/panel/onboarding/index.html"

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

check_http_200_contains "/onboarding/" "PIX2PI_319_ONBOARDING_APP_SHELL_START"
check_http_200_contains "/assets/onboarding/onboarding-runtime.js" "PIX2PI_319_ONBOARDING_RUNTIME_START"
