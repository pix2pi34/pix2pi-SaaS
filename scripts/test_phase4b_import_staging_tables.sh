#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_import_staging_tables.sh"
PY_SCRIPT="scripts/phase4b_import_staging_tables.py"
REPORT="docs/phase4/14_3_import_staging_tables_report.md"
INVENTORY="docs/phase4/14_3_import_staging_tables_inventory.tsv"
MATRIX="docs/phase4/14_3_import_staging_tables_matrix.tsv"
UP_FILE="db/migrations/20260428_143001_import_staging_tables.up.sql"
DOWN_FILE="db/migrations/20260428_143001_import_staging_tables.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ import staging wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ import staging python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_14_3_import_staging_tables.log 2>&1 || {
  echo "TEST_FAIL ❌ import staging tables script hata verdi"
  cat /tmp/pix2pi_14_3_import_staging_tables.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "IMPORT_STAGING_TABLES=PASS" \
  "FAZ4B_14_3_FINAL_STATUS=PASS" \
  "PREVIOUS_14_1_FINAL_STATUS=PASS" \
  "PREVIOUS_14_2_FINAL_STATUS=PASS" \
  "IMPORT_STAGING_MIGRATION_PAIR=PASS" \
  "IMPORT_STAGING_SCHEMA_STATUS=PASS" \
  "IMPORT_STAGING_TABLE_STATUS=PASS" \
  "IMPORT_STAGING_TENANT_SAFETY_STATUS=PASS" \
  "IMPORT_STAGING_INDEX_STATUS=PASS" \
  "IMPORT_STAGING_DOWN_STATUS=PASS" \
  "IMPORT_STAGING_RISK_STATUS=PASS" \
  "IMPORT_STAGING_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,900p' "$REPORT" || true
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
  import_batches \
  import_files \
  import_customers_staging \
  import_vendors_staging \
  import_products_staging \
  import_opening_stocks_staging \
  import_price_lists_staging \
  import_validation_errors \
  import_row_status_events
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

grep -q "CREATE SCHEMA IF NOT EXISTS import_pipeline" "$UP_FILE" || {
  echo "TEST_FAIL ❌ import_pipeline schema create yok"
  exit 1
}

grep -q "tenant_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ tenant_id not null yok"
  exit 1
}

grep -q "import_batch_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ import_batch_id not null yok"
  exit 1
}

grep -q "raw_payload jsonb" "$UP_FILE" || {
  echo "TEST_FAIL ❌ raw_payload jsonb yok"
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

echo "PHASE4B_IMPORT_STAGING_TABLES_TEST=PASS ✅"
echo "PHASE4B_IMPORT_STAGING_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_IMPORT_STAGING_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_IMPORT_STAGING_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_IMPORT_STAGING_SECRET_TEST=PASS ✅"
