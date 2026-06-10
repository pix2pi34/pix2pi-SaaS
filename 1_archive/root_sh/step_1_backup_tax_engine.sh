#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/tax/service/erp_tax_recognition_service.go \
  backups/app/manual/erp_tax_recognition_service.go.bak 2>/dev/null || true

cp -f internal/erp/core/tax/service/erp_tax_apply_service.go \
  backups/app/manual/erp_tax_apply_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.tax.bak 2>/dev/null || true

echo "OK ✅ tax engine backup step finished"
