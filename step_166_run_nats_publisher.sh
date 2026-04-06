#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go run cmd/nats-publisher/nats_publisher_main.go

echo "OK ✅ nats publisher calisti"
