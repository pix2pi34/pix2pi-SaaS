#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/current/domain/erp_current_account.go \
  backups/app/manual/erp_current_account.go.bak 2>/dev/null || true

cp -f internal/erp/core/current/domain/erp_current_account_entry.go \
  backups/app/manual/erp_current_account_entry.go.bak 2>/dev/null || true

cp -f internal/erp/core/current/service/erp_current_account_service.go \
  backups/app/manual/erp_current_account_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.current_account.bak 2>/dev/null || true

echo "OK ✅ current account backup finished"
