#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/tax/service/erp_tax_recognition_service.go
ls -lah internal/erp/core/tax/service/erp_tax_apply_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ tax engine files exist"
