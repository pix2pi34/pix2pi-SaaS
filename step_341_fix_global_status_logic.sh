#!/bin/bash
set -e

FILE=~/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go

echo "=== BACKUP ==="
cp $FILE ${FILE}.bak_$(date +%s)

echo "=== PATCH GLOBAL LOGIC ==="

sed -i 's/if s.Status == "STOPPED" {/if s.Status == "STOPPED" \&\& s.Method != "design" {/' $FILE

echo "OK ✅ logic fix edildi"

echo
echo "=== BUILD ==="
cd ~/pix2pi/pix2pi-SaaS
go build -o bin/service-watchdog ./cmd/service-watchdog

echo
echo "=== RESTART ==="
systemctl restart pix2pi-watchdog
sleep 2

echo
echo "=== TEST ==="
curl http://127.0.0.1:8090/status
echo
echo "OK ✅ tamam"
