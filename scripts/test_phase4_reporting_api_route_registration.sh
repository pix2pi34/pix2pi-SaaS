#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_api_route_registration.sh"
REPORT="docs/phase4/17_2_reporting_api_route_registration_report.md"
INVENTORY="docs/phase4/17_2_reporting_api_route_registration_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting api route registration script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_17_2_route_registration.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting api route registration script hata verdi"
  cat /tmp/pix2pi_17_2_route_registration.log || true
  sed -n '1,500p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_API_ROUTE_REGISTRATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ route registration PASS degil"
  sed -n '1,500p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.1 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "ROUTE_REGISTRATION_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ route registration count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ go test PASS yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
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
  grep -q "$endpoint" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory endpoint eksik: $endpoint"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_REPORTING_API_ROUTE_REGISTRATION_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_ROUTE_GO_TEST=PASS ✅"
echo "PHASE4_REPORTING_ROUTE_NO_RUNTIME_TEST=PASS ✅"
echo "PHASE4_REPORTING_ROUTE_SECRET_TEST=PASS ✅"
