#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/kernel/ufk/domain/erp_account.go \
  backups/app/manual/erp_account.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.accounts.bak 2>/dev/null || true

cp -f internal/erp/core/finance/service/erp_chart_of_accounts_service.go \
  backups/app/manual/erp_chart_of_accounts_service.go.bak 2>/dev/null || true

echo "OK ✅ accounts seed backup step finished"
