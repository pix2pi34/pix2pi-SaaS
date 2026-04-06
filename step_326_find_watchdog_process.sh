#!/bin/bash
set -e

echo "=== WATCHDOG PROCESS ARAMA ==="
ps -ef | grep -i 'service-watchdog\|service_watchdog\|watchdog_main\|8090' | grep -v grep || true
echo

echo "=== WATCHDOG DOSYA ARAMA ==="
find ~/pix2pi/pix2pi-SaaS -type f | grep -i 'service-watchdog\|service_watchdog\|watchdog' || true
echo

echo "=== 8090 PORT KONTROL ==="
ss -tulpn | grep ':8090' || true
echo

echo "OK ✅ watchdog process arama bitti"
