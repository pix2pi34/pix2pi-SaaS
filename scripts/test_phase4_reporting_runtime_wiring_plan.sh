#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_runtime_wiring_plan.sh"
REPORT="docs/phase4/17_1_reporting_runtime_wiring_report.md"
INVENTORY="docs/phase4/17_1_reporting_runtime_wiring_inventory.tsv"
PLAN="docs/phase4/17_1_reporting_runtime_wiring_plan.md"
ENTRY="docs/phase4/17_1_reporting_service_entry_contract.md"
GATEWAY="docs/phase4/17_1_reporting_gateway_route_premanifest.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting runtime wiring plan script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_17_1_runtime_wiring.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting runtime wiring plan script hata verdi"
  cat /tmp/pix2pi_17_1_runtime_wiring.log || true
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_WIRING_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime wiring plan PASS degil"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_SERVICE_ENTRY_CONTRACT=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ service entry contract PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GATEWAY_PREMANIFEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway premanifest PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_16_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 16 final PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_16_4_API_ENDPOINT_SKELETON=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 16.4 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_16_5_REPORTING_QUERY_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 16.5 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_PREMANIFEST_ROUTE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway premanifest route count 6 yok"
  sed -n '1,260p' "$REPORT" || true
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
  grep -q "$endpoint" "$GATEWAY" || {
    echo "TEST_FAIL ❌ gateway endpoint eksik: $endpoint"
    cat "$GATEWAY" || true
    exit 1
  }

  grep -q "$endpoint" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory endpoint eksik: $endpoint"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "repository.New()" "$ENTRY" || {
  echo "TEST_FAIL ❌ entry contract repository.New yok"
  cat "$ENTRY" || true
  exit 1
}

grep -q "api.NewHandler" "$ENTRY" || {
  echo "TEST_FAIL ❌ entry contract api.NewHandler yok"
  cat "$ENTRY" || true
  exit 1
}

grep -q "handler.Register" "$PLAN" || {
  echo "TEST_FAIL ❌ runtime plan handler.Register yok"
  cat "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$PLAN" "$ENTRY" "$GATEWAY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_REPORTING_RUNTIME_WIRING_PLAN_TEST=PASS ✅"
echo "PHASE4_REPORTING_SERVICE_ENTRY_CONTRACT_TEST=PASS ✅"
echo "PHASE4_REPORTING_GATEWAY_PREMANIFEST_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_NO_START_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_SECRET_TEST=PASS ✅"
