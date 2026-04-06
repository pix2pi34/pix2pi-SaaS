#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/ledger/domain/erp_multi_ledger_account.go
ls -lah internal/erp/core/ledger/service/erp_multi_ledger_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ multi account ledger files exist"
