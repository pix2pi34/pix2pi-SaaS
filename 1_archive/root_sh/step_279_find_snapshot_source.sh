#!/bin/bash
set -e

echo "=== CRON ==="
crontab -l || true
echo

echo "=== PROCESS ==="
ps aux | grep -i snapshot | grep -v grep || true
echo

echo "=== SYSTEMD ==="
systemctl list-units --type=service | grep -i snapshot || true
echo

echo "=== FILE WATCH ==="
lsof | grep pix2pi_service_snapshot_cron.log || true
echo

echo "OK ✅ snapshot source arandi"
