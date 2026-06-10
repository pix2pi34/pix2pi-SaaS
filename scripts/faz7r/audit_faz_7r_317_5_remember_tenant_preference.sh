#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_5_REMEMBER_TENANT_PREFERENCE_GERCEK_AKIS.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_5_remember_tenant_preference.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_5_auth_tenant_preference.sql"
RUNTIME_FILE="internal/auth/tenantpreference/tenant_preference.go"
TEST_FILE="internal/auth/tenantpreference/tenant_preference_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_tenant_preferences" "$MIGRATION_FILE"
grep -Fq "user_id uuid NOT NULL UNIQUE" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_current_tenant_preferences" "$MIGRATION_FILE"

grep -Fq "func (s *Service) RememberTenant" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ResolveRememberedTenant" "$RUNTIME_FILE"
grep -Fq "func (s *Service) GetPreferenceHTTP" "$RUNTIME_FILE"
grep -Fq "func (s *Service) SetPreferenceHTTP" "$RUNTIME_FILE"
grep -Fq "SavePersistentTenantPreference" "$RUNTIME_FILE"
grep -Fq "SaveSessionTenantPreference" "$RUNTIME_FILE"

grep -Fq "TestRememberTenantSavesPersistentAndSessionPreference" "$TEST_FILE"
grep -Fq "TestResolveRememberedTenantReturnsAccessiblePreference" "$TEST_FILE"
grep -Fq "TestResolveFallsBackWhenPreferenceNotAccessible" "$TEST_FILE"
grep -Fq "TestRememberTenantRejectsInaccessibleTenant" "$TEST_FILE"
grep -Fq "TestGetPreferenceHTTP" "$TEST_FILE"
grep -Fq "TestSetPreferenceHTTP" "$TEST_FILE"

go test ./internal/auth/tenantpreference
