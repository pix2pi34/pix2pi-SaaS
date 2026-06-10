#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE.md"
test -f "configs/faz7r/faz_7r_354_localization_customer_smoke.v1.json"
test -f "web/panel/localization-customer-smoke/index.html"
test -f "web/panel/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
test -f "tests/faz7r/faz_7r_354_localization_customer_smoke_test.json"
test -f "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
test -f "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_354_localization_customer_smoke.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_354_localization_customer_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_RUNTIME_START" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "localizationScopeHeaders" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "validateLocalizationScope" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "fetchLocalizationSnapshot" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildLanguageRegistrySmoke" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildCalligraphyReferenceBindingCheck" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildRtlLtrLayoutSmoke" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildTranslationCompletenessSmoke" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildHardcodedTextGuardPreview" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "buildLocalizationRuntimeContract" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "Ahmed Hüsrev Altınbaşak" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "https://oku.risale.online/osm" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "otherReferenceSourcesAllowed: false" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"
grep -Fq "readyForStep355: true" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"

grep -Fq "PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_APP_SHELL_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_TENANT_DEFAULT_LANGUAGE_CONTEXT_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_USER_LANGUAGE_PREFERENCE_CONTEXT_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_LANGUAGE_REGISTRY_SMOKE_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_LATIN_TURKISH_SMOKE_TR_TR_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_OTTOMAN_TURKISH_ARABIC_SCRIPT_SMOKE_OTA_TR_ARAB_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_ARABIC_SMOKE_AR_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_FARSI_SMOKE_FA_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_ENGLISH_SMOKE_EN_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_AHMED_HUSREV_CALLIGRAPHY_REFERENCE_BINDING_CHECK_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_RTL_LTR_LAYOUT_SMOKE_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_DATE_TIME_NUMBER_CURRENCY_FORMAT_SMOKE_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_PANEL_POS_MARKETPLACE_LOCALIZATION_READINESS_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_NOTIFICATION_EMAIL_ERROR_LOCALIZATION_READINESS_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_MISSING_TRANSLATION_FALLBACK_PREVIEW_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_HARDCODED_UI_TEXT_GUARD_PREVIEW_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_TRANSLATION_COMPLETENESS_CUSTOMER_SMOKE_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_LOCALIZATION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_LOCALIZATION_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_I18N_READY_SMOKE_MARKER_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
grep -Fq "PIX2PI_354_SEO_OPENGRAPH_LOCALIZATION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"

cmp -s "web/panel/localization-customer-smoke/index.html" "$PANEL_WEB_ROOT/localization-customer-smoke/index.html"
cmp -s "web/panel/assets/localization-customer-smoke/localization-customer-smoke-runtime.js" "$PANEL_WEB_ROOT/assets/localization-customer-smoke/localization-customer-smoke-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

check_http_200_contains_not_pos_market() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "PIX2PI_351_POS_ACCESS_TEST_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_pos_market "/localization-customer-smoke/" "PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_APP_SHELL_START"
check_http_200_contains_not_pos_market "/assets/localization-customer-smoke/localization-customer-smoke-runtime.js" "PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_RUNTIME_START"
