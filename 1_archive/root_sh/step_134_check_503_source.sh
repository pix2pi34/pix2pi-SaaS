#!/bin/bash
set -e

echo "=== NGINX TEST ==="
nginx -t || true

echo
echo "=== GATEWAY 9010 ==="
curl -i http://127.0.0.1:9010/health || true

echo
echo "=== AUTH 9002 ==="
curl -i http://127.0.0.1:9002/health || true

echo
echo "=== IDENTITY 9001 ==="
curl -i http://127.0.0.1:9001/health || true

echo
echo "=== API DOMAIN AUTH ==="
curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true

echo
echo "=== API DOMAIN IDENTITY ==="
curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true

echo
echo "OK ✅ 503 kaynak kontrolu bitti"
