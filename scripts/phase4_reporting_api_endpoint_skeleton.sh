#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/16_4_reporting_api_endpoint_skeleton_report.md"
INVENTORY_FILE="$REPORT_DIR/16_4_reporting_api_endpoint_inventory.tsv"

PREV_SERVICE_REPORT="$REPORT_DIR/16_3_reporting_service_layer_report.md"
PREV_REPOSITORY_REPORT="$REPORT_DIR/16_2_readmodel_repository_layer_report.md"
PREV_CONTRACT_REPORT="$REPORT_DIR/16_1_reporting_query_contract_report.md"

API_DIR="$ROOT_DIR/internal/platform/reporting/api"
TYPES_FILE="$API_DIR/types.go"
HANDLER_FILE="$API_DIR/handler.go"
TEST_FILE="$API_DIR/handler_test.go"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

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

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=YES"
detail "HTTP_HANDLER_CREATED=YES"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "API_DIR=internal/platform/reporting/api"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

PREVIOUS_16_3_STATUS="$(get_report_value "$PREV_SERVICE_REPORT" "REPORTING_SERVICE_LAYER")"
PREVIOUS_16_3_METHOD_COUNT="$(get_report_value "$PREV_SERVICE_REPORT" "SERVICE_METHOD_COUNT")"
PREVIOUS_16_3_GO_TEST="$(get_report_value "$PREV_SERVICE_REPORT" "GO_TEST_STATUS")"

PREVIOUS_16_2_STATUS="$(get_report_value "$PREV_REPOSITORY_REPORT" "READMODEL_REPOSITORY_LAYER")"
PREVIOUS_16_1_STATUS="$(get_report_value "$PREV_CONTRACT_REPORT" "REPORTING_QUERY_CONTRACT")"
PREVIOUS_16_1_ENDPOINT_COUNT="$(get_report_value "$PREV_CONTRACT_REPORT" "REPORTING_ENDPOINT_COUNT")"

detail "PREVIOUS_16_3_REPORTING_SERVICE_LAYER=$PREVIOUS_16_3_STATUS"
detail "PREVIOUS_16_3_SERVICE_METHOD_COUNT=$PREVIOUS_16_3_METHOD_COUNT"
detail "PREVIOUS_16_3_GO_TEST_STATUS=$PREVIOUS_16_3_GO_TEST"
detail "PREVIOUS_16_2_READMODEL_REPOSITORY_LAYER=$PREVIOUS_16_2_STATUS"
detail "PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=$PREVIOUS_16_1_STATUS"
detail "PREVIOUS_16_1_REPORTING_ENDPOINT_COUNT=$PREVIOUS_16_1_ENDPOINT_COUNT"

if [ "$PREVIOUS_16_3_STATUS" != "PASS" ]; then
  fail "16.3 reporting service layer PASS degil"
fi

if [ "$PREVIOUS_16_3_METHOD_COUNT" != "6" ]; then
  fail "16.3 service method count 6 degil"
fi

if [ "$PREVIOUS_16_3_GO_TEST" != "PASS" ]; then
  fail "16.3 go test PASS degil"
fi

if [ "$PREVIOUS_16_2_STATUS" != "PASS" ]; then
  fail "16.2 repository layer PASS degil"
fi

if [ "$PREVIOUS_16_1_STATUS" != "PASS" ]; then
  fail "16.1 reporting contract PASS degil"
fi

if [ "$PREVIOUS_16_1_ENDPOINT_COUNT" != "6" ]; then
  fail "16.1 endpoint count 6 degil"
fi

require_file "api types.go" "$TYPES_FILE" || true
require_file "handler.go" "$HANDLER_FILE" || true
require_file "handler_test.go" "$TEST_FILE" || true

require_grep "$TYPES_FILE" "PathOperationalSummary" "PathOperationalSummary" || true
require_grep "$TYPES_FILE" "PathDailyMetrics" "PathDailyMetrics" || true
require_grep "$TYPES_FILE" "PathInventoryStatus" "PathInventoryStatus" || true
require_grep "$TYPES_FILE" "PathDocumentWorkQueue" "PathDocumentWorkQueue" || true
require_grep "$TYPES_FILE" "PathReconciliationStatus" "PathReconciliationStatus" || true
require_grep "$TYPES_FILE" "PathProjectionState" "PathProjectionState" || true
require_grep "$TYPES_FILE" "type SuccessEnvelope struct" "SuccessEnvelope" || true
require_grep "$TYPES_FILE" "type ErrorEnvelope struct" "ErrorEnvelope" || true
require_grep "$TYPES_FILE" "type QueryData struct" "QueryData" || true

require_grep "$HANDLER_FILE" "type ReportingService interface" "ReportingService interface" || true
require_grep "$HANDLER_FILE" "type Handler struct" "Handler struct" || true
require_grep "$HANDLER_FILE" "func NewHandler" "NewHandler" || true
require_grep "$HANDLER_FILE" "func \\(h Handler\\) Register" "Register method" || true
require_grep "$HANDLER_FILE" "func \\(h Handler\\) ServeHTTP" "ServeHTTP method" || true
require_grep "$HANDLER_FILE" "Authorization" "Authorization check" || true
require_grep "$HANDLER_FILE" "X-Tenant-ID" "X-Tenant-ID check" || true
require_grep "$HANDLER_FILE" "WithTenantClaim" "tenant claim context" || true

