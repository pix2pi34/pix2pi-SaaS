#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_inventory_tests.sh"
PY_SCRIPT="scripts/phase4b_inventory_tests.py"
REPORT="docs/phase4/18_8_inventory_tests_report.md"
MATRIX="docs/phase4/18_8_inventory_tests_matrix.tsv"
INVENTORY="docs/phase4/18_8_inventory_tests_inventory.tsv"
CLOSURE="docs/phase4/18_inventory_pilot_motor_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ inventory tests wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ inventory tests python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_8_inventory_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ inventory tests script hata verdi"
  cat /tmp/pix2pi_18_8_inventory_tests.log || true
  sed -n '1,1800p' "$REPORT" || true
  exit 1
}

for required in \
  "INVENTORY_TEST_SET=PASS" \
  "INVENTORY_FINAL_CLOSURE=PASS" \
  "FAZ4B_18_8_FINAL_STATUS=PASS" \
  "FAZ4B_18_FINAL_STATUS=PASS" \
  "OPENING_STOCK_TEST=PASS" \
  "STOCK_MOVEMENT_ENGINE_TEST=PASS" \
  "SALES_STOCK_DECREMENT_TEST=PASS" \
  "PURCHASE_STOCK_INCREMENT_TEST=PASS" \
  "STOCK_RESERVATION_TEST=PASS" \
  "NEGATIVE_STOCK_POLICY_TEST=PASS" \
  "STOCK_VALUATION_TEST=PASS" \
  "INVENTORY_TENANT_SAFETY_TEST=PASS" \
  "INVENTORY_MIGRATION_PAIR_TEST=PASS" \
  "INVENTORY_NO_APPLY_TEST=PASS" \
  "INVENTORY_SECRET_SAFETY_TEST=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "STOCK_BALANCE_MUTATION=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_18_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ 18 final closure PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  opening_stock_test \
  stock_movement_engine_test \
  sales_stock_decrement_test \
  purchase_stock_increment_test \
  stock_reservation_test \
  negative_stock_policy_test \
  stock_valuation_test \
  inventory_tenant_safety_test \
  inventory_migration_pair_test \
  inventory_no_apply_test \
  inventory_secret_safety_test
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_18_8_INVENTORY_TEST_SET=PASS ✅"
echo "PHASE4B_18_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_18_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_18_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4B_18_SECRET_SAFETY_TEST=PASS ✅"
