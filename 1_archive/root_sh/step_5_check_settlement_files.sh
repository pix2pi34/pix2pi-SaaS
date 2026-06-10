#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/payments/domain/erp_settlement_batch.go
ls -lah internal/erp/core/payments/service/erp_settlement_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ settlement files exist"
