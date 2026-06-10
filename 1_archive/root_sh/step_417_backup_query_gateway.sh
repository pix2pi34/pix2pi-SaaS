#!/bin/bash
set -euo pipefail

echo "=== STEP 417A / BACKUP QUERY GATEWAY ==="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/pix2pi/pix2pi-SaaS/.backups/step_417_$TS"

mkdir -p "$BACKUP_DIR/cmd/api-gateway"
mkdir -p "$BACKUP_DIR/internal/services/query_read_model"

cp "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go" \
   "$BACKUP_DIR/cmd/api-gateway/" || true

cp "$HOME/pix2pi/pix2pi-SaaS/internal/services/query_read_model/service.go" \
   "$BACKUP_DIR/internal/services/query_read_model/" || true

cp "$HOME/pix2pi/pix2pi-SaaS/internal/services/query_read_model/routes.go" \
   "$BACKUP_DIR/internal/services/query_read_model/" || true

echo "OK ✅ backup alindi: $BACKUP_DIR"
echo "=== STEP 417A TAMAM ✅ ==="
