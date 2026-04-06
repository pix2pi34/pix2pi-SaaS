#!/bin/bash
set -euo pipefail

echo "=== STEP 402 / FIX FUNCTION ORDER ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. main en sona aliniyor..."

# main çağrısını kaldır
sed -i '/^main "\$@"/d' "$SCRIPT"

# en sona ekle
echo "" >> "$SCRIPT"
echo "main \"\$@\"" >> "$SCRIPT"

echo "OK ✅ main sona alindi"

echo
echo "3. syntax test..."
bash -n "$SCRIPT"
echo "OK ✅ syntax"

echo
echo "=== STEP 402 TAMAM ✅ ==="
