#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go test ./internal/platform/journal -v

echo "OK ✅ journal builder test bitti"
