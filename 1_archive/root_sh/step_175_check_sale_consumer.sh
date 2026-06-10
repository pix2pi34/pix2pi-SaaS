#!/bin/bash
set -e

docker exec pix2pi_nats_cli sh -lc '
nats --server nats://127.0.0.1:4222 consumer info PIX2PI_EVENTS SALE_PROCESSOR
'

echo "OK ✅ sale consumer kontrol bitti"
