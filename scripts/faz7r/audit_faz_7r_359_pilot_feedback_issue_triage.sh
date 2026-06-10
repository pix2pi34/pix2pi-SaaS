#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_359_PILOT_FEEDBACK_ISSUE_TRIAGE.md"
test -f "configs/faz7r/faz_7r_359_pilot_feedback_issue_triage.v1.json"
test -f "web/panel/pilot-feedback-triage/index.html"
test -f "web/panel/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"
test -f "tests/faz7r/faz_7r_359_pilot_feedback_issue_triage_smoke_test.json"
test -f "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"
test -f "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_359_pilot_feedback_issue_triage.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_359_pilot_feedback_issue_triage_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_359_PILOT_FEEDBACK_TRIAGE_RUNTIME_START" "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"
grep -Fq "feedbackScopeHeaders" "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"
grep -Fq "buildFeedbackTriageRuntimeContract" "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"
grep -Fq "readyForStep360: true" "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"

grep -Fq "PIX2PI_359_PILOT_FEEDBACK_TRIAGE_APP_SHELL_START" "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"
grep -Fq "PIX2PI_359_PILOT_TENANT_CUSTOMER_FEEDBACK_CONTEXT_START" "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"
grep -Fq "PIX2PI_359_ISSUE_TRIAGE_QUEUE_PREVIEW_START" "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"
grep -Fq "PIX2PI_359_FEEDBACK_TRIAGE_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"

cmp -s "web/panel/pilot-feedback-triage/index.html" "$PANEL_WEB_ROOT/pilot-feedback-triage/index.html"
cmp -s "web/panel/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js" "$PANEL_WEB_ROOT/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/pilot-feedback-triage/")"
test "$status" = "200"
grep -Fq "PIX2PI_359_PILOT_FEEDBACK_TRIAGE_APP_SHELL_START" "$body_file"
! grep -Fq "PIX2PI_358_CONTROLLED_PILOT_MONITORING_APP_SHELL_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/pilot-feedback-triage/pilot-feedback-triage-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_359_PILOT_FEEDBACK_TRIAGE_RUNTIME_START" "$body_file"
rm -f "$body_file"
