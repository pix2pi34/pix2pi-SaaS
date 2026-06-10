#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/gw_ingress_scan/${TS}"
REPORT_TXT="reports/gw_ingress_scan_${TS}.txt"
LATEST_TXT="reports/gw_ingress_scan_latest.txt"

mkdir -p "$BACKUP_DIR" reports

echo "===== STEP 1 - NGINX YEDEK ====="
for path in \
  /etc/nginx/nginx.conf \
  /etc/nginx/conf.d \
  /etc/nginx/sites-enabled \
  /etc/nginx/sites-available \
  /etc/nginx/snippets
do
  if [ -e "$path" ]; then
    cp -a "$path" "$BACKUP_DIR"/
    echo "OK ✅ yedek alindi: $path"
  fi
done

{
  echo "===== GW INGRESS SCAN ====="
  echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "Root: $(pwd)"
  echo

  echo "===== LISTEN PORTLARI ====="
  ss -lntp || true
  echo

  echo "===== PIX2PI / NGINX SERVISLERI ====="
  systemctl list-units --type=service --all | grep -Ei 'pix2pi|nginx' || true
  echo

  echo "===== NGINX FILTRELI CONFIG ====="
  nginx -T 2>/dev/null | grep -nEi 'server_name|listen |location |proxy_pass|upstream|auth_request|/api|/health|9001|9002|9003|9010|pix2pi' || true
  echo

  echo "===== LOCAL HTTP KONTROL ====="

  for url in \
    "http://127.0.0.1/" \
    "http://127.0.0.1/health" \
    "http://127.0.0.1/health/live" \
    "http://127.0.0.1/api/me" \
    "http://127.0.0.1:9010/health/live" \
    "http://127.0.0.1:9010/api/me" \
    "http://127.0.0.1:9001/health" \
    "http://127.0.0.1:9001/whoami" \
    "http://127.0.0.1:9002/health"
  do
    echo "--- ${url} ---"
    curl -sS -i --max-time 5 "${url}" || true
    echo
  done

} | tee "$REPORT_TXT"

cp "$REPORT_TXT" "$LATEST_TXT"

echo
echo "OK ✅ rapor hazir: $REPORT_TXT"
echo "OK ✅ latest rapor guncellendi: $LATEST_TXT"
