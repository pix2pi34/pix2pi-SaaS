#!/bin/bash

echo "=== STEP 410 / FIX GO MODULE ==="

cd ~/pix2pi/pix2pi-SaaS

echo "1. go.mod kontrol..."

if [ ! -f go.mod ]; then
  echo "go.mod yok, oluşturuluyor..."
  go mod init pix2pi
else
  echo "go.mod var"
fi

echo "2. tidy..."
go mod tidy

echo "3. verify..."
cat go.mod

echo "OK ✅ module hazır"

echo "=== STEP 410 TAMAM ==="
