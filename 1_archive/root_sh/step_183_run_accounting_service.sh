#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

nohup go run cmd/accounting-service/accounting_service_main.go >/tmp/pix2pi_accounting_service.log 2>&1 &

sleep 2

cat /tmp/pix2pi_accounting_service.log || true

echo "OK ✅ accounting service baslatildi"
