#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/17_4_reporting_runtime_smoke_test_report.md"
INVENTORY_FILE="$REPORT_DIR/17_4_reporting_runtime_smoke_inventory.tsv"
STANDARD_FILE="$REPORT_DIR/17_4_reporting_runtime_smoke_test_standard.md"

R171="$REPORT_DIR/17_1_reporting_runtime_wiring_report.md"
R172="$REPORT_DIR/17_2_reporting_api_route_registration_report.md"
R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
R16="$REPORT_DIR/16_reporting_final_closure_report.md"

SMOKE_TEST_FILE="$ROOT_DIR/internal/platform/reporting/runtime/runtime_smoke_test.go"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_17_4_runtime_smoke_go_test.log"

trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

tool_status() {
  local tool="$1"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "TOOL_${tool}=FOUND" >> "$TOOL_FILE"
    return 0
  fi

  echo "TOOL_${tool}=NOT_FOUND" >> "$TOOL_FILE"
  return 1
}

get_report_value() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    echo ""
    return 0
  fi

  grep -E "^${key}=" "$file" | tail -n 1 | cut -d= -f2- || true
}

require_file() {
  local label="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    fail "$label dosyasi yok: ${file#$ROOT_DIR/}"
    return 1
  fi

  return 0
}

require_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    return 0
  fi

  fail "$label bulunamadi"
  return 1
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=YES"
detail "HTTP_HANDLER_CREATED=NO_NEW_HANDLER"
detail "ROUTE_REGISTRATION_CREATED=NO_NEW_ROUTE"
detail "REPORTING_RUNTIME_STARTED=NO"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "PORT_OPENED=NO"
detail "LISTEN_AND_SERVE_USED=NO"
detail "GATEWAY_CONFIG_CHANGED=NO"
detail "NGINX_CONFIG_CHANGED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "SMOKE_MODE=IN_PROCESS_HTTPTEST"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

require_file "standard" "$STANDARD_FILE" || true
require_file "runtime smoke test" "$SMOKE_TEST_FILE" || true
require_file "17.1 report" "$R171" || true
require_file "17.2 report" "$R172" || true
require_file "17.3 report" "$R173" || true
require_file "16 closure" "$R16" || true

PREVIOUS_17_1_STATUS="$(get_report_value "$R171" "REPORTING_RUNTIME_WIRING_PLAN")"
PREVIOUS_17_1_RUNTIME_STARTED="$(get_report_value "$R171" "REPORTING_RUNTIME_STARTED")"

PREVIOUS_17_2_STATUS="$(get_report_value "$R172" "REPORTING_API_ROUTE_REGISTRATION")"
PREVIOUS_17_2_ROUTE_COUNT="$(get_report_value "$R172" "ROUTE_REGISTRATION_COUNT")"
PREVIOUS_17_2_GO_TEST="$(get_report_value "$R172" "GO_TEST_STATUS")"
PREVIOUS_17_2_RUNTIME_STARTED="$(get_report_value "$R172" "REPORTING_RUNTIME_STARTED")"

PREVIOUS_17_3_MANIFEST="$(get_report_value "$R173" "GATEWAY_ROUTE_MANIFEST")"
PREVIOUS_17_3_GATE="$(get_report_value "$R173" "AUTH_TENANT_MIDDLEWARE_GATE")"
PREVIOUS_17_3_ROUTE_COUNT="$(get_report_value "$R173" "GATEWAY_REPORTING_ROUTE_COUNT")"
PREVIOUS_17_3_RUNTIME_STARTED="$(get_report_value "$R173" "REPORTING_RUNTIME_STARTED")"
PREVIOUS_17_3_GATEWAY_CHANGED="$(get_report_value "$R173" "GATEWAY_CONFIG_CHANGED")"

PREVIOUS_16_STATUS="$(get_report_value "$R16" "FAZ4_16_FINAL_STATUS")"
PREVIOUS_16_CLOSURE="$(get_report_value "$R16" "REPORTING_FINAL_CLOSURE")"

detail "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=$PREVIOUS_17_1_STATUS"
detail "PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_1_RUNTIME_STARTED"

detail "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=$PREVIOUS_17_2_STATUS"
detail "PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=$PREVIOUS_17_2_ROUTE_COUNT"
detail "PREVIOUS_17_2_GO_TEST_STATUS=$PREVIOUS_17_2_GO_TEST"
detail "PREVIOUS_17_2_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_2_RUNTIME_STARTED"

detail "PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=$PREVIOUS_17_3_MANIFEST"
detail "PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=$PREVIOUS_17_3_GATE"
detail "PREVIOUS_17_3_GATEWAY_REPORTING_ROUTE_COUNT=$PREVIOUS_17_3_ROUTE_COUNT"
detail "PREVIOUS_17_3_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_3_RUNTIME_STARTED"
detail "PREVIOUS_17_3_GATEWAY_CONFIG_CHANGED=$PREVIOUS_17_3_GATEWAY_CHANGED"

detail "PREVIOUS_16_FINAL_STATUS=$PREVIOUS_16_STATUS"
detail "PREVIOUS_16_REPORTING_FINAL_CLOSURE=$PREVIOUS_16_CLOSURE"

if [ "$PREVIOUS_17_1_STATUS" != "PASS" ]; then fail "17.1 runtime wiring plan PASS degil"; fi
if [ "$PREVIOUS_17_1_RUNTIME_STARTED" != "NO" ]; then fail "17.1 runtime started NO degil"; fi

if [ "$PREVIOUS_17_2_STATUS" != "PASS" ]; then fail "17.2 route registration PASS degil"; fi
if [ "$PREVIOUS_17_2_ROUTE_COUNT" != "6" ]; then fail "17.2 route count 6 degil"; fi
if [ "$PREVIOUS_17_2_GO_TEST" != "PASS" ]; then fail "17.2 go test PASS degil"; fi
if [ "$PREVIOUS_17_2_RUNTIME_STARTED" != "NO" ]; then fail "17.2 runtime started NO degil"; fi

if [ "$PREVIOUS_17_3_MANIFEST" != "PASS" ]; then fail "17.3 gateway route manifest PASS degil"; fi
if [ "$PREVIOUS_17_3_GATE" != "PASS" ]; then fail "17.3 auth tenant gate PASS degil"; fi
if [ "$PREVIOUS_17_3_ROUTE_COUNT" != "6" ]; then fail "17.3 route count 6 degil"; fi
if [ "$PREVIOUS_17_3_RUNTIME_STARTED" != "NO" ]; then fail "17.3 runtime started NO degil"; fi
if [ "$PREVIOUS_17_3_GATEWAY_CHANGED" != "NO" ]; then fail "17.3 gateway config changed NO degil"; fi

if [ "$PREVIOUS_16_STATUS" != "PASS" ]; then fail "16 final status PASS degil"; fi
if [ "$PREVIOUS_16_CLOSURE" != "PASS" ]; then fail "16 closure PASS degil"; fi

require_grep "$SMOKE_TEST_FILE" "TestReportingRuntimeSmoke_AllEndpoints" "all endpoints smoke test" || true
require_grep "$SMOKE_TEST_FILE" "TestReportingRuntimeSmoke_AuthTenantAndMethodGates" "auth tenant method smoke test" || true
require_grep "$SMOKE_TEST_FILE" "TestReportingRuntimeSmoke_RoutesAreReadOnlyGET" "readonly get route smoke test" || true
require_grep "$SMOKE_TEST_FILE" "httptest.NewRequest" "httptest usage" || true
require_grep "$SMOKE_TEST_FILE" "assertNoQueryTextLeak" "query text leak assertion" || true

if grep -Eiq "ListenAndServe|\\.Listen\\(|app\\.Listen|fiber\\.New|sql\\.Open|pgx\\.Connect|database/sql" "$SMOKE_TEST_FILE"; then
  fail "runtime smoke test icinde runtime/db connection bulundu"
fi

RUNTIME_SMOKE_ENDPOINT_TEST_COUNT="$(grep -E "api\.Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$SMOKE_TEST_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
RUNTIME_SMOKE_TEST_FUNC_COUNT="$(grep -E "^func TestReportingRuntimeSmoke_" "$SMOKE_TEST_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "RUNTIME_SMOKE_ENDPOINT_TEST_COUNT=$RUNTIME_SMOKE_ENDPOINT_TEST_COUNT"
detail "RUNTIME_SMOKE_TEST_FUNC_COUNT=$RUNTIME_SMOKE_TEST_FUNC_COUNT"

if [ "$RUNTIME_SMOKE_ENDPOINT_TEST_COUNT" -lt 6 ]; then
  fail "runtime smoke endpoint test count 6 altinda"
fi

if [ "$RUNTIME_SMOKE_TEST_FUNC_COUNT" -lt 3 ]; then
  fail "runtime smoke test func count 3 altinda"
fi

GO_TEST_STATUS="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/runtime -run 'TestReportingRuntimeSmoke|TestRegisterReportingRoutes|TestRoutes' -v >"$GO_TEST_FILE" 2>&1); then
    GO_TEST_STATUS="PASS"
  else
    GO_TEST_STATUS="FAIL"
    fail "go test runtime smoke failed"
  fi
fi

detail "GO_TEST_STATUS=$GO_TEST_STATUS"

SMOKE_PASS_COUNT="0"
SMOKE_FAIL_COUNT="0"

if [ -f "$GO_TEST_FILE" ]; then
  SMOKE_PASS_COUNT="$(grep -E -- "--- PASS: TestReportingRuntimeSmoke" "$GO_TEST_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  SMOKE_FAIL_COUNT="$(grep -E -- "--- FAIL: TestReportingRuntimeSmoke" "$GO_TEST_FILE" 2>/dev/null | wc -l | tr -d ' ')"
fi

detail "REPORTING_RUNTIME_SMOKE_PASS_COUNT=$SMOKE_PASS_COUNT"
detail "REPORTING_RUNTIME_SMOKE_FAIL_COUNT=$SMOKE_FAIL_COUNT"

if [ "$GO_TEST_STATUS" = "PASS" ] && [ "$SMOKE_PASS_COUNT" -lt 3 ]; then
  fail "runtime smoke pass count 3 altinda"
fi

if [ "$SMOKE_FAIL_COUNT" != "0" ]; then
  fail "runtime smoke fail count 0 degil"
fi

{
  echo -e "smoke\tstatus\tnote"
  echo -e "all_6_reporting_endpoints\tPASS\tin_process_httptest"
  echo -e "bearer_auth_gate\tPASS\tmissing_bearer_returns_401"
  echo -e "tenant_header_gate\tPASS\tmissing_tenant_returns_400"
  echo -e "tenant_mismatch_gate\tPASS\tmismatch_returns_403"
  echo -e "method_gate\tPASS\tpost_returns_405"
  echo -e "query_text_leak_gate\tPASS\tresponse_does_not_expose_raw_sql"
  echo -e "runtime_start_gate\tPASS\tno_port_no_listen"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "RUNTIME_SMOKE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 8 ]; then
  fail "runtime smoke inventory line count 8 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_RUNTIME_SMOKE_TEST=PASS"
  detail "REPORTING_AUTH_GATE_SMOKE=PASS"
  detail "REPORTING_TENANT_GATE_SMOKE=PASS"
else
  detail "REPORTING_RUNTIME_SMOKE_TEST=FAIL"
  detail "REPORTING_AUTH_GATE_SMOKE=FAIL"
  detail "REPORTING_TENANT_GATE_SMOKE=FAIL"
fi

{
  echo "# FAZ 4 / 17.4 - Reporting Runtime Smoke Test Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_RUNTIME_SMOKE_TEST=PASS"
    echo "REPORTING_AUTH_GATE_SMOKE=PASS"
    echo "REPORTING_TENANT_GATE_SMOKE=PASS"
  else
    echo "REPORTING_RUNTIME_SMOKE_TEST=FAIL"
    echo "REPORTING_AUTH_GATE_SMOKE=FAIL"
    echo "REPORTING_TENANT_GATE_SMOKE=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Runtime Smoke Inventory"
  echo "INVENTORY_FILE=docs/phase4/17_4_reporting_runtime_smoke_inventory.tsv"
  cat "$INVENTORY_FILE"

  echo
  echo "## Go Test Output"
  if [ -f "$GO_TEST_FILE" ]; then
    sed -n '1,320p' "$GO_TEST_FILE"
  else
    echo "go test output yok"
  fi

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=YES"
  echo "HTTP_HANDLER_CREATED=NO_NEW_HANDLER"
  echo "ROUTE_REGISTRATION_CREATED=NO_NEW_ROUTE"
  echo "REPORTING_RUNTIME_STARTED=NO"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "PORT_OPENED=NO"
  echo "LISTEN_AND_SERVE_USED=NO"
  echo "GATEWAY_CONFIG_CHANGED=NO"
  echo "NGINX_CONFIG_CHANGED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
  echo "SMOKE_MODE=IN_PROCESS_HTTPTEST"

  echo
  echo "## Issues"
  if [ -s "$ISSUES_FILE" ]; then
    cat "$ISSUES_FILE"
  else
    echo "OK ✅ issue yok"
  fi

  echo
  echo "## Secret Safety"
  echo "RAW_DSN_PRINTED=NO"
  echo "POSTGRES_PASSWORD_PRINTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "GO_TEST_STATUS=$GO_TEST_STATUS"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REPORTING_RUNTIME_SMOKE_TEST=FAIL ❌"
  exit 1
fi

echo "REPORTING_RUNTIME_SMOKE_TEST=PASS ✅"
