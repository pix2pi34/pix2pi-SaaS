#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_stock_movement_engine.sh"
PY_SCRIPT="scripts/phase4b_stock_movement_engine.py"
REPORT="docs/phase4/18_2_stock_movement_engine_report.md"
INVENTORY="docs/phase4/18_2_stock_movement_engine_inventory.tsv"
MATRIX="docs/phase4/18_2_stock_movement_engine_matrix.tsv"
UP_FILE="db/migrations/20260428_182001_inventory_stock_movement_engine.up.sql"
DOWN_FILE="db/migrations/20260428_182001_inventory_stock_movement_engine.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock movement wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock movement python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_2_stock_movement_engine.log 2>&1 || {
  echo "TEST_FAIL ❌ stock movement engine script hata verdi"
  cat /tmp/pix2pi_18_2_stock_movement_engine.log || true
  sed -n '1,1200p' "$REPORT" || true
  exit 1
}

for required in \
  "STOCK_MOVEMENT_ENGINE=PASS" \
  "FAZ4B_18_2_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_FINAL_STATUS=PASS" \
  "PREVIOUS_18_1_FINAL_STATUS=PASS" \
  "STOCK_MOVEMENT_MIGRATION_PAIR=PASS" \
  "STOCK_MOVEMENT_SCHEMA_STATUS=PASS" \
  "STOCK_MOVEMENT_TABLE_STATUS=PASS" \
  "STOCK_MOVEMENT_TENANT_SAFETY_STATUS=PASS" \
  "STOCK_MOVEMENT_HEADER_STATUS=PASS" \
  "STOCK_MOVEMENT_LINE_STATUS=PASS" \
  "STOCK_MOVEMENT_LOCATION_STATUS=PASS" \
  "STOCK_MOVEMENT_QUANTITY_DELTA_STATUS=PASS" \
  "STOCK_MOVEMENT_IDEMPOTENCY_STATUS=PASS" \
  "STOCK_MOVEMENT_INDEX_STATUS=PASS" \
  "STOCK_MOVEMENT_DOWN_STATUS=PASS" \
  "STOCK_MOVEMENT_RISK_STATUS=PASS" \
  "STOCK_MOVEMENT_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "STOCK_MOVEMENT_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1200p' "$REPORT" || true
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
  stock_movement_batches \
  stock_movement_documents \
  stock_movements \
  stock_movement_lines \
  stock_movement_allocations \
  stock_movement_validation_errors \
  stock_movement_posting_runs
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

grep -q "movement_type text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ movement_type not null yok"
  exit 1
}

grep -q "movement_direction text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ movement_direction not null yok"
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

echo "PHASE4B_STOCK_MOVEMENT_ENGINE_TEST=PASS ✅"
echo "PHASE4B_STOCK_MOVEMENT_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_STOCK_MOVEMENT_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_STOCK_MOVEMENT_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_STOCK_MOVEMENT_SECRET_TEST=PASS ✅"
