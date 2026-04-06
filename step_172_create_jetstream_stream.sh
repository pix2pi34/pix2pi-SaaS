#!/bin/bash
set -e

docker exec pix2pi_nats_cli sh -lc '
nats --server nats://127.0.0.1:4222 stream add PIX2PI_EVENTS \
  --subjects "pix2pi.>" \
  --storage file \
  --retention limits \
  --discard old \
  --max-msgs=-1 \
  --max-bytes=-1 \
  --max-age=168h \
  --dupe-window=2m \
  --defaults
'

echo "OK ✅ jetstream stream olusturuldu"
