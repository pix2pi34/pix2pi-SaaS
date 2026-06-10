#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_gateway_runtime_apply_readiness.sh"
REPORT="docs/phase4/18_1_gateway_runtime_apply_readiness_report.md"
INVENTORY="docs/phase4/18_1_gateway_runtime_discovery_inventory.tsv"
MATRIX="docs/phase4/18_1_gateway_runtime_apply_readiness_matrix.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ gateway runtime apply readiness script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_18_1_apply_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ gateway runtime apply readiness script hata verdi"
  cat /tmp/pix2pi_18_1_apply_readiness.log || true
  sed -n '1,720p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ apply readiness discovery PASS degil"
  sed -n '1,720p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17 final PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17 closure PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=1" "$REPORT" || {
  echo "TEST_FAIL ❌ RegisterReportingRoutes count 1 yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_ROUTE_CONSTANT_USAGE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ route constant usage count 6 yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,720p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ apply executed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ discovery inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ readiness matrix yok"
  exit 1
fi

for item in \
  reporting_runtime \
  reporting_api \
  reporting_service \
  reporting_repository \
  runtime_registration \
  register_function \
  route_constants
do
  grep -q "$item" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory item eksik: $item"
    cat "$INVENTORY" || true
    exit 1
  }
done

for gate in \
  previous_17_final \
  route_registration \
  gateway_manifest \
  auth_tenant_gate \
  runtime_smoke \
  go_test_suite \
  apply_readiness
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_GATEWAY_RUNTIME_APPLY_READINESS_TEST=PASS ✅"
echo "PHASE4_GATEWAY_RUNTIME_DISCOVERY_TEST=PASS ✅"
echo "PHASE4_GATEWAY_RUNTIME_NO_APPLY_TEST=PASS ✅"
echo "PHASE4_GATEWAY_RUNTIME_GO_TEST_SUITE_TEST=PASS ✅"
echo "PHASE4_GATEWAY_RUNTIME_SECRET_TEST=PASS ✅"
