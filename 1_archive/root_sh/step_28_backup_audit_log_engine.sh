#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.audit_log_engine.bak 2>/dev/null || true

echo "OK ✅ audit log engine yedegi alindi"
