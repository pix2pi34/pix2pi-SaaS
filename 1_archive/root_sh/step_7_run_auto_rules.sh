#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

go run cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ auto rules run step finished"
