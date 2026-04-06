#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/cari/service/erp_cari_hesap_service.go \
  backups/app/manual/erp_cari_hesap_service.go.getir_fix.bak 2>/dev/null || true

echo "OK ✅ cari service yedegi alindi"
