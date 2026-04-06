#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS
go build -o bin/service-watchdog ./cmd/service-watchdog

echo "OK ✅ watchdog build tamam"
