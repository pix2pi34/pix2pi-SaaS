#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/finance/service/erp_commission_service.go \
backups/app/manual/erp_commission_service.go.bak 2>/dev/null || true

cp -f internal/erp/core/finance/domain/erp_commission_result.go \
backups/app/manual/erp_commission_result.go.bak 2>/dev/null || true

echo "OK ✅ commission engine backup finished"
