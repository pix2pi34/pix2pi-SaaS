#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_363_CONTROLLED_ROLLOUT_COHORT_APPROVAL_GATE.md"
test -f "configs/faz7r/faz_7r_363_controlled_rollout_cohort_approval_gate.v1.json"
test -f "web/panel/controlled-rollout-cohort-approval/index.html"
test -f "web/panel/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"
test -f "tests/faz7r/faz_7r_363_controlled_rollout_cohort_approval_gate_smoke_test.json"
test -f "$PANEL_WEB_ROOT/controlled-rollout-cohort-approval/index.html"
test -f "$PANEL_WEB_ROOT/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_363_controlled_rollout_cohort_approval_gate.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_363_controlled_rollout_cohort_approval_gate_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_363_CONTROLLED_ROLLOUT_COHORT_APPROVAL_RUNTIME_START" "$PANEL_WEB_ROOT/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"
grep -Fq "approvalGateHeaders" "$PANEL_WEB_ROOT/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"
grep -Fq "buildApprovalRuntimeContract" "$PANEL_WEB_ROOT/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"
grep -Fq "readyForStep364: true" "$PANEL_WEB_ROOT/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js"

grep -Fq "PIX2PI_363_CONTROLLED_ROLLOUT_APPROVAL_APP_SHELL_START" "$PANEL_WEB_ROOT/controlled-rollout-cohort-approval/index.html"
grep -Fq "PIX2PI_363_COHORT_APPROVAL_CONTEXT_START" "$PANEL_WEB_ROOT/controlled-rollout-cohort-approval/index.html"
grep -Fq "PIX2PI_363_APPROVAL_DECISION_MATRIX_START" "$PANEL_WEB_ROOT/controlled-rollout-cohort-approval/index.html"
grep -Fq "PIX2PI_363_APPROVAL_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/controlled-rollout-cohort-approval/index.html"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${PANEL_DOMAIN};"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/controlled-rollout-cohort-approval/")"
test "$status" = "200"
grep -Fq "PIX2PI_363_CONTROLLED_ROLLOUT_APPROVAL_APP_SHELL_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/controlled-rollout-cohort-approval/controlled-rollout-cohort-approval-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_363_CONTROLLED_ROLLOUT_COHORT_APPROVAL_RUNTIME_START" "$body_file"
rm -f "$body_file"
