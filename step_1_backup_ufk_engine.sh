#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/kernel/ufk/engine/erp_accounting_engine.go \
  backups/app/manual/erp_accounting_engine.go.bak 2>/dev/null || true

echo "OK ✅ backup step finished"
