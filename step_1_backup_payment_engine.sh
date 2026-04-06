#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS
mkdir -p backups/app/manual

cp -f internal/erp/core/payments/service/erp_payment_engine.go \
  backups/app/manual/erp_payment_engine.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.payment.bak 2>/dev/null || true

echo "OK ✅ payment engine backup step finished"
