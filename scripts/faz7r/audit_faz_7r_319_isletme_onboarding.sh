#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
PANEL_WEB_ROOT="/var/www/pix2pi/panel"
ACTIVE_PANEL_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_panel.conf"

cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_319_ISLETME_ONBOARDING_GERCEK_DB_KAYIT.md"
CONFIG_FILE="configs/faz7r/faz_7r_319_isletme_onboarding.v1.json"
MIGRATION_FILE="db/migrations/20260511_319_business_onboarding_real_records.sql"
RUNTIME_FILE="internal/onboarding/businessonboarding/business_onboarding.go"
TEST_FILE="internal/onboarding/businessonboarding/business_onboarding_test.go"
JS_FILE="web/panel/assets/onboarding/business-onboarding-runtime.js"
HTML_FILE="web/panel/onboarding/index.html"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"
test -f "$JS_FILE"
test -f "$HTML_FILE"
test -f "$PANEL_WEB_ROOT/onboarding/index.html"
test -f "$PANEL_WEB_ROOT/assets/onboarding/business-onboarding-runtime.js"
test -f "$ACTIVE_PANEL_NGINX_ROUTE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS tenant_onboarding.business_onboarding_requests" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS tenant_onboarding.business_onboarding_audit_events" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS core.tenants" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS core.legal_entities" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS core.branches" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_tenant_memberships" "$MIGRATION_FILE"

grep -Fq "func (s *Service) Complete" "$RUNTIME_FILE"
grep -Fq "func (s *Service) CompleteHTTP" "$RUNTIME_FILE"
grep -Fq "func BuildTenantSlug" "$RUNTIME_FILE"
grep -Fq "CreateTenant" "$RUNTIME_FILE"
grep -Fq "CreateLegalEntity" "$RUNTIME_FILE"
grep -Fq "CreateBranch" "$RUNTIME_FILE"
grep -Fq "CreateMembership" "$RUNTIME_FILE"
grep -Fq "SaveOnboardingRequest" "$RUNTIME_FILE"
grep -Fq "RecordAuditEvent" "$RUNTIME_FILE"

grep -Fq "TestCompleteCreatesTenantLegalBranchMembershipAndRequest" "$TEST_FILE"
grep -Fq "TestValidationRejectsMissingBusinessName" "$TEST_FILE"
grep -Fq "TestValidationRejectsInvalidTaxOrTCKN" "$TEST_FILE"
grep -Fq "TestValidationRejectsUnsupportedLanguageCurrencyAndRole" "$TEST_FILE"
grep -Fq "TestBuildTenantSlug" "$TEST_FILE"
grep -Fq "TestCompleteHTTP" "$TEST_FILE"

grep -Fq "PIX2PI_319_BUSINESS_ONBOARDING_RUNTIME_START" "$JS_FILE"
grep -Fq "submitOnboarding" "$JS_FILE"

grep -Fq "PIX2PI_319_BUSINESS_ONBOARDING_SCREEN_START" "$HTML_FILE"
grep -Fq "PIX2PI_319_BUSINESS_BASIC_INFO_START" "$HTML_FILE"
grep -Fq "PIX2PI_319_ADDRESS_BRANCH_START" "$HTML_FILE"
grep -Fq "PIX2PI_319_DEFAULTS_ROLE_START" "$HTML_FILE"
grep -Fq "PIX2PI_319_ONBOARDING_COMPLETION_START" "$HTML_FILE"

grep -Fq "server_name ${PANEL_DOMAIN};" "$ACTIVE_PANEL_NGINX_ROUTE"
grep -Fq "root ${PANEL_WEB_ROOT};" "$ACTIVE_PANEL_NGINX_ROUTE"

go test ./internal/onboarding/businessonboarding

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/onboarding/")"
test "$status" = "200"
grep -Fq "PIX2PI_319_BUSINESS_ONBOARDING_SCREEN_START" "$body_file"
rm -f "$body_file"

body_file="$(mktemp)"
status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}/assets/onboarding/business-onboarding-runtime.js")"
test "$status" = "200"
grep -Fq "PIX2PI_319_BUSINESS_ONBOARDING_RUNTIME_START" "$body_file"
rm -f "$body_file"
