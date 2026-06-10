#!/bin/bash
set -e

echo "=== DOCKER ==="
docker --version

echo
echo "=== DOCKER COMPOSE ==="
docker compose version

echo
echo "=== FIREWALL ==="
ufw status

echo
echo "=== PRODUCTION DIRS ==="
test -d /opt/pix2pi/apps && echo "OK ✅ /opt/pix2pi/apps var"
test -d /opt/pix2pi/config && echo "OK ✅ /opt/pix2pi/config var"
test -d /opt/pix2pi/logs && echo "OK ✅ /opt/pix2pi/logs var"
test -d /opt/pix2pi/backups && echo "OK ✅ /opt/pix2pi/backups var"
test -d /opt/pix2pi/nginx && echo "OK ✅ /opt/pix2pi/nginx var"
test -d /opt/pix2pi/ssl && echo "OK ✅ /opt/pix2pi/ssl var"

echo
echo "OK ✅ production server hazirlik testi bitti"
