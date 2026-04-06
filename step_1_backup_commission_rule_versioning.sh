#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/finance/domain/erp_commission_rule.go \
  backups/app/manual/erp_commission_rule.go.bak 2>/dev/null || true

cp -f internal/erp/core/finance/service/erp_commission_rule_service.go \
  backups/app/manual/erp_commission_rule_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.commission_rule_versioning.bak 2>/dev/null || true

echo "OK ✅ commission rule versioning backup finished"
