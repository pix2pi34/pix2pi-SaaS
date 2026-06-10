#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/ledger/domain/erp_ledger_posting.go
ls -lah internal/erp/core/ledger/service/erp_ledger_posting_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ ledger posting files exist"
