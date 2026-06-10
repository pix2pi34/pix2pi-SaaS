#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_migration_lifecycle_import_tests.sh"
PY_SCRIPT="scripts/phase4b_migration_lifecycle_import_tests.py"
REPORT="docs/phase4/14_7_migration_lifecycle_import_tests_report.md"
MATRIX="docs/phase4/14_7_migration_lifecycle_import_tests_matrix.tsv"
INVENTORY="docs/phase4/14_7_migration_lifecycle_import_tests_inventory.tsv"
CLOSURE="docs/phase4/14_migration_lifecycle_import_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ 14.7 wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ 14.7 python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_14_7_migration_lifecycle_import_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ 14.7 migration lifecycle import tests script hata verdi"
  cat /tmp/pix2pi_14_7_migration_lifecycle_import_tests.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "MIGRATION_LIFECYCLE_IMPORT_TESTS=PASS" \
  "FAZ4B_14_7_FINAL_STATUS=PASS" \
  "FAZ4B_14_FINAL_STATUS=PASS" \
  "MIGRATION_CHAIN_TEST=PASS" \
  "REFERENCE_SEED_TEST=PASS" \
  "IMPORT_STAGING_TEST=PASS" \
  "BACKFILL_REBUILD_TEST=PASS" \
  "RETENTION_MODEL_TEST=PASS" \
  "BACKUP_RESTORE_TEST=PASS" \
  "SECRET_SAFETY_TEST=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1000p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_14_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure final PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  migration_chain_test \
  reference_seed_test \
  import_staging_test \
  backfill_rebuild_test \
  retention_model_test \
  backup_restore_test \
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

echo "PHASE4B_14_7_MIGRATION_LIFECYCLE_IMPORT_TEST=PASS ✅"
echo "PHASE4B_14_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_14_SECRET_SAFETY_TEST=PASS ✅"
echo "PHASE4B_14_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4B_14_READY_FOR_NEXT_BLOCK_TEST=PASS ✅"
