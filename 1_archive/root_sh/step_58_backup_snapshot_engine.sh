#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.snapshot_engine.bak 2>/dev/null || true

cp -f internal/ufk/domain/ledger_account.go \
  backups/app/manual/ledger_account.go.snapshot_engine.bak 2>/dev/null || true

cp -f internal/ufk/service/ledger_posting_service.go \
  backups/app/manual/ledger_posting_service.go.snapshot_engine.bak 2>/dev/null || true

echo "OK ✅ snapshot engine yedegi alindi"
