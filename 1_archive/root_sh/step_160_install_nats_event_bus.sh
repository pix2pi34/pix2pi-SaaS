#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p deploy/nats

cat <<'NATSYML' > deploy/nats/docker-compose.yml
services:
  nats:
    image: nats:2.10-alpine
    container_name: pix2pi_nats
    command:
      - "-js"
      - "-sd"
      - "/data"
    ports:
      - "4222:4222"
      - "8222:8222"
    volumes:
      - pix2pi_nats_data:/data
    restart: unless-stopped

volumes:
  pix2pi_nats_data:
NATSYML

docker compose -f deploy/nats/docker-compose.yml up -d

docker ps | grep pix2pi_nats || true

echo "OK ✅ NATS Event Bus kuruldu"
