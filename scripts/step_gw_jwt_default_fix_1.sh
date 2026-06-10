#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/backups/gateway_jwt_default_fix/$TS"

FILE="cmd/api-gateway/gateway_config.go"
TEST_FILE="cmd/api-gateway/gateway_config_security_test.go"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
SERVICE="pix2pi-api-gateway.service"

mkdir -p "$BACKUP_DIR"

echo "===== STEP 1 - YEDEK ====="
cp -a "$FILE" "$BACKUP_DIR"/
if [ -f "$TEST_FILE" ]; then
  cp -a "$TEST_FILE" "$BACKUP_DIR"/
fi
cp -a "$ENV_FILE" "$BACKUP_DIR"/common.env.bak
echo "OK ✅ yedek alindi: $BACKUP_DIR"

echo
echo "===== STEP 2 - ON KONTROL ====="
grep -n 'JWT_SECRET' "$FILE" || true
grep -n '^JWT_SECRET=' "$ENV_FILE" || true
echo "OK ✅ on kontrol tamam"

echo
echo "===== STEP 3 - ENV GARANTI ====="
if ! grep -q '^JWT_SECRET=' "$ENV_FILE"; then
  printf '\nJWT_SECRET=dev-jwt-secret\n' >> "$ENV_FILE"
  echo "OK ✅ common.env icine JWT_SECRET acik olarak yazildi"
else
  echo "OK ✅ common.env icinde JWT_SECRET zaten var"
fi

echo
echo "===== STEP 4 - KOD PATCH ====="
python3 - <<'PY'
from pathlib import Path

p = Path("cmd/api-gateway/gateway_config.go")
data = p.read_text()
orig = data

needle = 'envString("JWT_SECRET", "dev-jwt-secret")'
repl   = 'requiredEnv("JWT_SECRET")'

if needle not in data and repl not in data:
    raise SystemExit("HATA ❌ hedef JWT default satiri bulunamadi")

data = data.replace(needle, repl)

if "func requiredEnv(" not in data:
    helper = '''
func requiredEnv(key string) string {
\tvalue := os.Getenv(key)
\tif value == "" {
\t\tpanic("required env missing: " + key)
\t}
\treturn value
}
'''
    data = data.rstrip() + "\n" + helper

if data == orig:
    print("OK ✅ kod zaten patchli")
else:
    p.write_text(data)
    print("OK ✅ gateway_config.go patchlendi")
PY

echo
echo "===== STEP 5 - TEST DOSYASI YAZ ====="
cat <<'EOF_TEST' > "$TEST_FILE"
package main

import (
	"os"
	"testing"
)

func TestRequiredEnvReturnsValue(t *testing.T) {
	t.Setenv("JWT_SECRET", "dev-jwt-secret")

	got := requiredEnv("JWT_SECRET")
	if got != "dev-jwt-secret" {
		t.Fatalf("beklenen dev-jwt-secret, gelen %q", got)
	}
}

func TestRequiredEnvPanicsWhenMissing(t *testing.T) {
	_ = os.Unsetenv("JWT_SECRET")

	defer func() {
		if r := recover(); r == nil {
			t.Fatal("JWT_SECRET bosken panic bekleniyordu")
		}
	}()

	_ = requiredEnv("JWT_SECRET")
}
EOF_TEST
echo "OK ✅ test dosyasi yazildi: $TEST_FILE"

echo
echo "===== STEP 6 - GOFMT ====="
gofmt -w "$FILE" "$TEST_FILE"
echo "OK ✅ gofmt tamam"

echo
echo "===== STEP 7 - TEST ====="
go test ./cmd/api-gateway
echo "OK ✅ cmd api-gateway test tam"

echo
echo "===== STEP 8 - BUILD ====="
go build -o pix2pi-api-gateway ./cmd/api-gateway
echo "OK ✅ gateway build tamam"

echo
echo "===== STEP 9 - RESTART ====="
systemctl restart "$SERVICE"
sleep 2
systemctl --no-pager --full status "$SERVICE" | sed -n '1,25p'
echo "OK ✅ gateway restart denendi"

echo
echo "===== STEP 10 - CANLI DOGRULAMA ====="
echo "--- /health/live ---"
curl -sS -i http://127.0.0.1:9010/health/live | sed -n '1,20p'
echo
echo "--- /api/me ---"
curl -sS -i http://127.0.0.1:9010/api/me | sed -n '1,20p'
echo
echo "OK ✅ jwt default fallback kapatma adimi bitti"
