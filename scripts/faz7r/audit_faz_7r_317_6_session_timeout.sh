#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_6_SESSION_TIMEOUT_GERCEK_DAVRANIS.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_6_session_timeout.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_6_auth_session_timeout.sql"
RUNTIME_FILE="internal/auth/sessiontimeout/session_timeout.go"
TEST_FILE="internal/auth/sessiontimeout/session_timeout_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.session_timeout_events" "$MIGRATION_FILE"
grep -Fq "ADD COLUMN IF NOT EXISTS last_seen_at" "$MIGRATION_FILE"

grep -Fq "func (s *Service) ValidateSession" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Logout" "$RUNTIME_FILE"
grep -Fq "func (s *Service) ValidateHTTP" "$RUNTIME_FILE"
grep -Fq "func (s *Service) LogoutHTTP" "$RUNTIME_FILE"
grep -Fq "ErrIdleTimeoutExceeded" "$RUNTIME_FILE"
grep -Fq "ErrAbsoluteTimeoutEnded" "$RUNTIME_FILE"

grep -Fq "TestValidateActiveSessionTouchesLastSeen" "$TEST_FILE"
grep -Fq "TestRejectsExpiredAccessToken" "$TEST_FILE"
grep -Fq "TestRejectsExpiredRefreshToken" "$TEST_FILE"
grep -Fq "TestRejectsIdleTimeout" "$TEST_FILE"
grep -Fq "TestRejectsAbsoluteTimeout" "$TEST_FILE"
grep -Fq "TestRejectsRevokedSession" "$TEST_FILE"
grep -Fq "TestLogoutRevokesSession" "$TEST_FILE"
grep -Fq "TestValidateHTTP" "$TEST_FILE"
grep -Fq "TestLogoutHTTP" "$TEST_FILE"

go test ./internal/auth/sessiontimeout
