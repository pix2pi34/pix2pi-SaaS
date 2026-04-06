#!/bin/bash
set -e

echo "=== CRONTAB ==="
crontab -l || true
echo

echo "=== /etc/crontab ==="
cat /etc/crontab || true
echo

echo "=== /etc/init.d ==="
ls -la /etc/init.d | grep -i kong || true
echo

echo "=== /etc/systemd/system ==="
ls -la /etc/systemd/system | grep -i kong || true
echo

echo "=== /etc/rc.local ==="
cat /etc/rc.local 2>/dev/null || true
echo

echo "=== /etc/profile.d ==="
grep -R "openresty" /etc/profile.d 2>/dev/null || true
echo

echo "=== /usr/local icinde arama ==="
grep -R "openresty" /usr/local 2>/dev/null | head -20
echo

echo "OK 🔍 kong starter arama bitti"
