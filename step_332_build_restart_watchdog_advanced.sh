#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== BUILD ==="
go build -o bin/service-watchdog ./cmd/service-watchdog
echo "OK ✅ build tamam"

echo
echo "=== RESTART ==="
systemctl restart pix2pi-watchdog
sleep 2
systemctl status pix2pi-watchdog --no-pager -n 20 || true

echo
echo "=== STATUS TEST ==="
curl -s http://127.0.0.1:8090/status
echo
echo "OK ✅ watchdog restart ve status test tamam"
