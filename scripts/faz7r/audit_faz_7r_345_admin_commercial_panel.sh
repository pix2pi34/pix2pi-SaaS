#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_345_ADMIN_COMMERCIAL_PANEL.md"
test -f "configs/faz7r/faz_7r_345_admin_commercial_panel.v1.json"
test -f "web/panel/admin-commercial/index.html"
test -f "web/panel/assets/admin-commercial/panel-admin-commercial-runtime.js"
test -f "tests/faz7r/faz_7r_345_admin_commercial_panel_smoke_test.json"
test -f "$PANEL_WEB_ROOT/admin-commercial/index.html"
test -f "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_345_admin_commercial_panel.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_345_admin_commercial_panel_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_345_PANEL_ADMIN_COMMERCIAL_RUNTIME_START" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "adminCommercialScopeHeaders" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "validateAdminCommercialScope" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "fetchAdminCommercialSnapshot" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "buildAdminCommercialRuntimeContract" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "buildCommercialOverrideDisabledGuard" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "realManualOverrideEnabled: false" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "realTenantSuspendResumeEnabled: false" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "realSubscriptionMutationEnabled: false" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "realPaymentProviderLiveEnabled: false" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "realExportReportEnabled: false" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "readyForStep346: true" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "X-Admin-Session" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "X-Tenant-ID" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"
grep -Fq "X-Commercial-Scope" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"

grep -Fq "PIX2PI_345_ADMIN_COMMERCIAL_APP_SHELL_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_PLATFORM_ADMIN_CONTEXT_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_TENANT_COMMERCIAL_OVERVIEW_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_SUBSCRIPTION_ACCOUNT_STATUS_TABLE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_PLAN_CATALOG_MANAGEMENT_PREVIEW_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_BILLING_APPROVAL_QUEUE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_PAYMENT_PROVIDER_GATE_STATUS_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_REVENUE_MRR_TRIAL_KPI_CARDS_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_RISK_COMPLIANCE_GATE_PANEL_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_MANUAL_COMMERCIAL_OVERRIDE_DISABLED_GATE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_TENANT_SUSPEND_RESUME_CANCEL_DISABLED_GATE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_COMMERCIAL_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_EXPORT_REPORT_DISABLED_GATE_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_ADMIN_TENANT_COMMERCIAL_SCOPE_GUARD_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_ADMIN_COMMERCIAL_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_I18N_READY_ADMIN_COMMERCIAL_MARKER_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"
grep -Fq "PIX2PI_345_SEO_OPENGRAPH_ADMIN_COMMERCIAL_PLACEHOLDER_START" "$PANEL_WEB_ROOT/admin-commercial/index.html"

cmp -s "web/panel/admin-commercial/index.html" "$PANEL_WEB_ROOT/admin-commercial/index.html"
cmp -s "web/panel/assets/admin-commercial/panel-admin-commercial-runtime.js" "$PANEL_WEB_ROOT/assets/admin-commercial/panel-admin-commercial-runtime.js"

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

check_http_200_contains_not_market "/admin-commercial/" "PIX2PI_345_ADMIN_COMMERCIAL_APP_SHELL_START"
check_http_200_contains_not_market "/assets/admin-commercial/panel-admin-commercial-runtime.js" "PIX2PI_345_PANEL_ADMIN_COMMERCIAL_RUNTIME_START"
