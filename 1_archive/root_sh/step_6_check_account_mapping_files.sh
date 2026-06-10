#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/finance/service/erp_account_mapping_service.go
ls -lah internal/erp/core/finance/service/erp_account_mapping_apply_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ account mapping files exist"
