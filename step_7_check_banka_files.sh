#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/banka/domain/erp_banka_hesap.go
ls -lah internal/erp/core/banka/domain/erp_banka_hareket.go
ls -lah internal/erp/core/banka/service/erp_banka_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ banka dosyalari var"
