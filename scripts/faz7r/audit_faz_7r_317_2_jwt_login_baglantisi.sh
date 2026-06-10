#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_2_JWT_LOGIN_BAGLANTISI_REAL_IMPLEMENTATION.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_2_jwt_login_baglantisi.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_2_auth_jwt_login.sql"
RUNTIME_FILE="internal/auth/jwtlogin/jwt_login.go"
TEST_FILE="internal/auth/jwtlogin/jwt_login_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.login_sessions" "$MIGRATION_FILE"
grep -Fq "CREATE TABLE IF NOT EXISTS auth.user_tenant_memberships" "$MIGRATION_FILE"

grep -Fq "func (s *Service) Login" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Sign" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Verify" "$RUNTIME_FILE"
grep -Fq "TenantMembership" "$RUNTIME_FILE"
grep -Fq "RecordLoginSession" "$RUNTIME_FILE"
grep -Fq "ErrTenantForbidden" "$RUNTIME_FILE"
grep -Fq "ErrTokenExpired" "$RUNTIME_FILE"

grep -Fq "TestLoginIssuesAndVerifiesJWT" "$TEST_FILE"
grep -Fq "TestLoginRejectsWrongPassword" "$TEST_FILE"
grep -Fq "TestLoginRejectsTenantWithoutMembership" "$TEST_FILE"
grep -Fq "TestVerifyRejectsExpiredToken" "$TEST_FILE"
grep -Fq "TestVerifyRejectsTamperedToken" "$TEST_FILE"

go test ./internal/auth/jwtlogin
