#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_sales_stock_decrement.sh"
PY_SCRIPT="scripts/phase4b_sales_stock_decrement.py"
REPORT="docs/phase4/18_3_sales_stock_decrement_report.md"
INVENTORY="docs/phase4/18_3_sales_stock_decrement_inventory.tsv"
MATRIX="docs/phase4/18_3_sales_stock_decrement_matrix.tsv"
UP_FILE="db/migrations/20260428_183001_inventory_sales_stock_decrement.up.sql"
DOWN_FILE="db/migrations/20260428_183001_inventory_sales_stock_decrement.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ sales stock decrement wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ sales stock decrement python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_3_sales_stock_decrement.log 2>&1 || {
  echo "TEST_FAIL ❌ sales stock decrement script hata verdi"
  cat /tmp/pix2pi_18_3_sales_stock_decrement.log || true
  sed -n '1,1200p' "$REPORT" || true
  exit 1
}

for required in \
  "SALES_STOCK_DECREMENT=PASS" \
  "FAZ4B_18_3_FINAL_STATUS=PASS" \
  "PREVIOUS_18_2_FINAL_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_MIGRATION_PAIR=PASS" \
  "SALES_STOCK_DECREMENT_SCHEMA_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_TABLE_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_TENANT_SAFETY_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_SALES_SOURCE_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_MOVEMENT_LINK_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_QUANTITY_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_NEGATIVE_POLICY_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_IDEMPOTENCY_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_INDEX_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_DOWN_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_RISK_STATUS=PASS" \
  "SALES_STOCK_DECREMENT_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "SALES_STOCK_DECREMENT_EXECUTED=NO" \
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
  sales_stock_decrement_batches \
  sales_stock_decrement_lines \
  sales_stock_decrement_allocations \
  sales_stock_decrement_movement_links \
  sales_stock_decrement_validation_errors \
  sales_stock_decrement_posting_runs
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

grep -q "movement_direction text NOT NULL DEFAULT 'OUT'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ OUT movement direction yok"
  exit 1
}

grep -q "negative_stock_allowed boolean NOT NULL DEFAULT false" "$UP_FILE" || {
  echo "TEST_FAIL ❌ negative_stock_allowed alanı yok"
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

echo "PHASE4B_SALES_STOCK_DECREMENT_TEST=PASS ✅"
echo "PHASE4B_SALES_STOCK_DECREMENT_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_SALES_STOCK_DECREMENT_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_SALES_STOCK_DECREMENT_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_SALES_STOCK_DECREMENT_SECRET_TEST=PASS ✅"
