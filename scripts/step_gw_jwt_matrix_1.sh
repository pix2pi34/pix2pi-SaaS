#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/root/pix2pi/pix2pi-SaaS}"
cd "$ROOT_DIR"

REPORT_DIR="$ROOT_DIR/reports"
TMP_DIR="$ROOT_DIR/tmp"
REPORT_FILE="$REPORT_DIR/gw_jwt_matrix_1_latest.txt"
CANDIDATE_FILE="$TMP_DIR/gw_jwt_candidates.tsv"
GO_FILE="$TMP_DIR/gw_jwt_matrix_main.go"
WINNER_ENV="$TMP_DIR/gw_jwt_matrix_winner.env"
BODY_FILE="$TMP_DIR/gw_jwt_matrix_body.json"

mkdir -p "$REPORT_DIR" "$TMP_DIR"

echo "===== GW JWT MATRIX 1 =====" | tee "$REPORT_FILE"
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
  echo "HATA ❌ jwt kutuphanesi bulunamadi" | tee -a "$REPORT_FILE"
  exit 1
fi
echo "OK ✅ jwt import: $JWT_IMPORT" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 2 - GATEWAY PID BUL =====" | tee -a "$REPORT_FILE"
GW_PID="$(ss -lntp 2>/dev/null | grep '127.0.0.1:9010' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n 1 || true)"
if [ -z "$GW_PID" ]; then
  GW_PID="$(pgrep -xo pix2pi-api-gate || true)"
fi
if [ -z "$GW_PID" ]; then
  echo "HATA ❌ gateway pid bulunamadi" | tee -a "$REPORT_FILE"
  exit 1
fi
echo "OK ✅ gateway pid: $GW_PID" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 3 - PROCESS ENV SECRET ADAYLARI =====" | tee -a "$REPORT_FILE"
python3 <<'PY' > "$CANDIDATE_FILE"
import os
import re

pid = os.environ["GW_PID"]
path = f"/proc/{pid}/environ"

wanted = []
seen = set()

def add(name, value, source):
    key = (name, value, source)
    if key in seen:
        return
    seen.add(key)
    wanted.append((name, value, source))

with open(path, "rb") as f:
    data = f.read().decode("utf-8", errors="ignore")

for item in data.split("\x00"):
    if "=" not in item:
        continue
    name, value = item.split("=", 1)
    up = name.upper()
    if "INTERNAL_KEY" in up:
        continue
    if ("JWT" in up or "TOKEN" in up or "AUTH" in up) and ("SECRET" in up or up.endswith("_KEY")):
        if value.strip():
            add(name, value, "process_env")

for hard in [
    "JWT_SECRET",
    "APP_JWT_SECRET",
    "AUTH_JWT_SECRET",
    "AUTH_SECRET",
    "ACCESS_TOKEN_SECRET",
    "IDENTITY_JWT_SECRET",
    "JWT_HMAC_SECRET",
    "JWT_SIGNING_SECRET",
    "TOKEN_SECRET",
]:
    v = os.environ.get(hard, "")
    if v.strip():
        add(hard, v, "current_shell")

for name, value, source in wanted:
    print(f"{name}\t{value}\t{source}")
PY

if [ ! -s "$CANDIDATE_FILE" ]; then
  echo "HATA ❌ process env icinde aday secret bulunamadi" | tee -a "$REPORT_FILE"
  exit 1
fi

awk -F'\t' '{printf "OK ✅ %s | source=%s | len=%d\n",$1,$3,length($2)}' "$CANDIDATE_FILE" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 4 - GATEWAY JWT KAYNAK TARAMASI =====" | tee -a "$REPORT_FILE"
grep -RniE 'ParseWithClaims|SignedString|JWT_SECRET|AUTH_JWT_SECRET|AUTH_SECRET|ACCESS_TOKEN_SECRET|IDENTITY_JWT_SECRET|TOKEN_SECRET|jwt|SigningKey|tenant_id|tenant_uuid' \
  cmd/api-gateway internal 2>/dev/null | head -n 120 | tee -a "$REPORT_FILE" || true
echo "OK ✅ kaynak taramasi tamam" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 5 - TOKEN GENERATOR YAZ =====" | tee -a "$REPORT_FILE"
cat <<EOFGO > "$GO_FILE"
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	jwt "$JWT_IMPORT"
)

