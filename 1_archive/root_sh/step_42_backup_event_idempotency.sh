#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/platform/eventbus/service/event_bus_service.go \
backups/app/manual/event_bus_service.go.idempotency.bak

echo "OK ✅ event idempotency yedegi alindi"
