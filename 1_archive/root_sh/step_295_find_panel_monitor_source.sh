#!/bin/bash
set -e

echo "===== PANEL DOSYALARINDA SERVICE MONITOR ARANIYOR ====="
grep -Rni "service-monitor\|internal/service-monitor\|api/services\|Server Monitor\|Son guncelleme\|api_gateway\|accounting_service" \
  ~/pix2pi/pix2pi-SaaS 2>/dev/null || true

echo
echo "===== NGINX SITES-ENABLED ====="
ls -la /etc/nginx/sites-enabled || true

echo
echo "===== PIX2PI SSL DOSYASI ====="
sed -n '1,220p' /etc/nginx/sites-enabled/pix2pi_ssl 2>/dev/null || true

echo
echo "===== PIX2PI HTTP REDIRECT DOSYASI ====="
sed -n '1,220p' /etc/nginx/sites-enabled/pix2pi_http_redirect 2>/dev/null || true

echo
echo "OK ✅ panel monitor source tarandi"
