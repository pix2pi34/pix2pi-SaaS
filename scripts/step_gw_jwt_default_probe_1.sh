#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/root/pix2pi/pix2pi-SaaS}"
cd "$ROOT_DIR"

REPORT_DIR="$ROOT_DIR/reports"
TMP_DIR="$ROOT_DIR/tmp"
REPORT_FILE="$REPORT_DIR/gw_jwt_default_probe_1_latest.txt"
GO_FILE="$TMP_DIR/gw_jwt_default_probe_main.go"
BODY_FILE="$TMP_DIR/gw_jwt_default_probe_body.json"
WINNER_ENV="$TMP_DIR/gw_jwt_default_probe_winner.env"

mkdir -p "$REPORT_DIR" "$TMP_DIR"

echo "===== GW JWT DEFAULT PROBE 1 =====" | tee "$REPORT_FILE"
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')" | tee -a "$REPORT_FILE"
echo "Root: $ROOT_DIR" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 1 - JWT LIB =====" | tee -a "$REPORT_FILE"
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

echo "===== STEP 2 - KODDAN DEFAULT SECRET CEK =====" | tee -a "$REPORT_FILE"
DEFAULT_SECRET="$(python3 <<'PY'
import re
from pathlib import Path

targets = [
    Path("cmd/api-gateway/gateway_config.go"),
    Path("cmd/api-gateway/api_gateway_main.go"),
]

for p in targets:
    if not p.exists():
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r'envString\(\s*"JWT_SECRET"\s*,\s*"([^"]+)"\s*\)', text)
    if m:
        print(m.group(1))
        raise SystemExit(0)

print("")
PY
)"
if [ -z "${DEFAULT_SECRET:-}" ]; then
  DEFAULT_SECRET="dev-jwt-secret"
  echo "WARN ⚠️ koddan cekilemedi, fallback kullanildi: $DEFAULT_SECRET" | tee -a "$REPORT_FILE"
else
  echo "OK ✅ kod default secret: $DEFAULT_SECRET" | tee -a "$REPORT_FILE"
fi

grep -Rni 'envString("JWT_SECRET"' cmd/api-gateway 2>/dev/null | tee -a "$REPORT_FILE" || true
echo | tee -a "$REPORT_FILE"

echo "===== STEP 3 - TOKEN GENERATOR YAZ =====" | tee -a "$REPORT_FILE"
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
	secret := os.Getenv("GW_PROBE_SECRET")
	tenant := os.Getenv("GW_PROBE_TENANT")
	profile := os.Getenv("GW_PROBE_PROFILE")

	if secret == "" {
		panic("GW_PROBE_SECRET bos")
	}
	if tenant == "" {
		panic("GW_PROBE_TENANT bos")
	}
	if profile == "" {
		panic("GW_PROBE_PROFILE bos")
	}

	now := time.Now()
	claims := jwt.MapClaims{}

	switch profile {
	case "min":
		claims["tenant_id"] = tenant
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	case "std":
		claims["sub"] = "gwprobe-user"
		claims["email"] = "gwprobe@pix2pi.local"
		claims["role"] = "admin"
		claims["tenant_id"] = tenant
		claims["iat"] = now.Unix()
		claims["nbf"] = now.Add(-1 * time.Minute).Unix()
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	case "rich":
		claims["sub"] = "gwprobe-user"
		claims["email"] = "gwprobe@pix2pi.local"
		claims["role"] = "admin"
		claims["scope"] = "admin"
		claims["tenant_id"] = tenant
		claims["tenant"] = tenant
		claims["tenant_uuid"] = tenant
		claims["iat"] = now.Unix()
		claims["nbf"] = now.Add(-1 * time.Minute).Unix()
		claims["exp"] = now.Add(2 * time.Hour).Unix()

	default:
		panic("bilinmeyen profile")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		panic(err)
	}

	out := map[string]any{
		"token":   signed,
		"tenant":  tenant,
		"profile": profile,
	}
	b, _ := json.Marshal(out)
	fmt.Println(string(b))
}
EOFGO
echo "OK ✅ token generator yazildi" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

