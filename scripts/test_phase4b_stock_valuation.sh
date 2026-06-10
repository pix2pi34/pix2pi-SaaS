#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_stock_valuation.sh"
PY_SCRIPT="scripts/phase4b_stock_valuation.py"
REPORT="docs/phase4/18_7_stock_valuation_report.md"
INVENTORY="docs/phase4/18_7_stock_valuation_inventory.tsv"
MATRIX="docs/phase4/18_7_stock_valuation_matrix.tsv"
UP_FILE="db/migrations/20260428_187001_inventory_stock_valuation.up.sql"
DOWN_FILE="db/migrations/20260428_187001_inventory_stock_valuation.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock valuation wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ stock valuation python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_7_stock_valuation.log 2>&1 || {
  echo "TEST_FAIL ❌ stock valuation script hata verdi"
  cat /tmp/pix2pi_18_7_stock_valuation.log || true
  sed -n '1,1500p' "$REPORT" || true
  exit 1
}

for required in \
  "STOCK_VALUATION=PASS" \
  "FAZ4B_18_7_FINAL_STATUS=PASS" \
  "PREVIOUS_18_6_FINAL_STATUS=PASS" \
  "STOCK_VALUATION_MIGRATION_PAIR=PASS" \
  "STOCK_VALUATION_SCHEMA_STATUS=PASS" \
  "STOCK_VALUATION_TABLE_STATUS=PASS" \
  "STOCK_VALUATION_TENANT_SAFETY_STATUS=PASS" \
  "STOCK_VALUATION_METHOD_STATUS=PASS" \
  "STOCK_VALUATION_SCOPE_STATUS=PASS" \
  "STOCK_VALUATION_COST_STATUS=PASS" \
  "STOCK_VALUATION_MOVEMENT_REF_STATUS=PASS" \
  "STOCK_VALUATION_IDEMPOTENCY_STATUS=PASS" \
  "STOCK_VALUATION_INDEX_STATUS=PASS" \
  "STOCK_VALUATION_DOWN_STATUS=PASS" \
  "STOCK_VALUATION_RISK_STATUS=PASS" \
  "STOCK_VALUATION_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "STOCK_VALUATION_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1500p' "$REPORT" || true
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
  stock_valuation_profiles \
  stock_valuation_layers \
  stock_valuation_entries \
  stock_valuation_adjustments \
  stock_revaluation_runs \
  stock_valuation_validation_errors
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

grep -q "valuation_method text NOT NULL DEFAULT 'WEIGHTED_AVERAGE'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ WEIGHTED_AVERAGE valuation_method yok"
  exit 1
}

grep -q "unit_cost numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ unit_cost yok"
  exit 1
}

grep -q "average_unit_cost numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ average_unit_cost yok"
  exit 1
}

grep -q "valuation_amount numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ valuation_amount yok"
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

echo "PHASE4B_STOCK_VALUATION_TEST=PASS ✅"
echo "PHASE4B_STOCK_VALUATION_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_STOCK_VALUATION_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_STOCK_VALUATION_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_STOCK_VALUATION_SECRET_TEST=PASS ✅"
