#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_ebelge_export_reporting_mart.sh"
PY_SCRIPT="scripts/phase4b_ebelge_export_reporting_mart.py"
REPORT="docs/phase4/15_3_ebelge_export_reporting_mart_report.md"
INVENTORY="docs/phase4/15_3_ebelge_export_reporting_mart_inventory.tsv"
MATRIX="docs/phase4/15_3_ebelge_export_reporting_mart_matrix.tsv"
UP_FILE="db/migrations/20260428_153001_ebelge_export_reporting_mart.up.sql"
DOWN_FILE="db/migrations/20260428_153001_ebelge_export_reporting_mart.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ ebelge export wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ ebelge export python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_15_3_ebelge_export_reporting_mart.log 2>&1 || {
  echo "TEST_FAIL ❌ ebelge export reporting mart script hata verdi"
  cat /tmp/pix2pi_15_3_ebelge_export_reporting_mart.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "EBELGE_EXPORT_REPORTING_MART=PASS" \
  "FAZ4B_15_3_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_2_FINAL_STATUS=PASS" \
  "EBELGE_EXPORT_MIGRATION_PAIR=PASS" \
  "EBELGE_EXPORT_SCHEMA_STATUS=PASS" \
  "EBELGE_EXPORT_TABLE_STATUS=PASS" \
  "EBELGE_EXPORT_TENANT_SAFETY_STATUS=PASS" \
  "EBELGE_EXPORT_PERIOD_STATUS=PASS" \
  "EBELGE_EXPORT_EBELGE_TYPE_STATUS=PASS" \
  "EBELGE_EXPORT_PROVIDER_STATUS=PASS" \
  "EBELGE_EXPORT_INDEX_STATUS=PASS" \
  "EBELGE_EXPORT_DOWN_STATUS=PASS" \
  "EBELGE_EXPORT_RISK_STATUS=PASS" \
  "EBELGE_EXPORT_CHAIN_STATUS=PASS" \
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
  ebelge_daily_summaries \
  ebelge_document_status_summaries \
  ebelge_error_summaries \
  accounting_export_batch_summaries \
  accounting_export_provider_summaries \
  accounting_export_error_summaries \
  accounting_export_tenant_kpis
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

grep -q "period_key text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ period_key not null yok"
  exit 1
}

grep -q "ebelge_type text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ ebelge_type not null yok"
  exit 1
}

grep -q "provider_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ provider_code not null yok"
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

echo "PHASE4B_EBELGE_EXPORT_REPORTING_MART_TEST=PASS ✅"
echo "PHASE4B_EBELGE_EXPORT_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_EBELGE_EXPORT_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_EBELGE_EXPORT_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_EBELGE_EXPORT_SECRET_TEST=PASS ✅"
