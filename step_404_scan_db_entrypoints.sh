#!/bin/bash
set -euo pipefail

echo "=== STEP 404 / SCAN DB ENTRYPOINTS ==="

BASE="$HOME/pix2pi/pix2pi-SaaS"

echo
echo "1. postgres/sqlx/gorm/pgx arama..."
grep -RniE 'sql\.Open|pgx|gorm|postgres|postgresql|database/sql|sqlx|Connect\(' \
  "$BASE/cmd" "$BASE/internal" "$BASE/pkg" 2>/dev/null | head -n 300 || true

echo
echo "2. repository/store/db package arama..."
find "$BASE" -type f | grep -E '/(db|database|repo|repository|store)/|db_.*\.go|.*repository.*\.go|.*store.*\.go' || true

echo
echo "3. env/config içinde db arama..."
grep -RniE 'DB_|DATABASE_URL|POSTGRES|PGHOST|PGPORT|PGUSER|PGDATABASE' \
  "$BASE" 2>/dev/null | head -n 200 || true

echo
echo "OK ✅ scan tamam"
