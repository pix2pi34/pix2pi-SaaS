#!/bin/bash
set -e

echo "=== REDIS PING ==="
redis-cli ping

echo
echo "=== REDIS INFO SERVER ==="
redis-cli info server | head -20 || true

echo
echo "OK ✅ redis kontrol bitti"
