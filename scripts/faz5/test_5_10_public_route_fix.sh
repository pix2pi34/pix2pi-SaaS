#!/usr/bin/env bash
set -u

REPORT_FILE="reports/faz5/FAZ_5_10_PUBLIC_ROUTE_FIX_REPORT.txt"

FAIL_COUNT=0
OK_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

check_url() {
  local url="$1"
  local marker="$2"
  local label="$3"
  local tmp_file="$4"

  echo
  echo "===== URL TEST: $label ====="

  local status
  status="$(curl -k -L -sS \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o "$tmp_file" \
    -w "%{http_code}" \
    "$url")"

  echo "URL=$url"
  echo "HTTP_STATUS=$status"

  if [ "$status" = "200" ]; then
    pass "$label HTTP 200"
  else
    fail_soft "$label HTTP 200 degil: $status"
  fi

  if grep -Fq "$marker" "$tmp_file"; then
    pass "$label beklenen marker dondu: $marker"
  else
    fail_soft "$label beklenen marker donmedi: $marker"
    echo "----- DONEN TITLE / ILK SATIRLAR -----"
    grep -Eio '<title>[^<]+' "$tmp_file" | head -3 || true
    head -20 "$tmp_file" || true
    echo "--------------------------------------"
  fi
}

echo "===== FAZ 5-10 PUBLIC ROUTE FIX TEST BASLADI ====="

if grep -Fq "location /faz5/" /etc/nginx/conf.d/pix2pi_faz4d_static.conf; then
  pass "nginx conf icinde location /faz5/ var"
else
  fail_soft "nginx conf icinde location /faz5/ yok"
fi

if grep -Fq "root /var/www/pix2pi;" /etc/nginx/conf.d/pix2pi_faz4d_static.conf; then
  pass "nginx faz5 root dogru"
else
  fail_soft "nginx faz5 root bulunamadi"
fi

check_url "https://pix2pi.com.tr/faz5/" "Pix2pi FAZ 5 Public Surfaces" "faz5 index" "/tmp/pix2pi_faz5_route_fix_index.html"
check_url "https://pix2pi.com.tr/faz5/pricing/" "Public Pricing Surface" "faz5 pricing" "/tmp/pix2pi_faz5_route_fix_pricing.html"
check_url "https://pix2pi.com.tr/faz5/developer/" "Developer Surface" "faz5 developer" "/tmp/pix2pi_faz5_route_fix_developer.html"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  ROUTE_STATUS="PASS ✅"
else
  ROUTE_STATUS="HATA ❌"
fi

{
  echo "FAZ_5_10_PUBLIC_ROUTE_FIX_STATUS=$ROUTE_STATUS"
  echo "OK_COUNT=$OK_COUNT"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "URL_INDEX=https://pix2pi.com.tr/faz5/"
  echo "URL_PRICING=https://pix2pi.com.tr/faz5/pricing/"
  echo "URL_DEVELOPER=https://pix2pi.com.tr/faz5/developer/"
  echo "NGINX_CONF=/etc/nginx/conf.d/pix2pi_faz4d_static.conf"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC ROUTE FIX RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC ROUTE FIX TEST OZETI ====="
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-10 PUBLIC ROUTE FIX TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-10 PUBLIC ROUTE FIX TEST SONUCU: HATA ❌ ====="
  exit 1
fi
