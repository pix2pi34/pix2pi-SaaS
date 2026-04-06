#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_USER="${DB_USER:-pix2pi}"
DB_PASSWORD="${DB_PASSWORD:-pix2pi}"
DB_NAME="${DB_NAME:-pix2pi}"

echo "=== RLS SQL APPLY ==="
PGPASSWORD="${DB_PASSWORD}" psql "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER}" \
  -f deploy/sql/rls_tenant_policy.sql

echo
echo "=== TENANT-001 SELECT ==="
PGPASSWORD='pix2pi_app_123' psql "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=pix2pi_app" <<'SQL'
SET app.tenant_id = 'tenant-001';
TABLE cari_hesaplar;
SQL

echo
echo "=== TENANT-002 SELECT ==="
PGPASSWORD='pix2pi_app_123' psql "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=pix2pi_app" <<'SQL'
SET app.tenant_id = 'tenant-002';
TABLE cari_hesaplar;
SQL

echo
echo "OK ✅ postgres rls test calistirma bitti"
