#!/usr/bin/env bash
set -euo pipefail

ROOT="${PIX2PI_ROOT:-/root/pix2pi/pix2pi-SaaS}"
PANEL_ROOT="${PANEL_ROOT:-/var/www/pix2pi/panel}"
PKG_DIR="$ROOT/internal/faz7r/auth/passwordflow"
CONFIG="$ROOT/configs/faz7r/faz7r_349_password_flow_real_v2.json"
MIGRATION="$ROOT/db/migrations/20260511_349_password_flow_real_v2.sql"
DOC="$ROOT/docs/faz7r/FAZ_7R_349_PASSWORD_FLOW_REAL_V2.md"
HTML="$PANEL_ROOT/password-login/index.html"
JS="$PANEL_ROOT/password-login/password-login-runtime.js"

echo "===== FAZ 7-R / 349 PASSWORD FLOW REAL V2 STANDALONE AUDIT START ====="

test -f "$CONFIG"
test -f "$MIGRATION"
test -f "$DOC"
test -f "$PKG_DIR/password_flow.go"
test -f "$PKG_DIR/password_flow_test.go"
test -f "$HTML"
test -f "$JS"

grep -q "passwordSetup" "$CONFIG"
grep -q "auth.user_password_credentials" "$MIGRATION"
grep -q "SetupPassword" "$PKG_DIR/password_flow.go"
grep -q "RequestPasswordReset" "$PKG_DIR/password_flow.go"
grep -q "ValidateSession" "$PKG_DIR/password_flow.go"
grep -q "TestPasswordResetFlow" "$PKG_DIR/password_flow_test.go"
grep -q "PIX2PI_349_PASSWORD_LOGIN_SCREEN_V2_START" "$HTML"
grep -q "PIX2PI_349_PASSWORD_LOGIN_RUNTIME_V2_START" "$JS"

if grep -R -E "PLACEHOLDER_ONLY|DISABLED_RUNTIME|PARTIAL_PASS" "$CONFIG" "$DOC" "$PKG_DIR" "$HTML" "$JS" >/dev/null; then
  echo "FORBIDDEN_MARKER_FOUND / FAIL ❌"
  exit 1
fi

cd "$ROOT"
go test ./internal/faz7r/auth/passwordflow

echo "===== FAZ 7-R / 349 PASSWORD FLOW REAL V2 STANDALONE AUDIT PASS ====="
