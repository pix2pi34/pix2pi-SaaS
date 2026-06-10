#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/16_3_reporting_service_layer_report.md"
INVENTORY_FILE="$REPORT_DIR/16_3_reporting_service_inventory.tsv"

PREV_REPORT="$REPORT_DIR/16_2_readmodel_repository_layer_report.md"
CONTRACT_REPORT="$REPORT_DIR/16_1_reporting_query_contract_report.md"

SERVICE_DIR="$ROOT_DIR/internal/platform/reporting/service"
TYPES_FILE="$SERVICE_DIR/types.go"
SERVICE_FILE="$SERVICE_DIR/service.go"
TEST_FILE="$SERVICE_DIR/service_test.go"

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
detail "SERVICE_RUNTIME_STARTED=NO"
detail "HTTP_HANDLER_CREATED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "SERVICE_DIR=internal/platform/reporting/service"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

PREVIOUS_REPOSITORY_STATUS="$(get_report_value "$PREV_REPORT" "READMODEL_REPOSITORY_LAYER")"
PREVIOUS_REPOSITORY_METHOD_COUNT="$(get_report_value "$PREV_REPORT" "REPOSITORY_METHOD_COUNT")"
PREVIOUS_REPOSITORY_GO_TEST="$(get_report_value "$PREV_REPORT" "GO_TEST_STATUS")"
REPORTING_CONTRACT_STATUS="$(get_report_value "$CONTRACT_REPORT" "REPORTING_QUERY_CONTRACT")"
REPORTING_ENDPOINT_COUNT="$(get_report_value "$CONTRACT_REPORT" "REPORTING_ENDPOINT_COUNT")"

detail "PREVIOUS_16_2_READMODEL_REPOSITORY_LAYER=$PREVIOUS_REPOSITORY_STATUS"
detail "PREVIOUS_16_2_REPOSITORY_METHOD_COUNT=$PREVIOUS_REPOSITORY_METHOD_COUNT"
detail "PREVIOUS_16_2_GO_TEST_STATUS=$PREVIOUS_REPOSITORY_GO_TEST"
detail "PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=$REPORTING_CONTRACT_STATUS"
detail "PREVIOUS_16_1_REPORTING_ENDPOINT_COUNT=$REPORTING_ENDPOINT_COUNT"

if [ "$PREVIOUS_REPOSITORY_STATUS" != "PASS" ]; then
  fail "16.2 readmodel repository layer PASS degil"
fi

if [ "$PREVIOUS_REPOSITORY_METHOD_COUNT" != "6" ]; then
  fail "16.2 repository method count 6 degil"
fi

if [ "$PREVIOUS_REPOSITORY_GO_TEST" != "PASS" ]; then
  fail "16.2 go test PASS degil"
fi

if [ "$REPORTING_CONTRACT_STATUS" != "PASS" ]; then
  fail "16.1 reporting query contract PASS degil"
fi

if [ "$REPORTING_ENDPOINT_COUNT" != "6" ]; then
  fail "16.1 endpoint count 6 degil"
fi

require_file "service types.go" "$TYPES_FILE" || true
require_file "service.go" "$SERVICE_FILE" || true
require_file "service_test.go" "$TEST_FILE" || true

require_grep "$TYPES_FILE" "type ErrorCode string" "ErrorCode type" || true
require_grep "$TYPES_FILE" "type ServiceError struct" "ServiceError struct" || true
require_grep "$TYPES_FILE" "type QueryResponse struct" "QueryResponse struct" || true
require_grep "$TYPES_FILE" "type PageMeta struct" "PageMeta struct" || true

require_grep "$SERVICE_FILE" "type ReadmodelRepository interface" "ReadmodelRepository interface" || true
require_grep "$SERVICE_FILE" "type Service struct" "Service struct" || true
require_grep "$SERVICE_FILE" "func New\\(repo ReadmodelRepository\\) Service" "New service constructor" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) OperationalSummary" "OperationalSummary service method" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) DailyMetrics" "DailyMetrics service method" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) InventoryStatus" "InventoryStatus service method" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) DocumentWorkQueue" "DocumentWorkQueue service method" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) ReconciliationStatus" "ReconciliationStatus service method" || true
require_grep "$SERVICE_FILE" "func \\(s Service\\) ProjectionState" "ProjectionState service method" || true
require_grep "$SERVICE_FILE" "func mapRepositoryError" "error mapping function" || true
require_grep "$SERVICE_FILE" "func normalizePage" "page normalization function" || true

