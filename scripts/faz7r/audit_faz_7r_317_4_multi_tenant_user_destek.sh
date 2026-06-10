#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_4_MULTI_TENANT_USER_DESTEK_GERCEK_AKIS.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_4_multi_tenant_user_destek.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_4_auth_multi_tenant_user_context.sql"
RUNTIME_FILE="internal/auth/multitenantuser/multi_tenant_user.go"
TEST_FILE="internal/auth/multitenantuser/multi_tenant_user_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_current_tenant_preferences" "$MIGRATION_FILE"
grep -Fq "UNIQUE (user_id, session_id)" "$MIGRATION_FILE"

grep -Fq "func (s *Service) ListTenantOptions" "$RUNTIME_FILE"
grep -Fq "func (s *Service) SwitchTenant" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ResolveCurrentTenant" "$RUNTIME_FILE"
grep -Fq "func (s *Service) CanAccessTenant" "$RUNTIME_FILE"
grep -Fq "SaveCurrentTenant" "$RUNTIME_FILE"
grep -Fq "GetCurrentTenantID" "$RUNTIME_FILE"
grep -Fq "ErrTenantAccessDenied" "$RUNTIME_FILE"

grep -Fq "TestListsMultipleTenantMemberships" "$TEST_FILE"
grep -Fq "TestSwitchTenantPersistsCurrentTenant" "$TEST_FILE"
grep -Fq "TestRejectsTenantWithoutMembership" "$TEST_FILE"
grep -Fq "TestRejectsInactiveMembershipAndTenant" "$TEST_FILE"
grep -Fq "TestResolveCurrentTenantFromSession" "$TEST_FILE"
grep -Fq "TestCanAccessTenant" "$TEST_FILE"

go test ./internal/auth/multitenantuser
