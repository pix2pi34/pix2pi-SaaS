#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_opening_stock.sh"
PY_SCRIPT="scripts/phase4b_opening_stock.py"
REPORT="docs/phase4/18_1_opening_stock_report.md"
INVENTORY="docs/phase4/18_1_opening_stock_inventory.tsv"
MATRIX="docs/phase4/18_1_opening_stock_matrix.tsv"
UP_FILE="db/migrations/20260428_181001_inventory_opening_stock.up.sql"
DOWN_FILE="db/migrations/20260428_181001_inventory_opening_stock.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ opening stock wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ opening stock python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_1_opening_stock.log 2>&1 || {
  echo "TEST_FAIL ❌ opening stock script hata verdi"
  cat /tmp/pix2pi_18_1_opening_stock.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "OPENING_STOCK=PASS" \
  "FAZ4B_18_1_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_FINAL_STATUS=PASS" \
  "OPENING_STOCK_MIGRATION_PAIR=PASS" \
  "OPENING_STOCK_SCHEMA_STATUS=PASS" \
  "OPENING_STOCK_TABLE_STATUS=PASS" \
  "OPENING_STOCK_TENANT_SAFETY_STATUS=PASS" \
  "OPENING_STOCK_LINE_STATUS=PASS" \
  "OPENING_STOCK_IMPORT_ALIGNMENT_STATUS=PASS" \
  "OPENING_STOCK_IDEMPOTENCY_STATUS=PASS" \
  "OPENING_STOCK_INDEX_STATUS=PASS" \
  "OPENING_STOCK_DOWN_STATUS=PASS" \
  "OPENING_STOCK_RISK_STATUS=PASS" \
  "OPENING_STOCK_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "STOCK_POSTING_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1000p' "$REPORT" || true
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
  opening_stock_batches \
  opening_stock_lines \
  opening_stock_validation_errors \
  opening_stock_posting_runs \
  opening_stock_balance_snapshots
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

grep -q "product_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ product_code not null yok"
  exit 1
}

grep -q "location_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ location_code not null yok"
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

echo "PHASE4B_OPENING_STOCK_TEST=PASS ✅"
echo "PHASE4B_OPENING_STOCK_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_OPENING_STOCK_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_OPENING_STOCK_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_OPENING_STOCK_SECRET_TEST=PASS ✅"
