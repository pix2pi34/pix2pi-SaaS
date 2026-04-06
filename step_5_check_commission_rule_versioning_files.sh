#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/finance/domain/erp_commission_rule.go
ls -lah internal/erp/core/finance/service/erp_commission_rule_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ commission rule versioning files exist"
