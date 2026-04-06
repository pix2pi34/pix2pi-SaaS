#!/bin/bash
set -e

docker exec pix2pi_nats_cli sh -lc '
nats --server nats://127.0.0.1:4222 stream info PIX2PI_EVENTS
'

echo "OK ✅ jetstream stream kontrol bitti"
