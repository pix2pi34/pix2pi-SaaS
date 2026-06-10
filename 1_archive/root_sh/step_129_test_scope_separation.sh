#!/bin/bash
set -e

echo "=== AUTH ILK ISTEK ==="
curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
echo
echo

echo "=== IDENTITY ILK ISTEK ==="
curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
echo
echo

echo "=== REDIS AUTH KEY ==="
redis-cli GET tenant:tenant-scope-001:gateway:auth:rate_limit || true
echo

echo "=== REDIS IDENTITY KEY ==="
redis-cli GET tenant:tenant-scope-001:gateway:identity:rate_limit || true
echo

echo "OK ✅ scope separation test bitti"
