#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

nohup go run cmd/replay-service/replay_service_main.go > /tmp/pix2pi_replay_service.log 2>&1 &

sleep 2

cat /tmp/pix2pi_replay_service.log || true

echo "OK replay service basladi"
