#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/operations/reporting/service/erp_balance_sheet_service.go \
  backups/app/manual/erp_balance_sheet_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.balance_sheet.bak 2>/dev/null || true

echo "OK ✅ balance sheet backup step finished"
