#!/bin/bash
set -e

echo "=== CACHE HEALTH ==="
curl -s http://127.0.0.1:9011/health
echo
echo

echo "=== CACHE SET ==="
curl -s "http://127.0.0.1:9011/cache/set?key=urun:1001&value=1250"
echo
echo

echo "=== CACHE GET ==="
curl -s "http://127.0.0.1:9011/cache/get?key=urun:1001"
echo
echo

echo "=== CACHE LOG ==="
cat /tmp/pix2pi_cache_service.log || true
echo

echo "OK ✅ cache service test bitti"
