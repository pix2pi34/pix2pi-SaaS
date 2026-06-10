#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_358_CONTROLLED_PILOT_MONITORING_FIRST_DAY_WATCH.md"
test -f "configs/faz7r/faz_7r_358_controlled_pilot_monitoring_first_day_watch.v1.json"
test -f "web/panel/controlled-pilot-monitoring/index.html"
test -f "web/panel/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
test -f "tests/faz7r/faz_7r_358_controlled_pilot_monitoring_first_day_watch_smoke_test.json"
test -f "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
test -f "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_358_controlled_pilot_monitoring_first_day_watch.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_358_controlled_pilot_monitoring_first_day_watch_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_358_CONTROLLED_PILOT_MONITORING_RUNTIME_START" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "monitoringScopeHeaders" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "validateMonitoringScope" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "fetchMonitoringSnapshot" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "buildPilotHealthDashboard" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "buildRuntimeErrorDashboard" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "buildMutationGuardWatch" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "buildEarlyWarningThresholds" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "buildMonitoringRuntimeContract" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "realCustomerDataMutationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"
grep -Fq "readyForStep359: true" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"

grep -Fq "PIX2PI_358_CONTROLLED_PILOT_MONITORING_APP_SHELL_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_PILOT_TENANT_CUSTOMER_WATCH_CONTEXT_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_FIRST_DAY_WATCH_TIMELINE_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_PILOT_HEALTH_DASHBOARD_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_PANEL_POS_MARKET_ROUTE_HEALTH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_AUTH_PERMISSION_TENANT_ISOLATION_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_RUNTIME_ERROR_DASHBOARD_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_INCIDENT_WATCH_QUEUE_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_SUPPORT_HANDOFF_CUSTOMER_CONTACT_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_CUSTOMER_ACTIVITY_SESSION_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_TRANSACTION_MUTATION_GUARD_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_BILLING_PAYMENT_DISABLED_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_LOCALIZATION_WATCH_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_SLO_EARLY_WARNING_THRESHOLDS_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_ROLLBACK_TRIGGER_CHECKLIST_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_DAILY_PILOT_REPORT_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_MONITORING_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_MONITORING_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_I18N_READY_MONITORING_MARKER_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
grep -Fq "PIX2PI_358_SEO_OPENGRAPH_MONITORING_PLACEHOLDER_START" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"

cmp -s "web/panel/controlled-pilot-monitoring/index.html" "$PANEL_WEB_ROOT/controlled-pilot-monitoring/index.html"
cmp -s "web/panel/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js" "$PANEL_WEB_ROOT/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/controlled-pilot-monitoring/")"
test "$status" = "200"
grep -Fq "PIX2PI_358_CONTROLLED_PILOT_MONITORING_APP_SHELL_START" "$body_file"
! grep -Fq "PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_APP_SHELL_START" "$body_file"
! grep -Fq "PIX2PI_335_STOREFRONT_APP_SHELL_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/controlled-pilot-monitoring/controlled-pilot-monitoring-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_358_CONTROLLED_PILOT_MONITORING_RUNTIME_START" "$body_file"
rm -f "$body_file"
