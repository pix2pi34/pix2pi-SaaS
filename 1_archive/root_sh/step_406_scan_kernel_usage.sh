#!/bin/bash
set -euo pipefail

echo "=== STEP 406 / SCAN KERNEL USAGE ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/internal/platform/kernel/kernel.go"

echo
echo "1. masterDB / InitDB / gorm.Open satirlari..."
grep -nE 'masterDB|InitDB|gorm\.Open|GetWriteDB|GetReadDB|DBManager|DB\.' "$FILE" || true

echo
echo "2. ilk 260 satir..."
nl -ba "$FILE" | sed -n '1,260p'

echo
echo "OK ✅ scan tamam"
