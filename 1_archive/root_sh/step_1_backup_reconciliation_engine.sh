#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/reconciliation/service/erp_reconciliation_service.go \
  backups/app/manual/erp_reconciliation_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.reconciliation.bak 2>/dev/null || true

echo "OK ✅ reconciliation backup step finished"
