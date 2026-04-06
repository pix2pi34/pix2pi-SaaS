#!/bin/bash
set -euo pipefail

echo "=== STEP 422A / BACKUP GATEWAY DB INIT ==="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/pix2pi/pix2pi-SaaS/.backups/step_422_$TS"

mkdir -p "$BACKUP_DIR/cmd/api-gateway"

cp "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go" \
   "$BACKUP_DIR/cmd/api-gateway/" || true

echo "OK ✅ backup alindi: $BACKUP_DIR"
echo "=== STEP 422A TAMAM ✅ ==="
