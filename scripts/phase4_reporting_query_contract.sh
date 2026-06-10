#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/16_1_reporting_query_contract_standard.md"
MANIFEST_FILE="$REPORT_DIR/16_1_reporting_query_endpoint_manifest.md"
CONTRACTS_FILE="$REPORT_DIR/16_1_reporting_query_contracts.md"
INVENTORY_FILE="$REPORT_DIR/16_1_reporting_query_endpoint_inventory.tsv"
REPORT_FILE="$REPORT_DIR/16_1_reporting_query_contract_report.md"

READMODEL_CLOSURE="$REPORT_DIR/15_readmodel_final_closure_report.md"

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

endpoint_count() {
  grep -E "^\| [0-9]+ \| GET \| /api/v1/reporting/" "$MANIFEST_FILE" 2>/dev/null | wc -l | tr -d ' '
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

require_file "standard" "$STANDARD_FILE" || true
require_file "endpoint manifest" "$MANIFEST_FILE" || true
require_file "contracts" "$CONTRACTS_FILE" || true
require_file "readmodel final closure" "$READMODEL_CLOSURE" || true

READMODEL_FINAL_STATUS="$(get_report_value "$READMODEL_CLOSURE" "FAZ4_15_FINAL_STATUS")"
READMODEL_FINAL_CLOSURE="$(get_report_value "$READMODEL_CLOSURE" "READMODEL_FINAL_CLOSURE")"
READMODEL_TARGET_TABLE_COUNT="$(get_report_value "$READMODEL_CLOSURE" "READMODEL_TARGET_TABLE_COUNT")"

detail "READMODEL_FINAL_CLOSURE=$READMODEL_FINAL_CLOSURE"
detail "FAZ4_15_FINAL_STATUS=$READMODEL_FINAL_STATUS"
detail "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"

if [ "$READMODEL_FINAL_STATUS" != "PASS" ]; then
  fail "15 readmodel final status PASS degil"
fi

if [ "$READMODEL_FINAL_CLOSURE" != "PASS" ]; then
  fail "readmodel final closure PASS degil"
fi

if [ "$READMODEL_TARGET_TABLE_COUNT" != "6" ]; then
  fail "readmodel target table count 6 degil"
fi

require_grep "$MANIFEST_FILE" "/api/v1/reporting/operational/summary" "operational summary endpoint" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/operational/daily-metrics" "daily metrics endpoint" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/inventory/status" "inventory status endpoint" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/documents/work-queue" "document work queue endpoint" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/reconciliation/status" "reconciliation status endpoint" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/projections/state" "projection state endpoint" || true

require_grep "$MANIFEST_FILE" "Authorization: Bearer JWT" "authorization contract" || true
require_grep "$MANIFEST_FILE" "X-Tenant-ID" "tenant header contract" || true
require_grep "$MANIFEST_FILE" "Cross-tenant query yasak" "cross tenant deny rule" || true

require_grep "$CONTRACTS_FILE" '"status": "ok"' "success envelope" || true
require_grep "$CONTRACTS_FILE" '"status": "error"' "error envelope" || true
require_grep "$CONTRACTS_FILE" "TENANT_MISMATCH" "tenant mismatch error" || true
require_grep "$CONTRACTS_FILE" "REPORTING_CURSOR_INVALID" "cursor invalid error" || true
require_grep "$CONTRACTS_FILE" "limit max: 200" "pagination max limit" || true
require_grep "$CONTRACTS_FILE" "Query text loglanmaz" "query text no log" || true

ENDPOINT_COUNT="$(endpoint_count)"
detail "REPORTING_ENDPOINT_COUNT=$ENDPOINT_COUNT"

if [ "$ENDPOINT_COUNT" -ne 6 ]; then
  fail "reporting endpoint count 6 degil"
fi

{
  echo -e "method\tpath\tsource_table\tpurpose"
  echo -e "GET\t/api/v1/reporting/operational/summary\treadmodel.tenant_operational_snapshot\tTenant operasyon ozet kartlari"
  echo -e "GET\t/api/v1/reporting/operational/daily-metrics\treadmodel.daily_operational_metrics\tGunluk operasyon metrikleri"
  echo -e "GET\t/api/v1/reporting/inventory/status\treadmodel.inventory_status_snapshot\tStok durum snapshotlari"
  echo -e "GET\t/api/v1/reporting/documents/work-queue\treadmodel.document_work_queue\tBelge is kuyrugu"
  echo -e "GET\t/api/v1/reporting/reconciliation/status\treadmodel.reconciliation_status_snapshot\tMutabakat durum snapshotlari"
  echo -e "GET\t/api/v1/reporting/projections/state\treadmodel.projection_state\tProjection state lag kontrolu"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "REPORTING_ENDPOINT_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 7 ]; then
  fail "inventory line count 7 degil"
fi

detail "REPORTING_ENDPOINT_MANIFEST=$([ "$ENDPOINT_COUNT" -eq 6 ] && echo PASS || echo FAIL)"

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_CONTRACTS=PASS"
  detail "REPORTING_QUERY_CONTRACT=PASS"
else
  detail "REPORTING_CONTRACTS=FAIL"
  detail "REPORTING_QUERY_CONTRACT=FAIL"
fi

{
  echo "# FAZ 4 / 16.1 - Reporting Query Contract Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_QUERY_CONTRACT=PASS"
  else
    echo "REPORTING_QUERY_CONTRACT=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/16_1_reporting_query_endpoint_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=NO"
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
  echo "REPORTING_QUERY_CONTRACT=FAIL ❌"
  exit 1
fi

echo "REPORTING_QUERY_CONTRACT=PASS ✅"
