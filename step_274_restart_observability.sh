#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS/infra/observability

docker compose down
docker compose up -d

sleep 8

docker compose ps

echo "OK ✅ observability restart bitti"