func main() {
	secret := os.Getenv("GW_MATRIX_SECRET")
	profile := os.Getenv("GW_MATRIX_PROFILE")

	if secret == "" {
		panic("GW_MATRIX_SECRET bos")
	}
	if profile == "" {
		panic("GW_MATRIX_PROFILE bos")
	}

	now := time.Now()
	claims := jwt.MapClaims{}

	switch profile {
	case "p1":
		claims["iss"] = "gw-matrix"
		claims["sub"] = "gwprobe-user"
		claims["email"] = "gwprobe@pix2pi.local"
		claims["role"] = "admin"
		claims["tenant_id"] = "tenant-demo"
		claims["iat"] = now.Unix()
		claims["nbf"] = now.Add(-1 * time.Minute).Unix()
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	case "p2":
		claims["tenant_id"] = "tenant-demo"
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	case "p3":
		claims["iss"] = "gw-matrix"
		claims["sub"] = "gwprobe-user"
		claims["email"] = "gwprobe@pix2pi.local"
		claims["role"] = "admin"
		claims["tenant_id"] = "tenant-demo"
		claims["tenant"] = "tenant-demo"
		claims["tenant_uuid"] = "tenant-demo"
		claims["iat"] = now.Unix()
		claims["nbf"] = now.Add(-1 * time.Minute).Unix()
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	case "p4":
		claims["tenant_id"] = "tenant-demo"
		claims["tenant"] = "tenant-demo"
		claims["tenantId"] = "tenant-demo"
		claims["tenant_uuid"] = "tenant-demo"
		claims["tenantUuid"] = "tenant-demo"
		claims["email"] = "gwprobe@pix2pi.local"
		claims["role"] = "admin"
		claims["scope"] = "admin"
		claims["iat"] = now.Unix()
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	default:
		panic("bilinmeyen profile: " + profile)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		panic(err)
	}

	out := map[string]any{
		"profile": profile,
		"claims":  claims,
		"token":   signed,
	}
	b, _ := json.Marshal(out)
	fmt.Println(string(b))
}
EOFGO
echo "OK ✅ token generator yazildi" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 6 - MATRIX TEST =====" | tee -a "$REPORT_FILE"

FOUND=0
FOUND_NAME=""
FOUND_PROFILE=""
FOUND_CODE=""
FOUND_TOKEN=""

while IFS=$'\t' read -r SECRET_NAME SECRET_VALUE SECRET_SOURCE; do
  [ -z "$SECRET_NAME" ] && continue

  for PROFILE in p1 p2 p3 p4; do
    RAW="$(GW_MATRIX_SECRET="$SECRET_VALUE" GW_MATRIX_PROFILE="$PROFILE" go run "$GO_FILE")"
    TOKEN="$(printf '%s' "$RAW" | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')"

    HTTP_CODE="$(curl -sS -o "$BODY_FILE" -w '%{http_code}' \
      -H "Authorization: Bearer $TOKEN" \
      -H "X-Tenant-ID: tenant-demo" \
      http://127.0.0.1:9010/api/me || true)"

    BODY_CODE="$(python3 - "$BODY_FILE" <<'PY'
import json, sys
p = sys.argv[1]
try:
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("code",""))
except Exception:
    print("")
PY
)"

    echo "TRY name=$SECRET_NAME source=$SECRET_SOURCE profile=$PROFILE http=$HTTP_CODE body_code=$BODY_CODE" | tee -a "$REPORT_FILE"

    if [ "$BODY_CODE" != "invalid_token" ]; then
      FOUND=1
      FOUND_NAME="$SECRET_NAME"
      FOUND_PROFILE="$PROFILE"
      FOUND_CODE="$HTTP_CODE"
      FOUND_TOKEN="$TOKEN"
      break 2
    fi
  done
done < "$CANDIDATE_FILE"

echo | tee -a "$REPORT_FILE"

if [ "$FOUND" = "1" ]; then
  cat <<EOFENV > "$WINNER_ENV"
export GW_TEST_BEARER='$FOUND_TOKEN'
export GW_TEST_TENANT_ID='tenant-demo'
export GW_TEST_SECRET_NAME='$FOUND_NAME'
export GW_TEST_PROFILE='$FOUND_PROFILE'
export GW_TEST_HTTP_CODE='$FOUND_CODE'
EOFENV

  echo "OK ✅ kabul edilen kombinasyon bulundu" | tee -a "$REPORT_FILE"
  echo "OK ✅ secret_name=$FOUND_NAME" | tee -a "$REPORT_FILE"
  echo "OK ✅ profile=$FOUND_PROFILE" | tee -a "$REPORT_FILE"
  echo "OK ✅ http_code=$FOUND_CODE" | tee -a "$REPORT_FILE"
  echo "OK ✅ winner env: $WINNER_ENV" | tee -a "$REPORT_FILE"
else
  echo "HATA ❌ hicbir kombinasyon invalid_token engelini gecemedi" | tee -a "$REPORT_FILE"
  exit 1
fi

echo | tee -a "$REPORT_FILE"
echo "===== STEP 7 - SON =====" | tee -a "$REPORT_FILE"
echo "OK ✅ GW-JWT-MATRIX-1 bitti" | tee -a "$REPORT_FILE"
