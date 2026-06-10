#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/operations/reporting/service/erp_income_statement_service.go \
  backups/app/manual/erp_income_statement_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.income_statement.bak 2>/dev/null || true

echo "OK ✅ income statement backup step finished"
