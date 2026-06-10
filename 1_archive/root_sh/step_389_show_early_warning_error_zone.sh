#!/bin/bash
set -euo pipefail

echo "=== STEP 389 / SHOW ERROR ZONE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo
echo "1. dosya var mi..."
ls -l "$SCRIPT"
echo "OK ✅ dosya bulundu"

echo
echo "2. syntax check..."
bash -n "$SCRIPT" || true

echo
echo "3. 80-130 arasi..."
nl -ba "$SCRIPT" | sed -n '80,130p'

echo
echo "=== STEP 389 TAMAM ✅ ==="
