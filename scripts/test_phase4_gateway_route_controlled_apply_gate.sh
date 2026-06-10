#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_gateway_route_controlled_apply_gate.sh"
PY_SCRIPT="scripts/phase4_gateway_route_controlled_apply_gate.py"
REPORT="docs/phase4/18_3_gateway_route_controlled_apply_gate_report.md"
INVENTORY="docs/phase4/18_3_gateway_route_apply_gate_inventory.tsv"
MATRIX="docs/phase4/18_3_gateway_route_apply_gate_matrix.tsv"
EXECUTION="docs/phase4/18_3_gateway_route_controlled_apply_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ gateway route controlled apply gate script executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ gateway route controlled apply gate python validator executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ gateway route controlled apply gate wrapper syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ gateway route controlled apply gate python syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_18_3_apply_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ gateway route controlled apply gate script hata verdi"
  cat /tmp/pix2pi_18_3_apply_gate.log || true
  sed -n '1,820p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ controlled apply gate PASS degil"
  sed -n '1,820p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_GATE_READY=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ apply gate ready YES yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_2_SELECTED_ENTRY_TARGET_KIND=API_GATEWAY" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.2 target API_GATEWAY degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go" "$REPORT" || {
  echo "TEST_FAIL ❌ selected target api-gateway degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "SELECTED_ENTRY_TARGET_KIND=API_GATEWAY" "$REPORT" || {
  echo "TEST_FAIL ❌ selected target kind API_GATEWAY yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=1" "$REPORT" || {
  echo "TEST_FAIL ❌ RegisterReportingRoutes count 1 yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_ROUTE_CONSTANT_USAGE_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ route constant usage count 6 yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "CANDIDATE_EXECUTION_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ candidate execution created YES yok"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ candidate execution blocked YES yok"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,820p' "$REPORT" || true
  exit 1
}

grep -q "API_GATEWAY_GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ api gateway go test PASS yok"
  sed -n '1,820p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ apply executed NO yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime started NO yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ apply gate inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ apply gate matrix yok"
  exit 1
fi

if [ ! -f "$EXECUTION" ]; then
  echo "TEST_FAIL ❌ candidate execution file yok"
  exit 1
fi

grep -q "exit 99" "$EXECUTION" || {
  echo "TEST_FAIL ❌ execution file exit 99 ile bloklu degil"
  sed -n '1,180p' "$EXECUTION" || true
  exit 1
}

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$EXECUTION" || {
  echo "TEST_FAIL ❌ execution file do not run flag yok"
  sed -n '1,180p' "$EXECUTION" || true
  exit 1
}

for item in \
  selected_entry_target \
  selected_entry_kind \
  runtime_registration \
  register_function \
  routes_function \
  route_constants \
  candidate_execution \
  apply_gate_ready
do
  grep -q "$item" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory item eksik: $item"
    cat "$INVENTORY" || true
    exit 1
  }
done

for gate in \
  previous_18_1_readiness \
  previous_18_2_plan \
  previous_17_final \
  selected_target_api_gateway \
  runtime_registration \
  reporting_go_test_suite \
  api_gateway_go_test \
  candidate_execution_created \
  apply_executed \
  gateway_config_changed \
  runtime_started \
  db_mutation \
  apply_gate_ready
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX" "$EXECUTION"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$MATRIX" "$EXECUTION"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE_TEST=PASS ✅"
echo "PHASE4_GATEWAY_ROUTE_APPLY_GATE_READY_TEST=PASS ✅"
echo "PHASE4_GATEWAY_ROUTE_CANDIDATE_EXECUTION_TEST=PASS ✅"
echo "PHASE4_GATEWAY_ROUTE_NO_APPLY_TEST=PASS ✅"
echo "PHASE4_GATEWAY_ROUTE_SECRET_TEST=PASS ✅"
