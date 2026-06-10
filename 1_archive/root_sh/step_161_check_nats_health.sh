#!/bin/bash
set -e

echo "=== NATS 4222 ==="
ss -lntp | grep 4222 || true

echo
echo "=== NATS MONITOR 8222 ==="
curl -s http://127.0.0.1:8222/healthz || true
echo

echo
echo "OK ✅ NATS health kontrol bitti"
