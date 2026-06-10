#!/bin/bash
set -e

docker exec pix2pi_nats_cli sh -lc '
nats --server nats://127.0.0.1:4222 consumer rm PIX2PI_EVENTS SALE_PROCESSOR -f >/dev/null 2>&1 || true

nats --server nats://127.0.0.1:4222 consumer add PIX2PI_EVENTS SALE_PROCESSOR \
  --pull \
  --filter "pix2pi.sale.created" \
  --ack explicit \
  --deliver all \
  --replay instant \
  --max-deliver 5 \
  --wait 5s \
  --max-pending 1000 \
  --defaults
'

echo "OK ✅ sale durable consumer olusturuldu"
