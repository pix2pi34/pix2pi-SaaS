#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
TXT_REPORT="$ROOT/reports/gw_master_close_${TS}.txt"
MD_REPORT="$ROOT/reports/gw_master_close_${TS}.md"
LATEST_TXT="$ROOT/reports/gw_master_close_latest.txt"
LATEST_MD="$ROOT/reports/gw_master_close_latest.md"

SERVICE="pix2pi-api-gateway.service"
ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
LOCAL_BASE="http://127.0.0.1:9010"
PUBLIC_BASE="https://pix2pi.com.tr"

PASS_COUNT=0
FAIL_COUNT=0

mkdir -p "$ROOT/reports" "$ROOT/tmp"

ok() {
  echo "OK ✅ $1"
  PASS_COUNT=$((PASS_COUNT+1))
}

fail() {
  echo "HATA ❌ $1"
  FAIL_COUNT=$((FAIL_COUNT+1))
}

echo "===== GW MASTER CLOSE 1 ====="
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Root: $ROOT"
echo "Service: $SERVICE"
echo "Local Base: $LOCAL_BASE"
echo "Public Base: $PUBLIC_BASE"
echo

TMP_DIR="$ROOT/tmp/gw_master_close_${TS}"
mkdir -p "$TMP_DIR"

INTERNAL_KEY=""
if grep -q '^GATEWAY_INTERNAL_KEY=' "$ENV_FILE"; then
  INTERNAL_KEY="$(grep '^GATEWAY_INTERNAL_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
elif grep -q '^INTERNAL_GATEWAY_KEY=' "$ENV_FILE"; then
  INTERNAL_KEY="$(grep '^INTERNAL_GATEWAY_KEY=' "$ENV_FILE" | tail -n 1 | cut -d= -f2-)"
fi

echo "===== STEP 1 - SERVICE ====="
if systemctl is-active --quiet "$SERVICE"; then
  ok "gateway service aktif"
else
  fail "gateway service aktif degil"
fi
systemctl --no-pager --full status "$SERVICE" | sed -n '1,20p'
echo

echo "===== STEP 2 - JWT DEFAULT FALLBACK KONTROL ====="
if grep -q 'requiredEnv("JWT_SECRET")' cmd/api-gateway/gateway_config.go; then
  ok 'gateway_config.go icinde requiredEnv("JWT_SECRET") var'
else
  fail 'requiredEnv("JWT_SECRET") bulunamadi'
fi

if grep -q 'envString("JWT_SECRET", "dev-jwt-secret")' cmd/api-gateway/gateway_config.go; then
  fail 'eski default JWT fallback hala duruyor'
else
  ok 'eski default JWT fallback koddan kalkmis'
fi
echo

echo "===== STEP 3 - LOCAL HEALTH ====="
LOCAL_HEALTH_BODY="$TMP_DIR/local_health.txt"
LOCAL_HEALTH_CODE="$(curl -sS -o "$LOCAL_HEALTH_BODY" -w '%{http_code}' "$LOCAL_BASE/health/live" || true)"
echo "local_health_code=$LOCAL_HEALTH_CODE"
cat "$LOCAL_HEALTH_BODY" || true
echo
if [ "$LOCAL_HEALTH_CODE" = "200" ] && grep -q '"status":"ok"' "$LOCAL_HEALTH_BODY"; then
  ok "local /health/live 200 ve json dogru"
else
  fail "local /health/live beklenen gibi degil"
fi
echo

echo "===== STEP 4 - LOCAL API ME JWT BLOK ====="
LOCAL_API_BODY="$TMP_DIR/local_api_me.txt"
LOCAL_API_CODE="$(curl -sS -o "$LOCAL_API_BODY" -w '%{http_code}' "$LOCAL_BASE/api/me" || true)"
echo "local_api_me_code=$LOCAL_API_CODE"
cat "$LOCAL_API_BODY" || true
echo
if [ "$LOCAL_API_CODE" = "401" ] && grep -q 'missing_authorization_header' "$LOCAL_API_BODY"; then
  ok "local /api/me jwt olmadan 401"
else
  fail "local /api/me jwt blok sonucu beklenen gibi degil"
fi
echo

