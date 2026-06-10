#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/operations/reporting/service/erp_cash_flow_service.go \
  backups/app/manual/erp_cash_flow_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.cash_flow.bak 2>/dev/null || true

echo "OK ✅ cash flow backup step finished"
