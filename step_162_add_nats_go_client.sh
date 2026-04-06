#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go get github.com/nats-io/nats.go@v1.37.0

echo "OK ✅ Go NATS client eklendi"
