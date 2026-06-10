#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/cari/domain/erp_cari_hesap.go \
  backups/app/manual/erp_cari_hesap.go.v2.bak 2>/dev/null || true

cp -f internal/erp/core/cari/service/erp_cari_hesap_service.go \
  backups/app/manual/erp_cari_hesap_service.go.v2.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.cari_v2.bak 2>/dev/null || true

echo "OK ✅ cari v2 yedegi alindi"
