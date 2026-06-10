#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/finance/service/erp_financial_consistency_service.go \
  backups/app/manual/erp_financial_consistency_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.financial_consistency.bak 2>/dev/null || true

echo "OK ✅ financial consistency backup step finished"
