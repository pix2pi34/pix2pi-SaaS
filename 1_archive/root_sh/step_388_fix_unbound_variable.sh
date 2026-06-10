#!/bin/bash
set -euo pipefail

echo "=== STEP 388 / FIX UNBOUND VARIABLE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo
echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅"

echo
echo "2. global init ekleniyor..."

# en üste ekle (ilk satırlardan sonra)
sed -i '1a STOPPED_NAMES=""\nSEVERITY="unknown"' "$SCRIPT"

echo "OK ✅ init eklendi"

echo
echo "3. test..."
/opt/pix2pi/bin/pix2pi_early_warning.sh
echo "OK ✅ test"

echo
echo "=== STEP 388 TAMAM ✅ ==="
