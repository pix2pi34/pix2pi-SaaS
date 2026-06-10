#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_runtime_smoke_test.sh"
REPORT="docs/phase4/17_4_reporting_runtime_smoke_test_report.md"
INVENTORY="docs/phase4/17_4_reporting_runtime_smoke_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting runtime smoke test script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_17_4_runtime_smoke.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting runtime smoke test script hata verdi"
  cat /tmp/pix2pi_17_4_runtime_smoke.log || true
  sed -n '1,560p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_SMOKE_TEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime smoke PASS degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_AUTH_GATE_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ auth gate smoke PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_TENANT_GATE_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ tenant gate smoke PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.3 manifest PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 17.3 gate PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ go test PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "PORT_OPENED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ port opened NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "LISTEN_AND_SERVE_USED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ ListenAndServe NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ runtime smoke inventory yok"
  exit 1
fi

for smoke in \
  all_6_reporting_endpoints \
  bearer_auth_gate \
  tenant_header_gate \
  tenant_mismatch_gate \
  method_gate \
  query_text_leak_gate \
  runtime_start_gate
do
  grep -q "$smoke.*PASS" "$INVENTORY" || {
    echo "TEST_FAIL ❌ smoke inventory PASS eksik: $smoke"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_REPORTING_RUNTIME_SMOKE_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_AUTH_GATE_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_TENANT_GATE_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_NO_START_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_SECRET_TEST=PASS ✅"
