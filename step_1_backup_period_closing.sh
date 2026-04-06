#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/closing/service/erp_period_closing_service.go \
  backups/app/manual/erp_period_closing_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.period_closing.bak 2>/dev/null || true

echo "OK ✅ period closing backup step finished"
