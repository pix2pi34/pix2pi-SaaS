#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_purchase_stock_increment.sh"
PY_SCRIPT="scripts/phase4b_purchase_stock_increment.py"
REPORT="docs/phase4/18_4_purchase_stock_increment_report.md"
INVENTORY="docs/phase4/18_4_purchase_stock_increment_inventory.tsv"
MATRIX="docs/phase4/18_4_purchase_stock_increment_matrix.tsv"
UP_FILE="db/migrations/20260428_184001_inventory_purchase_stock_increment.up.sql"
DOWN_FILE="db/migrations/20260428_184001_inventory_purchase_stock_increment.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ purchase stock increment wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ purchase stock increment python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_4_purchase_stock_increment.log 2>&1 || {
  echo "TEST_FAIL ❌ purchase stock increment script hata verdi"
  cat /tmp/pix2pi_18_4_purchase_stock_increment.log || true
  sed -n '1,1300p' "$REPORT" || true
  exit 1
}

for required in \
  "PURCHASE_STOCK_INCREMENT=PASS" \
  "FAZ4B_18_4_FINAL_STATUS=PASS" \
  "PREVIOUS_18_3_FINAL_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_MIGRATION_PAIR=PASS" \
  "PURCHASE_STOCK_INCREMENT_SCHEMA_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_TABLE_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_TENANT_SAFETY_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_PURCHASE_SOURCE_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_MOVEMENT_LINK_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_QUANTITY_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_VALUATION_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_IDEMPOTENCY_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_INDEX_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_DOWN_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_RISK_STATUS=PASS" \
  "PURCHASE_STOCK_INCREMENT_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PURCHASE_STOCK_INCREMENT_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1300p' "$REPORT" || true
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
  purchase_stock_increment_batches \
  purchase_stock_increment_lines \
  purchase_stock_increment_allocations \
  purchase_stock_increment_movement_links \
  purchase_stock_increment_validation_errors \
  purchase_stock_increment_posting_runs
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

grep -q "movement_direction text NOT NULL DEFAULT 'IN'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ IN movement direction yok"
  exit 1
}

grep -q "valuation_method text NOT NULL DEFAULT 'weighted_average'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ valuation_method yok"
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

echo "PHASE4B_PURCHASE_STOCK_INCREMENT_TEST=PASS ✅"
echo "PHASE4B_PURCHASE_STOCK_INCREMENT_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_PURCHASE_STOCK_INCREMENT_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_PURCHASE_STOCK_INCREMENT_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_PURCHASE_STOCK_INCREMENT_SECRET_TEST=PASS ✅"
