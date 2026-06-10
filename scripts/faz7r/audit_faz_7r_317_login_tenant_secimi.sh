#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_317_LOGIN_TENANT_SECIMI.md"
test -f "configs/faz7r/faz_7r_317_login_tenant_secimi.v1.json"
test -f "web/panel/assets/auth/auth-runtime.js"
test -f "web/panel/login/index.html"
test -f "web/panel/tenant-select/index.html"
test -f "web/panel/unauthorized/index.html"
test -f "web/panel/forbidden/index.html"
test -f "web/panel/session-timeout/index.html"
test -f "tests/faz7r/faz_7r_317_login_tenant_secimi_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/auth/auth-runtime.js"
test -f "$PANEL_WEB_ROOT/login/index.html"
test -f "$PANEL_WEB_ROOT/tenant-select/index.html"
test -f "$PANEL_WEB_ROOT/unauthorized/index.html"
test -f "$PANEL_WEB_ROOT/forbidden/index.html"
test -f "$PANEL_WEB_ROOT/session-timeout/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_317_login_tenant_secimi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_317_login_tenant_secimi_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_317_AUTH_RUNTIME_START" "web/panel/assets/auth/auth-runtime.js"
grep -Fq "loginWithJwtConnection" "web/panel/assets/auth/auth-runtime.js"
grep -Fq "tenantPreferenceStorageKey" "web/panel/assets/auth/auth-runtime.js"
grep -Fq "sessionTimeoutMs" "web/panel/assets/auth/auth-runtime.js"
grep -Fq "LOGIN_ERROR_MESSAGES" "web/panel/assets/auth/auth-runtime.js"

grep -Fq "PIX2PI_317_LOGIN_SCREEN_START" "web/panel/login/index.html"
grep -Fq "PIX2PI_317_JWT_LOGIN_CONNECTION_START" "web/panel/login/index.html"
grep -Fq "PIX2PI_317_LOGIN_ERROR_MESSAGES_START" "web/panel/login/index.html"

grep -Fq "PIX2PI_317_TENANT_SELECTION_SCREEN_START" "web/panel/tenant-select/index.html"
grep -Fq "PIX2PI_317_MULTI_TENANT_USER_SUPPORT_START" "web/panel/tenant-select/index.html"
grep -Fq "PIX2PI_317_REMEMBER_TENANT_PREFERENCE_START" "web/panel/tenant-select/index.html"

grep -Fq "PIX2PI_317_UNAUTHORIZED_SCREEN_START" "web/panel/unauthorized/index.html"
grep -Fq "PIX2PI_317_FORBIDDEN_SCREEN_START" "web/panel/forbidden/index.html"
grep -Fq "PIX2PI_317_SESSION_TIMEOUT_BEHAVIOR_START" "web/panel/session-timeout/index.html"

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

check_http_200_contains "/login/" "PIX2PI_317_LOGIN_SCREEN_START"
check_http_200_contains "/tenant-select/" "PIX2PI_317_TENANT_SELECTION_SCREEN_START"
check_http_200_contains "/assets/auth/auth-runtime.js" "PIX2PI_317_AUTH_RUNTIME_START"
check_http_200_contains "/unauthorized/" "PIX2PI_317_UNAUTHORIZED_SCREEN_START"
check_http_200_contains "/forbidden/" "PIX2PI_317_FORBIDDEN_SCREEN_START"
check_http_200_contains "/session-timeout/" "PIX2PI_317_SESSION_TIMEOUT_BEHAVIOR_START"
