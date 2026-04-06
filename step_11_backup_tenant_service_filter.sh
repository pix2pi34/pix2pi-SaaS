#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/cari/domain/erp_cari_hesap.go \
  backups/app/manual/erp_cari_hesap.go.tenant_filter.bak 2>/dev/null || true

cp -f internal/erp/core/cari/service/erp_cari_hesap_service.go \
  backups/app/manual/erp_cari_hesap_service.go.tenant_filter.bak 2>/dev/null || true

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.tenant_filter.bak 2>/dev/null || true

echo "OK ✅ tenant service filter yedegi alindi"
