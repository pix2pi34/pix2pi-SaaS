#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

STARTED=0

echo "=== 1 DOCKER COMPOSE ILE DENE ==="
COMPOSE_FILE="$(find . -maxdepth 3 \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'docker-compose.yaml' \) | head -n 1 || true)"

if [ -n "$COMPOSE_FILE" ]; then
  echo "Bulunan compose: $COMPOSE_FILE"
  COMPOSE_DIR="$(dirname "$COMPOSE_FILE")"

  if command -v docker >/dev/null 2>&1; then
    if docker compose version >/dev/null 2>&1; then
      (
        cd "$COMPOSE_DIR"
        docker compose up -d postgres db database 2>/dev/null || true
      )
      STARTED=1
    fi
  fi
else
  echo "Compose dosyasi bulunamadi"
fi

echo
echo "=== 2 SYSTEM POSTGRES ILE DENE ==="
if systemctl list-unit-files | grep -q '^postgresql'; then
  systemctl start postgresql || true
  STARTED=1
else
  echo "System postgres servisi bulunamadi"
fi

echo
echo "=== 3 PORT KONTROL ==="
ss -ltnp | grep 5432 || true

echo
echo "=== 4 PG_ISREADY ==="
if command -v pg_isready >/dev/null 2>&1; then
  DB_HOST_VAL="$(grep -E '^DB_HOST=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
  DB_PORT_VAL="$(grep -E '^DB_PORT=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
  DB_HOST_VAL="${DB_HOST_VAL:-localhost}"
  DB_PORT_VAL="${DB_PORT_VAL:-5432}"
  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
else
  echo "pg_isready yok"
fi

echo
if [ "$STARTED" -eq 1 ]; then
  echo "OK ✅ postgres baslatma denemesi bitti"
else
  echo "HATA ❌ postgres icin baslatilacak kaynak bulunamadi"
fi
