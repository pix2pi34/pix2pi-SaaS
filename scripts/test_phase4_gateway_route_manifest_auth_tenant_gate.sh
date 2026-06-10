#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh"
REPORT="docs/phase4/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
INVENTORY="docs/phase4/17_3_reporting_gateway_route_inventory.tsv"
MANIFEST="docs/phase4/17_3_reporting_gateway_route_manifest.md"
GATE="docs/phase4/17_3_reporting_auth_tenant_gate_contract.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ gateway route manifest auth tenant gate script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_17_3_gateway_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ gateway route manifest auth tenant gate script hata verdi"
  cat /tmp/pix2pi_17_3_gateway_gate.log || true
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_ROUTE_MANIFEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway route manifest PASS degil"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "AUTH_TENANT_MIDDLEWARE_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ auth tenant gate PASS degil"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.2 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_REPORTING_ROUTE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway route count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "AUTH_TENANT_ALLOWLIST_ROUTE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ auth tenant allowlist route count 6 yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting runtime started NO yok"
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
  grep -q "$endpoint" "$MANIFEST" || {
    echo "TEST_FAIL ❌ manifest endpoint eksik: $endpoint"
    cat "$MANIFEST" || true
    exit 1
  }

  grep -q "$endpoint" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory endpoint eksik: $endpoint"
    cat "$INVENTORY" || true
    exit 1
  }

  grep -q "$endpoint" "$GATE" || {
    echo "TEST_FAIL ❌ gate allowlist endpoint eksik: $endpoint"
    cat "$GATE" || true
    exit 1
  }
done

grep -q "AUTH_REQUIRED" "$GATE" || {
  echo "TEST_FAIL ❌ AUTH_REQUIRED yok"
  cat "$GATE" || true
  exit 1
}

grep -q "TENANT_HEADER_REQUIRED" "$GATE" || {
  echo "TEST_FAIL ❌ TENANT_HEADER_REQUIRED yok"
  cat "$GATE" || true
  exit 1
}

grep -q "TENANT_MISMATCH" "$GATE" || {
  echo "TEST_FAIL ❌ TENANT_MISMATCH yok"
  cat "$GATE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MANIFEST" "$GATE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_GATEWAY_ROUTE_MANIFEST_TEST=PASS ✅"
echo "PHASE4_AUTH_TENANT_MIDDLEWARE_GATE_TEST=PASS ✅"
echo "PHASE4_GATEWAY_NO_CONFIG_MUTATION_TEST=PASS ✅"
echo "PHASE4_GATEWAY_ROUTE_SECRET_TEST=PASS ✅"
