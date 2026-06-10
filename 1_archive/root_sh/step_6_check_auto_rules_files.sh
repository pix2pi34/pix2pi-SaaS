#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/rules/domain/erp_accounting_rule.go
ls -lah internal/erp/core/rules/service/erp_accounting_rule_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ auto rules files exist"
