#!/bin/bash
set -euo pipefail

echo "=== STEP 421A / BACKUP KERNEL SAFE ==="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/pix2pi/pix2pi-SaaS/.backups/step_421_$TS"

mkdir -p "$BACKUP_DIR/internal/platform/kernel"

cp "$HOME/pix2pi/pix2pi-SaaS/internal/platform/kernel/kernel.go" \
   "$BACKUP_DIR/internal/platform/kernel/" || true

echo "OK ✅ backup alindi: $BACKUP_DIR"
echo "=== STEP 421A TAMAM ✅ ==="
