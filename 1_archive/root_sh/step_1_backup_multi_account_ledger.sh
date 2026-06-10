#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/ledger/domain/erp_multi_ledger_account.go \
backups/app/manual/erp_multi_ledger_account.go.bak 2>/dev/null || true

cp -f internal/erp/core/ledger/service/erp_multi_ledger_service.go \
backups/app/manual/erp_multi_ledger_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.multi_ledger.bak 2>/dev/null || true

echo "OK ✅ multi account ledger backup finished"
