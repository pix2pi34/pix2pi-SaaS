#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/17_1_reporting_runtime_wiring_plan_standard.md"
PLAN_FILE="$REPORT_DIR/17_1_reporting_runtime_wiring_plan.md"
ENTRY_CONTRACT_FILE="$REPORT_DIR/17_1_reporting_service_entry_contract.md"
GATEWAY_PREMANIFEST_FILE="$REPORT_DIR/17_1_reporting_gateway_route_premanifest.md"
INVENTORY_FILE="$REPORT_DIR/17_1_reporting_runtime_wiring_inventory.tsv"
REPORT_FILE="$REPORT_DIR/17_1_reporting_runtime_wiring_report.md"

R16_CLOSURE="$REPORT_DIR/16_reporting_final_closure_report.md"
R164="$REPORT_DIR/16_4_reporting_api_endpoint_skeleton_report.md"
R165="$REPORT_DIR/16_5_reporting_query_smoke_final_closure_report.md"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
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

count_reporting_routes() {
  local file="$1"
  grep -E "^\| [0-9]+ \| GET \| /api/v1/reporting/" "$file" 2>/dev/null | wc -l | tr -d ' '
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=NO"
detail "HTTP_HANDLER_CREATED=NO_IN_17_1"
detail "REPORTING_RUNTIME_STARTED=NO"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "GATEWAY_CONFIG_CHANGED=NO"
detail "NGINX_CONFIG_CHANGED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

require_file "standard" "$STANDARD_FILE" || true
require_file "runtime wiring plan" "$PLAN_FILE" || true
require_file "service entry contract" "$ENTRY_CONTRACT_FILE" || true
require_file "gateway premanifest" "$GATEWAY_PREMANIFEST_FILE" || true
require_file "16 final closure" "$R16_CLOSURE" || true
require_file "16.4 api skeleton report" "$R164" || true
require_file "16.5 smoke closure report" "$R165" || true

R16_FINAL="$(get_report_value "$R16_CLOSURE" "FAZ4_16_FINAL_STATUS")"
R16_CLOSURE_STATUS="$(get_report_value "$R16_CLOSURE" "REPORTING_FINAL_CLOSURE")"
R16_ENDPOINT_COUNT="$(get_report_value "$R16_CLOSURE" "REPORTING_ENDPOINT_COUNT")"
R16_GO_TEST="$(get_report_value "$R16_CLOSURE" "REPORTING_GO_TEST_SUITE")"

R164_STATUS="$(get_report_value "$R164" "REPORTING_API_ENDPOINT_SKELETON")"
R164_ENDPOINT_COUNT="$(get_report_value "$R164" "API_ENDPOINT_COUNT")"
R164_ROUTE_COUNT="$(get_report_value "$R164" "HANDLER_ROUTE_CASE_COUNT")"

R165_STATUS="$(get_report_value "$R165" "REPORTING_QUERY_SMOKE")"
R165_READ_SMOKE_PASS="$(get_report_value "$R165" "READMODEL_READ_SMOKE_PASS_COUNT")"
R165_READ_SMOKE_FAIL="$(get_report_value "$R165" "READMODEL_READ_SMOKE_FAIL_COUNT")"

detail "PREVIOUS_16_FINAL_STATUS=$R16_FINAL"
detail "PREVIOUS_16_REPORTING_FINAL_CLOSURE=$R16_CLOSURE_STATUS"
detail "PREVIOUS_16_REPORTING_ENDPOINT_COUNT=$R16_ENDPOINT_COUNT"
detail "PREVIOUS_16_REPORTING_GO_TEST_SUITE=$R16_GO_TEST"

detail "PREVIOUS_16_4_API_ENDPOINT_SKELETON=$R164_STATUS"
detail "PREVIOUS_16_4_API_ENDPOINT_COUNT=$R164_ENDPOINT_COUNT"
detail "PREVIOUS_16_4_HANDLER_ROUTE_CASE_COUNT=$R164_ROUTE_COUNT"

detail "PREVIOUS_16_5_REPORTING_QUERY_SMOKE=$R165_STATUS"
detail "PREVIOUS_16_5_READ_SMOKE_PASS_COUNT=$R165_READ_SMOKE_PASS"
detail "PREVIOUS_16_5_READ_SMOKE_FAIL_COUNT=$R165_READ_SMOKE_FAIL"

if [ "$R16_FINAL" != "PASS" ]; then fail "16 final status PASS degil"; fi
if [ "$R16_CLOSURE_STATUS" != "PASS" ]; then fail "16 reporting final closure PASS degil"; fi
if [ "$R16_ENDPOINT_COUNT" != "6" ]; then fail "16 endpoint count 6 degil"; fi
if [ "$R16_GO_TEST" != "PASS" ]; then fail "16 reporting go test suite PASS degil"; fi

if [ "$R164_STATUS" != "PASS" ]; then fail "16.4 api endpoint skeleton PASS degil"; fi
if [ "$R164_ENDPOINT_COUNT" != "6" ]; then fail "16.4 api endpoint count 6 degil"; fi
if [ "$R164_ROUTE_COUNT" != "6" ]; then fail "16.4 handler route count 6 degil"; fi

if [ "$R165_STATUS" != "PASS" ]; then fail "16.5 reporting query smoke PASS degil"; fi
if [ "$R165_READ_SMOKE_PASS" != "6" ]; then fail "16.5 read smoke pass count 6 degil"; fi
if [ "$R165_READ_SMOKE_FAIL" != "0" ]; then fail "16.5 read smoke fail count 0 degil"; fi

require_grep "$PLAN_FILE" "repository.New\\(\\)" "repository.New wiring" || true
require_grep "$PLAN_FILE" "service.New\\(repository\\)" "service.New wiring text" || true
require_grep "$PLAN_FILE" "api.NewHandler\\(service\\)" "api.NewHandler wiring text" || true
require_grep "$PLAN_FILE" "handler.Register\\(mux/router\\)" "handler register wiring text" || true
require_grep "$PLAN_FILE" "RUNTIME_STARTED=NO" "runtime not started" || true

require_grep "$ENTRY_CONTRACT_FILE" "repo := repository.New\\(\\)" "entry repo contract" || true
require_grep "$ENTRY_CONTRACT_FILE" "svc  := service.New\\(repo\\)" "entry service contract" || true
require_grep "$ENTRY_CONTRACT_FILE" "h    := api.NewHandler\\(svc\\)" "entry handler contract" || true
require_grep "$ENTRY_CONTRACT_FILE" "h.Register\\(mux\\)" "entry register contract" || true
require_grep "$ENTRY_CONTRACT_FILE" "REPORTING_API_ENABLED" "runtime config contract" || true

require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/operational/summary" "gateway summary route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/operational/daily-metrics" "gateway daily metrics route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/inventory/status" "gateway inventory route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/documents/work-queue" "gateway work queue route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/reconciliation/status" "gateway reconciliation route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "/api/v1/reporting/projections/state" "gateway projection route" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "Bearer required" "gateway bearer required" || true
require_grep "$GATEWAY_PREMANIFEST_FILE" "X-Tenant-ID required" "gateway tenant required" || true

GATEWAY_PREMANIFEST_ROUTE_COUNT="$(count_reporting_routes "$GATEWAY_PREMANIFEST_FILE")"
detail "GATEWAY_PREMANIFEST_ROUTE_COUNT=$GATEWAY_PREMANIFEST_ROUTE_COUNT"

if [ "$GATEWAY_PREMANIFEST_ROUTE_COUNT" -ne 6 ]; then
  fail "gateway premanifest route count 6 degil"
fi

{
  echo -e "artifact\tpath\tstatus"
  echo -e "standard\tdocs/phase4/17_1_reporting_runtime_wiring_plan_standard.md\tCREATED"
  echo -e "runtime_plan\tdocs/phase4/17_1_reporting_runtime_wiring_plan.md\tCREATED"
  echo -e "service_entry_contract\tdocs/phase4/17_1_reporting_service_entry_contract.md\tCREATED"
  echo -e "gateway_premanifest\tdocs/phase4/17_1_reporting_gateway_route_premanifest.md\tCREATED"
  echo -e "route\tGET /api/v1/reporting/operational/summary\tPLANNED"
  echo -e "route\tGET /api/v1/reporting/operational/daily-metrics\tPLANNED"
  echo -e "route\tGET /api/v1/reporting/inventory/status\tPLANNED"
  echo -e "route\tGET /api/v1/reporting/documents/work-queue\tPLANNED"
  echo -e "route\tGET /api/v1/reporting/reconciliation/status\tPLANNED"
  echo -e "route\tGET /api/v1/reporting/projections/state\tPLANNED"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "REPORTING_RUNTIME_WIRING_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 11 ]; then
  fail "runtime wiring inventory line count 11 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_RUNTIME_WIRING_PLAN=PASS"
  detail "REPORTING_SERVICE_ENTRY_CONTRACT=PASS"
  detail "REPORTING_GATEWAY_PREMANIFEST=PASS"
else
  detail "REPORTING_RUNTIME_WIRING_PLAN=FAIL"
  detail "REPORTING_SERVICE_ENTRY_CONTRACT=FAIL"
  detail "REPORTING_GATEWAY_PREMANIFEST=FAIL"
fi

{
  echo "# FAZ 4 / 17.1 - Reporting Runtime Wiring Plan Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_RUNTIME_WIRING_PLAN=PASS"
  else
    echo "REPORTING_RUNTIME_WIRING_PLAN=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/17_1_reporting_runtime_wiring_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=NO"
  echo "HTTP_HANDLER_CREATED=NO_IN_17_1"
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

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REPORTING_RUNTIME_WIRING_PLAN=FAIL ❌"
  exit 1
fi

echo "REPORTING_RUNTIME_WIRING_PLAN=PASS ✅"
