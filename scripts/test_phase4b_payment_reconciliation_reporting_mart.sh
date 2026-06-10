#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_payment_reconciliation_reporting_mart.sh"
PY_SCRIPT="scripts/phase4b_payment_reconciliation_reporting_mart.py"
REPORT="docs/phase4/15_4_payment_reconciliation_reporting_mart_report.md"
INVENTORY="docs/phase4/15_4_payment_reconciliation_reporting_mart_inventory.tsv"
MATRIX="docs/phase4/15_4_payment_reconciliation_reporting_mart_matrix.tsv"
UP_FILE="db/migrations/20260428_154001_payment_reconciliation_reporting_mart.up.sql"
DOWN_FILE="db/migrations/20260428_154001_payment_reconciliation_reporting_mart.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ payment reconciliation wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ payment reconciliation python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_15_4_payment_reconciliation_reporting_mart.log 2>&1 || {
  echo "TEST_FAIL ❌ payment reconciliation reporting mart script hata verdi"
  cat /tmp/pix2pi_15_4_payment_reconciliation_reporting_mart.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "PAYMENT_RECONCILIATION_REPORTING_MART=PASS" \
  "FAZ4B_15_4_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_2_FINAL_STATUS=PASS" \
  "PREVIOUS_15_3_FINAL_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_MIGRATION_PAIR=PASS" \
  "PAYMENT_RECONCILIATION_SCHEMA_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_TABLE_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_TENANT_SAFETY_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_PERIOD_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_PROVIDER_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_STATUS_CODE_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_CURRENCY_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_AMOUNT_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_INDEX_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_DOWN_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_RISK_STATUS=PASS" \
  "PAYMENT_RECONCILIATION_CHAIN_STATUS=PASS" \
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
  payment_attempt_summaries \
  payment_provider_summaries \
  settlement_summaries \
  reconciliation_difference_summaries \
  commission_summaries \
  merchant_payout_summaries \
  payment_reconciliation_tenant_kpis
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

grep -q "provider_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ provider_code not null yok"
  exit 1
}

grep -q "status_code text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ status_code not null yok"
  exit 1
}

grep -q "currency_code text NOT NULL DEFAULT 'TRY'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ currency_code TRY default yok"
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

echo "PHASE4B_PAYMENT_RECONCILIATION_REPORTING_MART_TEST=PASS ✅"
echo "PHASE4B_PAYMENT_RECONCILIATION_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_PAYMENT_RECONCILIATION_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_PAYMENT_RECONCILIATION_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_PAYMENT_RECONCILIATION_SECRET_TEST=PASS ✅"
