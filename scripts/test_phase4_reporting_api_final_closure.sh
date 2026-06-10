#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_api_final_closure.sh"
REPORT="docs/phase4/17_5_reporting_api_final_closure_report.md"
INVENTORY="docs/phase4/17_5_reporting_api_final_closure_inventory.tsv"
CLOSURE="docs/phase4/17_reporting_api_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting api final closure script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_17_5_reporting_api_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting api final closure script hata verdi"
  cat /tmp/pix2pi_17_5_reporting_api_final_closure.log || true
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_API_FINAL_CLOSURE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting api final closure PASS degil"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_17_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ FAZ4 17 final status PASS yok"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.1 PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.2 PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.3 manifest PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.3 gate PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.4 smoke PASS yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "PORT_OPENED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ port opened NO yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ final closure inventory yok"
  exit 1
fi

for block in \
  17.1_reporting_runtime_wiring_plan \
  17.2_reporting_api_route_registration \
  17.3_gateway_route_manifest_auth_tenant_gate \
  17.4_reporting_runtime_smoke_test \
  go_test_suite \
  runtime_start \
  gateway_config_changed \
  db_mutation \
  query_text_printed
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ 17 closure file yok"
  exit 1
fi

grep -q "REPORTING_API_FINAL_CLOSURE=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure final PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

grep -q "FAZ4_17_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure FAZ4 17 PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_REPORTING_API_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_GO_TEST_SUITE_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_NO_RUNTIME_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_NO_GATEWAY_MUTATION_TEST=PASS ✅"
echo "PHASE4_REPORTING_API_SECRET_TEST=PASS ✅"