echo "===== STEP 5 - PUBLIC HEALTH ====="
PUBLIC_HEALTH_HEAD="$TMP_DIR/public_health_headers.txt"
PUBLIC_HEALTH_BODY="$TMP_DIR/public_health_body.txt"
PUBLIC_HEALTH_CODE="$(curl -sS -D "$PUBLIC_HEALTH_HEAD" -o "$PUBLIC_HEALTH_BODY" -w '%{http_code}' "$PUBLIC_BASE/health/live" || true)"
echo "public_health_code=$PUBLIC_HEALTH_CODE"
sed -n '1,20p' "$PUBLIC_HEALTH_HEAD" || true
echo
sed -n '1,20p' "$PUBLIC_HEALTH_BODY" || true
echo
if [ "$PUBLIC_HEALTH_CODE" = "200" ] && grep -q '"status":"ok"' "$PUBLIC_HEALTH_BODY" && ! grep -qi '<html' "$PUBLIC_HEALTH_BODY"; then
  ok "public /health/live 200 ve panel HTML donmuyor"
else
  fail "public /health/live beklenen gibi degil"
fi
echo

echo "===== STEP 6 - PUBLIC API ME JWT BLOK ====="
PUBLIC_API_HEAD="$TMP_DIR/public_api_headers.txt"
PUBLIC_API_BODY="$TMP_DIR/public_api_body.txt"
PUBLIC_API_CODE="$(curl -sS -D "$PUBLIC_API_HEAD" -o "$PUBLIC_API_BODY" -w '%{http_code}' "$PUBLIC_BASE/api/me" || true)"
echo "public_api_me_code=$PUBLIC_API_CODE"
sed -n '1,20p' "$PUBLIC_API_HEAD" || true
echo
sed -n '1,20p' "$PUBLIC_API_BODY" || true
echo
if [ "$PUBLIC_API_CODE" = "401" ] && grep -q 'missing_authorization_header' "$PUBLIC_API_BODY" && ! grep -qi '<html' "$PUBLIC_API_BODY"; then
  ok "public /api/me jwt olmadan 401"
else
  fail "public /api/me jwt blok sonucu beklenen gibi degil"
fi
echo

echo "===== STEP 7 - PUBLIC INTERNAL ROUTES BLOK ====="
PUBLIC_INTERNAL_HEAD="$TMP_DIR/public_internal_headers.txt"
PUBLIC_INTERNAL_BODY="$TMP_DIR/public_internal_body.txt"
PUBLIC_INTERNAL_CODE="$(curl -sS -D "$PUBLIC_INTERNAL_HEAD" -o "$PUBLIC_INTERNAL_BODY" -w '%{http_code}' "$PUBLIC_BASE/internal/routes" || true)"
echo "public_internal_routes_code=$PUBLIC_INTERNAL_CODE"
sed -n '1,20p' "$PUBLIC_INTERNAL_HEAD" || true
echo
sed -n '1,20p' "$PUBLIC_INTERNAL_BODY" || true
echo
if [ "$PUBLIC_INTERNAL_CODE" = "404" ] && grep -q 'public_internal_route_blocked' "$PUBLIC_INTERNAL_BODY" && ! grep -qi '<html' "$PUBLIC_INTERNAL_BODY"; then
  ok "public /internal/routes ingress tarafinda bloklu"
else
  fail "public /internal/routes blok sonucu beklenen gibi degil"
fi
echo

echo "===== STEP 8 - INTERNAL POLICY ====="
POLICY_BODY="$TMP_DIR/internal_policy_body.txt"
POLICY_CODE="000"
if [ -n "$INTERNAL_KEY" ]; then
  POLICY_CODE="$(curl -sS -o "$POLICY_BODY" -w '%{http_code}' -H "X-Gateway-Internal-Key: $INTERNAL_KEY" "$LOCAL_BASE/internal/policy" || true)"
else
  : > "$POLICY_BODY"
fi
echo "internal_policy_code=$POLICY_CODE"
cat "$POLICY_BODY" || true
echo

