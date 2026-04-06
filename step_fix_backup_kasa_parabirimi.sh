#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/kasa/domain/erp_kasa_hareket.go \
  backups/app/manual/erp_kasa_hareket.go.parabirimi.bak 2>/dev/null || true

cp -f internal/erp/core/kasa/service/erp_kasa_service.go \
  backups/app/manual/erp_kasa_service.go.parabirimi.bak 2>/dev/null || true

echo "OK ✅ kasa para birimi kontrol yedegi alindi"
