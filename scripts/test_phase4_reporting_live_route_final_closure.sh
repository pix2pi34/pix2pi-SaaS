#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_live_route_final_closure.sh"
PY_SCRIPT="scripts/phase4_reporting_live_route_final_closure.py"
REPORT="docs/phase4/18_6_reporting_live_route_final_closure_report.md"
INVENTORY="docs/phase4/18_6_reporting_live_route_final_closure_inventory.tsv"
MATRIX="docs/phase4/18_6_reporting_live_route_final_closure_matrix.tsv"
CLOSURE="docs/phase4/18_reporting_live_route_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ final closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ final closure python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ final closure wrapper syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ final closure python syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_18_6_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ final closure script hata verdi"
  cat /tmp/pix2pi_18_6_final_closure.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_LIVE_ROUTE_FINAL_CLOSURE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final closure PASS degil"
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_18_FINAL_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ FAZ4 18 final status PASS yok"
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "18_1_GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS" \
  "18_2_REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS" \
  "18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS" \
  "18_4_CONTROLLED_GATEWAY_RUNTIME_APPLY=PASS" \
  "18_5_LIVE_HTTP_SMOKE_AUTH_TENANT=PASS" \
  "TARGET_REPORTING_IMPORT_COUNT=1" \
  "TARGET_REPORTING_REGISTER_CALL_COUNT=1" \
  "REPORTING_GO_TEST_SUITE=PASS" \
  "API_GATEWAY_GO_TEST_STATUS=PASS" \
  "RUNTIME_RESTART_EXECUTED=NO" \
  "GATEWAY_CONFIG_CHANGED=NO" \
  "NGINX_CONFIG_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ report required eksik: $required"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
done

if grep -q "LIVE_AUTH_MODE=NO_VALID_TOKEN_PROVIDED" "$REPORT"; then
  grep -q "LIVE_ROUTE_SECURITY_STATUS=AUTH_PROTECTED" "$REPORT" || {
    echo "TEST_FAIL ❌ no token modunda AUTH_PROTECTED yok"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }

  grep -q "REAL_TOKEN_FULL_SMOKE_STATUS=DEFERRED_NO_VALID_TOKEN" "$REPORT" || {
    echo "TEST_FAIL ❌ real token full smoke deferred yok"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
fi

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ matrix yok"
  exit 1
fi

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ 18 closure file yok"
  exit 1
fi

grep -q "FAZ4_18_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure file FAZ4 18 PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

grep -q "REPORTING_LIVE_ROUTE_FINAL_CLOSURE=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure file final closure PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for item in \
  18.1_readiness \
  18.2_service_entry_plan \
  18.3_apply_gate \
  18.4_controlled_apply \
  18.5_live_smoke \
  target_reporting_import_count \
  target_reporting_register_call_count \
  live_route_security_status \
  reporting_go_test_suite \
  api_gateway_go_test_status
do
  grep -q "$item" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory item eksik: $item"
    cat "$INVENTORY" || true
    exit 1
  }
done

for gate in \
  previous_17_final \
  18.1_readiness \
  18.2_service_entry_plan \
  18.3_apply_gate \
  18.4_controlled_apply \
  18.5_live_http_smoke \
  target_code_patch \
  live_route_security \
  query_text_leak \
  reporting_go_test_suite \
  api_gateway_go_test \
  reporting_live_route_final_closure
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "Bearer smoke-token" "$REPORT" "$INVENTORY" "$MATRIX" "$CLOSURE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$MATRIX" "$CLOSURE"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_REPORTING_LIVE_ROUTE_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_REPORTING_LIVE_ROUTE_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4_REPORTING_LIVE_ROUTE_GO_TEST=PASS ✅"
echo "PHASE4_REPORTING_LIVE_ROUTE_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_REPORTING_LIVE_ROUTE_SECRET_TEST=PASS ✅"
