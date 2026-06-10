#!/usr/bin/env bash
set -u

REPORT_FILE="reports/faz5/FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_REPORT.txt"
TS="$(date +%s)"

FAIL_COUNT=0
OK_COUNT=0
WARN_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

warn_soft() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "UYARI ⚠️ $1"
}

check_file_contains() {
  local file="$1"
  local marker="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$marker" "$file"; then
    pass "$label marker var"
  else
    fail_soft "$label marker yok: $marker"
  fi
}

check_url_required() {
  local url="$1"
  local marker="$2"
  local label="$3"
  local tmp_file="$4"

  echo
  echo "===== URL REQUIRED TEST: $label ====="

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
    pass "$label beklenen marker dondu"
  else
    fail_soft "$label beklenen marker donmedi: $marker"
    echo "----- DONEN TITLE / ILK SATIRLAR -----"
    grep -Eio '<title>[^<]+' "$tmp_file" | head -3 || true
    head -20 "$tmp_file" || true
    echo "--------------------------------------"
  fi
}

check_url_cache_note() {
  local url="$1"
  local marker="$2"
  local label="$3"
  local tmp_file="$4"

  echo
  echo "===== URL CACHE NOTE TEST: $label ====="

  local status
  status="$(curl -k -L -sS \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o "$tmp_file" \
    -w "%{http_code}" \
    "$url")"

  echo "URL=$url"
  echo "HTTP_STATUS=$status"

  if [ "$status" = "200" ] && grep -Fq "$marker" "$tmp_file"; then
    pass "$label bare URL dogru"
  else
    warn_soft "$label bare URL halen eski cache/fallback donebilir"
    echo "----- DONEN TITLE / ILK SATIRLAR -----"
    grep -Eio '<title>[^<]+' "$tmp_file" | head -3 || true
    head -10 "$tmp_file" || true
    echo "--------------------------------------"
  fi
}

echo "===== FAZ 5-10 PUBLIC EXACT ROUTE FIX TEST BASLADI ====="

echo
echo "===== LOCAL DOSYA KONTROLU ====="

check_file_contains "/var/www/pix2pi/faz5/index.html" "Pix2pi FAZ 5 Public Surfaces" "local faz5 index"
check_file_contains "/var/www/pix2pi/faz5/pricing/index.html" "Public Pricing Surface" "local pricing"
check_file_contains "/var/www/pix2pi/faz5/developer/index.html" "Developer Surface" "local developer"

echo
echo "===== NGINX CONF KONTROLU ====="

if grep -Fq "location = /faz5/" /etc/nginx/conf.d/pix2pi_faz4d_static.conf; then
  pass "nginx exact location = /faz5/ var"
else
  fail_soft "nginx exact location = /faz5/ yok"
fi

if grep -Fq "location = /faz5/pricing/" /etc/nginx/conf.d/pix2pi_faz4d_static.conf; then
  pass "nginx exact location = /faz5/pricing/ var"
else
  fail_soft "nginx exact location = /faz5/pricing/ yok"
fi

if grep -Fq "location = /faz5/developer/" /etc/nginx/conf.d/pix2pi_faz4d_static.conf; then
  pass "nginx exact location = /faz5/developer/ var"
else
  fail_soft "nginx exact location = /faz5/developer/ yok"
fi

echo
echo "===== ORIGIN DIRECT TESTLERI ====="

check_url_required "https://pix2pi.com.tr/faz5/?v=$TS" "Pix2pi FAZ 5 Public Surfaces" "origin/public faz5 index cache-bust" "/tmp/pix2pi_exact_faz5_index_cachebust.html"
check_url_required "https://pix2pi.com.tr/faz5/pricing/?v=$TS" "Public Pricing Surface" "origin/public faz5 pricing cache-bust" "/tmp/pix2pi_exact_faz5_pricing_cachebust.html"
check_url_required "https://pix2pi.com.tr/faz5/developer/?v=$TS" "Developer Surface" "origin/public faz5 developer cache-bust" "/tmp/pix2pi_exact_faz5_developer_cachebust.html"

echo
echo "===== BARE URL CACHE KONTROLU ====="

check_url_cache_note "https://pix2pi.com.tr/faz5/" "Pix2pi FAZ 5 Public Surfaces" "bare faz5 index" "/tmp/pix2pi_exact_faz5_index_bare.html"
check_url_cache_note "https://pix2pi.com.tr/faz5/pricing/" "Public Pricing Surface" "bare faz5 pricing" "/tmp/pix2pi_exact_faz5_pricing_bare.html"
check_url_cache_note "https://pix2pi.com.tr/faz5/developer/" "Developer Surface" "bare faz5 developer" "/tmp/pix2pi_exact_faz5_developer_bare.html"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  ROUTE_STATUS="PASS ✅"
else
  ROUTE_STATUS="HATA ❌"
fi

{
  echo "FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_STATUS=$ROUTE_STATUS"
  echo "OK_COUNT=$OK_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "URL_INDEX=https://pix2pi.com.tr/faz5/"
  echo "URL_PRICING=https://pix2pi.com.tr/faz5/pricing/"
  echo "URL_DEVELOPER=https://pix2pi.com.tr/faz5/developer/"
  echo "CACHE_BUST_INDEX=https://pix2pi.com.tr/faz5/?v=$TS"
  echo "CACHE_BUST_PRICING=https://pix2pi.com.tr/faz5/pricing/?v=$TS"
  echo "CACHE_BUST_DEVELOPER=https://pix2pi.com.tr/faz5/developer/?v=$TS"
  echo "NGINX_CONF=/etc/nginx/conf.d/pix2pi_faz4d_static.conf"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC EXACT ROUTE FIX RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC EXACT ROUTE FIX TEST OZETI ====="
echo "OK_COUNT=$OK_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-10 PUBLIC EXACT ROUTE FIX TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-10 PUBLIC EXACT ROUTE FIX TEST SONUCU: HATA ❌ ====="
  exit 1
fi
