#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_query_contract.sh"
REPORT="docs/phase4/16_1_reporting_query_contract_report.md"
INVENTORY="docs/phase4/16_1_reporting_query_endpoint_inventory.tsv"
MANIFEST="docs/phase4/16_1_reporting_query_endpoint_manifest.md"
CONTRACTS="docs/phase4/16_1_reporting_query_contracts.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting query contract script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_16_1_reporting_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting query contract script hata verdi"
  cat /tmp/pix2pi_16_1_reporting_contract.log || true
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_QUERY_CONTRACT=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting query contract PASS degil"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_ENDPOINT_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ endpoint count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_CONTRACTS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting contracts PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_15_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ readmodel final PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_CODE_CREATED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ service code created NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

for endpoint in \
  "/api/v1/reporting/operational/summary" \
  "/api/v1/reporting/operational/daily-metrics" \
  "/api/v1/reporting/inventory/status" \
  "/api/v1/reporting/documents/work-queue" \
  "/api/v1/reporting/reconciliation/status" \
  "/api/v1/reporting/projections/state"
do
  grep -q "$endpoint" "$MANIFEST" || {
    echo "TEST_FAIL ❌ manifest endpoint eksik: $endpoint"
    sed -n '1,220p' "$MANIFEST" || true
    exit 1
  }

  grep -q "$endpoint" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory endpoint eksik: $endpoint"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "TENANT_MISMATCH" "$CONTRACTS" || {
  echo "TEST_FAIL ❌ TENANT_MISMATCH contract yok"
  sed -n '1,220p' "$CONTRACTS" || true
  exit 1
}

grep -q "Query text loglanmaz" "$CONTRACTS" || {
  echo "TEST_FAIL ❌ query text loglanmaz contract yok"
  sed -n '1,220p' "$CONTRACTS" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MANIFEST" "$CONTRACTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_REPORTING_QUERY_CONTRACT_TEST=PASS ✅"
echo "PHASE4_REPORTING_ENDPOINT_MANIFEST_TEST=PASS ✅"
echo "PHASE4_REPORTING_TENANT_CONTRACT_TEST=PASS ✅"
echo "PHASE4_REPORTING_SECRET_TEST=PASS ✅"
