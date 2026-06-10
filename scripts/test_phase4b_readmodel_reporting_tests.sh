#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_readmodel_reporting_tests.sh"
PY_SCRIPT="scripts/phase4b_readmodel_reporting_tests.py"
REPORT="docs/phase4/15_7_readmodel_reporting_tests_report.md"
MATRIX="docs/phase4/15_7_readmodel_reporting_tests_matrix.tsv"
INVENTORY="docs/phase4/15_7_readmodel_reporting_tests_inventory.tsv"
CLOSURE="docs/phase4/15_readmodel_reporting_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ 15.7 wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ 15.7 python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_15_7_readmodel_reporting_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ 15.7 readmodel reporting tests script hata verdi"
  cat /tmp/pix2pi_15_7_readmodel_reporting_tests.log || true
  sed -n '1,1200p' "$REPORT" || true
  exit 1
}

for required in \
  "READMODEL_REPORTING_TEST_SET=PASS" \
  "READMODEL_REPORTING_FINAL_CLOSURE=PASS" \
  "FAZ4B_15_7_FINAL_STATUS=PASS" \
  "FAZ4B_15_FINAL_STATUS=PASS" \
  "OPERATIONAL_READMODEL_TEST=PASS" \
  "FINANCE_REPORTING_TEST=PASS" \
  "EBELGE_EXPORT_REPORTING_TEST=PASS" \
  "PAYMENT_RECONCILIATION_REPORTING_TEST=PASS" \
  "SEARCH_INDEX_PROJECTION_TEST=PASS" \
  "MATERIALIZED_CACHE_PROJECTION_TEST=PASS" \
  "TENANT_SAFETY_TEST=PASS" \
  "MIGRATION_PAIR_TEST=PASS" \
  "NO_APPLY_TEST=PASS" \
  "SECRET_SAFETY_TEST=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "REDIS_MUTATION=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_15_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure final PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  operational_readmodel_test \
  finance_reporting_test \
  ebelge_export_reporting_test \
  payment_reconciliation_reporting_test \
  search_index_projection_test \
  materialized_cache_projection_test \
  tenant_safety_test \
  migration_pair_test \
  no_apply_test \
  secret_safety_test
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

echo "PHASE4B_15_7_READMODEL_REPORTING_TEST=PASS ✅"
echo "PHASE4B_15_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_15_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_15_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4B_15_SECRET_SAFETY_TEST=PASS ✅"
