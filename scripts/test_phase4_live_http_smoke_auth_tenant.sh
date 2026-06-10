#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_live_http_smoke_auth_tenant.sh"
PY_SCRIPT="scripts/phase4_live_http_smoke_auth_tenant.py"
REPORT="docs/phase4/18_5_live_http_smoke_auth_tenant_report.md"
RESULTS="docs/phase4/18_5_live_http_smoke_endpoint_results.tsv"
MATRIX="docs/phase4/18_5_live_http_smoke_matrix.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ live http smoke wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ live http smoke python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ live http smoke wrapper syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ live http smoke python syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_18_5_live_http_smoke.log 2>&1 || {
  echo "TEST_FAIL ❌ live http smoke hata verdi"
  cat /tmp/pix2pi_18_5_live_http_smoke.log || true
  sed -n '1,760p' "$REPORT" || true
  exit 1
}

grep -q "LIVE_HTTP_SMOKE_AUTH_TENANT=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ live http smoke PASS degil"
  sed -n '1,760p' "$REPORT" || true
  exit 1
}

grep -q "PREVIOUS_18_4_CONTROLLED_GATEWAY_RUNTIME_APPLY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ previous 18.4 PASS yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "LIVE_GATEWAY_REACHABLE=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ live gateway reachable YES yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

if grep -q "LIVE_AUTH_MODE=REAL_TOKEN_PROVIDED" "$REPORT"; then
  grep -q "LIVE_REPORTING_ROUTE_ACTIVE=YES" "$REPORT" || {
    echo "TEST_FAIL ❌ real token ile live reporting route active YES yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }

  grep -q "LIVE_REPORTING_ENDPOINT_200_COUNT=6" "$REPORT" || {
    echo "TEST_FAIL ❌ real token ile live reporting endpoint 200 count 6 yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }
else
  grep -q "LIVE_REPORTING_PROTECTED_ROUTE_STATUS=PASS" "$REPORT" || {
    echo "TEST_FAIL ❌ token yokken protected route status PASS yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }

  grep -q "LIVE_REPORTING_AUTH_PROTECTED_401_COUNT=6" "$REPORT" || {
    echo "TEST_FAIL ❌ token yokken auth protected 401 count 6 yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }
fi

grep -q "LIVE_AUTH_GATE_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ live auth gate PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

if grep -q "LIVE_AUTH_MODE=REAL_TOKEN_PROVIDED" "$REPORT"; then
  grep -q "LIVE_TENANT_GATE_STATUS=PASS" "$REPORT" || {
    echo "TEST_FAIL ❌ real token ile live tenant gate PASS yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }

  grep -q "LIVE_METHOD_GATE_STATUS=PASS" "$REPORT" || {
    echo "TEST_FAIL ❌ real token ile live method gate PASS yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }
else
  grep -q "LIVE_TENANT_GATE_STATUS=DEFERRED_NO_VALID_TOKEN" "$REPORT" || {
    echo "TEST_FAIL ❌ token yokken tenant gate deferred yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }

  grep -q "LIVE_METHOD_GATE_STATUS=DEFERRED_NO_VALID_TOKEN" "$REPORT" || {
    echo "TEST_FAIL ❌ token yokken method gate deferred yok"
    sed -n '1,520p' "$REPORT" || true
    exit 1
  }
fi

grep -q "QUERY_TEXT_LEAK_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ query text leak check PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "RUNTIME_RESTART_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ runtime restart executed NO yok"
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

if [ ! -f "$RESULTS" ]; then
  echo "TEST_FAIL ❌ endpoint results yok"
  exit 1
fi

if [ ! -f "$MATRIX" ]; then
  echo "TEST_FAIL ❌ smoke matrix yok"
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
  grep -q "$endpoint" "$RESULTS" || {
    echo "TEST_FAIL ❌ endpoint result eksik: $endpoint"
    cat "$RESULTS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$RESULTS" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "Bearer smoke-token" "$REPORT" "$RESULTS" "$MATRIX"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$RESULTS" "$MATRIX"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_LIVE_HTTP_SMOKE_AUTH_TENANT_TEST=PASS ✅"
echo "PHASE4_LIVE_HTTP_SMOKE_ENDPOINTS_TEST=PASS ✅"
echo "PHASE4_LIVE_HTTP_SMOKE_GATES_TEST=PASS ✅"
echo "PHASE4_LIVE_HTTP_SMOKE_NO_RESTART_TEST=PASS ✅"
echo "PHASE4_LIVE_HTTP_SMOKE_SECRET_TEST=PASS ✅"
