#!/bin/bash
set -euo pipefail

echo "=== STEP 423B / GERCEK HATA YAKALAMA ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

echo
echo "1. common.env dosyasi kontrol ediliyor..."
if [ ! -f /opt/pix2pi/orchestrator/env/common.env ]; then
  echo "HATA ❌ /opt/pix2pi/orchestrator/env/common.env bulunamadi"
  exit 1
fi
echo "OK ✅ common.env bulundu"

echo
echo "2. env yukleniyor..."
set -a
source /opt/pix2pi/orchestrator/env/common.env
set +a
echo "OK ✅ env yüklendi"

echo
echo "3. env kontrol..."
echo "DB_WRITE_DSN=${DB_WRITE_DSN:-BOS}"
echo "DB_READ_DSN=${DB_READ_DSN:-BOS}"
echo "PIX2PI_ROOT=${PIX2PI_ROOT:-BOS}"
echo "GO_BIN=${GO_BIN:-BOS}"
echo "OK ✅ env kontrol bitti"

echo
echo "4. go ortami kontrol..."
go version
echo "OK ✅ go version alindi"

echo
echo "5. go run basliyor..."
echo "BURADAN SONRA CIKAN GERCEK HATAYI TAM HALIYLE KOPYALAYIP BANA GONDER"
echo "------------------------------------------------------------"

go run ./cmd/api-gateway
