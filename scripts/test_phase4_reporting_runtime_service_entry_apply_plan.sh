#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_runtime_service_entry_apply_plan.sh"
REPORT="docs/phase4/18_2_reporting_runtime_service_entry_apply_plan_report.md"
INVENTORY="docs/phase4/18_2_reporting_runtime_service_entry_candidate_inventory.tsv"
MATRIX="docs/phase4/18_2_reporting_runtime_service_entry_apply_matrix.tsv"
EXECUTION="docs/phase4/18_2_reporting_runtime_service_entry_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting runtime service entry apply plan script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_18_2_service_entry_apply_plan.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting runtime service entry apply plan script hata verdi"
  cat /tmp/pix2pi_18_2_service_entry_apply_plan.log || true
  sed -n '1,760p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ service entry apply plan PASS degil"
  sed -n '1,760p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_1_READINESS_DISCOVERY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.1 PASS yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_1_APPLY_READINESS_STATUS=READY" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.1 READY yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_REGISTRATION_FILE_STATUS=FOUND" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime registration file FOUND yok"
  sed -n '1,420p' "$REPORT" || true
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

grep -q "CANDIDATE_EXECUTION_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ candidate execution created YES yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ candidate execution blocked YES yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go" "$REPORT" || {
  echo "TEST_FAIL ❌ selected entry target api-gateway degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "SELECTED_ENTRY_TARGET_KIND=API_GATEWAY" "$REPORT" || {
  echo "TEST_FAIL ❌ selected entry target kind API_GATEWAY degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}


grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,760p' "$REPORT" || true
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
  echo "TEST_FAIL ❌ candidate inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ apply matrix yok"
  exit 1
fi

if [ ! -f "$EXECUTION" ]; then
  echo "TEST_FAIL ❌ candidate execution file yok"
  exit 1
fi

grep -q "exit 99" "$EXECUTION" || {
  echo "TEST_FAIL ❌ execution file exit 99 ile bloklu degil"
  sed -n '1,160p' "$EXECUTION" || true
  exit 1
}

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$EXECUTION" || {
  echo "TEST_FAIL ❌ execution file do not run flag yok"
  sed -n '1,160p' "$EXECUTION" || true
  exit 1
}

for item in \
  selected_entry_target \
  runtime_registration \
  candidate_execution \
  entry_candidate_total \
  apply_mode
do
  grep -q "$item" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory item eksik: $item"
    cat "$INVENTORY" || true
    exit 1
  }
done

for gate in \
  previous_18_1_readiness \
  previous_17_final \
  runtime_registration \
  candidate_execution_created \
  reporting_go_test_suite \
  apply_executed \
  gateway_config_changed \
  runtime_started \
  db_mutation
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

echo "PHASE4_REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_CANDIDATE_EXECUTION_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_NO_APPLY_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_GO_TEST_SUITE_TEST=PASS ✅"
echo "PHASE4_REPORTING_RUNTIME_SECRET_TEST=PASS ✅"
