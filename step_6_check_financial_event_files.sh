#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

ls -lah internal/erp/core/events/domain/erp_financial_event_record.go
ls -lah internal/erp/core/events/service/erp_financial_event_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go

echo "OK ✅ financial event files exist"
