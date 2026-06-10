#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_347_PILOT_MUSTERI_TENANT_ACILISI.md"
test -f "configs/faz7r/faz_7r_347_pilot_musteri_tenant_acilisi.v1.json"
test -f "web/panel/pilot-tenant/index.html"
test -f "web/panel/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
test -f "tests/faz7r/faz_7r_347_pilot_musteri_tenant_acilisi_smoke_test.json"
test -f "$PANEL_WEB_ROOT/pilot-tenant/index.html"
test -f "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_347_pilot_musteri_tenant_acilisi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_347_pilot_musteri_tenant_acilisi_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_347_PANEL_PILOT_TENANT_RUNTIME_START" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "tenantOpeningScopeHeaders" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "validateTenantOpeningScope" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "fetchPilotTenantSnapshot" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "buildPilotTenantDraftPayload" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "buildTenantProvisioningDisabledGuard" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "buildTenantOpeningRuntimeContract" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "realTenantInsertEnabled: false" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "realOwnerInviteEnabled: false" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "realTenantActivationEnabled: false" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "realCustomerAccessEnabled: false" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "readyForStep348: true" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "X-Admin-Session" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "X-Tenant-Opening-Scope" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"
grep -Fq "X-Correlation-ID" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"

grep -Fq "PIX2PI_347_PILOT_TENANT_OPENING_APP_SHELL_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_PILOT_TENANT_REQUEST_DRAFT_CONTEXT_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_TENANT_SLUG_DOMAIN_ENVIRONMENT_CONTEXT_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_BUSINESS_BASIC_INFO_CHECKLIST_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_LEGAL_ENTITY_BRANCH_PLACEHOLDER_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_DEFAULT_PLAN_BINDING_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_DEFAULT_LANGUAGE_TIMEZONE_CURRENCY_BINDING_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_OWNER_ADMIN_ASSIGNMENT_PLACEHOLDER_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_KVKK_LEGAL_COMMERCIAL_APPROVAL_GATE_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_DATA_ISOLATION_RLS_READINESS_GATE_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_PANEL_POS_MARKET_ACCESS_PREPARATION_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_TENANT_PROVISIONING_DISABLED_GUARD_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_TENANT_ACTIVATION_DISABLED_GUARD_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_TENANT_OPENING_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_TENANT_OPENING_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_I18N_READY_PILOT_TENANT_MARKER_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
grep -Fq "PIX2PI_347_SEO_OPENGRAPH_PILOT_TENANT_PLACEHOLDER_START" "$PANEL_WEB_ROOT/pilot-tenant/index.html"

cmp -s "web/panel/pilot-tenant/index.html" "$PANEL_WEB_ROOT/pilot-tenant/index.html"
cmp -s "web/panel/assets/pilot-tenant/panel-pilot-tenant-runtime.js" "$PANEL_WEB_ROOT/assets/pilot-tenant/panel-pilot-tenant-runtime.js"

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

check_http_200_contains_not_market "/pilot-tenant/" "PIX2PI_347_PILOT_TENANT_OPENING_APP_SHELL_START"
check_http_200_contains_not_market "/assets/pilot-tenant/panel-pilot-tenant-runtime.js" "PIX2PI_347_PANEL_PILOT_TENANT_RUNTIME_START"
