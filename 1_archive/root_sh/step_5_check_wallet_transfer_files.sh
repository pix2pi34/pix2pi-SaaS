#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/ledger/domain/erp_wallet_transfer.go
ls -lah internal/erp/core/ledger/service/erp_wallet_transfer_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ wallet transfer files exist"
