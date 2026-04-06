#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/tahsilat/service/erp_tahsilat_service.go \
  backups/app/manual/erp_tahsilat_service.go.v2.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.tahsilat_odeme_v2.bak 2>/dev/null || true

echo "OK ✅ tahsilat odeme v2 yedegi alindi"
