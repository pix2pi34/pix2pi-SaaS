#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_352_TENANT_IZOLASYON_KONTROLU.md"
test -f "configs/faz7r/faz_7r_352_tenant_izolasyon_kontrolu.v1.json"
test -f "web/panel/tenant-isolation-check/index.html"
test -f "web/panel/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
test -f "tests/faz7r/faz_7r_352_tenant_izolasyon_kontrolu_smoke_test.json"
test -f "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
test -f "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_352_tenant_izolasyon_kontrolu.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_352_tenant_izolasyon_kontrolu_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_352_TENANT_ISOLATION_CHECK_RUNTIME_START" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "tenantIsolationScopeHeaders" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "validateTenantIsolationScope" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "fetchTenantIsolationSnapshot" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "buildIsolationDecision" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "buildCrossTenantAccessDenialPreview" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "buildTenantIsolationRuntimeContract" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "realCrossTenantQueryEnabled: false" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "realBreakGlassEnabled: false" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "realExportEnabled: false" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"
grep -Fq "readyForStep353: true" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"

grep -Fq "PIX2PI_352_TENANT_ISOLATION_APP_SHELL_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_SOURCE_TENANT_TARGET_TENANT_CONTEXT_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_CROSS_TENANT_ACCESS_DENIAL_PREVIEW_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_RLS_READINESS_CHECKLIST_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_SCOPED_ROUTE_GUARD_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_SCOPED_PANEL_DATA_GUARD_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_SCOPED_POS_DATA_GUARD_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_SCOPED_MARKETPLACE_DATA_GUARD_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_AUDIT_EXPORT_ISOLATION_PREVIEW_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_BREAK_GLASS_DISABLED_PREVIEW_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_ISOLATION_REGRESSION_CHECKLIST_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_ISOLATION_INCIDENT_PREVIEW_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_ISOLATION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_ISOLATION_DECISION_CONTRACT_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_TENANT_ISOLATION_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_I18N_READY_ISOLATION_MARKER_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
grep -Fq "PIX2PI_352_SEO_OPENGRAPH_ISOLATION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"

cmp -s "web/panel/tenant-isolation-check/index.html" "$PANEL_WEB_ROOT/tenant-isolation-check/index.html"
cmp -s "web/panel/assets/tenant-isolation-check/tenant-isolation-check-runtime.js" "$PANEL_WEB_ROOT/assets/tenant-isolation-check/tenant-isolation-check-runtime.js"

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

check_http_200_contains_not_pos_market "/tenant-isolation-check/" "PIX2PI_352_TENANT_ISOLATION_APP_SHELL_START"
check_http_200_contains_not_pos_market "/assets/tenant-isolation-check/tenant-isolation-check-runtime.js" "PIX2PI_352_TENANT_ISOLATION_CHECK_RUNTIME_START"
