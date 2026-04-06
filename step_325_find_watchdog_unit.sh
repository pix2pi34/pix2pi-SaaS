#!/bin/bash
set -e

echo "=== SYSTEMD WATCHDOG ARAMA ==="
systemctl list-unit-files --type=service | grep -i 'watchdog\|pix2pi' || true
echo

echo "=== SYSTEMD ACTIVE SERVICE ARAMA ==="
systemctl list-units --type=service | grep -i 'watchdog\|pix2pi' || true
echo

echo "=== DOSYA ARAMA ==="
ls -la /etc/systemd/system | grep -i 'watchdog\|pix2pi' || true
echo
ls -la /lib/systemd/system | grep -i 'watchdog\|pix2pi' || true
echo

echo "OK ✅ watchdog unit arama bitti"
