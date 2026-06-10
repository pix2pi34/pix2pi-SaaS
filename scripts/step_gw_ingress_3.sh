#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
TXT_REPORT="$REPORT_DIR/gw_ingress_3_${TS}.txt"
LATEST_REPORT="$REPORT_DIR/gw_ingress_3_latest.txt"

DOMAIN="pix2pi.com.tr"
TARGET_IP="127.0.0.1"

request_check() {
  local label="$1"
  local path="$2"
  local expect1="$3"
  local expect2="${4:-}"

  local HEAD_FILE
  local BODY_FILE

  HEAD_FILE="$(mktemp)"
  BODY_FILE="$(mktemp)"

  {
    echo
    echo "===== ${label} ====="
    echo "URL: https://${DOMAIN}${path}"
  } | tee -a "$TXT_REPORT"

  curl -k -sS --max-time 15 \
    --resolve "${DOMAIN}:443:${TARGET_IP}" \
    -D "$HEAD_FILE" \
    -o "$BODY_FILE" \
    "https://${DOMAIN}${path}" || true

  cat "$HEAD_FILE" | tee -a "$TXT_REPORT"
  echo | tee -a "$TXT_REPORT"
  sed -n '1,40p' "$BODY_FILE" | tee -a "$TXT_REPORT"
  echo | tee -a "$TXT_REPORT"

  local code
  code="$(awk 'toupper($1) ~ /^HTTP\// {c=$2} END{print c}' "$HEAD_FILE")"

  if [[ "$code" == "$expect1" || ( -n "$expect2" && "$code" == "$expect2" ) ]]; then
    echo "OK ✅ ${label} status dogru: ${code}" | tee -a "$TXT_REPORT"
  else
    if [[ -n "$expect2" ]]; then
      echo "HATA ❌ ${label} beklenen: ${expect1} veya ${expect2} | gelen: ${code:-yok}" | tee -a "$TXT_REPORT"
    else
      echo "HATA ❌ ${label} beklenen: ${expect1} | gelen: ${code:-yok}" | tee -a "$TXT_REPORT"
    fi
  fi

  if grep -qi "Pix2pi Admin Panel" "$BODY_FILE"; then
    echo "HATA ❌ ${label} panel HTML dondu" | tee -a "$TXT_REPORT"
  else
    echo "OK ✅ ${label} panel HTML donmedi" | tee -a "$TXT_REPORT"
  fi

  rm -f "$HEAD_FILE" "$BODY_FILE"
}

{
  echo "===== GW-INGRESS-3 BASLIYOR ====="
  echo "Tarih: $(date '+%F %T %z')"
  echo "Domain: ${DOMAIN}"
  echo "SNI/Resolve IP: ${TARGET_IP}"
} | tee "$TXT_REPORT"

request_check "health_live" "/health/live" "200"
request_check "api_me_jwt_yok" "/api/me" "401"
request_check "internal_routes" "/internal/routes" "404" "403"

cp "$TXT_REPORT" "$LATEST_REPORT"

echo
echo "===== RAPOR ====="
echo "OK ✅ rapor hazir: $TXT_REPORT"
echo "OK ✅ latest rapor: $LATEST_REPORT"
