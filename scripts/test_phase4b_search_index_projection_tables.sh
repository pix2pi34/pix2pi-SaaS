#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_search_index_projection_tables.sh"
PY_SCRIPT="scripts/phase4b_search_index_projection_tables.py"
REPORT="docs/phase4/15_5_search_index_projection_tables_report.md"
INVENTORY="docs/phase4/15_5_search_index_projection_tables_inventory.tsv"
MATRIX="docs/phase4/15_5_search_index_projection_tables_matrix.tsv"
UP_FILE="db/migrations/20260428_155001_search_index_projection_tables.up.sql"
DOWN_FILE="db/migrations/20260428_155001_search_index_projection_tables.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ search index wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ search index python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_15_5_search_index_projection_tables.log 2>&1 || {
  echo "TEST_FAIL ❌ search index projection tables script hata verdi"
  cat /tmp/pix2pi_15_5_search_index_projection_tables.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "SEARCH_INDEX_PROJECTION_TABLES=PASS" \
  "FAZ4B_15_5_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_2_FINAL_STATUS=PASS" \
  "PREVIOUS_15_3_FINAL_STATUS=PASS" \
  "PREVIOUS_15_4_FINAL_STATUS=PASS" \
  "SEARCH_INDEX_MIGRATION_PAIR=PASS" \
  "SEARCH_INDEX_SCHEMA_STATUS=PASS" \
  "SEARCH_INDEX_TABLE_STATUS=PASS" \
  "SEARCH_INDEX_TENANT_SAFETY_STATUS=PASS" \
  "SEARCH_INDEX_ENTITY_STATUS=PASS" \
  "SEARCH_INDEX_SEARCH_TEXT_STATUS=PASS" \
  "SEARCH_INDEX_INDEX_STATUS=PASS" \
  "SEARCH_INDEX_DOWN_STATUS=PASS" \
  "SEARCH_INDEX_RISK_STATUS=PASS" \
  "SEARCH_INDEX_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
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
  party_search_documents \
  product_search_documents \
  inventory_search_documents \
  business_document_search_documents \
  finance_search_documents \
  global_search_documents \
  search_projection_rebuild_state
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

grep -q "search_text text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ search_text not null yok"
  exit 1
}

grep -q "search_keywords text\\[\\] NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ search_keywords text array yok"
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

echo "PHASE4B_SEARCH_INDEX_PROJECTION_TABLES_TEST=PASS ✅"
echo "PHASE4B_SEARCH_INDEX_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_SEARCH_INDEX_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_SEARCH_INDEX_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_SEARCH_INDEX_SECRET_TEST=PASS ✅"
