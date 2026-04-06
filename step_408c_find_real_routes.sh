#!/bin/bash
set -euo pipefail

echo "=== STEP 408C / FIND REAL ROUTES ==="

cd ~/pix2pi/pix2pi-SaaS

echo
echo "1. fiber.New geçen dosyalar..."
grep -Rni "fiber.New()" internal cmd || true

echo
echo "2. app.Get / app.Post / app.Group geçen dosyalar..."
grep -RniE 'app\.(Get|Post|Put|Delete)|app\.Group|router\.Group' internal cmd || true

echo
echo "3. unsupported API version metni..."
grep -Rni 'unsupported API version' . || true

echo
echo "4. api-gateway dosyalari..."
find internal cmd -type f | grep -Ei 'gateway|route|http|fiber' || true

echo
echo "OK ✅ scan tamam"
