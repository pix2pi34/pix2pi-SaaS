#!/bin/bash
set -e

echo "===== SERVER_NAME SATIRLARI ====="
nginx -T 2>/dev/null | grep -n "server_name"

echo
echo "===== INTERNAL SERVICE-MONITOR GECIYOR MU ====="
nginx -T 2>/dev/null | grep -n "internal/service-monitor" || true

echo
echo "===== PIX2PI CONFIG DOSYALARI ====="
grep -Rni "pix2pi.com.tr\|api.pix2pi.com.tr" /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/conf.d 2>/dev/null || true

echo
echo "OK ✅ nginx gercek config tarandi"
