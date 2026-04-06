#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/vergi/engine/erp_vergi_tani_engine.go \
  backups/app/manual/erp_vergi_tani_engine.go.ufk_journal.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.ufk_journal.bak 2>/dev/null || true

echo "OK ✅ ufk event journal yedegi alindi"
