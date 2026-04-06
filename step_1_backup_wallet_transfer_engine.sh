#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/ledger/domain/erp_wallet_transfer.go \
backups/app/manual/erp_wallet_transfer.go.bak 2>/dev/null || true

cp -f internal/erp/core/ledger/service/erp_wallet_transfer_service.go \
backups/app/manual/erp_wallet_transfer_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.wallet_transfer.bak 2>/dev/null || true

echo "OK ✅ wallet transfer backup finished"
