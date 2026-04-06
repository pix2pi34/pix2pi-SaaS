#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.event_retry.bak 2>/dev/null || true

cp -f internal/platform/eventbus/domain/event_message.go \
  backups/app/manual/event_message.go.event_retry.bak 2>/dev/null || true

cp -f internal/platform/eventbus/service/event_bus_service.go \
  backups/app/manual/event_bus_service.go.event_retry.bak 2>/dev/null || true

echo "OK ✅ event retry yedegi alindi"
