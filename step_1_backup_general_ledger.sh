#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/operations/reporting/service/erp_general_ledger_service.go \
  backups/app/manual/erp_general_ledger_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.general_ledger.bak 2>/dev/null || true

echo "OK ✅ general ledger backup step finished"
