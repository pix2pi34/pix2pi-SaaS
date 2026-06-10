#!/bin/bash
set -e

echo "===== STREAM LIST ====="
docker exec -it pix2pi_nats_cli nats stream ls || true

echo
echo "===== CONSUMER LIST (tum olasi streamler icin) ====="
for s in $(docker exec -it pix2pi_nats_cli nats stream ls 2>/dev/null | awk 'NR>1 {print $1}'); do
  echo
  echo "--- STREAM: $s ---"
  docker exec -it pix2pi_nats_cli nats stream info "$s" || true
done

echo
echo "OK ✅ JetStream stream kontrolu bitti"
