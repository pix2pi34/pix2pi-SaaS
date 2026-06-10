#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_negative_stock_policy.sh"
PY_SCRIPT="scripts/phase4b_negative_stock_policy.py"
REPORT="docs/phase4/18_6_negative_stock_policy_report.md"
INVENTORY="docs/phase4/18_6_negative_stock_policy_inventory.tsv"
MATRIX="docs/phase4/18_6_negative_stock_policy_matrix.tsv"
UP_FILE="db/migrations/20260428_186001_inventory_negative_stock_policy.up.sql"
DOWN_FILE="db/migrations/20260428_186001_inventory_negative_stock_policy.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ negative stock policy wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ negative stock policy python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_18_6_negative_stock_policy.log 2>&1 || {
  echo "TEST_FAIL ❌ negative stock policy script hata verdi"
  cat /tmp/pix2pi_18_6_negative_stock_policy.log || true
  sed -n '1,1400p' "$REPORT" || true
  exit 1
}

for required in \
  "NEGATIVE_STOCK_POLICY=PASS" \
  "FAZ4B_18_6_FINAL_STATUS=PASS" \
  "PREVIOUS_18_5_FINAL_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_MIGRATION_PAIR=PASS" \
  "NEGATIVE_STOCK_POLICY_SCHEMA_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_TABLE_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_TENANT_SAFETY_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_MODE_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_SCOPE_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_QUANTITY_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_MOVEMENT_REF_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_APPROVAL_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_IDEMPOTENCY_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_INDEX_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_DOWN_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_RISK_STATUS=PASS" \
  "NEGATIVE_STOCK_POLICY_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "NEGATIVE_STOCK_POLICY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1400p' "$REPORT" || true
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
  negative_stock_policy_profiles \
  negative_stock_policy_rules \
  negative_stock_policy_exceptions \
  negative_stock_policy_evaluations \
  negative_stock_policy_decisions \
  negative_stock_policy_validation_errors
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

grep -q "policy_mode text NOT NULL DEFAULT 'BLOCK'" "$UP_FILE" || {
  echo "TEST_FAIL ❌ BLOCK policy mode yok"
  exit 1
}

grep -q "decision_action text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ decision_action yok"
  exit 1
}

grep -q "allow_negative_stock boolean NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ allow_negative_stock yok"
  exit 1
}

grep -q "negative_quantity numeric(18,4) NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ negative_quantity yok"
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

echo "PHASE4B_NEGATIVE_STOCK_POLICY_TEST=PASS ✅"
echo "PHASE4B_NEGATIVE_STOCK_POLICY_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_NEGATIVE_STOCK_POLICY_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_NEGATIVE_STOCK_POLICY_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_NEGATIVE_STOCK_POLICY_SECRET_TEST=PASS ✅"
