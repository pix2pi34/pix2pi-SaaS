#!/bin/bash
set -e

URL_IDENTITY="https://api.pix2pi.com.tr/api/identity/health"
URL_AUTH="https://api.pix2pi.com.tr/api/auth/health"

echo "=== TEST 1 bearer yok ==="
curl -s -i -H "X-Tenant-ID: tenant-001" "$URL_IDENTITY"
echo
echo

echo "=== TEST 2 gecersiz bearer ==="
curl -s -i \
  -H "Authorization: Bearer invalid-token" \
  -H "X-Tenant-ID: tenant-001" \
  "$URL_IDENTITY"
echo
echo

echo "=== TEST 3 dogru bearer + dogru tenant ==="
curl -s -i \
  -H "Authorization: Bearer pix2pi-token-tenant-001" \
  -H "X-Tenant-ID: tenant-001" \
  "$URL_IDENTITY"
echo
echo

echo "=== TEST 4 dogru bearer + yanlis tenant ==="
curl -s -i \
  -H "Authorization: Bearer pix2pi-token-tenant-001" \
  -H "X-Tenant-ID: tenant-999" \
  "$URL_IDENTITY"
echo
echo

echo "=== TEST 5 super admin + secilen tenant ==="
curl -s -i \
  -H "Authorization: Bearer pix2pi-admin-token" \
  -H "X-Tenant-ID: tenant-777" \
  "$URL_AUTH"
echo
echo

echo "OK ✅ bearer tenant match test bitti"
