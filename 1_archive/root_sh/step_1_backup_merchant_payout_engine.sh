#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/payments/domain/erp_merchant_payout.go \
  backups/app/manual/erp_merchant_payout.go.bak 2>/dev/null || true

cp -f internal/erp/core/payments/service/erp_merchant_payout_service.go \
  backups/app/manual/erp_merchant_payout_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.merchant_payout.bak 2>/dev/null || true

echo "OK ✅ merchant payout backup finished"
