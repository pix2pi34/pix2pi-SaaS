#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/vergi/domain/erp_vergi_kural.go \
  backups/app/manual/erp_vergi_kural.go.ufk_event.bak 2>/dev/null || true

cp -f internal/erp/core/vergi/service/erp_vergi_motoru_service.go \
  backups/app/manual/erp_vergi_motoru_service.go.ufk_event.bak 2>/dev/null || true

cp -f internal/erp/core/vergi/engine/erp_vergi_tani_engine.go \
  backups/app/manual/erp_vergi_tani_engine.go.ufk_event.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
  backups/app/manual/erp_ufk_main.go.ufk_event.bak 2>/dev/null || true

echo "OK ✅ ufk event engine yedegi alindi"
