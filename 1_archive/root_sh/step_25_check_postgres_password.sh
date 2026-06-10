#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== POSTGRES CONTAINER ENV ==="
docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true

echo
echo "=== .env DB BILGILERI ==="
grep -E '^(DB_HOST|DB_PORT|DB_USER|DB_NAME|DB_PASSWORD|POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB)=' .env || true

echo
echo "OK ✅ postgres sifre kontrolu bitti"
