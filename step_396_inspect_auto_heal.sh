#!/bin/bash
set -euo pipefail

echo "=== STEP 396 / INSPECT AUTO HEAL ==="
echo

echo "1. script yolu..."
SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"
echo "$SCRIPT"
echo

echo "2. stopped / severity geçen satırlar..."
grep -nE 'STOPPED|stopped|severity|status.json|jq|stopped_names|degraded_names' "$SCRIPT" || true
echo

echo "3. ilk 260 satır..."
nl -ba "$SCRIPT" | sed -n '1,260p'
echo

echo "OK ✅ inspect tamam"
