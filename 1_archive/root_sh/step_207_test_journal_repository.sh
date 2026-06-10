#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

PIX2PI_DB_TEST=1 go test ./internal/platform/journal -v

echo "OK ✅ journal repository test bitti"
