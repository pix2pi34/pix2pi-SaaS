#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_349_KULLANICI_SIFRE_GIRIS_AKISI_GERCEK_PASSWORD_SESSION.md"
CONFIG_FILE="configs/faz7r/faz_7r_349_kullanici_sifre_giris_akisi.v1.json"
MIGRATION_FILE="db/migrations/20260511_349_auth_password_flow.sql"
RUNTIME_FILE="internal/auth/passwordflow/password_flow.go"
TEST_FILE="internal/auth/passwordflow/password_flow_test.go"
JS_FILE="web/panel/assets/password-flow/password-flow-runtime.js"
HTML_FILE="web/panel/password-login/index.html"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"
test -f "$JS_FILE"
test -f "$HTML_FILE"
test -f "$PANEL_WEB_ROOT/password-login/index.html"
test -f "$PANEL_WEB_ROOT/assets/password-flow/password-flow-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_password_credentials" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS auth.password_reset_tokens" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS auth.password_flow_events" "$MIGRATION_FILE"

grep -Fq "func (s *Service) SetInitialPassword" "$RUNTIME_FILE"
grep -Fq "func (s *Service) RequestPasswordReset" "$RUNTIME_FILE"
grep -Fq "func (s *Service) CompletePasswordReset" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Login" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ValidateSession" "$RUNTIME_FILE"
grep -Fq "func (s *Service) InitialPasswordHTTP" "$RUNTIME_FILE"
grep -Fq "func (s *Service) LoginHTTP" "$RUNTIME_FILE"

grep -Fq "TestInitialPasswordSetupPersistsCredentialAndAcceptsInvite" "$TEST_FILE"
grep -Fq "TestPasswordPolicyRejectsWeakAndMismatch" "$TEST_FILE"
grep -Fq "TestPasswordResetFlowUpdatesHashAndConsumesToken" "$TEST_FILE"
grep -Fq "TestLoginCreatesSessionForTenant" "$TEST_FILE"
grep -Fq "TestLoginRejectsWrongPasswordAndRequiresTenant" "$TEST_FILE"
grep -Fq "TestSessionValidationTouchesSession" "$TEST_FILE"
grep -Fq "TestHTTPHandlers" "$TEST_FILE"

grep -Fq "PIX2PI_349_PASSWORD_FLOW_RUNTIME_START" "$JS_FILE"
grep -Fq "submitInitialPassword" "$JS_FILE"
grep -Fq "submitLogin" "$JS_FILE"
grep -Fq "submitResetRequest" "$JS_FILE"
grep -Fq "submitResetComplete" "$JS_FILE"

grep -Fq "PIX2PI_349_PASSWORD_LOGIN_SCREEN_START" "$HTML_FILE"
grep -Fq "PIX2PI_349_INITIAL_PASSWORD_FORM_START" "$HTML_FILE"
grep -Fq "PIX2PI_349_LOGIN_FORM_START" "$HTML_FILE"
grep -Fq "PIX2PI_349_PASSWORD_RESET_FORM_START" "$HTML_FILE"
grep -Fq "PIX2PI_349_SESSION_VALIDATION_CONTRACT_START" "$HTML_FILE"

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

go test ./internal/auth/passwordflow

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/password-login/")"
test "$status" = "200"
grep -Fq "PIX2PI_349_PASSWORD_LOGIN_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/password-flow/password-flow-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_349_PASSWORD_FLOW_RUNTIME_START" "$body_file"
rm -f "$body_file"
