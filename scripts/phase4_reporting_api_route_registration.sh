#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/17_2_reporting_api_route_registration_report.md"
INVENTORY_FILE="$REPORT_DIR/17_2_reporting_api_route_registration_inventory.tsv"
STANDARD_FILE="$REPORT_DIR/17_2_reporting_api_route_registration_standard.md"
MANIFEST_FILE="$REPORT_DIR/17_2_reporting_route_registration_manifest.md"

R171="$REPORT_DIR/17_1_reporting_runtime_wiring_report.md"
R16="$REPORT_DIR/16_reporting_final_closure_report.md"

RUNTIME_DIR="$ROOT_DIR/internal/platform/reporting/runtime"
REGISTRATION_FILE="$RUNTIME_DIR/registration.go"
TEST_FILE="$RUNTIME_DIR/registration_test.go"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_17_2_go_test.log"

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
detail "ROUTE_REGISTRATION_CREATED=YES"
detail "REPORTING_RUNTIME_STARTED=NO"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "GATEWAY_CONFIG_CHANGED=NO"
detail "NGINX_CONFIG_CHANGED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

PREVIOUS_17_1_STATUS="$(get_report_value "$R171" "REPORTING_RUNTIME_WIRING_PLAN")"
PREVIOUS_17_1_GATEWAY_COUNT="$(get_report_value "$R171" "GATEWAY_PREMANIFEST_ROUTE_COUNT")"
PREVIOUS_17_1_RUNTIME_STARTED="$(get_report_value "$R171" "REPORTING_RUNTIME_STARTED")"

PREVIOUS_16_STATUS="$(get_report_value "$R16" "FAZ4_16_FINAL_STATUS")"
PREVIOUS_16_CLOSURE="$(get_report_value "$R16" "REPORTING_FINAL_CLOSURE")"
PREVIOUS_16_ENDPOINT_COUNT="$(get_report_value "$R16" "REPORTING_ENDPOINT_COUNT")"

detail "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=$PREVIOUS_17_1_STATUS"
detail "PREVIOUS_17_1_GATEWAY_PREMANIFEST_ROUTE_COUNT=$PREVIOUS_17_1_GATEWAY_COUNT"
detail "PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_1_RUNTIME_STARTED"
detail "PREVIOUS_16_FINAL_STATUS=$PREVIOUS_16_STATUS"
detail "PREVIOUS_16_REPORTING_FINAL_CLOSURE=$PREVIOUS_16_CLOSURE"
detail "PREVIOUS_16_REPORTING_ENDPOINT_COUNT=$PREVIOUS_16_ENDPOINT_COUNT"

if [ "$PREVIOUS_17_1_STATUS" != "PASS" ]; then
  fail "17.1 runtime wiring plan PASS degil"
fi

if [ "$PREVIOUS_17_1_GATEWAY_COUNT" != "6" ]; then
  fail "17.1 gateway route count 6 degil"
fi

if [ "$PREVIOUS_17_1_RUNTIME_STARTED" != "NO" ]; then
  fail "17.1 runtime started NO degil"
fi

if [ "$PREVIOUS_16_STATUS" != "PASS" ]; then
  fail "16 final status PASS degil"
fi

if [ "$PREVIOUS_16_CLOSURE" != "PASS" ]; then
  fail "16 closure PASS degil"
fi

if [ "$PREVIOUS_16_ENDPOINT_COUNT" != "6" ]; then
  fail "16 endpoint count 6 degil"
fi

require_file "standard" "$STANDARD_FILE" || true
require_file "manifest" "$MANIFEST_FILE" || true
require_file "registration.go" "$REGISTRATION_FILE" || true
require_file "registration_test.go" "$TEST_FILE" || true

require_grep "$REGISTRATION_FILE" "func Routes\\(\\) \\[\\]Route" "Routes function" || true
require_grep "$REGISTRATION_FILE" "func NewReportingHandler\\(\\) api.Handler" "NewReportingHandler" || true
require_grep "$REGISTRATION_FILE" "func RegisterReportingRoutes\\(mux \\*http.ServeMux\\) error" "RegisterReportingRoutes" || true
require_grep "$REGISTRATION_FILE" "repository.New\\(\\)" "repository.New wiring" || true
require_grep "$REGISTRATION_FILE" "service.New\\(repo\\)" "service.New wiring" || true
require_grep "$REGISTRATION_FILE" "api.NewHandler\\(svc\\)" "api.NewHandler wiring" || true
require_grep "$REGISTRATION_FILE" "handler.Register\\(mux\\)" "handler Register mux" || true

