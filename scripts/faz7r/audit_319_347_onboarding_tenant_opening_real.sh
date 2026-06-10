#!/usr/bin/env bash
set -euo pipefail

ROOT="${PIX2PI_ROOT:-/root/pix2pi/pix2pi-SaaS}"
PANEL_ROOT="${PANEL_ROOT:-/var/www/pix2pi/panel}"

PKG_DIR="$ROOT/internal/faz7r/onboarding/tenantopening"
CONFIG="$ROOT/configs/faz7r/faz7r_319_347_onboarding_tenant_opening_real.json"
MIGRATION="$ROOT/db/migrations/20260511_319_347_onboarding_tenant_opening_real.sql"
DOC="$ROOT/docs/faz7r/FAZ_7R_319_347_ONBOARDING_TENANT_OPENING_REAL.md"
HTML="$PANEL_ROOT/onboarding/index.html"
JS="$PANEL_ROOT/onboarding/onboarding-runtime.js"

echo "===== FAZ 7-R / 319 + 347 STANDALONE AUDIT START ====="

test -f "$CONFIG"
test -f "$MIGRATION"
test -f "$DOC"
test -f "$PKG_DIR/tenant_opening.go"
test -f "$PKG_DIR/memory_repo.go"
test -f "$PKG_DIR/tenant_opening_test.go"
test -f "$HTML"
test -f "$JS"

python3 -m json.tool "$CONFIG" >/dev/null

grep -q "tenant_onboarding.business_onboardings" "$MIGRATION"
grep -q "tenant_onboarding.tenant_configs" "$MIGRATION"
grep -q "tenant_onboarding.tenant_branches" "$MIGRATION"
grep -q "tenant_onboarding.tenant_registers" "$MIGRATION"
grep -q "tenant_onboarding.tenant_user_roles" "$MIGRATION"
grep -q "tenant_onboarding.tenant_opening_audit_events" "$MIGRATION"

grep -q "CompleteBusinessOnboarding" "$PKG_DIR/tenant_opening.go"
grep -q "OpenPilotTenant" "$PKG_DIR/tenant_opening.go"
grep -q "NewPostgresRepository" "$PKG_DIR/tenant_opening.go"
grep -q "Test319CompleteBusinessOnboardingWritesAllFields" "$PKG_DIR/tenant_opening_test.go"
grep -q "Test347OpenPilotTenantCreatesConfigBranchRegisterAndOwner" "$PKG_DIR/tenant_opening_test.go"
grep -q "PIX2PI_319_347_ONBOARDING_TENANT_OPENING_SCREEN_START" "$HTML"
grep -q "PIX2PI_319_347_ONBOARDING_TENANT_OPENING_RUNTIME_START" "$JS"

cd "$ROOT"
go test ./internal/faz7r/onboarding/tenantopening

echo "===== FAZ 7-R / 319 + 347 STANDALONE AUDIT PASS ====="
