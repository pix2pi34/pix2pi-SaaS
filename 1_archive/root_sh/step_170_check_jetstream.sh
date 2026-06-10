#!/bin/bash
set -e

echo "=== NATS JetStream kontrol ==="

curl -s http://127.0.0.1:8222/jsz | head -20

echo
echo "OK ✅ JetStream kontrol bitti"
