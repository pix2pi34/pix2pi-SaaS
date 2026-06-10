#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/finance/service/erp_chart_of_accounts_service.go
ls -lah internal/erp/core/kernel/ufk/domain/erp_account.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ accounts seed files exist"
