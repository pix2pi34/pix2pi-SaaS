#!/bin/bash
set -euo pipefail

echo "=== STEP 416 / INSPECT QUERY ROUTE ==="

echo
echo "1. query route dosyasi..."
sed -n '1,220p' ~/pix2pi/pix2pi-SaaS/internal/services/query_read_model/routes.go || true
echo
echo "OK ✅ route dosyasi gosterildi"

echo
echo "2. query service dosyasi..."
sed -n '1,260p' ~/pix2pi/pix2pi-SaaS/internal/services/query_read_model/service.go || true
echo
echo "OK ✅ service dosyasi gosterildi"

echo
echo "=== STEP 416 TAMAM ✅ ==="
