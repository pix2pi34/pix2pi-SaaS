#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_8_UNAUTHORIZED_FORBIDDEN_EKRANLARI.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_8_unauthorized_forbidden_ekranlari.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_8_auth_access_denial_events.sql"
RUNTIME_FILE="internal/auth/accessdenial/access_denial.go"
TEST_FILE="internal/auth/accessdenial/access_denial_test.go"
JS_FILE="web/panel/assets/access-denial/access-denial-runtime.js"
UNAUTHORIZED_HTML_FILE="web/panel/unauthorized/index.html"
FORBIDDEN_HTML_FILE="web/panel/forbidden/index.html"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"
test -f "$JS_FILE"
test -f "$UNAUTHORIZED_HTML_FILE"
test -f "$FORBIDDEN_HTML_FILE"
test -f "$PANEL_WEB_ROOT/unauthorized/index.html"
test -f "$PANEL_WEB_ROOT/forbidden/index.html"
test -f "$PANEL_WEB_ROOT/assets/access-denial/access-denial-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.access_denial_events" "$MIGRATION_FILE"
grep -Fq "correlation_id text NOT NULL" "$MIGRATION_FILE"

grep -Fq "func Catalog" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Decide" "$RUNTIME_FILE"
grep -Fq "func (s *Service) WriteHTTP" "$RUNTIME_FILE"
grep -Fq "func CodeFromError" "$RUNTIME_FILE"
grep -Fq "func ValidateCatalog" "$RUNTIME_FILE"
grep -Fq "RecordAccessDenial" "$RUNTIME_FILE"

grep -Fq "TestCatalogIsComplete" "$TEST_FILE"
grep -Fq "TestUnauthorizedDecision" "$TEST_FILE"
grep -Fq "TestForbiddenDecision" "$TEST_FILE"
grep -Fq "TestCodeFromErrorMappings" "$TEST_FILE"
grep -Fq "TestWriteHTTP" "$TEST_FILE"
grep -Fq "TestLocaleFallback" "$TEST_FILE"

grep -Fq "PIX2PI_317_8_ACCESS_DENIAL_RUNTIME_START" "$JS_FILE"
grep -Fq "setAccessDenialScreen" "$JS_FILE"

grep -Fq "PIX2PI_317_8_UNAUTHORIZED_SCREEN_START" "$UNAUTHORIZED_HTML_FILE"
grep -Fq "PIX2PI_317_8_FORBIDDEN_SCREEN_START" "$FORBIDDEN_HTML_FILE"

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

go test ./internal/auth/accessdenial

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/unauthorized/")"
test "$status" = "200"
grep -Fq "PIX2PI_317_8_UNAUTHORIZED_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/forbidden/")"
test "$status" = "200"
grep -Fq "PIX2PI_317_8_FORBIDDEN_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/access-denial/access-denial-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_317_8_ACCESS_DENIAL_RUNTIME_START" "$body_file"
rm -f "$body_file"
