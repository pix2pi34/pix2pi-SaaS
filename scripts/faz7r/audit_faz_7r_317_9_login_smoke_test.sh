#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
PANEL_DOMAIN="panel.pix2pi.com.tr"
cd "$REPO"

DOC_FILE="docs/faz7r/FAZ_7R_317_9_LOGIN_SMOKE_TEST_GERCEK_E2E.md"
CONFIG_FILE="configs/faz7r/faz_7r_317_9_login_smoke_test.v1.json"
MIGRATION_FILE="db/migrations/20260511_317_9_auth_login_smoke_runs.sql"
RUNTIME_FILE="internal/auth/loginsmoke/login_smoke.go"
TEST_FILE="internal/auth/loginsmoke/login_smoke_test.go"

test -f "$DOC_FILE"
test -f "$CONFIG_FILE"
test -f "$MIGRATION_FILE"
test -f "$RUNTIME_FILE"
test -f "$TEST_FILE"

python3 -m json.tool "$CONFIG_FILE" >/dev/null

grep -Fq "CREATE TABLE IF NOT EXISTS auth.login_smoke_runs" "$MIGRATION_FILE"

grep -Fq "type StepStatus struct" "$RUNTIME_FILE"
grep -Fq "type Report struct" "$RUNTIME_FILE"
grep -Fq "func BuildReport" "$RUNTIME_FILE"
grep -Fq "func AllPass" "$RUNTIME_FILE"

grep -Fq "TestLoginSmokeFullE2EHappyPath" "$TEST_FILE"
grep -Fq "TestLoginSmokeWrongPasswordSafeError" "$TEST_FILE"
grep -Fq "TestLoginSmokeAccessDenialDecisions" "$TEST_FILE"
grep -Fq "TestLoginSmokeReportRequiresEveryStep" "$TEST_FILE"

go test ./internal/auth/loginsmoke

for path in "/login/" "/tenant-select/" "/unauthorized/" "/forbidden/"; do
  body_file="$(mktemp)"
  status="$(curl --noproxy '*' --resolve "${PANEL_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${PANEL_DOMAIN}${path}")"
  test "$status" = "200"
  test -s "$body_file"
  rm -f "$body_file"
done
