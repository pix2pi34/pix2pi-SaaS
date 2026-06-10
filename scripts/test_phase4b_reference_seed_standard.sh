#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_reference_seed_standard.sh"
PY_SCRIPT="scripts/phase4b_reference_seed_standard.py"
REPORT="docs/phase4/14_2_reference_seed_report.md"
MATRIX="docs/phase4/14_2_reference_seed_matrix.tsv"
MANIFEST="config/reference-data/seed_manifest.tsv"
DOC_MANIFEST="docs/phase4/14_2_reference_seed_manifest.tsv"
SCOPE="docs/phase4/14_2_reference_seed_scope_rules.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reference seed wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ reference seed python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_14_2_reference_seed_standard.log 2>&1 || {
  echo "TEST_FAIL ❌ reference seed standard script hata verdi"
  cat /tmp/pix2pi_14_2_reference_seed_standard.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "REFERENCE_SEED_STANDARD=PASS" \
  "FAZ4B_14_2_FINAL_STATUS=PASS" \
  "PREVIOUS_14_1_FINAL_STATUS=PASS" \
  "REFERENCE_SEED_MANIFEST_STATUS=PASS" \
  "REFERENCE_SEED_SCOPE_STATUS=PASS" \
  "REFERENCE_SEED_IDEMPOTENCY_STATUS=PASS" \
  "REFERENCE_SEED_ROLLBACK_STATUS=PASS" \
  "REFERENCE_SEED_TENANT_SAFETY_STATUS=PASS" \
  "REFERENCE_SEED_APPLY_GATE_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "SEED_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$SCOPE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for key in \
  tdhp_chart_of_accounts \
  tax_vat_rates \
  document_types \
  currency_codes \
  unit_definitions \
  product_categories \
  stock_locations \
  payment_methods \
  customer_import_seed \
  product_import_seed \
  opening_stock_seed
do
  grep -q "$key" "$MANIFEST" || {
    echo "TEST_FAIL ❌ seed key eksik: $key"
    cat "$MANIFEST" || true
    exit 1
  }
done

for scope in \
  GLOBAL_REFERENCE \
  TENANT_DEFAULT \
  TENANT_SPECIFIC
do
  grep -q "$scope" "$MANIFEST" || {
    echo "TEST_FAIL ❌ scope eksik: $scope"
    cat "$MANIFEST" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$SCOPE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$SCOPE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$SCOPE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_REFERENCE_SEED_STANDARD_TEST=PASS ✅"
echo "PHASE4B_REFERENCE_SEED_SCOPE_TEST=PASS ✅"
echo "PHASE4B_REFERENCE_SEED_IDEMPOTENCY_TEST=PASS ✅"
echo "PHASE4B_REFERENCE_SEED_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_REFERENCE_SEED_SECRET_TEST=PASS ✅"
