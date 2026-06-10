#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

python3 -m json.tool "configs/faz7r/faz_7r_318_i18n_alfabe_altyapisi.v1.json" >/dev/null
python3 -m json.tool "configs/faz7r/faz_7r_318_ahmed_husrev_altinbasak_hat_reference.v1.json" >/dev/null
python3 -m json.tool "web/panel/i18n/language-registry.json" >/dev/null
python3 -m json.tool "web/panel/i18n/translation-keys.required.json" >/dev/null
python3 -m json.tool "web/panel/i18n/locales/tr-TR.json" >/dev/null
python3 -m json.tool "web/panel/i18n/locales/ota.json" >/dev/null
python3 -m json.tool "web/panel/i18n/locales/ar.json" >/dev/null
python3 -m json.tool "web/panel/i18n/locales/fa.json" >/dev/null
python3 -m json.tool "web/panel/i18n/locales/en.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_318_i18n_alfabe_altyapisi_smoke_test.json" >/dev/null

python3 - <<'PY'
import json
from pathlib import Path

base = Path("web/panel/i18n")
keys = json.loads((base / "translation-keys.required.json").read_text())
langs = ["tr-TR", "ota", "ar", "fa", "en"]

for lang in langs:
    data = json.loads((base / "locales" / f"{lang}.json").read_text())
    missing = [key for key in keys if key not in data or data[key] == ""]
    if missing:
        raise SystemExit(f"{lang} missing keys: {missing}")

registry = json.loads((base / "language-registry.json").read_text())
assert registry["default_language"] == "tr-TR"
assert registry["fallback_language"] == "tr-TR"
assert registry["language_order"] == ["tr-TR", "ota", "ar", "fa", "en"]
policy = registry["calligraphy_reference_policy"]
assert policy["primary_reference_name"] == "Ahmed Hüsrev Altınbaşak hattı"
assert policy["primary_reference_url"] == "https://oku.risale.online/osm"
assert policy["use_other_reference_sources"] is False

by_code = {item["code"]: item for item in registry["languages"]}
for code in ["ota", "ar"]:
    assert by_code[code]["calligraphy_reference"] == "Ahmed Hüsrev Altınbaşak hattı"
    assert by_code[code]["calligraphy_reference_url"] == "https://oku.risale.online/osm"
PY

grep -Fq "Ahmed Hüsrev Altınbaşak hattı" "docs/faz7r/FAZ_7R_318_I18N_ALFABE_ALTYAPISI.md"
grep -Fq "https://oku.risale.online/osm" "docs/faz7r/FAZ_7R_318_I18N_ALFABE_ALTYAPISI.md"
grep -Fq "Ahmed Hüsrev Altınbaşak hattı" "configs/faz7r/faz_7r_318_i18n_alfabe_altyapisi.v1.json"
grep -Fq "https://oku.risale.online/osm" "configs/faz7r/faz_7r_318_i18n_alfabe_altyapisi.v1.json"
grep -Fq "Ahmed Hüsrev Altınbaşak hattı" "configs/faz7r/faz_7r_318_ahmed_husrev_altinbasak_hat_reference.v1.json"
grep -Fq "https://oku.risale.online/osm" "configs/faz7r/faz_7r_318_ahmed_husrev_altinbasak_hat_reference.v1.json"

grep -Fq "calligraphyReferenceOf" "web/panel/assets/i18n/i18n-runtime.js"
grep -Fq "calligraphyReferenceUrlOf" "web/panel/assets/i18n/i18n-runtime.js"
grep -Fq "useOtherReferenceSources: false" "web/panel/assets/i18n/i18n-runtime.js"
grep -Fq "Ahmed Hüsrev Altınbaşak hattı" "web/panel/assets/i18n/i18n-runtime.js"
grep -Fq "https://oku.risale.online/osm" "web/panel/assets/i18n/i18n-runtime.js"

grep -Fq "PIX2PI_318_AHMED_HUSREV_CALLIGRAPHY_REFERENCE_START" "web/panel/i18n-demo/index.html"
grep -Fq "data-calligraphy-reference-required=\"Ahmed Hüsrev Altınbaşak hattı\"" "web/panel/i18n-demo/index.html"
grep -Fq "data-calligraphy-reference-url=\"https://oku.risale.online/osm\"" "web/panel/i18n-demo/index.html"

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

check_http_200_contains "/i18n-demo/" "PIX2PI_318_AHMED_HUSREV_CALLIGRAPHY_REFERENCE_START"
check_http_200_contains "/assets/i18n/i18n-runtime.js" "calligraphyReferenceOf"
check_http_200_contains "/i18n/language-registry.json" "\"calligraphy_reference\": \"Ahmed Hüsrev Altınbaşak hattı\""
