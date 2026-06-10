#!/bin/bash
set -e

echo "=== 9001 IDENTITY ==="
curl -s http://127.0.0.1:9001/health || true

echo
echo "=== 9010 GATEWAY ==="
curl -s http://127.0.0.1:9010/health || true

echo
echo "OK ✅ identity ve gateway port testi bitti"
