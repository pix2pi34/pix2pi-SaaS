#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

nohup go run cmd/nats-subscriber/nats_subscriber_main.go >/tmp/pix2pi_nats_subscriber.log 2>&1 &

sleep 2

cat /tmp/pix2pi_nats_subscriber.log || true

echo "OK ✅ nats subscriber baslatildi"
