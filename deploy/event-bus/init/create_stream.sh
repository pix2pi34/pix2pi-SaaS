#!/bin/bash

echo "Pix2pi Event Stream oluşturuluyor..."

docker exec -it event-bus-nats-1 nats stream add PIX2PI_EVENTS \
--subjects "pix2pi.>" \
--storage file \
--retention limits \
--max-msgs=-1 \
--max-bytes=-1 \
--max-age=168h \
--dupe-window=2m \
--replicas=1 \
--discard old

echo "OK ✅ stream oluşturuldu"
