#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/rules/domain/erp_accounting_rule.go \
  backups/app/manual/erp_accounting_rule.go.bak 2>/dev/null || true

cp -f internal/erp/core/rules/service/erp_accounting_rule_service.go \
  backups/app/manual/erp_accounting_rule_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.auto_rules.bak 2>/dev/null || true

echo "OK ✅ auto rules backup step finished"
