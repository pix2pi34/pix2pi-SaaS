#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_347_PILOT_MUSTERI_TENANT_ACILISI_GERCEK_PROVISIONING.md"
CONFIG_FILE="configs/faz7r/faz_7r_347_pilot_tenant_opening.v1.json"
MIGRATION_FILE="db/migrations/20260511_347_pilot_tenant_opening_real_provisioning.sql"
RUNTIME_FILE="internal/onboarding/pilottenantopening/pilot_tenant_opening.go"
TEST_FILE="internal/onboarding/pilottenantopening/pilot_tenant_opening_test.go"
JS_FILE="web/panel/assets/pilot-tenant-opening/pilot-tenant-opening-runtime.js"
HTML_FILE="web/panel/pilot-tenant-opening/index.html"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"
test -f "$JS_FILE"
test -f "$HTML_FILE"
test -f "$PANEL_WEB_ROOT/pilot-tenant-opening/index.html"
test -f "$PANEL_WEB_ROOT/assets/pilot-tenant-opening/pilot-tenant-opening-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS tenant_onboarding.pilot_tenant_opening_runs" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS tenant_onboarding.pilot_tenant_opening_audit_events" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS core.tenant_configs" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS commercial.tenant_plan_bindings" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS pos.registers" "$MIGRATION_FILE"

grep -Fq "func (s *Service) Provision" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ProvisionHTTP" "$RUNTIME_FILE"
grep -Fq "func BuildRegisterCode" "$RUNTIME_FILE"
grep -Fq "OwnerMembershipExists" "$RUNTIME_FILE"
grep -Fq "CreateTenantConfig" "$RUNTIME_FILE"
grep -Fq "CreatePlanBinding" "$RUNTIME_FILE"
grep -Fq "CreateBranch" "$RUNTIME_FILE"
grep -Fq "CreateRegister" "$RUNTIME_FILE"
grep -Fq "SaveOpeningRun" "$RUNTIME_FILE"
grep -Fq "RecordAuditEvent" "$RUNTIME_FILE"

grep -Fq "TestProvisionCreatesConfigPlanBranchRegisterAndRun" "$TEST_FILE"
grep -Fq "TestProvisionRejectsMissingTenantAndOwner" "$TEST_FILE"
grep -Fq "TestProvisionRequiresTRDefaultLanguage" "$TEST_FILE"
grep -Fq "TestProvisionRejectsMissingPlanBranchRegister" "$TEST_FILE"
grep -Fq "TestProvisionRequiresOwnerMembership" "$TEST_FILE"
grep -Fq "TestBuildRegisterCode" "$TEST_FILE"
grep -Fq "TestProvisionHTTP" "$TEST_FILE"

grep -Fq "PIX2PI_347_PILOT_TENANT_OPENING_RUNTIME_START" "$JS_FILE"
grep -Fq "submitOpening" "$JS_FILE"

grep -Fq "PIX2PI_347_PILOT_TENANT_OPENING_SCREEN_START" "$HTML_FILE"
grep -Fq "PIX2PI_347_TENANT_CONFIG_START" "$HTML_FILE"
grep -Fq "PIX2PI_347_DEFAULTS_START" "$HTML_FILE"
grep -Fq "PIX2PI_347_BRANCH_REGISTER_START" "$HTML_FILE"
grep -Fq "PIX2PI_347_OPENING_COMPLETION_START" "$HTML_FILE"

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

go test ./internal/onboarding/pilottenantopening

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/pilot-tenant-opening/")"
test "$status" = "200"
grep -Fq "PIX2PI_347_PILOT_TENANT_OPENING_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/pilot-tenant-opening/pilot-tenant-opening-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_347_PILOT_TENANT_OPENING_RUNTIME_START" "$body_file"
rm -f "$body_file"
