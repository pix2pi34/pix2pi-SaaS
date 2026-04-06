#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go test ./internal/platform/audit -v

echo "OK ✅ audit test bitti"
