#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_operational_readmodel_tables.sh"
MIGRATION_BASE="20260427_151001_readmodel_operational_tables"
UP_FILE="db/migrations/${MIGRATION_BASE}.up.sql"
DOWN_FILE="db/migrations/${MIGRATION_BASE}.down.sql"
REPORT="docs/phase4/15_1_operational_readmodel_tables_report.md"
INVENTORY="docs/phase4/15_1_operational_readmodel_tables_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ validation script executable degil"
  exit 1
fi

bash "$SCRIPT" . "$MIGRATION_BASE" >/tmp/pix2pi_15_1_readmodel.log 2>&1 || {
  echo "TEST_FAIL ❌ operational readmodel validation hata verdi"
  cat /tmp/pix2pi_15_1_readmodel.log || true
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "OPERATIONAL_READMODEL_TABLES=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ operational readmodel PASS degil"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_MIGRATION_PAIR=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ migration pair PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "OPERATIONAL_READMODEL_TABLE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ table count 6 degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB apply NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

for table_name in \
  "readmodel.projection_state" \
  "readmodel.tenant_operational_snapshot" \
  "readmodel.daily_operational_metrics" \
  "readmodel.inventory_status_snapshot" \
  "readmodel.document_work_queue" \
  "readmodel.reconciliation_status_snapshot"
do
  grep -q "$table_name" "$UP_FILE" || {
    echo "TEST_FAIL ❌ up migration table eksik: $table_name"
    sed -n '1,260p' "$UP_FILE" || true
    exit 1
  }

  grep -q "$table_name" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory table eksik: $table_name"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "DROP TABLE IF EXISTS readmodel.projection_state" "$DOWN_FILE" || {
  echo "TEST_FAIL ❌ down migration drop eksik"
  sed -n '1,220p' "$DOWN_FILE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$UP_FILE" "$DOWN_FILE" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_OPERATIONAL_READMODEL_TABLES_TEST=PASS ✅"
echo "PHASE4_OPERATIONAL_READMODEL_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4_OPERATIONAL_READMODEL_NO_APPLY_TEST=PASS ✅"
echo "PHASE4_OPERATIONAL_READMODEL_SECRET_TEST=PASS ✅"
