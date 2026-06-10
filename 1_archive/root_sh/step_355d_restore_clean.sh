#!/bin/bash
set -e

SRC="/root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go.bak_clean_1773944628"
DST="/root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"
BIN="/root/pix2pi/pix2pi-SaaS/bin/service-watchdog"

echo "=== STEP 355D / RESTORE CLEAN ==="

echo
echo "1. restore..."
cp "$SRC" "$DST"
echo "OK ✅ restore edildi"

echo
echo "2. build..."

cd /root/pix2pi/pix2pi-SaaS
go build -o "$BIN" ./cmd/service-watchdog

echo "OK ✅ build OK"

echo
echo "3. restart..."

pkill service-watchdog || true
"$BIN" &

sleep 2

echo "OK ✅ restart"

echo
echo "4. test..."

curl -s http://127.0.0.1:8090/status | head -c 300
echo

echo
echo "OK ✅ sistem geri geldi"
