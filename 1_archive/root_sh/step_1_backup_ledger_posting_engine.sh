#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/ledger/domain/erp_ledger_posting.go \
backups/app/manual/erp_ledger_posting.go.bak 2>/dev/null || true

cp -f internal/erp/core/ledger/service/erp_ledger_posting_service.go \
backups/app/manual/erp_ledger_posting_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.ledger_posting.bak 2>/dev/null || true

echo "OK ✅ ledger posting backup finished"
