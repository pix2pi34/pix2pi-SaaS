#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_348_ILK_ISLETME_KULLANICI_DAVETI.md"
test -f "configs/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti.v1.json"
test -f "web/panel/user-invite/index.html"
test -f "web/panel/assets/user-invite/panel-user-invite-runtime.js"
test -f "tests/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti_smoke_test.json"
test -f "$PANEL_WEB_ROOT/user-invite/index.html"
test -f "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_348_PANEL_USER_INVITE_RUNTIME_START" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "inviteScopeHeaders" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "validateInviteScope" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "validateInvitePayload" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "fetchInviteSnapshot" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "buildInviteDraftPayload" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "buildDuplicateInvitationGuard" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "buildInviteSendDisabledGuard" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "buildInviteRuntimeContract" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "realUserCreateEnabled: false" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "realInviteTokenEnabled: false" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "realEmailSendEnabled: false" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "realSmsSendEnabled: false" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "realPasswordSetupEnabled: false" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "readyForStep349: true" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "X-Admin-Session" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"
grep -Fq "X-Invite-Scope" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"

grep -Fq "PIX2PI_348_FIRST_USER_INVITE_APP_SHELL_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_PILOT_TENANT_OWNER_INVITE_CONTEXT_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_INVITE_USER_IDENTITY_FORM_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_OWNER_ADMIN_ROLE_SELECTION_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_TENANT_SCOPE_VALIDATION_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_EMAIL_INVITE_CHANNEL_PLACEHOLDER_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_SMS_WHATSAPP_INVITE_CHANNEL_PLACEHOLDER_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_INVITE_TOKEN_PREVIEW_DISABLED_GATE_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_PASSWORD_SETUP_FLOW_HANDOFF_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_INVITE_SEND_DISABLED_GUARD_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_DUPLICATE_INVITATION_GUARD_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_INVITATION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_USER_ACTIVATION_STATUS_PREVIEW_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_INVITE_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_I18N_READY_INVITE_MARKER_START" "$PANEL_WEB_ROOT/user-invite/index.html"
grep -Fq "PIX2PI_348_SEO_OPENGRAPH_INVITE_PLACEHOLDER_START" "$PANEL_WEB_ROOT/user-invite/index.html"

cmp -s "web/panel/user-invite/index.html" "$PANEL_WEB_ROOT/user-invite/index.html"
cmp -s "web/panel/assets/user-invite/panel-user-invite-runtime.js" "$PANEL_WEB_ROOT/assets/user-invite/panel-user-invite-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

check_http_200_contains_not_market() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  ! grep -Fq "PIX2PI_340_CUSTOMER_SHOPPING_APP_SHELL_START" "$body_file"
  ! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains_not_market "/user-invite/" "PIX2PI_348_FIRST_USER_INVITE_APP_SHELL_START"
check_http_200_contains_not_market "/assets/user-invite/panel-user-invite-runtime.js" "PIX2PI_348_PANEL_USER_INVITE_RUNTIME_START"
