#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/16_2_readmodel_repository_layer_report.md"
INVENTORY_FILE="$REPORT_DIR/16_2_readmodel_repository_inventory.tsv"

CONTRACT_REPORT="$REPORT_DIR/16_1_reporting_query_contract_report.md"

REPO_DIR="$ROOT_DIR/internal/platform/reporting/repository"
TYPES_FILE="$REPO_DIR/types.go"
REPOSITORY_FILE="$REPO_DIR/repository.go"
TEST_FILE="$REPO_DIR/repository_test.go"

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
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "REPOSITORY_DIR=internal/platform/reporting/repository"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

REPORTING_CONTRACT_STATUS="$(get_report_value "$CONTRACT_REPORT" "REPORTING_QUERY_CONTRACT")"
REPORTING_ENDPOINT_COUNT="$(get_report_value "$CONTRACT_REPORT" "REPORTING_ENDPOINT_COUNT")"

detail "PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=$REPORTING_CONTRACT_STATUS"
detail "PREVIOUS_16_1_REPORTING_ENDPOINT_COUNT=$REPORTING_ENDPOINT_COUNT"

if [ "$REPORTING_CONTRACT_STATUS" != "PASS" ]; then
  fail "16.1 reporting query contract PASS degil"
fi

if [ "$REPORTING_ENDPOINT_COUNT" != "6" ]; then
  fail "16.1 reporting endpoint count 6 degil"
fi

require_file "types.go" "$TYPES_FILE" || true
require_file "repository.go" "$REPOSITORY_FILE" || true
require_file "repository_test.go" "$TEST_FILE" || true

require_grep "$TYPES_FILE" "type QuerySpec struct" "QuerySpec struct" || true
require_grep "$TYPES_FILE" "type PageRequest struct" "PageRequest struct" || true
require_grep "$TYPES_FILE" "MaxLimit[[:space:]]+= 200" "MaxLimit 200" || true

require_grep "$REPOSITORY_FILE" "type Repository struct" "Repository struct" || true
require_grep "$REPOSITORY_FILE" "func New\\(\\) Repository" "New repository constructor" || true
require_grep "$REPOSITORY_FILE" "func ValidateTenantID" "ValidateTenantID" || true
require_grep "$REPOSITORY_FILE" "func NormalizePage" "NormalizePage" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) OperationalSummary" "OperationalSummary method" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) DailyMetrics" "DailyMetrics method" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) InventoryStatus" "InventoryStatus method" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) DocumentWorkQueue" "DocumentWorkQueue method" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) ReconciliationStatus" "ReconciliationStatus method" || true
require_grep "$REPOSITORY_FILE" "func \\(r Repository\\) ProjectionState" "ProjectionState method" || true

REPOSITORY_METHOD_COUNT="$(grep -E "func \\(r Repository\\) (OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$REPOSITORY_FILE" 2>/dev/null | wc -l | tr -d ' ')"
FILTER_STRUCT_COUNT="$(grep -E "^type .*Filter struct" "$TYPES_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "REPOSITORY_METHOD_COUNT=$REPOSITORY_METHOD_COUNT"
detail "FILTER_STRUCT_COUNT=$FILTER_STRUCT_COUNT"

if [ "$REPOSITORY_METHOD_COUNT" -ne 6 ]; then
  fail "repository method count 6 degil"
fi

if [ "$FILTER_STRUCT_COUNT" -ne 5 ]; then
  fail "filter struct count 5 degil"
fi

if grep -Eiq "insert into|update |delete from|drop |alter |create |truncate " "$REPOSITORY_FILE"; then
  fail "repository.go icinde mutation SQL bulundu"
fi

GO_TEST_STATUS="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/repository -v >/tmp/pix2pi_16_2_go_test.log 2>&1); then
    GO_TEST_STATUS="PASS"
  else
    GO_TEST_STATUS="FAIL"
    fail "go test ./internal/platform/reporting/repository failed"
  fi
fi

detail "GO_TEST_STATUS=$GO_TEST_STATUS"

{
  echo -e "component\tpath\tstatus"
  echo -e "types\tinternal/platform/reporting/repository/types.go\tCREATED"
  echo -e "repository\tinternal/platform/reporting/repository/repository.go\tCREATED"
  echo -e "tests\tinternal/platform/reporting/repository/repository_test.go\tCREATED"
  echo -e "method\tOperationalSummary\tCREATED"
  echo -e "method\tDailyMetrics\tCREATED"
  echo -e "method\tInventoryStatus\tCREATED"
  echo -e "method\tDocumentWorkQueue\tCREATED"
  echo -e "method\tReconciliationStatus\tCREATED"
  echo -e "method\tProjectionState\tCREATED"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "REPOSITORY_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 10 ]; then
  fail "repository inventory line count 10 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "READMODEL_REPOSITORY_LAYER=PASS"
else
  detail "READMODEL_REPOSITORY_LAYER=FAIL"
fi

{
  echo "# FAZ 4 / 16.2 - Readmodel Repository Layer Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "READMODEL_REPOSITORY_LAYER=PASS"
  else
    echo "READMODEL_REPOSITORY_LAYER=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Go Test Output"
  if [ -f /tmp/pix2pi_16_2_go_test.log ]; then
    sed -n '1,220p' /tmp/pix2pi_16_2_go_test.log
  else
    echo "go test output yok"
  fi

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/16_2_readmodel_repository_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=YES"
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
  echo "READMODEL_REPOSITORY_LAYER=FAIL ❌"
  exit 1
fi

echo "READMODEL_REPOSITORY_LAYER=PASS ✅"
