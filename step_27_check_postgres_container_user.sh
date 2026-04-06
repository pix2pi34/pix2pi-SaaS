#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== CONTAINER POSTGRES ENV ==="
docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true

echo
echo "OK ✅ postgres container user kontrolu bitti"
