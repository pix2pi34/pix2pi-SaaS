#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/rapor/domain/erp_gelir_tablosu.go \
  backups/app/manual/erp_gelir_tablosu.go.bak 2>/dev/null || true

cp -f internal/erp/core/rapor/service/erp_gelir_tablosu_service.go \
  backups/app/manual/erp_gelir_tablosu_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.gelir_tablosu.bak 2>/dev/null || true

echo "OK ✅ gelir tablosu engine yedegi alindi"
