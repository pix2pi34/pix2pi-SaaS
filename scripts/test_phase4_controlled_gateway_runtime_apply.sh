#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_controlled_gateway_runtime_apply.sh"
PY_SCRIPT="scripts/phase4_controlled_gateway_runtime_apply.py"
REPORT="docs/phase4/18_4_controlled_gateway_runtime_apply_report.md"
INVENTORY="docs/phase4/18_4_controlled_gateway_runtime_apply_inventory.tsv"
MATRIX="docs/phase4/18_4_controlled_gateway_runtime_apply_matrix.tsv"
TARGET="cmd/api-gateway/api_gateway_main.go"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ controlled gateway runtime apply wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ controlled gateway runtime apply python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_18_4_controlled_apply.log 2>&1 || {
  echo "TEST_FAIL ❌ controlled gateway runtime apply hata verdi"
  cat /tmp/pix2pi_18_4_controlled_apply.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "CONTROLLED_GATEWAY_RUNTIME_APPLY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ controlled gateway runtime apply PASS degil"
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_EXECUTED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ apply executed YES yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.3 gate PASS yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_3_APPLY_GATE_READY=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.3 apply gate ready YES yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_IMPORT_COUNT_AFTER=1" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting runtime import count after 1 degil"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER=1" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting runtime register call after 1 degil"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "GOFMT_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ gofmt PASS yok"
  sed -n '1,620p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "API_GATEWAY_GO_TEST_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ api gateway go test PASS yok"
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting runtime started NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "PORT_OPENED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ port opened NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "GATEWAY_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ gateway config changed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "NGINX_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ nginx config changed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ matrix yok"
  exit 1
fi

grep -q 'internal/platform/reporting/runtime' "$TARGET" || {
  echo "TEST_FAIL ❌ target dosyada reporting runtime import yok"
  sed -n '1,120p' "$TARGET" || true
  exit 1
}

grep -q 'reportingruntime.RegisterReportingRoutes' "$TARGET" || {
  echo "TEST_FAIL ❌ target dosyada RegisterReportingRoutes call yok"
  grep -n 'RegisterReportingRoutes\|NewServeMux\|DefaultServeMux' "$TARGET" || true
  exit 1
}

if [ "$(grep -c 'reportingruntime.RegisterReportingRoutes' "$TARGET")" -ne 1 ]; then
  echo "TEST_FAIL ❌ RegisterReportingRoutes duplicate veya eksik"
  grep -n 'RegisterReportingRoutes' "$TARGET" || true
  exit 1
fi

for item in \
  target_file \
  runtime_registration \
  backup_file \
  patch_mode \
  gateway_code_changed \
  reporting_import_count_after \
  reporting_register_call_count_after \
  gofmt_status \
  reporting_go_test_suite \
  api_gateway_go_test_status \
  rollback_ready
do
  grep -q "$item" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory item eksik: $item"
    cat "$INVENTORY" || true
    exit 1
  }
done

for gate in \
  previous_18_3_gate \
  previous_17_final \
  target_file \
  backup_created \
  patch_applied \
  reporting_import_after \
  reporting_register_call_after \
  gofmt \
  reporting_go_test_suite \
  api_gateway_go_test \
  runtime_started \
  gateway_config_changed \
  db_mutation \
  controlled_apply
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

echo "PHASE4_CONTROLLED_GATEWAY_RUNTIME_APPLY_TEST=PASS ✅"
echo "PHASE4_CONTROLLED_GATEWAY_RUNTIME_PATCH_TEST=PASS ✅"
echo "PHASE4_CONTROLLED_GATEWAY_RUNTIME_GO_TEST=PASS ✅"
echo "PHASE4_CONTROLLED_GATEWAY_RUNTIME_NO_RESTART_TEST=PASS ✅"
echo "PHASE4_CONTROLLED_GATEWAY_RUNTIME_SECRET_TEST=PASS ✅"
