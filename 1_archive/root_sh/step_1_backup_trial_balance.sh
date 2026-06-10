#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/operations/reporting/service/erp_trial_balance_service.go \
  backups/app/manual/erp_trial_balance_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.trial_balance.bak 2>/dev/null || true

echo "OK ✅ trial balance backup step finished"
