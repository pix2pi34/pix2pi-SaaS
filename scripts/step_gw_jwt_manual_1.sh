#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/root/pix2pi/pix2pi-SaaS}"
cd "$ROOT_DIR"

REPORT_DIR="$ROOT_DIR/reports"
TMP_DIR="$ROOT_DIR/tmp"
OUT_ENV="$TMP_DIR/gw_manual_bearer.env"
REPORT_FILE="$REPORT_DIR/gw_jwt_manual_1_latest.txt"
TMP_GO="$TMP_DIR/gw_manual_jwt_main.go"

mkdir -p "$REPORT_DIR" "$TMP_DIR"

echo "===== GW JWT MANUAL 1 =====" | tee "$REPORT_FILE"
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')" | tee -a "$REPORT_FILE"
echo "Root: $ROOT_DIR" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 1 - JWT LIB TESPIT =====" | tee -a "$REPORT_FILE"

JWT_IMPORT=""
if grep -q 'github.com/golang-jwt/jwt/v5' go.mod 2>/dev/null; then
  JWT_IMPORT='github.com/golang-jwt/jwt/v5'
elif grep -q 'github.com/golang-jwt/jwt/v4' go.mod 2>/dev/null; then
  JWT_IMPORT='github.com/golang-jwt/jwt/v4'
elif grep -q 'github.com/golang-jwt/jwt ' go.mod 2>/dev/null; then
  JWT_IMPORT='github.com/golang-jwt/jwt'
elif grep -q 'github.com/dgrijalva/jwt-go' go.mod 2>/dev/null; then
  JWT_IMPORT='github.com/dgrijalva/jwt-go'
else
  echo "HATA ❌ go.mod icinde desteklenen jwt kutuphanesi bulunamadi" | tee -a "$REPORT_FILE"
  exit 1
fi

echo "OK ✅ jwt import bulundu: $JWT_IMPORT" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 2 - KAYNAK TARAMASI =====" | tee -a "$REPORT_FILE"
grep -RniE 'os\.Getenv\("([A-Z0-9_]+)"\)|SignedString|tenant_id|tenant_uuid|tenantId|tenantUuid|Authorization|Bearer' cmd internal 2>/dev/null | head -n 80 | tee -a "$REPORT_FILE" || true
echo "OK ✅ kaynak taramasi tamam" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 3 - ADAY SECRET ENV BUL =====" | tee -a "$REPORT_FILE"

python3 <<'PY' > "$TMP_DIR/gw_jwt_candidate_envs.txt"
import re
from pathlib import Path

root = Path("/root/pix2pi/pix2pi-SaaS")
cand = set()

default_names = [
    "JWT_SECRET",
    "JWT_SIGNING_SECRET",
    "AUTH_JWT_SECRET",
    "AUTH_SECRET",
    "TOKEN_SECRET",
    "APP_JWT_SECRET",
    "IDENTITY_JWT_SECRET",
    "ACCESS_TOKEN_SECRET",
    "JWT_HMAC_SECRET",
]

for x in default_names:
    cand.add(x)

rx = re.compile(r'os\.Getenv\("([A-Z0-9_]+)"\)')
for path in list(root.glob("cmd/**/*.go")) + list(root.glob("internal/**/*.go")):
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    for m in rx.findall(text):
        up = m.upper()
        if ("JWT" in up or "TOKEN" in up or "AUTH" in up) and ("SECRET" in up or up.endswith("_KEY")):
            if "INTERNAL_KEY" in up:
                continue
            if "GATEWAY_INTERNAL_KEY" in up:
                continue
            cand.add(up)

for item in sorted(cand):
    print(item)
PY

cat "$TMP_DIR/gw_jwt_candidate_envs.txt" | tee -a "$REPORT_FILE"
echo "OK ✅ aday env listesi hazir" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 4 - SECRET DEGERINI COZ =====" | tee -a "$REPORT_FILE"

FOUND_NAME=""
FOUND_VALUE=""

resolve_from_file() {
  local env_name="$1"
  local env_file="$2"

  python3 - "$env_name" "$env_file" <<'PY'
import sys, re
name = sys.argv[1]
path = sys.argv[2]

try:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
except Exception:
    print("")
    raise SystemExit(0)

rx = re.compile(r'^\s*(?:export\s+)?([A-Z0-9_]+)\s*=\s*(.*)\s*$')
for raw in lines:
    line = raw.rstrip("\n")
    m = rx.match(line)
    if not m:
        continue
    k, v = m.group(1), m.group(2)
    if k != name:
        continue
    v = v.strip()
    if len(v) >= 2 and ((v[0] == v[-1] == '"') or (v[0] == v[-1] == "'")):
        v = v[1:-1]
    print(v)
    raise SystemExit(0)

print("")
PY
}

