#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_3_TENANT_SELECTION_SCREEN_GERCEK_TENANT_AKISI.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_3_tenant_selection_screen.v1.json"
RUNTIME_FILE="internal/auth/tenantselection/tenant_selection.go"
TEST_FILE="internal/auth/tenantselection/tenant_selection_test.go"
JS_FILE="web/panel/assets/tenant-selection/tenant-selection-runtime.js"
HTML_FILE="web/panel/tenant-select/index.html"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"
test -f "$JS_FILE"
test -f "$HTML_FILE"
test -f "$PANEL_WEB_ROOT/tenant-select/index.html"
test -f "$PANEL_WEB_ROOT/assets/tenant-selection/tenant-selection-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "func (s *Service) ListTenants" "$RUNTIME_FILE"
grep -Fq "func (s *Service) SelectTenant" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ListTenantsHTTP" "$RUNTIME_FILE"
grep -Fq "func (s *Service) SelectTenantHTTP" "$RUNTIME_FILE"
grep -Fq "SaveTenantPreference" "$RUNTIME_FILE"
grep -Fq "ErrNoTenantAccess" "$RUNTIME_FILE"

grep -Fq "TestListTenantOptionsFromAccessToken" "$TEST_FILE"
grep -Fq "TestSelectTenantPersistsPreference" "$TEST_FILE"
grep -Fq "TestSelectTenantRejectsTenantWithoutMembership" "$TEST_FILE"
grep -Fq "TestHTTPListTenants" "$TEST_FILE"
grep -Fq "TestHTTPSelectTenant" "$TEST_FILE"

grep -Fq "PIX2PI_317_3_TENANT_SELECTION_RUNTIME_START" "$JS_FILE"
grep -Fq "loadTenantList" "$JS_FILE"
grep -Fq "selectTenant" "$JS_FILE"

grep -Fq "PIX2PI_317_3_TENANT_SELECTION_SCREEN_START" "$HTML_FILE"
grep -Fq "PIX2PI_317_3_TENANT_LIST_API_RESULT_START" "$HTML_FILE"
grep -Fq "PIX2PI_317_3_TENANT_SELECTION_API_CONTRACT_START" "$HTML_FILE"

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

go test ./internal/auth/tenantselection

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/tenant-select/")"
test "$status" = "200"
grep -Fq "PIX2PI_317_3_TENANT_SELECTION_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/tenant-selection/tenant-selection-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_317_3_TENANT_SELECTION_RUNTIME_START" "$body_file"
rm -f "$body_file"
