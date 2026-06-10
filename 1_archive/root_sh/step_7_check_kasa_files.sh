#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/kasa/domain/erp_kasa_hesap.go
ls -lah internal/erp/core/kasa/domain/erp_kasa_hareket.go
ls -lah internal/erp/core/kasa/service/erp_kasa_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ kasa dosyalari var"