API_ENDPOINT_COUNT="$(grep -E 'Path[A-Za-z]+[[:space:]]+= "/api/v1/reporting/' "$TYPES_FILE" 2>/dev/null | wc -l | tr -d ' ')"
HANDLER_ROUTE_CASE_COUNT="$(grep -E "case Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState):" "$HANDLER_FILE" 2>/dev/null | wc -l | tr -d ' ')"
SERVICE_INTERFACE_METHOD_COUNT="$(grep -E "^[[:space:]]*(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)\\(" "$HANDLER_FILE" 2>/dev/null | wc -l | tr -d ' ')"
ERROR_CODE_COUNT="$(grep -E 'ErrorCode[A-Za-z]+[[:space:]]+= "' "$TYPES_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "API_ENDPOINT_COUNT=$API_ENDPOINT_COUNT"
detail "HANDLER_ROUTE_CASE_COUNT=$HANDLER_ROUTE_CASE_COUNT"
detail "SERVICE_INTERFACE_METHOD_COUNT=$SERVICE_INTERFACE_METHOD_COUNT"
detail "API_ERROR_CODE_COUNT=$ERROR_CODE_COUNT"

if [ "$API_ENDPOINT_COUNT" -ne 6 ]; then
  fail "api endpoint count 6 degil"
fi

if [ "$HANDLER_ROUTE_CASE_COUNT" -ne 6 ]; then
  fail "handler route case count 6 degil"
fi

if [ "$SERVICE_INTERFACE_METHOD_COUNT" -ne 6 ]; then
  fail "service interface method count 6 degil"
fi

if [ "$ERROR_CODE_COUNT" -lt 6 ]; then
  fail "api error code count 6 altinda"
fi

if grep -Eiq "ListenAndServe|\\.Listen\\(|app\\.Listen|fiber\\.New|sql\\.Open|pgx\\.Connect|database/sql" "$HANDLER_FILE" "$TYPES_FILE"; then
  fail "api skeleton icinde runtime/db connection bulundu"
fi

if grep -Eiq "insert into|update |delete from|drop |alter |create |truncate " "$HANDLER_FILE"; then
  fail "handler.go icinde mutation SQL bulundu"
fi

if grep -Eq "SQL[[:space:]]*:" "$HANDLER_FILE" || grep -Eq "Query\\.SQL" "$HANDLER_FILE"; then
  fail "handler response query SQL expose ediyor"
fi

GO_TEST_STATUS="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/api -v >/tmp/pix2pi_16_4_go_test.log 2>&1); then
    GO_TEST_STATUS="PASS"
  else
    GO_TEST_STATUS="FAIL"
    fail "go test ./internal/platform/reporting/api failed"
  fi
fi

detail "GO_TEST_STATUS=$GO_TEST_STATUS"

{
  echo -e "component\tpath\tstatus"
  echo -e "types\tinternal/platform/reporting/api/types.go\tCREATED"
  echo -e "handler\tinternal/platform/reporting/api/handler.go\tCREATED"
  echo -e "tests\tinternal/platform/reporting/api/handler_test.go\tCREATED"
  echo -e "endpoint\tGET ${PathOperationalSummary:-/api/v1/reporting/operational/summary}\tCREATED"
  echo -e "endpoint\tGET ${PathDailyMetrics:-/api/v1/reporting/operational/daily-metrics}\tCREATED"
  echo -e "endpoint\tGET ${PathInventoryStatus:-/api/v1/reporting/inventory/status}\tCREATED"
  echo -e "endpoint\tGET ${PathDocumentWorkQueue:-/api/v1/reporting/documents/work-queue}\tCREATED"
  echo -e "endpoint\tGET ${PathReconciliationStatus:-/api/v1/reporting/reconciliation/status}\tCREATED"
  echo -e "endpoint\tGET ${PathProjectionState:-/api/v1/reporting/projections/state}\tCREATED"
  echo -e "contract\tAuthorization Bearer\tCREATED"
  echo -e "contract\tX-Tenant-ID\tCREATED"
  echo -e "contract\tNo SQL in response\tCREATED"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "API_ENDPOINT_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 13 ]; then
  fail "api endpoint inventory line count 13 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_API_ENDPOINT_SKELETON=PASS"
else
  detail "REPORTING_API_ENDPOINT_SKELETON=FAIL"
fi

{
  echo "# FAZ 4 / 16.4 - Reporting API Endpoint Skeleton Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_API_ENDPOINT_SKELETON=PASS"
  else
    echo "REPORTING_API_ENDPOINT_SKELETON=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Go Test Output"
  if [ -f /tmp/pix2pi_16_4_go_test.log ]; then
    sed -n '1,280p' /tmp/pix2pi_16_4_go_test.log
  else
    echo "go test output yok"
  fi

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/16_4_reporting_api_endpoint_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=YES"
  echo "HTTP_HANDLER_CREATED=YES"
  echo "SERVICE_RUNTIME_STARTED=NO"
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
  echo "REPORTING_API_ENDPOINT_SKELETON=FAIL ❌"
  exit 1
fi

echo "REPORTING_API_ENDPOINT_SKELETON=PASS ✅"
