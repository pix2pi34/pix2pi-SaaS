#!/usr/bin/env bash
set -u

REPORT_FILE="reports/faz5/FAZ_5_10_PUBLIC_ROUTE_DIAGNOSE_REPORT.txt"

PUBLIC_ROOT="/var/www/pix2pi"
LOCAL_INDEX="$PUBLIC_ROOT/faz5/index.html"
LOCAL_PRICING="$PUBLIC_ROOT/faz5/pricing/index.html"
LOCAL_DEVELOPER="$PUBLIC_ROOT/faz5/developer/index.html"

URL_INDEX="https://pix2pi.com.tr/faz5/"
URL_PRICING="https://pix2pi.com.tr/faz5/pricing/"
URL_DEVELOPER="https://pix2pi.com.tr/faz5/developer/"

TMP_INDEX="/tmp/pix2pi_diag_faz5_index.html"
TMP_PRICING="/tmp/pix2pi_diag_faz5_pricing.html"
TMP_DEVELOPER="/tmp/pix2pi_diag_faz5_developer.html"

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

check_file_contains() {
  local file="$1"
  local marker="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$marker" "$file"; then
    pass "$label marker var: $marker"
  else
    fail_soft "$label marker yok: $marker"
  fi
}

curl_check() {
  local url="$1"
  local outfile="$2"
  local marker="$3"
  local label="$4"

  echo
  echo "===== CURL KONTROL: $label ====="
  local status
  status="$(curl -k -L -sS \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o "$outfile" \
    -w "%{http_code}" \
    "$url")"

  echo "URL=$url"
  echo "HTTP_STATUS=$status"
  echo "BODY_FILE=$outfile"

  if [ "$status" = "200" ]; then
    pass "$label HTTP 200"
  else
    fail_soft "$label HTTP 200 degil: $status"
  fi

  if grep -Fq "$marker" "$outfile"; then
    pass "$label beklenen marker dondu: $marker"
  else
    fail_soft "$label beklenen marker donmedi: $marker"
    echo "----- DONEN HTML TITLE / ILK SATIRLAR -----"
    grep -Eio '<title>[^<]+' "$outfile" | head -3 || true
    head -20 "$outfile" || true
    echo "------------------------------------------"
  fi
}

echo "===== FAZ 5-10 PUBLIC ROUTE DIAGNOSE BASLADI ====="

echo
echo "===== LOCAL DOSYA KONTROLU ====="
check_file_contains "$LOCAL_INDEX" "Pix2pi FAZ 5 Public Surfaces" "local faz5 index"
check_file_contains "$LOCAL_PRICING" "Public Pricing Surface" "local pricing"
check_file_contains "$LOCAL_DEVELOPER" "Developer Surface" "local developer"

echo
echo "===== PUBLIC URL KONTROLU ====="
curl_check "$URL_INDEX" "$TMP_INDEX" "Pix2pi FAZ 5 Public Surfaces" "public faz5 index"
curl_check "$URL_PRICING" "$TMP_PRICING" "Public Pricing Surface" "public pricing"
curl_check "$URL_DEVELOPER" "$TMP_DEVELOPER" "Developer Surface" "public developer"

echo
echo "===== NGINX AKTIF CONFIG OZETI ====="

echo
echo "----- enabled sites -----"
ls -la /etc/nginx/sites-enabled || true

echo
echo "----- server_name pix2pi aramasi -----"
grep -RIn "server_name.*pix2pi\|pix2pi.com.tr" /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null || true

echo
echo "----- root / alias / try_files aramasi -----"
grep -RIn "root \|alias \|try_files \|location /faz5\|location / " /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null || true

echo
echo "===== MUHTEMEL DURUM ====="

if grep -Fq "Pix2pi FAZ 5 Public Surfaces" "$TMP_INDEX" \
  && grep -Fq "Public Pricing Surface" "$TMP_PRICING" \
  && grep -Fq "Developer Surface" "$TMP_DEVELOPER"; then
  pass "public route dogru icerik donduruyor"
  ROUTE_STATUS="PASS ✅"
else
  fail_soft "public route HTTP 200 donuyor ama beklenen icerigi dondurmuyor"
  ROUTE_STATUS="ROUTE_MISMATCH ❌"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

{
  echo "FAZ_5_10_PUBLIC_ROUTE_DIAGNOSE_STATUS=$ROUTE_STATUS"
  echo "OK_COUNT=$OK_COUNT"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "LOCAL_INDEX=$LOCAL_INDEX"
  echo "LOCAL_PRICING=$LOCAL_PRICING"
  echo "LOCAL_DEVELOPER=$LOCAL_DEVELOPER"
  echo "URL_INDEX=$URL_INDEX"
  echo "URL_PRICING=$URL_PRICING"
  echo "URL_DEVELOPER=$URL_DEVELOPER"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC ROUTE DIAGNOSE RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-10 PUBLIC ROUTE DIAGNOSE BITTI ====="

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "PUBLIC_ROUTE_STATUS=PASS ✅"
  exit 0
else
  echo "PUBLIC_ROUTE_STATUS=ROUTE_MISMATCH ❌"
  exit 1
fi