echo "===== STEP 4 - PROBE MATRIX =====" | tee -a "$REPORT_FILE"

FOUND=0
FOUND_SECRET=""
FOUND_TENANT=""
FOUND_PROFILE=""
FOUND_HTTP=""
FOUND_BODY_CODE=""
FOUND_TOKEN=""

for SECRET_NAME in DEFAULT CODE_FALLBACK SHELL_ENV; do
  SECRET_VALUE=""
  case "$SECRET_NAME" in
    DEFAULT) SECRET_VALUE="$DEFAULT_SECRET" ;;
    CODE_FALLBACK) SECRET_VALUE="dev-jwt-secret" ;;
    SHELL_ENV) SECRET_VALUE="${JWT_SECRET:-}" ;;
  esac

  if [ -z "$SECRET_VALUE" ]; then
    echo "SKIP name=$SECRET_NAME secret_bos" | tee -a "$REPORT_FILE"
    continue
  fi

  for TENANT in tenant-001 tenant-demo; do
    for PROFILE in min std rich; do
      RAW="$(GW_PROBE_SECRET="$SECRET_VALUE" GW_PROBE_TENANT="$TENANT" GW_PROBE_PROFILE="$PROFILE" go run "$GO_FILE")"
      TOKEN="$(printf '%s' "$RAW" | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')"

      HTTP_CODE="$(curl -sS -o "$BODY_FILE" -w '%{http_code}' \
        -H "Authorization: Bearer $TOKEN" \
        -H "X-Tenant-ID: $TENANT" \
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

      echo "TRY secret=$SECRET_NAME tenant=$TENANT profile=$PROFILE http=$HTTP_CODE body_code=$BODY_CODE" | tee -a "$REPORT_FILE"

      if [ "$BODY_CODE" != "invalid_token" ]; then
        FOUND=1
        FOUND_SECRET="$SECRET_VALUE"
        FOUND_TENANT="$TENANT"
        FOUND_PROFILE="$PROFILE"
        FOUND_HTTP="$HTTP_CODE"
        FOUND_BODY_CODE="$BODY_CODE"
        FOUND_TOKEN="$TOKEN"
        break 3
      fi
    done
  done
done

echo | tee -a "$REPORT_FILE"

if [ "$FOUND" = "1" ]; then
  cat <<EOFENV > "$WINNER_ENV"
export GW_TEST_BEARER='$FOUND_TOKEN'
export GW_TEST_TENANT_ID='$FOUND_TENANT'
export GW_TEST_PROFILE='$FOUND_PROFILE'
export GW_TEST_HTTP_CODE='$FOUND_HTTP'
export GW_TEST_BODY_CODE='$FOUND_BODY_CODE'
EOFENV

  echo "OK ✅ kazanan bulundu" | tee -a "$REPORT_FILE"
  echo "OK ✅ tenant=$FOUND_TENANT" | tee -a "$REPORT_FILE"
  echo "OK ✅ profile=$FOUND_PROFILE" | tee -a "$REPORT_FILE"
  echo "OK ✅ http=$FOUND_HTTP" | tee -a "$REPORT_FILE"
  echo "OK ✅ body_code=$FOUND_BODY_CODE" | tee -a "$REPORT_FILE"
  echo "OK ✅ winner env: $WINNER_ENV" | tee -a "$REPORT_FILE"
else
  echo "HATA ❌ default dahil hicbir kombinasyon invalid_token engelini gecemedi" | tee -a "$REPORT_FILE"
  exit 1
fi

echo | tee -a "$REPORT_FILE"
echo "===== STEP 5 - SON =====" | tee -a "$REPORT_FILE"
echo "OK ✅ GW JWT DEFAULT PROBE 1 bitti" | tee -a "$REPORT_FILE"
