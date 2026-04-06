#!/bin/bash
set -e

docker rm -f pix2pi_nats_cli >/dev/null 2>&1 || true

docker run -d \
  --name pix2pi_nats_cli \
  --network container:pix2pi_nats \
  natsio/nats-box:latest \
  sleep infinity

docker ps | grep pix2pi_nats_cli || true

echo "OK ✅ nats cli container hazir"
