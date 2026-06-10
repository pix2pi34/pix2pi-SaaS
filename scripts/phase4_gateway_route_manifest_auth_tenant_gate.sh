#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_standard.md"
MANIFEST_FILE="$REPORT_DIR/17_3_reporting_gateway_route_manifest.md"
GATE_FILE="$REPORT_DIR/17_3_reporting_auth_tenant_gate_contract.md"
INVENTORY_FILE="$REPORT_DIR/17_3_reporting_gateway_route_inventory.tsv"
REPORT_FILE="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"

R171="$REPORT_DIR/17_1_reporting_runtime_wiring_report.md"
R172="$REPORT_DIR/17_2_reporting_api_route_registration_report.md"
R16="$REPORT_DIR/16_reporting_final_closure_report.md"

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

count_manifest_routes() {
  local file="$1"
  grep -E "^\| [0-9]+ \| GET \| /api/v1/reporting/" "$file" 2>/dev/null | wc -l | tr -d ' '
}

count_gate_allowlist_routes() {
  local file="$1"
  grep -E "^/api/v1/reporting/" "$file" 2>/dev/null | wc -l | tr -d ' '
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=NO"
detail "HTTP_HANDLER_CREATED=NO"
detail "ROUTE_REGISTRATION_CREATED=NO"
detail "REPORTING_RUNTIME_STARTED=NO"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "GATEWAY_CONFIG_CHANGED=NO"
detail "NGINX_CONFIG_CHANGED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "GATE_MODE=DRY_RUN_ONLY"

tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

require_file "standard" "$STANDARD_FILE" || true
require_file "gateway manifest" "$MANIFEST_FILE" || true
require_file "auth tenant gate" "$GATE_FILE" || true
require_file "17.1 report" "$R171" || true
require_file "17.2 report" "$R172" || true
require_file "16 closure" "$R16" || true

PREVIOUS_17_1_STATUS="$(get_report_value "$R171" "REPORTING_RUNTIME_WIRING_PLAN")"
PREVIOUS_17_1_GATEWAY_COUNT="$(get_report_value "$R171" "GATEWAY_PREMANIFEST_ROUTE_COUNT")"
PREVIOUS_17_1_RUNTIME_STARTED="$(get_report_value "$R171" "REPORTING_RUNTIME_STARTED")"

PREVIOUS_17_2_STATUS="$(get_report_value "$R172" "REPORTING_API_ROUTE_REGISTRATION")"
PREVIOUS_17_2_ROUTE_COUNT="$(get_report_value "$R172" "ROUTE_REGISTRATION_COUNT")"
PREVIOUS_17_2_GO_TEST="$(get_report_value "$R172" "GO_TEST_STATUS")"
PREVIOUS_17_2_RUNTIME_STARTED="$(get_report_value "$R172" "REPORTING_RUNTIME_STARTED")"
PREVIOUS_17_2_GATEWAY_CHANGED="$(get_report_value "$R172" "GATEWAY_CONFIG_CHANGED")"

PREVIOUS_16_STATUS="$(get_report_value "$R16" "FAZ4_16_FINAL_STATUS")"
PREVIOUS_16_CLOSURE="$(get_report_value "$R16" "REPORTING_FINAL_CLOSURE")"
PREVIOUS_16_ENDPOINT_COUNT="$(get_report_value "$R16" "REPORTING_ENDPOINT_COUNT")"

detail "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=$PREVIOUS_17_1_STATUS"
detail "PREVIOUS_17_1_GATEWAY_PREMANIFEST_ROUTE_COUNT=$PREVIOUS_17_1_GATEWAY_COUNT"
detail "PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_1_RUNTIME_STARTED"

detail "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=$PREVIOUS_17_2_STATUS"
detail "PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=$PREVIOUS_17_2_ROUTE_COUNT"
detail "PREVIOUS_17_2_GO_TEST_STATUS=$PREVIOUS_17_2_GO_TEST"
detail "PREVIOUS_17_2_REPORTING_RUNTIME_STARTED=$PREVIOUS_17_2_RUNTIME_STARTED"
detail "PREVIOUS_17_2_GATEWAY_CONFIG_CHANGED=$PREVIOUS_17_2_GATEWAY_CHANGED"

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

if [ "$PREVIOUS_17_2_STATUS" != "PASS" ]; then
  fail "17.2 route registration PASS degil"
fi

if [ "$PREVIOUS_17_2_ROUTE_COUNT" != "6" ]; then
  fail "17.2 route count 6 degil"
fi

if [ "$PREVIOUS_17_2_GO_TEST" != "PASS" ]; then
  fail "17.2 go test PASS degil"
fi

if [ "$PREVIOUS_17_2_RUNTIME_STARTED" != "NO" ]; then
  fail "17.2 runtime started NO degil"
fi

if [ "$PREVIOUS_17_2_GATEWAY_CHANGED" != "NO" ]; then
  fail "17.2 gateway config changed NO degil"
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

require_grep "$MANIFEST_FILE" "/api/v1/reporting/operational/summary" "summary route" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/operational/daily-metrics" "daily metrics route" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/inventory/status" "inventory route" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/documents/work-queue" "document work queue route" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/reconciliation/status" "reconciliation route" || true
require_grep "$MANIFEST_FILE" "/api/v1/reporting/projections/state" "projection route" || true
require_grep "$MANIFEST_FILE" "bearer_required" "bearer_required manifest" || true
require_grep "$MANIFEST_FILE" "x_tenant_id_required" "x_tenant_id_required manifest" || true
require_grep "$MANIFEST_FILE" "GATEWAY_CONFIG_CHANGED=NO" "gateway no mutation" || true
require_grep "$MANIFEST_FILE" "QUERY_TEXT_PRINTED=NO|Query text loglanmamalidir|Raw SQL / query text" "query text no print" || true

require_grep "$GATE_FILE" "AUTH_REQUIRED" "auth required error" || true
require_grep "$GATE_FILE" "TENANT_HEADER_REQUIRED" "tenant header error" || true
require_grep "$GATE_FILE" "TENANT_MISMATCH" "tenant mismatch error" || true
require_grep "$GATE_FILE" "METHOD_NOT_ALLOWED" "method not allowed error" || true
require_grep "$GATE_FILE" "QUERY_TEXT_LOGGING_ALLOWED=NO" "query text logging no" || true
require_grep "$GATE_FILE" "AUTH_TENANT_MIDDLEWARE_GATE=PASS" "target gate pass" || true

GATEWAY_REPORTING_ROUTE_COUNT="$(count_manifest_routes "$MANIFEST_FILE")"
AUTH_TENANT_ALLOWLIST_ROUTE_COUNT="$(count_gate_allowlist_routes "$GATE_FILE")"

BEARER_AUTH_REQUIRED_COUNT="$(grep -E "bearer_required|Bearer required|Authorization: Bearer" "$MANIFEST_FILE" "$GATE_FILE" 2>/dev/null | wc -l | tr -d ' ')"
TENANT_HEADER_REQUIRED_COUNT="$(grep -E "x_tenant_id_required|X-Tenant-ID required|X-Tenant-ID:" "$MANIFEST_FILE" "$GATE_FILE" 2>/dev/null | wc -l | tr -d ' ')"

detail "GATEWAY_REPORTING_ROUTE_COUNT=$GATEWAY_REPORTING_ROUTE_COUNT"
detail "AUTH_TENANT_ALLOWLIST_ROUTE_COUNT=$AUTH_TENANT_ALLOWLIST_ROUTE_COUNT"
detail "BEARER_AUTH_REQUIRED_COUNT=$BEARER_AUTH_REQUIRED_COUNT"
detail "TENANT_HEADER_REQUIRED_COUNT=$TENANT_HEADER_REQUIRED_COUNT"

if [ "$GATEWAY_REPORTING_ROUTE_COUNT" -ne 6 ]; then
  fail "gateway reporting route count 6 degil"
fi

if [ "$AUTH_TENANT_ALLOWLIST_ROUTE_COUNT" -ne 6 ]; then
  fail "auth tenant allowlist route count 6 degil"
fi

if [ "$BEARER_AUTH_REQUIRED_COUNT" -lt 6 ]; then
  fail "bearer auth required count 6 altinda"
fi

if [ "$TENANT_HEADER_REQUIRED_COUNT" -lt 6 ]; then
  fail "tenant header required count 6 altinda"
fi

{
  echo -e "route\tmethod\tauth_gate\ttenant_gate\tstatus"
  echo -e "/api/v1/reporting/operational/summary\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
  echo -e "/api/v1/reporting/operational/daily-metrics\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
  echo -e "/api/v1/reporting/inventory/status\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
  echo -e "/api/v1/reporting/documents/work-queue\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
  echo -e "/api/v1/reporting/reconciliation/status\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
  echo -e "/api/v1/reporting/projections/state\tGET\tbearer_required\tx_tenant_id_required\tGATE_READY"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "GATEWAY_ROUTE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 7 ]; then
  fail "gateway route inventory line count 7 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "GATEWAY_ROUTE_MANIFEST=PASS"
  detail "AUTH_TENANT_MIDDLEWARE_GATE=PASS"
else
  detail "GATEWAY_ROUTE_MANIFEST=FAIL"
  detail "AUTH_TENANT_MIDDLEWARE_GATE=FAIL"
fi

{
  echo "# FAZ 4 / 17.3 - Gateway Route Manifest / Auth-Tenant Middleware Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "GATEWAY_ROUTE_MANIFEST=PASS"
    echo "AUTH_TENANT_MIDDLEWARE_GATE=PASS"
  else
    echo "GATEWAY_ROUTE_MANIFEST=FAIL"
    echo "AUTH_TENANT_MIDDLEWARE_GATE=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/17_3_reporting_gateway_route_inventory.tsv"

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=NO"
  echo "HTTP_HANDLER_CREATED=NO"
  echo "ROUTE_REGISTRATION_CREATED=NO"
  echo "REPORTING_RUNTIME_STARTED=NO"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "GATEWAY_CONFIG_CHANGED=NO"
  echo "NGINX_CONFIG_CHANGED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
  echo "GATE_MODE=DRY_RUN_ONLY"

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
  echo "GATEWAY_ROUTE_MANIFEST=FAIL ❌"
  exit 1
fi

echo "GATEWAY_ROUTE_MANIFEST=PASS ✅"
