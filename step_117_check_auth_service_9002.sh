#!/bin/bash
set -e

echo "=== AUTH 9002 HEALTH ==="
curl -s -i http://127.0.0.1:9002/health || true

echo
echo "OK ✅ auth 9002 kontrol bitti"
