#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/ledger/service/erp_ledger_balance_service.go \
backups/app/manual/erp_ledger_balance_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.ledger_balance.bak 2>/dev/null || true

echo "OK ✅ ledger balance backup finished"
