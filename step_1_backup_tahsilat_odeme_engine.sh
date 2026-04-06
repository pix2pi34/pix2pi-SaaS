#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/tahsilat/domain/* \
backups/app/manual/ 2>/dev/null || true

cp -f internal/erp/core/tahsilat/service/* \
backups/app/manual/ 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.tahsilat_odeme.bak 2>/dev/null || true

echo "OK ✅ tahsilat/odeme yedegi alindi"
