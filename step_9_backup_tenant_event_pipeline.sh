#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.tenant_event_pipeline.bak 2>/dev/null || true

cp -f internal/erp/core/eventstore/domain/erp_accounting_event.go \
  backups/app/manual/erp_accounting_event.go.tenant_event_pipeline.bak 2>/dev/null || true

cp -f internal/erp/core/eventstore/service/erp_event_store_service.go \
  backups/app/manual/erp_event_store_service.go.tenant_event_pipeline.bak 2>/dev/null || true

echo "OK ✅ tenant event pipeline yedegi alindi"
