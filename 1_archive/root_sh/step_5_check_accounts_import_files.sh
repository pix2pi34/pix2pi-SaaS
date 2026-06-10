#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/finance/service/erp_chart_of_accounts_import_service.go
ls -lah sample_accounts_import.csv
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ accounts import files exist"
