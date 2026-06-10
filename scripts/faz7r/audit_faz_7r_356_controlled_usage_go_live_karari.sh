#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_356_CONTROLLED_USAGE_GO_LIVE_KARARI.md"
test -f "configs/faz7r/faz_7r_356_controlled_usage_go_live_karari.v1.json"
test -f "web/panel/controlled-usage-go-live-decision/index.html"
test -f "web/panel/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
test -f "tests/faz7r/faz_7r_356_controlled_usage_go_live_karari_smoke_test.json"
test -f "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
test -f "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_356_controlled_usage_go_live_karari.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_356_controlled_usage_go_live_karari_smoke_test.json" >/dev/null

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

grep -Fq "PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_RUNTIME_START" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "goLiveDecisionScopeHeaders" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "validateGoLiveDecisionScope" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "fetchGoLiveDecisionSnapshot" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "buildPrerequisiteEvidenceChecklist" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "buildGateDecision" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "buildGoNoGoDecisionPreview" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "buildControlledGoLiveRuntimeContract" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "realCustomerGoLiveEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "realActivationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "realDataMutationEnabled: false" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"
grep -Fq "readyForStep357: true" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"

grep -Fq "PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_APP_SHELL_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_DECISION_BOARD_CONTEXT_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_PREREQUISITE_EVIDENCE_CHECKLIST_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_SECURITY_GATE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_TENANT_ISOLATION_GATE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_PERMISSION_GATE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_LOCALIZATION_GATE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_PANEL_POS_MARKET_ROUTE_GATE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_DATA_MUTATION_SAFETY_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_BILLING_PAYMENT_DISABLED_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_SUPPORT_ROLLBACK_READINESS_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_CUSTOMER_ACCESS_MODE_DECISION_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_GO_NO_GO_DECISION_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_APPROVER_CHECKLIST_PLACEHOLDER_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_FINAL_RISK_REGISTER_PREVIEW_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_DECISION_AUDIT_TIMELINE_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_CONTROLLED_GO_LIVE_RUNTIME_DATA_CONTRACT_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_I18N_READY_DECISION_MARKER_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
grep -Fq "PIX2PI_356_SEO_OPENGRAPH_DECISION_PLACEHOLDER_START" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"

cmp -s "web/panel/controlled-usage-go-live-decision/index.html" "$PANEL_WEB_ROOT/controlled-usage-go-live-decision/index.html"
cmp -s "web/panel/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js" "$PANEL_WEB_ROOT/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js"

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

check_http_200_contains_not_pos_market "/controlled-usage-go-live-decision/" "PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_APP_SHELL_START"
check_http_200_contains_not_pos_market "/assets/controlled-usage-go-live-decision/controlled-usage-go-live-decision-runtime.js" "PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_RUNTIME_START"
