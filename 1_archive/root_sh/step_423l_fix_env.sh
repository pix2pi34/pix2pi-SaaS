#!/bin/bash
set -euo pipefail

ENV_FILE="/opt/pix2pi/orchestrator/env/common.env"
BACKUP="$ENV_FILE.bak.$(date +%F_%H%M%S)"

echo "=== STEP 423L / ENV TEMIZLE ==="

echo
echo "1. backup..."
cp "$ENV_FILE" "$BACKUP"
echo "OK ✅ backup alindi -> $BACKUP"

echo
echo "2. temiz env yaziliyor..."

cat <<'EOT' > "$ENV_FILE"
# Pix2pi DB Config (CLEAN)

export DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"
export DB_READ_DSN="host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"

export PIX2PI_ROOT="/root/pix2pi/pix2pi-SaaS"
export GO_BIN="/usr/local/go/bin/go"
EOT

echo "OK ✅ env temizlendi"

echo
echo "3. kontrol..."
cat "$ENV_FILE" | sed -E 's/password=[^ ]+/password=***/g'

echo
echo "4. systemd restart..."
systemctl daemon-reload
systemctl restart pix2pi-api-gateway.service
sleep 3

echo
echo "5. health test..."
curl -fsS http://127.0.0.1:9010/health

echo
echo "OK ✅ STEP 423L tamam"
