#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/satis/domain/erp_satis_fatura.go \
  backups/app/manual/erp_satis_fatura.go.bak 2>/dev/null || true

cp -f internal/erp/core/satis/domain/erp_satis_fatura_satir.go \
  backups/app/manual/erp_satis_fatura_satir.go.bak 2>/dev/null || true

cp -f internal/erp/core/satis/service/erp_satis_fatura_service.go \
  backups/app/manual/erp_satis_fatura_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.satis_fatura.bak 2>/dev/null || true

echo "OK ✅ satis fatura yedegi alindi"
