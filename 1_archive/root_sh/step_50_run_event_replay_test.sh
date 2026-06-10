#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go run cmd/playground/playground_main.go

echo "OK ✅ event replay test calistirma bitti"
