#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/kasa/service/erp_kasa_service.go \
  backups/app/manual/erp_kasa_service.go.ekstre.bak 2>/dev/null || true

cp -f internal/erp/core/kasa/domain/erp_kasa_ekstre.go \
  backups/app/manual/erp_kasa_ekstre.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.kasa_ekstre.bak 2>/dev/null || true

echo "OK ✅ kasa ekstre yedegi alindi"
