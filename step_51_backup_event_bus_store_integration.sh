#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/platform/eventbus/service/event_bus_service.go \
  backups/app/manual/event_bus_service.go.integration.bak 2>/dev/null || true

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.integration.bak 2>/dev/null || true

echo "OK ✅ event bus store entegrasyon yedegi alindi"