while IFS= read -r candidate; do
  [ -z "$candidate" ] && continue

  value="${!candidate-}"
  if [ -n "$value" ]; then
    FOUND_NAME="$candidate"
    FOUND_VALUE="$value"
    echo "OK ✅ process env icinde bulundu: $FOUND_NAME" | tee -a "$REPORT_FILE"
    break
  fi

  for f in \
    /opt/pix2pi/orchestrator/env/common.env \
    /etc/pix2pi/ports.env \
    "$ROOT_DIR/.env" \
    "$ROOT_DIR/.env.local" \
    "$ROOT_DIR/.env.production"
  do
    if [ -f "$f" ]; then
      value="$(resolve_from_file "$candidate" "$f")"
      if [ -n "$value" ]; then
        FOUND_NAME="$candidate"
        FOUND_VALUE="$value"
        echo "OK ✅ env dosyasinda bulundu: $FOUND_NAME | file=$f" | tee -a "$REPORT_FILE"
        break 2
      fi
    fi
  done
done < "$TMP_DIR/gw_jwt_candidate_envs.txt"

if [ -z "$FOUND_NAME" ] || [ -z "$FOUND_VALUE" ]; then
  echo "HATA ❌ jwt secret env bulunamadi" | tee -a "$REPORT_FILE"
  exit 1
fi

echo "OK ✅ secilen secret env: $FOUND_NAME" | tee -a "$REPORT_FILE"
echo "OK ✅ secret length: ${#FOUND_VALUE}" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 5 - GO TOKEN URETICI YAZ =====" | tee -a "$REPORT_FILE"

cat <<EOFGO > "$TMP_GO"
package main

import (
	"fmt"
	"os"
	"time"

	jwt "$JWT_IMPORT"
)

func main() {
	secret := os.Getenv("GW_JWT_SECRET_VALUE")
	if secret == "" {
		panic("GW_JWT_SECRET_VALUE bos")
	}

	now := time.Now()

	claims := jwt.MapClaims{
		"iss":         "gw-manual-probe",
		"sub":         "gwprobe-user",
		"email":       "gwprobe@pix2pi.local",
		"role":        "admin",
		"tenant_id":   "tenant-demo",
		"tenant_uuid": "tenant-demo",
		"tenant":      "tenant-demo",
		"tenantId":    "tenant-demo",
		"tenantUuid":  "tenant-demo",
		"iat":         now.Unix(),
		"nbf":         now.Add(-1 * time.Minute).Unix(),
		"exp":         now.Add(2 * time.Hour).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		panic(err)
	}

	fmt.Println(signed)
}
EOFGO

echo "OK ✅ token uretici yazildi: $TMP_GO" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 6 - TOKEN URET =====" | tee -a "$REPORT_FILE"

TOKEN="$(GW_JWT_SECRET_VALUE="$FOUND_VALUE" go run "$TMP_GO")"
if [ -z "$TOKEN" ]; then
  echo "HATA ❌ token uretilemedi" | tee -a "$REPORT_FILE"
  exit 1
fi

cat <<EOFENV > "$OUT_ENV"
export GW_TEST_BEARER='$TOKEN'
export GW_TEST_TENANT_ID='tenant-demo'
export GW_TEST_JWT_SECRET_ENV='$FOUND_NAME'
EOFENV

echo "OK ✅ token env yazildi: $OUT_ENV" | tee -a "$REPORT_FILE"
echo "OK ✅ token uzunlugu: ${#TOKEN}" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 7 - LOKAL API TEST =====" | tee -a "$REPORT_FILE"

LOCAL_CODE="$(curl -sS -o "$TMP_DIR/gw_manual_me_body.json" -w '%{http_code}' \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: tenant-demo" \
  http://127.0.0.1:9010/api/me || true)"

echo "LOCAL_CODE=$LOCAL_CODE" | tee -a "$REPORT_FILE"
cat "$TMP_DIR/gw_manual_me_body.json" | tee -a "$REPORT_FILE" || true
echo | tee -a "$REPORT_FILE"

case "$LOCAL_CODE" in
  200|201|202|204|403|429)
    echo "OK ✅ jwt middleware tokeni kabul etmis gorunuyor" | tee -a "$REPORT_FILE"
    ;;
  401)
    echo "HATA ❌ token 401 dondu, secret yanlis olabilir" | tee -a "$REPORT_FILE"
    exit 1
    ;;
  *)
    echo "WARN ⚠ beklenmeyen local code: $LOCAL_CODE" | tee -a "$REPORT_FILE"
    ;;
esac

echo | tee -a "$REPORT_FILE"
echo "===== STEP 8 - SONUC =====" | tee -a "$REPORT_FILE"
echo "OUT_ENV=$OUT_ENV" | tee -a "$REPORT_FILE"
echo "SECRET_ENV=$FOUND_NAME" | tee -a "$REPORT_FILE"
echo "OK ✅ GW-JWT-MANUAL-1 bitti" | tee -a "$REPORT_FILE"
