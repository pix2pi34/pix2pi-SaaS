#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.rate_limit.bak 2>/dev/null || true

echo "OK ✅ rate limit yedegi alindi"
