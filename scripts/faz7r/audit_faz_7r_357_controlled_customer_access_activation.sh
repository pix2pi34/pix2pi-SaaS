#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION.md"
test -f "configs/faz7r/faz_7r_357_controlled_customer_access_activation.v1.json"
test -f "web/panel/controlled-customer-access-activation/index.html"
test -f "web/panel/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
test -f "tests/faz7r/faz_7r_357_controlled_customer_access_activation_smoke_test.json"
test -f "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
test -f "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_357_controlled_customer_access_activation.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_357_controlled_customer_access_activation_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_RUNTIME_START" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "activationScopeHeaders" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "validateActivationScope" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "fetchActivationSnapshot" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "buildApprovalBindingPreview" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "buildAccessTogglePreview" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "buildDataMutationSafetyGuard" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "buildActivationDecisionPreview" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "buildActivationRuntimeContract" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "realCustomerAccessActivationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "realPanelAccessActivationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "realPosAccessActivationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "realMarketAccessActivationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "realDataMutationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"
grep -Fq "readyForStep358: true" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"

grep -Fq "PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_APP_SHELL_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_TENANT_CUSTOMER_OWNER_ACTIVATION_CONTEXT_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_HUMAN_APPROVAL_BINDING_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_ACTIVATION_WINDOW_SCOPE_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_CUSTOMER_ACCESS_TOGGLE_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_PANEL_ACCESS_ACTIVATION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_POS_ACCESS_ACTIVATION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_MARKET_STOREFRONT_ACCESS_ACTIVATION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_ACTIVATION_TOKEN_SESSION_HANDOFF_DISABLED_GATE_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_DATA_MUTATION_SAFETY_REMAINS_DISABLED_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_SUPPORT_CHANNEL_HANDOFF_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_MONITORING_INCIDENT_READINESS_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_ROLLBACK_ACTIVATION_ACTION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_ACTIVATION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_CUSTOMER_NOTIFICATION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_ACTIVATION_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_I18N_READY_ACTIVATION_MARKER_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
grep -Fq "PIX2PI_357_SEO_OPENGRAPH_ACTIVATION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"

cmp -s "web/panel/controlled-customer-access-activation/index.html" "$PANEL_WEB_ROOT/controlled-customer-access-activation/index.html"
cmp -s "web/panel/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js" "$PANEL_WEB_ROOT/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/controlled-customer-access-activation/")"
test "$status" = "200"
grep -Fq "PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_APP_SHELL_START" "$body_file"
! grep -Fq "PIX2PI_351_POS_ACCESS_TEST_APP_SHELL_START" "$body_file"
! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/controlled-customer-access-activation/controlled-customer-access-activation-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_RUNTIME_START" "$body_file"
rm -f "$body_file"