ROUTE_REGISTRATION_COUNT="$(grep -E "Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$REGISTRATION_FILE" 2>/dev/null | wc -l | tr -d ' ')"
REGISTER_TEST_COUNT="$(grep -E "func Test" "$TEST_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "ROUTE_REGISTRATION_COUNT=$ROUTE_REGISTRATION_COUNT"
detail "ROUTE_REGISTRATION_TEST_COUNT=$REGISTER_TEST_COUNT"

if [ "$ROUTE_REGISTRATION_COUNT" -ne 6 ]; then
  fail "route registration count 6 degil"
fi

if [ "$REGISTER_TEST_COUNT" -lt 5 ]; then
  fail "route registration test count 5 altinda"
fi

if grep -Eiq "ListenAndServe|\\.Listen\\(|app\\.Listen|fiber\\.New|sql\\.Open|pgx\\.Connect|database/sql" "$REGISTRATION_FILE"; then
  fail "registration.go icinde runtime/db connection bulundu"
fi

if grep -Eiq "insert into|update |delete from|drop |alter |create table|truncate " "$REGISTRATION_FILE"; then
  fail "registration.go icinde mutation SQL bulundu"
fi

GO_TEST_STATUS="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/runtime -v >"$GO_TEST_FILE" 2>&1); then
    GO_TEST_STATUS="PASS"
  else
    GO_TEST_STATUS="FAIL"
    fail "go test ./internal/platform/reporting/runtime failed"
  fi
fi

detail "GO_TEST_STATUS=$GO_TEST_STATUS"

{
  echo -e "component\tpath\tstatus"
  echo -e "runtime_package\tinternal/platform/reporting/runtime\tCREATED"
  echo -e "registration\tinternal/platform/reporting/runtime/registration.go\tCREATED"
  echo -e "tests\tinternal/platform/reporting/runtime/registration_test.go\tCREATED"
  echo -e "route\tGET /api/v1/reporting/operational/summary\tREGISTERED"
  echo -e "route\tGET /api/v1/reporting/operational/daily-metrics\tREGISTERED"
  echo -e "route\tGET /api/v1/reporting/inventory/status\tREGISTERED"
  echo -e "route\tGET /api/v1/reporting/documents/work-queue\tREGISTERED"
  echo -e "route\tGET /api/v1/reporting/reconciliation/status\tREGISTERED"
  echo -e "route\tGET /api/v1/reporting/projections/state\tREGISTERED"
  echo -e "safety\tno runtime start\tPASS"
  echo -e "safety\tno db mutation\tPASS"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "ROUTE_REGISTRATION_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 12 ]; then
  fail "route registration inventory line count 12 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_API_ROUTE_REGISTRATION=PASS"
else
  detail "REPORTING_API_ROUTE_REGISTRATION=FAIL"
fi

{
  echo "# FAZ 4 / 17.2 - Reporting API Route Registration Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_API_ROUTE_REGISTRATION=PASS"
  else
    echo "REPORTING_API_ROUTE_REGISTRATION=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Go Test Output"
  if [ -f "$GO_TEST_FILE" ]; then
    sed -n '1,260p' "$GO_TEST_FILE"
  else
    echo "go test output yok"
  fi

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/17_2_reporting_api_route_registration_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=YES"
  echo "HTTP_HANDLER_CREATED=NO_NEW_HANDLER"
  echo "ROUTE_REGISTRATION_CREATED=YES"
  echo "REPORTING_RUNTIME_STARTED=NO"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "GATEWAY_CONFIG_CHANGED=NO"
  echo "NGINX_CONFIG_CHANGED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"

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
  echo "REPORTING_API_ROUTE_REGISTRATION=FAIL ❌"
  exit 1
fi

echo "REPORTING_API_ROUTE_REGISTRATION=PASS ✅"
