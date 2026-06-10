#!/bin/bash
set -e

echo "=== HOSTNAME ==="
hostname

echo
echo "=== OS ==="
cat /etc/os-release

echo
echo "=== CPU / RAM / DISK ==="
nproc || true
free -h || true
df -h || true

echo
echo "=== IP ==="
hostname -I || true

echo
echo "=== DOCKER ==="
docker --version || true

echo
echo "=== DOCKER COMPOSE ==="
docker compose version || true

echo
echo "=== UFW ==="
ufw status || true

echo
echo "=== OK ✅ production server kontrolu bitti ==="
