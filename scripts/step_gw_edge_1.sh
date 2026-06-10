#!/usr/bin/env bash
set -uo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
TXT_REPORT="$REPORT_DIR/gw_edge_1_${STAMP}.txt"
LATEST_REPORT="$REPORT_DIR/gw_edge_1_latest.txt"

{
  echo "===== GW EDGE 1 REPORT ====="
  echo "Tarih: $(date '+%F %T %z')"
  echo "Root: $ROOT"
  echo

  echo "===== STEP 1 - SYSTEMD OZET ====="
  systemctl status pix2pi-api-gateway.service --no-pager || true
  echo

  echo "===== STEP 2 - SYSTEMD DETAY ====="
  systemctl show pix2pi-api-gateway.service \
    -p MainPID \
    -p ExecStart \
    -p Environment \
    -p EnvironmentFiles || true
  echo

  echo "===== STEP 3 - 9010 LISTEN KONTROL ====="
  ss -lntp | grep -E '(:9010[[:space:]]|:9010$)' || true
  echo

  echo "===== STEP 4 - COMMON ENV ====="
  grep -nE 'GATEWAY|INTERNAL_GATEWAY_KEY|HOST|PORT|BIND' /opt/pix2pi/orchestrator/env/common.env || true
  echo

  echo "===== STEP 5 - KOD TARAMASI ====="
  grep -RInE 'ListenAndServe|:9010|9010|GATEWAY_HOST|GATEWAY_BIND|BIND_ADDR|INTERNAL_GATEWAY_KEY' \
    cmd/api-gateway internal 2>/dev/null | head -n 120 || true
  echo

  echo "===== STEP 6 - FIREWALL / RULES ====="
  ufw status numbered || true
  echo
  iptables -S 2>/dev/null | grep 9010 || true
  echo
  nft list ruleset 2>/dev/null | grep -n 9010 || true
  echo

  echo "===== STEP 7 - LOCAL CURL ====="
  echo "--- 127.0.0.1:9010/health/live ---"
  curl -i --max-time 5 http://127.0.0.1:9010/health/live || true
  echo
  echo "--- 127.0.0.1:9010/api/me ---"
  curl -i --max-time 5 http://127.0.0.1:9010/api/me || true
  echo

  echo "===== STEP 8 - KARAR ====="
  SS_LINE="$(ss -lntp 2>/dev/null | grep -E '(:9010[[:space:]]|:9010$)' | head -n 1 || true)"
  echo "DINLEME_SATIRI=$SS_LINE"

  if echo "$SS_LINE" | grep -Eq '127\.0\.0\.1:9010|::1:9010|\[::1\]:9010'; then
    echo "OK ✅ 9010 sadece local bind gibi duruyor"
  elif echo "$SS_LINE" | grep -Eq '\*:9010|0\.0\.0\.0:9010|\[::\]:9010'; then
    echo "HATA ❌ 9010 public bind gorunuyor"
  else
    echo "WARN ⚠️ 9010 bind satiri net yorumlanamadi"
  fi

  echo
  echo "===== STEP 9 - RAPOR DOSYASI ====="
  echo "TXT_REPORT=$TXT_REPORT"
} | tee "$TXT_REPORT"

cp "$TXT_REPORT" "$LATEST_REPORT"

echo
echo "OK ✅ gw_edge_1 raporu hazir: $TXT_REPORT"
echo "OK ✅ latest rapor: $LATEST_REPORT"
