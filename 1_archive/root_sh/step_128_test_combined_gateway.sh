#!/bin/bash
set -e

echo "=== IDENTITY TENANTSIZ ==="
curl -s -i https://api.pix2pi.com.tr/api/identity/health
echo
echo

echo "=== IDENTITY TENANTLI ==="
curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
echo
echo

echo "=== AUTH TENANTSIZ ==="
curl -s -i https://api.pix2pi.com.tr/api/auth/health
echo
echo

echo "=== AUTH TENANTLI ==="
curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
echo
echo

echo "=== REDIS KEY CONTROL ==="
redis-cli GET tenant:tenant-combined-identity:gateway:identity:rate_limit || true
echo
redis-cli GET tenant:tenant-combined-auth:gateway:auth:rate_limit || true
echo

echo "OK ✅ combined gateway test bitti"
