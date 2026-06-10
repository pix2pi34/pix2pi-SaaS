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
DB_USER="${DB_USER:-pix2pi_admin}"
DB_NAME="${DB_NAME:-pix2pi_saas}"

psql "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER}"