RATE_VALUE=""
QUOTA_VALUE=""
if [ "$POLICY_CODE" = "200" ]; then
  readarray -t POLICY_VALUES < <(python3 - <<'PY' "$POLICY_BODY"
import json, sys
p = sys.argv[1]
try:
    data = json.load(open(p))
    pol = data.get("policy", {})
    print(pol.get("rate_limit_per_minute", ""))
    print(pol.get("daily_quota", ""))
except Exception:
    print("")
    print("")
PY
)
  RATE_VALUE="${POLICY_VALUES[0]:-}"
  QUOTA_VALUE="${POLICY_VALUES[1]:-}"
fi

echo "rate_value=${RATE_VALUE:-}"
echo "quota_value=${QUOTA_VALUE:-}"
if [ "$POLICY_CODE" = "200" ] && [ "$RATE_VALUE" = "3" ] && [ "$QUOTA_VALUE" = "10" ]; then
  ok "internal policy varsayilan rate=3 quota=10"
else
  fail "internal policy rate/quota beklenen gibi degil"
fi
echo

echo "===== STEP 9 - LOG SON 30 ====="
journalctl -u "$SERVICE" -n 30 --no-pager || true
ok "gateway son log alindi"
echo

echo "===== STEP 10 - TXT RAPOR ====="
{
  echo "time=$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "service=$SERVICE"
  echo "local_base=$LOCAL_BASE"
  echo "public_base=$PUBLIC_BASE"
  echo "pass_count=$PASS_COUNT"
  echo "fail_count=$FAIL_COUNT"
  echo
  echo "[checks]"
  echo "service_active=$(systemctl is-active "$SERVICE" || true)"
  echo "jwt_required_helper_present=$(grep -q 'requiredEnv(\"JWT_SECRET\")' cmd/api-gateway/gateway_config.go && echo yes || echo no)"
  echo "jwt_default_fallback_removed=$(grep -q 'envString(\"JWT_SECRET\", \"dev-jwt-secret\")' cmd/api-gateway/gateway_config.go && echo no || echo yes)"
  echo "local_health_code=$LOCAL_HEALTH_CODE"
  echo "local_api_me_code=$LOCAL_API_CODE"
  echo "public_health_code=$PUBLIC_HEALTH_CODE"
  echo "public_api_me_code=$PUBLIC_API_CODE"
  echo "public_internal_routes_code=$PUBLIC_INTERNAL_CODE"
  echo "internal_policy_code=$POLICY_CODE"
  echo "rate_limit_per_minute=${RATE_VALUE:-}"
  echo "daily_quota=${QUOTA_VALUE:-}"
} > "$TXT_REPORT"

cp -f "$TXT_REPORT" "$LATEST_TXT"
ok "txt rapor yazildi: $TXT_REPORT"
echo

echo "===== STEP 11 - MD RAPOR ====="
{
  echo "# GW Master Close Report"
  echo
  echo "- Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "- Service: $SERVICE"
  echo "- Local Base: $LOCAL_BASE"
  echo "- Public Base: $PUBLIC_BASE"
  echo "- Gecen: $PASS_COUNT"
  echo "- Hata: $FAIL_COUNT"
  echo
  echo "## Sonuc"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "**BASARILI ✅**"
  else
    echo "**HATALI ❌**"
  fi
  echo
  echo "## Kontrol Ozetleri"
  echo "- gateway service aktif"
  echo "- JWT default fallback kaldirildi"
  echo "- local /health/live = $LOCAL_HEALTH_CODE"
  echo "- local /api/me jwt yok = $LOCAL_API_CODE"
  echo "- public /health/live = $PUBLIC_HEALTH_CODE"
  echo "- public /api/me jwt yok = $PUBLIC_API_CODE"
  echo "- public /internal/routes = $PUBLIC_INTERNAL_CODE"
  echo "- internal policy rate = ${RATE_VALUE:-bos}"
  echo "- internal policy quota = ${QUOTA_VALUE:-bos}"
} > "$MD_REPORT"

cp -f "$MD_REPORT" "$LATEST_MD"
ok "md rapor yazildi: $MD_REPORT"
echo

echo "===== STEP 12 - FINAL ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "TXT_RAPOR=$TXT_REPORT"
echo "MD_RAPOR=$MD_REPORT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  ok "GW-MASTER-CLOSE-1 basarili"
  exit 0
else
  fail "GW-MASTER-CLOSE-1 hata verdi"
  exit 1
fi
