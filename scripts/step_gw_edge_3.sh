#!/usr/bin/env bash
set -u

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
TXT_REPORT="$REPORT_DIR/gw_edge_3_${TS}.txt"
MD_REPORT="$REPORT_DIR/gw_edge_3_${TS}.md"
LATEST_TXT="$REPORT_DIR/gw_edge_3_latest.txt"
LATEST_MD="$REPORT_DIR/gw_edge_3_latest.md"

GW_PORT="${GW_PORT:-9010}"
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-https://pix2pi.com.tr}"
LOCAL_BASE="http://127.0.0.1:${GW_PORT}"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "OK ✅ $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

status_from_headers() {
  awk 'NR==1 {print $2}' "$1"
}

has_header() {
  local header_file="$1"
  local key="$2"
  local value="$3"
  grep -iq "^${key}: .*${value}" "$header_file"
}

contains_text() {
  local file="$1"
  local text="$2"
  grep -q "$text" "$file"
}

not_contains_text() {
  local file="$1"
  local text="$2"
  ! grep -qi "$text" "$file"
}

request_dump() {
  local label="$1"
  local url="$2"
  local header_file="$3"
  local body_file="$4"

  echo
  echo "===== ${label} ====="
  echo "URL: ${url}"
  curl -ksS -D "$header_file" -o "$body_file" "$url" || true
  cat "$header_file"
  echo
  cat "$body_file"
  echo
}

exec > >(tee "$TXT_REPORT") 2>&1

echo "===== GW EDGE 3 BASLIYOR ====="
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Root: $ROOT"
echo "Local Base: $LOCAL_BASE"
echo "Public Domain: $PUBLIC_DOMAIN"

echo
echo "===== STEP 1 - 9010 LISTEN KONTROL ====="
LISTEN_9010="$(ss -lntp 2>/dev/null | awk '$4 ~ /:9010$/ {print}')"
if [ -n "$LISTEN_9010" ]; then
  echo "$LISTEN_9010"
else
  echo "(bos)"
fi

if echo "$LISTEN_9010" | grep -Eq '127\.0\.0\.1:9010'; then
  ok "9010 localhost bind goruldu"
else
  fail "9010 localhost bind gorulmuyor"
fi

if echo "$LISTEN_9010" | grep -Eq '0\.0\.0\.0:9010|\*:9010|\[::\]:9010|:::9010'; then
  fail "9010 public bind gorunuyor"
else
  ok "9010 public bind gorunmuyor"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo
echo "===== STEP 2 - LOCAL HEALTH ====="
request_dump "LOCAL HEALTH" "${LOCAL_BASE}/health/live" "$TMP_DIR/local_health.h" "$TMP_DIR/local_health.b"
LOCAL_HEALTH_STATUS="$(status_from_headers "$TMP_DIR/local_health.h")"
if [ "$LOCAL_HEALTH_STATUS" = "200" ] && contains_text "$TMP_DIR/local_health.b" '"service":"api-gateway"'; then
  ok "local health 200 ve json dogru"
else
  fail "local health beklenen gibi degil"
fi

echo
echo "===== STEP 3 - PUBLIC HEALTH ====="
request_dump "PUBLIC HEALTH" "${PUBLIC_DOMAIN}/health/live" "$TMP_DIR/public_health.h" "$TMP_DIR/public_health.b"
PUBLIC_HEALTH_STATUS="$(status_from_headers "$TMP_DIR/public_health.h")"
if [ "$PUBLIC_HEALTH_STATUS" = "200" ] \
  && contains_text "$TMP_DIR/public_health.b" '"service":"api-gateway"' \
  && not_contains_text "$TMP_DIR/public_health.b" '<html'; then
  ok "public health 200 ve panel HTML donmuyor"
else
  fail "public health beklenen gibi degil"
fi

echo
echo "===== STEP 4 - PUBLIC API ME JWT BLOK ====="
request_dump "PUBLIC API ME" "${PUBLIC_DOMAIN}/api/me" "$TMP_DIR/public_api_me.h" "$TMP_DIR/public_api_me.b"
PUBLIC_API_ME_STATUS="$(status_from_headers "$TMP_DIR/public_api_me.h")"
if [ "$PUBLIC_API_ME_STATUS" = "401" ] \
  && contains_text "$TMP_DIR/public_api_me.b" 'missing_authorization_header' \
  && contains_text "$TMP_DIR/public_api_me.b" '"middleware":"jwt"' \
  && not_contains_text "$TMP_DIR/public_api_me.b" '<html'; then
  ok "public api me jwt ile bloklu"
else
  fail "public api me beklenen gibi degil"
fi

echo
echo "===== STEP 5 - PUBLIC INTERNAL ROUTES BLOK ====="
request_dump "PUBLIC INTERNAL ROUTES" "${PUBLIC_DOMAIN}/internal/routes" "$TMP_DIR/public_internal_routes.h" "$TMP_DIR/public_internal_routes.b"
PUBLIC_INTERNAL_STATUS="$(status_from_headers "$TMP_DIR/public_internal_routes.h")"
if [ "$PUBLIC_INTERNAL_STATUS" = "404" ] \
  && has_header "$TMP_DIR/public_internal_routes.h" 'x-ingress-policy' 'public-internal-deny' \
  && contains_text "$TMP_DIR/public_internal_routes.b" 'public_internal_route_blocked' \
  && not_contains_text "$TMP_DIR/public_internal_routes.b" '<html'; then
  ok "public internal routes nginx ingress tarafinda bloklu"
else
  fail "public internal routes beklenen gibi degil"
fi

echo
echo "===== STEP 6 - GATEWAY LOG SON 30 ====="
journalctl -u pix2pi-api-gateway -n 30 --no-pager || true

echo
echo "===== STEP 7 - FINAL OZET ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"

cat <<MD > "$MD_REPORT"
# GW Edge 3 Report

- Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')
- Root: $ROOT
- Local Base: $LOCAL_BASE
- Public Domain: $PUBLIC_DOMAIN
- Pass: $PASS_COUNT
- Fail: $FAIL_COUNT

## Kontrol Maddeleri
- 9010 localhost bind kontrolu
- 9010 public bind yok kontrolu
- local /health/live = 200
- public /health/live = 200
- public /api/me = 401
- public /internal/routes = 404 + ingress block
- gateway log son 30

## Final Sonuc
$(if [ "$FAIL_COUNT" -eq 0 ]; then echo "**BASARILI ✅**"; else echo "**HATA VAR ❌**"; fi)
MD

cp -f "$TXT_REPORT" "$LATEST_TXT"
cp -f "$MD_REPORT" "$LATEST_MD"

echo
echo "TXT RAPOR: $TXT_REPORT"
echo "MD RAPOR : $MD_REPORT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  ok "GW-EDGE-3 tamam"
  exit 0
else
  fail "GW-EDGE-3 hata ile bitti"
  exit 1
fi
