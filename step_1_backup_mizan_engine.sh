#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/rapor/domain/erp_mizan_satir.go \
  backups/app/manual/erp_mizan_satir.go.bak 2>/dev/null || true

cp -f internal/erp/core/rapor/service/erp_mizan_service.go \
  backups/app/manual/erp_mizan_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.mizan.bak 2>/dev/null || true

echo "OK ✅ mizan engine yedegi alindi"
