#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.export_isolation.bak 2>/dev/null || true

echo "OK ✅ export isolation yedegi alindi"
