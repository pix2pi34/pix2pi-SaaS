#!/bin/bash
set -e

echo "=== SYSTEMD ENABLE ==="
systemctl enable pix2pi-api-gateway.service
systemctl enable pix2pi-accounting.service
systemctl enable pix2pi-query-read-model.service
systemctl enable pix2pi-service-discovery.service

echo "=== START SERVICES ==="
systemctl restart pix2pi-api-gateway.service
systemctl restart pix2pi-accounting.service
systemctl restart pix2pi-query-read-model.service
systemctl restart pix2pi-service-discovery.service

sleep 2

echo
echo "=== STATUS ==="
systemctl status pix2pi-api-gateway.service --no-pager
systemctl status pix2pi-accounting.service --no-pager
systemctl status pix2pi-query-read-model.service --no-pager
systemctl status pix2pi-service-discovery.service --no-pager

echo
echo "=== PORT CHECK ==="
ss -tulnp | grep -E "8080|8007|8002|6379" || true

echo
echo "OK ✅ tum servisler baslatildi"
