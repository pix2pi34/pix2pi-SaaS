#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/events/domain/erp_financial_event_record.go \
  backups/app/manual/erp_financial_event_record.go.bak 2>/dev/null || true

cp -f internal/erp/core/events/service/erp_financial_event_service.go \
  backups/app/manual/erp_financial_event_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.financial_event.bak 2>/dev/null || true

echo "OK ✅ financial event backup step finished"
