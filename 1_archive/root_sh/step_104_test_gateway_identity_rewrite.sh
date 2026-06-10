#!/bin/bash
set -e

echo "=== GATEWAY HEALTH ==="
curl -s http://127.0.0.1:9010/health
echo

echo "=== IDENTITY DIRECT ==="
curl -s http://127.0.0.1:9001/health || true
echo

echo "=== IDENTITY VIA GATEWAY LOCAL ==="
curl -s http://127.0.0.1:9010/api/identity/health || true
echo

echo "=== IDENTITY VIA DOMAIN ==="
curl -s https://api.pix2pi.com.tr/api/identity/health || true
echo

echo "OK ✅ gateway identity rewrite test bitti"
