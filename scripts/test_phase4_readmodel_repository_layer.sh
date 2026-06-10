#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_readmodel_repository_layer.sh"
REPORT="docs/phase4/16_2_readmodel_repository_layer_report.md"
INVENTORY="docs/phase4/16_2_readmodel_repository_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ readmodel repository layer script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_16_2_repository_layer.log 2>&1 || {
  echo "TEST_FAIL ❌ readmodel repository layer script hata verdi"
  cat /tmp/pix2pi_16_2_repository_layer.log || true
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_REPOSITORY_LAYER=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ readmodel repository layer PASS degil"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 16.1 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "REPOSITORY_METHOD_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ repository method count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FILTER_STRUCT_COUNT=5" "$REPORT" || {
  echo "TEST_FAIL ❌ filter struct count 5 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ go test PASS yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_CODE_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ service code created YES yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ service runtime started NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ repository inventory yok"
  exit 1
fi

for method in \
  OperationalSummary \
  DailyMetrics \
  InventoryStatus \
  DocumentWorkQueue \
  ReconciliationStatus \
  ProjectionState
do
  grep -q "$method" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory method eksik: $method"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_READMODEL_REPOSITORY_LAYER_TEST=PASS ✅"
echo "PHASE4_READMODEL_REPOSITORY_GO_TEST=PASS ✅"
echo "PHASE4_READMODEL_REPOSITORY_NO_DB_MUTATION_TEST=PASS ✅"
echo "PHASE4_READMODEL_REPOSITORY_SECRET_TEST=PASS ✅"
