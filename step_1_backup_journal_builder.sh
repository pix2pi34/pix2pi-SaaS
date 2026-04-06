#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f internal/erp/core/journal/domain/erp_journal_entry.go \
backups/app/manual/erp_journal_entry.go.bak 2>/dev/null || true

cp -f internal/erp/core/journal/service/erp_journal_builder_service.go \
backups/app/manual/erp_journal_builder_service.go.bak 2>/dev/null || true

cp -f cmd/erp/core/ufk/erp_ufk_main.go \
backups/app/manual/erp_ufk_main.go.journal_builder.bak 2>/dev/null || true

echo "OK ✅ journal builder backup finished"
