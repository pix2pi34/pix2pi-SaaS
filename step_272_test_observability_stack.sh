#!/bin/bash
set -e

echo "=== PROMETHEUS ==="
curl -s http://127.0.0.1:9090/-/healthy
echo
echo

echo "=== LOKI ==="
curl -s http://127.0.0.1:3100/ready
echo
echo

echo "=== GRAFANA ==="
curl -s http://127.0.0.1:3001/api/health
echo
echo

echo "=== TMP LOG DOSYALARI ==="
ls -lah /tmp/pix2pi*.log || true
echo

echo "OK ✅ observability test bitti"