SERVICE_METHOD_COUNT="$(grep -E "func \\(s Service\\) (OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$SERVICE_FILE" 2>/dev/null | wc -l | tr -d ' ')"
SERVICE_REQUEST_DTO_COUNT="$(grep -E "^type (OperationalSummaryRequest|DailyMetricsRequest|InventoryStatusRequest|DocumentWorkQueueRequest|ReconciliationStatusRequest|ProjectionStateRequest) struct" "$TYPES_FILE" 2>/dev/null | wc -l | tr -d ' ')"
SERVICE_ERROR_CODE_COUNT="$(grep -E "ErrorCode[A-Za-z]+[[:space:]]+ErrorCode =" "$TYPES_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "SERVICE_METHOD_COUNT=$SERVICE_METHOD_COUNT"
detail "SERVICE_REQUEST_DTO_COUNT=$SERVICE_REQUEST_DTO_COUNT"
detail "SERVICE_ERROR_CODE_COUNT=$SERVICE_ERROR_CODE_COUNT"

if [ "$SERVICE_METHOD_COUNT" -ne 6 ]; then
  fail "service method count 6 degil"
fi

if [ "$SERVICE_REQUEST_DTO_COUNT" -ne 6 ]; then
  fail "service request DTO count 6 degil"
fi

if [ "$SERVICE_ERROR_CODE_COUNT" -lt 5 ]; then
  fail "service error code count 5 altinda"
fi

if grep -Eiq "insert into|update |delete from|drop |alter |create |truncate " "$SERVICE_FILE"; then
  fail "service.go icinde mutation SQL bulundu"
fi

if grep -Eiq "http\\.Handle|fiber\\.|Listen\\(|app\\.Get|router\\.Get" "$SERVICE_FILE" "$TYPES_FILE"; then
  fail "service layer icinde HTTP/runtime handler bulundu"
fi

GO_TEST_STATUS="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/service -v >/tmp/pix2pi_16_3_go_test.log 2>&1); then
    GO_TEST_STATUS="PASS"
  else
    GO_TEST_STATUS="FAIL"
    fail "go test ./internal/platform/reporting/service failed"
  fi
fi

detail "GO_TEST_STATUS=$GO_TEST_STATUS"

{
  echo -e "component\tpath\tstatus"
  echo -e "types\tinternal/platform/reporting/service/types.go\tCREATED"
  echo -e "service\tinternal/platform/reporting/service/service.go\tCREATED"
  echo -e "tests\tinternal/platform/reporting/service/service_test.go\tCREATED"
  echo -e "method\tOperationalSummary\tCREATED"
  echo -e "method\tDailyMetrics\tCREATED"
  echo -e "method\tInventoryStatus\tCREATED"
  echo -e "method\tDocumentWorkQueue\tCREATED"
  echo -e "method\tReconciliationStatus\tCREATED"
  echo -e "method\tProjectionState\tCREATED"
  echo -e "contract\tReadmodelRepository interface\tCREATED"
  echo -e "contract\tServiceError code mapping\tCREATED"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "SERVICE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 12 ]; then
  fail "service inventory line count 12 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_SERVICE_LAYER=PASS"
else
  detail "REPORTING_SERVICE_LAYER=FAIL"
fi

{
  echo "# FAZ 4 / 16.3 - Reporting Service Layer Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_SERVICE_LAYER=PASS"
  else
    echo "REPORTING_SERVICE_LAYER=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Go Test Output"
  if [ -f /tmp/pix2pi_16_3_go_test.log ]; then
    sed -n '1,260p' /tmp/pix2pi_16_3_go_test.log
  else
    echo "go test output yok"
  fi

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/16_3_reporting_service_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=YES"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "HTTP_HANDLER_CREATED=NO"
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
  echo "REPORTING_SERVICE_LAYER=FAIL ❌"
  exit 1
fi

echo "REPORTING_SERVICE_LAYER=PASS ✅"
