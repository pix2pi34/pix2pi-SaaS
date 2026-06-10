#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_329_POS_PIX2PI_ALTYAPISI.md"
test -f "configs/faz7r/faz_7r_329_pos_pix2pi_altyapisi.v1.json"
test -f "web/pos/index.html"
test -f "web/pos/health.json"
test -f "web/pos/assets/pos-shell-runtime.js"
test -f "infra/nginx/00_pix2pi_pos.conf"
test -f "$ACTIVE_NGINX_ROUTE"

test -f "$POS_WEB_ROOT/index.html"
test -f "$POS_WEB_ROOT/health.json"
test -f "$POS_WEB_ROOT/assets/pos-shell-runtime.js"

python3 -m json.tool "configs/faz7r/faz_7r_329_pos_pix2pi_altyapisi.v1.json" >/dev/null
python3 -m json.tool "web/pos/health.json" >/dev/null
python3 -m json.tool "$POS_WEB_ROOT/health.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "PIX2PI_329_POS_NGINX_ROUTE_START" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_329_POS_APP_SHELL_START" "$POS_WEB_ROOT/index.html"
grep -Fq "PIX2PI_329_POS_MOBILE_FIRST_SHELL_START" "$POS_WEB_ROOT/index.html"
grep -Fq "PIX2PI_329_POS_PWA_PLACEHOLDER_START" "$POS_WEB_ROOT/index.html"
grep -Fq "PIX2PI_329_POS_TENANT_SESSION_PLACEHOLDER_START" "$POS_WEB_ROOT/index.html"
grep -Fq "PIX2PI_329_POS_RUNTIME_CONTRACT_START" "$POS_WEB_ROOT/index.html"

grep -Fq "PIX2PI_329_POS_SHELL_RUNTIME_START" "$POS_WEB_ROOT/assets/pos-shell-runtime.js"
grep -Fq "bootPOSShell" "$POS_WEB_ROOT/assets/pos-shell-runtime.js"
grep -Fq "realCashierLoginEnabled: false" "$POS_WEB_ROOT/assets/pos-shell-runtime.js"
grep -Fq "readyForCashierLoginStep330: true" "$POS_WEB_ROOT/assets/pos-shell-runtime.js"

cmp -s "web/pos/index.html" "$POS_WEB_ROOT/index.html"
cmp -s "web/pos/health.json" "$POS_WEB_ROOT/health.json"
cmp -s "web/pos/assets/pos-shell-runtime.js" "$POS_WEB_ROOT/assets/pos-shell-runtime.js"
cmp -s "infra/nginx/00_pix2pi_pos.conf" "$ACTIVE_NGINX_ROUTE"

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

  if [[ "$path" = "/health" ]]; then
    python3 - "$body_file" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
assert data.get("status") == "ok"
assert data.get("service") == "pix2pi-pos"
assert data.get("surface") == "pos"
assert str(data.get("step")) == "329"
PY
  else
    grep -Fq "$marker" "$body_file"
  fi

  rm -f "$body_file"
}

check_http_200_contains "/" "PIX2PI_329_POS_APP_SHELL_START"
check_http_200_contains "/health" "pix2pi-pos"
check_http_200_contains "/assets/pos-shell-runtime.js" "PIX2PI_329_POS_SHELL_RUNTIME_START"
