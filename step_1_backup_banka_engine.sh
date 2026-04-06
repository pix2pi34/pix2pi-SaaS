#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/banka/domain/erp_banka_hesap.go \
  backups/app/manual/erp_banka_hesap.go.bak 2>/dev/null || true

cp -f internal/erp/core/banka/domain/erp_banka_hareket.go \
  backups/app/manual/erp_banka_hareket.go.bak 2>/dev/null || true

cp -f internal/erp/core/banka/service/erp_banka_service.go \
  backups/app/manual/erp_banka_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.banka_engine.bak 2>/dev/null || true

echo "OK ✅ banka engine yedegi alindi"
