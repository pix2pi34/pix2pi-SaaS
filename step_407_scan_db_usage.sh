#!/bin/bash
set -euo pipefail

echo "=== STEP 407 / SCAN DB USAGE ==="

cd ~/pix2pi/pix2pi-SaaS

grep -rn "gorm.DB" internal | grep -v vendor | head -50

echo
echo "---- query read model ----"
grep -rn "query_read_model" internal || true

echo
echo "OK ✅ scan tamam"
