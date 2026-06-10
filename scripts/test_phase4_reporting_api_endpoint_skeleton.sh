#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_api_endpoint_skeleton.sh"
REPORT="docs/phase4/16_4_reporting_api_endpoint_skeleton_report.md"
INVENTORY="docs/phase4/16_4_reporting_api_endpoint_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting api endpoint skeleton script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_16_4_api_skeleton.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting api endpoint skeleton script hata verdi"
  cat /tmp/pix2pi_16_4_api_skeleton.log || true
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_API_ENDPOINT_SKELETON=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting api endpoint skeleton PASS degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_16_3_REPORTING_SERVICE_LAYER=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 16.3 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "API_ENDPOINT_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ api endpoint count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "HANDLER_ROUTE_CASE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ handler route case count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_INTERFACE_METHOD_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ service interface method count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ go test PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "HTTP_HANDLER_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ HTTP handler YES yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ api endpoint inventory yok"
  exit 1
fi

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

echo "PHASE4_REPORTING_API_ENDPOINT_SKELETON_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_GO_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_NO_RUNTIME_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_SECRET_TEST=PASS ✅"
