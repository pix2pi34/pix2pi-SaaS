#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_migration_chain_standard.sh"
PY_SCRIPT="scripts/phase4b_migration_chain_standard.py"
REPORT="docs/phase4/14_1_pilot_migration_chain_report.md"
INVENTORY="docs/phase4/14_1_pilot_migration_chain_inventory.tsv"
MATRIX="docs/phase4/14_1_pilot_migration_chain_matrix.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ migration chain wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ migration chain python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_14_1_migration_chain_standard.log 2>&1 || {
  echo "TEST_FAIL ❌ migration chain standard script hata verdi"
  cat /tmp/pix2pi_14_1_migration_chain_standard.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "MIGRATION_CHAIN_STANDARD=PASS" \
  "FAZ4B_14_1_FINAL_STATUS=PASS" \
  "MIGRATION_NAMING_STATUS=PASS" \
  "MIGRATION_PAIRING_STATUS=PASS" \
  "MIGRATION_DUPLICATE_STATUS=PASS" \
  "MIGRATION_ROLLBACK_FILE_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ report required eksik: $required"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
done

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ matrix yok"
  exit 1
fi

for gate in \
  migration_directory \
  migration_naming \
  migration_pairing \
  migration_duplicates \
  rollback_files \
  up_sql_risk \
  schema_migrations_db_check \
  db_mutation \
  query_text_printed
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

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

echo "PHASE4B_MIGRATION_CHAIN_STANDARD_TEST=PASS ✅"
echo "PHASE4B_MIGRATION_PAIRING_TEST=PASS ✅"
echo "PHASE4B_MIGRATION_NAMING_TEST=PASS ✅"
echo "PHASE4B_MIGRATION_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_MIGRATION_SECRET_TEST=PASS ✅"
