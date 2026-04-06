#!/bin/bash
set -euo pipefail

echo "=== STEP 400 / VERIFY STATUS JSON ==="

echo
echo "1. json oku..."
cat /opt/pix2pi/runtime/auto_heal/status.json | jq .

echo
echo "2. stopped_names..."
cat /opt/pix2pi/runtime/auto_heal/status.json | jq -r '.stopped_names'

echo
echo "3. running/stopped counts..."
cat /opt/pix2pi/runtime/auto_heal/status.json | jq '.counts'

echo
echo "=== STEP 400 TAMAM ✅ ==="
