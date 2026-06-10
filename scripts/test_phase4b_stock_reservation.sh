#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_stock_reservation.sh"
PY_SCRIPT="scripts/phase4b_stock_reservation.py"
REPORT="docs/phase4/18_5_stock_reservation_report.md"
INVENTORY="docs/phase4/18_5_stock_reservation_inventory.tsv"
MATRIX="docs/phase4/18_5_stock_reservation_matrix.tsv"
UP_FILE="db/migrations/20260428_185001_inventory_stock_reservation.up.sql"
DOWN_FILE="db/migrations/20260428_185001_inventory_stock_reservation.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock reservation wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock reservation python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_18_5_stock_reservation.log 2>&1 || {
  echo "TEST_FAIL ❌ stock reservation script hata verdi"
  cat /tmp/pix2pi_18_5_stock_reservation.log || true
  sed -n '1,1400p' "$REPORT" || true
  exit 1
}

for required in \
  "STOCK_RESERVATION=PASS" \
  "FAZ4B_18_5_FINAL_STATUS=PASS" \
  "PREVIOUS_18_4_FINAL_STATUS=PASS" \
  "STOCK_RESERVATION_MIGRATION_PAIR=PASS" \
  "STOCK_RESERVATION_SCHEMA_STATUS=PASS" \
  "STOCK_RESERVATION_TABLE_STATUS=PASS" \
  "STOCK_RESERVATION_TENANT_SAFETY_STATUS=PASS" \
  "STOCK_RESERVATION_REFERENCE_STATUS=PASS" \
  "STOCK_RESERVATION_QUANTITY_STATUS=PASS" \
  "STOCK_RESERVATION_DELTA_STATUS=PASS" \
  "STOCK_RESERVATION_EXPIRY_STATUS=PASS" \
  "STOCK_RESERVATION_IDEMPOTENCY_STATUS=PASS" \
  "STOCK_RESERVATION_LIFECYCLE_STATUS=PASS" \
  "STOCK_RESERVATION_INDEX_STATUS=PASS" \
  "STOCK_RESERVATION_DOWN_STATUS=PASS" \
  "STOCK_RESERVATION_RISK_STATUS=PASS" \
  "STOCK_RESERVATION_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "STOCK_RESERVATION_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1400p' "$REPORT" || true
    exit 1
  }
done

for f in "$INVENTORY" "$MATRIX" "$UP_FILE" "$DOWN_FILE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for table in \
  stock_reservation_batches \
  stock_reservations \
  stock_reservation_lines \
  stock_reservation_allocations \
  stock_reservation_releases \
  stock_reservation_validation_errors \
  stock_reservation_expiry_runs
do
  grep -q "$table" "$UP_FILE" || {
    echo "TEST_FAIL ❌ up migration table eksik: $table"
    exit 1
  }

  grep -q "$table" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory table eksik: $table"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "tenant_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ tenant_id not null yok"
  exit 1
}

grep -q "reserved_quantity numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ reserved_quantity yok"
  exit 1
}

grep -q "available_quantity numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ available_quantity yok"
  exit 1
}

grep -q "expires_at timestamptz" "$UP_FILE" || {
  echo "TEST_FAIL ❌ expires_at yok"
  exit 1
}

grep -q "idempotency_key text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ idempotency_key not null yok"
  exit 1
}

if grep -Ei "ALTER SYSTEM|docker|systemctl|psql " "$UP_FILE"; then
  echo "TEST_FAIL ❌ up migration icinde sistem tokeni var"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_STOCK_RESERVATION_TEST=PASS ✅"
echo "PHASE4B_STOCK_RESERVATION_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_STOCK_RESERVATION_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_STOCK_RESERVATION_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_STOCK_RESERVATION_SECRET_TEST=PASS ✅"
