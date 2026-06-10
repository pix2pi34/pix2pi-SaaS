#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_360_PILOT_STABILIZATION_FIX_PLAN_CLOSURE.md"
test -f "configs/faz7r/faz_7r_360_pilot_stabilization_fix_plan_closure.v1.json"
test -f "web/panel/pilot-stabilization-fix-plan/index.html"
test -f "web/panel/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"
test -f "tests/faz7r/faz_7r_360_pilot_stabilization_fix_plan_closure_smoke_test.json"
test -f "$PANEL_WEB_ROOT/pilot-stabilization-fix-plan/index.html"
test -f "$PANEL_WEB_ROOT/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_360_pilot_stabilization_fix_plan_closure.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_360_pilot_stabilization_fix_plan_closure_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_360_PILOT_STABILIZATION_FIX_PLAN_RUNTIME_START" "$PANEL_WEB_ROOT/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"
grep -Fq "stabilizationScopeHeaders" "$PANEL_WEB_ROOT/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"
grep -Fq "buildStabilizationRuntimeContract" "$PANEL_WEB_ROOT/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"
grep -Fq "readyForStep361: true" "$PANEL_WEB_ROOT/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js"

grep -Fq "PIX2PI_360_PILOT_STABILIZATION_APP_SHELL_START" "$PANEL_WEB_ROOT/pilot-stabilization-fix-plan/index.html"
grep -Fq "PIX2PI_360_PILOT_TRIAGE_SUMMARY_CONTEXT_START" "$PANEL_WEB_ROOT/pilot-stabilization-fix-plan/index.html"
grep -Fq "PIX2PI_360_GO_FORWARD_DECISION_PREVIEW_START" "$PANEL_WEB_ROOT/pilot-stabilization-fix-plan/index.html"
grep -Fq "PIX2PI_360_STABILIZATION_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/pilot-stabilization-fix-plan/index.html"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/pilot-stabilization-fix-plan/")"
test "$status" = "200"
grep -Fq "PIX2PI_360_PILOT_STABILIZATION_APP_SHELL_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/pilot-stabilization-fix-plan/pilot-stabilization-fix-plan-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_360_PILOT_STABILIZATION_FIX_PLAN_RUNTIME_START" "$body_file"
rm -f "$body_file"
