#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_330_KASIYER_GIRIS_EKRANI.md"
test -f "configs/faz7r/faz_7r_330_kasiyer_giris_ekrani.v1.json"
test -f "web/pos/assets/login/cashier-login-runtime.js"
test -f "web/pos/login/index.html"
test -f "tests/faz7r/faz_7r_330_kasiyer_giris_ekrani_smoke_test.json"

test -f "$POS_WEB_ROOT/assets/login/cashier-login-runtime.js"
test -f "$POS_WEB_ROOT/login/index.html"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_330_kasiyer_giris_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_330_kasiyer_giris_ekrani_smoke_test.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_330_CASHIER_LOGIN_RUNTIME_START" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "tenantDeviceHeaders" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "validateLoginPayload" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "buildLoginPayload" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "buildDemoSession" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "saveCashierSession" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "verifyCashierSession" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "realBackendLoginEnabled: false" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "readyForStep331: true" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "X-Tenant-ID" "web/pos/assets/login/cashier-login-runtime.js"
grep -Fq "X-POS-Device-ID" "web/pos/assets/login/cashier-login-runtime.js"

grep -Fq "PIX2PI_330_CASHIER_LOGIN_APP_SHELL_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_CASHIER_CODE_PIN_FORM_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_TENANT_CONTEXT_INDICATOR_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_DEVICE_REGISTER_PLACEHOLDER_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_AUTH_ENDPOINT_CONTRACT_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_SESSION_STORAGE_CONTRACT_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_LOGIN_VALIDATION_CONTRACT_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_ERROR_LOCKOUT_MESSAGES_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_POS_SALE_REDIRECT_PLACEHOLDER_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_OFFLINE_LOGIN_POLICY_PLACEHOLDER_START" "web/pos/login/index.html"
grep -Fq "PIX2PI_330_I18N_READY_MARKERS_START" "web/pos/login/index.html"

cmp -s "web/pos/login/index.html" "$POS_WEB_ROOT/login/index.html"
cmp -s "web/pos/assets/login/cashier-login-runtime.js" "$POS_WEB_ROOT/assets/login/cashier-login-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${POS_DOMAIN};"

check_http_200_contains() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${POS_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${POS_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains "/login/" "PIX2PI_330_CASHIER_LOGIN_APP_SHELL_START"
check_http_200_contains "/assets/login/cashier-login-runtime.js" "PIX2PI_330_CASHIER_LOGIN_RUNTIME_START"
