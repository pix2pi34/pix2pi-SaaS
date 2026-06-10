#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go test ./internal/platform -v

echo "OK ✅ retry test bitti"
