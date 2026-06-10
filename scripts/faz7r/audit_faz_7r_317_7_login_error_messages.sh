#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_7_LOGIN_ERROR_MESSAGES_GERCEK_HATA_MESAJLARI.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_7_login_error_messages.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_7_auth_login_error_events.sql"
RUNTIME_FILE="internal/auth/loginerrors/login_errors.go"
TEST_FILE="internal/auth/loginerrors/login_errors_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.login_error_events" "$MIGRATION_FILE"
grep -Fq "correlation_id text NOT NULL" "$MIGRATION_FILE"

grep -Fq "func Catalog" "$RUNTIME_FILE"
grep -Fq "func (s *Service) Build" "$RUNTIME_FILE"
grep -Fq "func (s *Service) WriteHTTP" "$RUNTIME_FILE"
grep -Fq "func CodeFromError" "$RUNTIME_FILE"
grep -Fq "func ValidateCatalog" "$RUNTIME_FILE"
grep -Fq "RecordLoginError" "$RUNTIME_FILE"

grep -Fq "TestCatalogIsComplete" "$TEST_FILE"
grep -Fq "TestCodeFromErrorMappings" "$TEST_FILE"
grep -Fq "TestBuildReturnsLocalizedSafeMessageAndRecordsEvent" "$TEST_FILE"
grep -Fq "TestInternalErrorDoesNotExposeDetail" "$TEST_FILE"
grep -Fq "TestLocaleFallbackToTurkish" "$TEST_FILE"
grep -Fq "TestWriteHTTP" "$TEST_FILE"

go test ./internal/auth/loginerrors
