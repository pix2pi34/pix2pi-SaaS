#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.pix2pi.com.tr}"
PANEL_WEB_ROOT="${PANEL_WEB_ROOT:-/var/www/pix2pi/panel}"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_321_KULLANICI_ROL_PERSONEL_EKRANI.md"
test -f "configs/faz7r/faz_7r_321_kullanici_rol_personel_ekrani.v1.json"
test -f "web/panel/assets/users/users-runtime.js"
test -f "web/panel/users/index.html"
test -f "tests/faz7r/faz_7r_321_kullanici_rol_personel_ekrani_smoke_test.json"

test -f "$PANEL_WEB_ROOT/assets/users/users-runtime.js"
test -f "$PANEL_WEB_ROOT/users/index.html"

python3 -m json.tool "configs/faz7r/faz_7r_321_kullanici_rol_personel_ekrani.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_321_kullanici_rol_personel_ekrani_smoke_test.json" >/dev/null

grep -Fq "PIX2PI_321_USERS_RUNTIME_START" "web/panel/assets/users/users-runtime.js"
grep -Fq "tenantScopedHeaders" "web/panel/assets/users/users-runtime.js"
grep -Fq "validateInvitePayload" "web/panel/assets/users/users-runtime.js"
grep -Fq "buildInvitePayload" "web/panel/assets/users/users-runtime.js"
grep -Fq "buildRoleAssignmentPayload" "web/panel/assets/users/users-runtime.js"
grep -Fq "buildStatusUpdatePayload" "web/panel/assets/users/users-runtime.js"
grep -Fq "buildPermissionMatrix" "web/panel/assets/users/users-runtime.js"
grep -Fq "X-Tenant-ID" "web/panel/assets/users/users-runtime.js"

grep -Fq "PIX2PI_321_USERS_APP_SHELL_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_USER_LIST_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_INVITE_USER_FORM_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_ROLE_ASSIGNMENT_SURFACE_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_PERSONNEL_PROFILE_CARD_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_PERMISSION_MATRIX_PREVIEW_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_TENANT_SCOPED_USER_GUARD_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_ACTIVATION_SUSPEND_BEHAVIOR_START" "web/panel/users/index.html"
grep -Fq "PIX2PI_321_I18N_READY_MARKERS_START" "web/panel/users/index.html"

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

check_http_200_contains "/users/" "PIX2PI_321_USERS_APP_SHELL_START"
check_http_200_contains "/assets/users/users-runtime.js" "PIX2PI_321_USERS_RUNTIME_START"
