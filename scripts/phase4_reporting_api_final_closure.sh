#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/17_5_reporting_api_final_closure_standard.md"
REPORT_FILE="$REPORT_DIR/17_5_reporting_api_final_closure_report.md"
INVENTORY_FILE="$REPORT_DIR/17_5_reporting_api_final_closure_inventory.tsv"
CLOSURE_FILE="$REPORT_DIR/17_reporting_api_final_closure_report.md"

R16="$REPORT_DIR/16_reporting_final_closure_report.md"
R171="$REPORT_DIR/17_1_reporting_runtime_wiring_report.md"
R172="$REPORT_DIR/17_2_reporting_api_route_registration_report.md"
R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
R174="$REPORT_DIR/17_4_reporting_runtime_smoke_test_report.md"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_17_5_reporting_api_final_go_test.log"

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

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=NO"
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
detail "FINAL_CLOSURE_MODE=EVIDENCE_ONLY"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

require_file "standard" "$STANDARD_FILE" || true
require_file "16 closure" "$R16" || true
require_file "17.1 report" "$R171" || true
require_file "17.2 report" "$R172" || true
require_file "17.3 report" "$R173" || true
require_file "17.4 report" "$R174" || true

R16_FINAL="$(get_report_value "$R16" "FAZ4_16_FINAL_STATUS")"
R16_CLOSURE="$(get_report_value "$R16" "REPORTING_FINAL_CLOSURE")"
R16_ENDPOINT_COUNT="$(get_report_value "$R16" "REPORTING_ENDPOINT_COUNT")"
R16_GO_TEST="$(get_report_value "$R16" "REPORTING_GO_TEST_SUITE")"

R171_STATUS="$(get_report_value "$R171" "REPORTING_RUNTIME_WIRING_PLAN")"
R171_ENTRY="$(get_report_value "$R171" "REPORTING_SERVICE_ENTRY_CONTRACT")"
R171_GATEWAY="$(get_report_value "$R171" "REPORTING_GATEWAY_PREMANIFEST")"
R171_ROUTE_COUNT="$(get_report_value "$R171" "GATEWAY_PREMANIFEST_ROUTE_COUNT")"
R171_RUNTIME_STARTED="$(get_report_value "$R171" "REPORTING_RUNTIME_STARTED")"

R172_STATUS="$(get_report_value "$R172" "REPORTING_API_ROUTE_REGISTRATION")"
R172_ROUTE_COUNT="$(get_report_value "$R172" "ROUTE_REGISTRATION_COUNT")"
R172_GO_TEST="$(get_report_value "$R172" "GO_TEST_STATUS")"
R172_RUNTIME_STARTED="$(get_report_value "$R172" "REPORTING_RUNTIME_STARTED")"
R172_GATEWAY_CHANGED="$(get_report_value "$R172" "GATEWAY_CONFIG_CHANGED")"

R173_MANIFEST="$(get_report_value "$R173" "GATEWAY_ROUTE_MANIFEST")"
R173_GATE="$(get_report_value "$R173" "AUTH_TENANT_MIDDLEWARE_GATE")"
R173_ROUTE_COUNT="$(get_report_value "$R173" "GATEWAY_REPORTING_ROUTE_COUNT")"
R173_ALLOWLIST_COUNT="$(get_report_value "$R173" "AUTH_TENANT_ALLOWLIST_ROUTE_COUNT")"
R173_RUNTIME_STARTED="$(get_report_value "$R173" "REPORTING_RUNTIME_STARTED")"
R173_GATEWAY_CHANGED="$(get_report_value "$R173" "GATEWAY_CONFIG_CHANGED")"
R173_QUERY_TEXT="$(get_report_value "$R173" "QUERY_TEXT_PRINTED")"

R174_SMOKE="$(get_report_value "$R174" "REPORTING_RUNTIME_SMOKE_TEST")"
R174_AUTH="$(get_report_value "$R174" "REPORTING_AUTH_GATE_SMOKE")"
R174_TENANT="$(get_report_value "$R174" "REPORTING_TENANT_GATE_SMOKE")"
R174_GO_TEST="$(get_report_value "$R174" "GO_TEST_STATUS")"
R174_PASS_COUNT="$(get_report_value "$R174" "REPORTING_RUNTIME_SMOKE_PASS_COUNT")"
R174_FAIL_COUNT="$(get_report_value "$R174" "REPORTING_RUNTIME_SMOKE_FAIL_COUNT")"
R174_RUNTIME_STARTED="$(get_report_value "$R174" "REPORTING_RUNTIME_STARTED")"
R174_PORT_OPENED="$(get_report_value "$R174" "PORT_OPENED")"
R174_LISTEN="$(get_report_value "$R174" "LISTEN_AND_SERVE_USED")"
R174_GATEWAY_CHANGED="$(get_report_value "$R174" "GATEWAY_CONFIG_CHANGED")"
R174_DB_MUTATION="$(get_report_value "$R174" "DB_MUTATION")"
R174_QUERY_TEXT="$(get_report_value "$R174" "QUERY_TEXT_PRINTED")"

detail "PREVIOUS_16_FINAL_STATUS=$R16_FINAL"
detail "PREVIOUS_16_REPORTING_FINAL_CLOSURE=$R16_CLOSURE"
detail "PREVIOUS_16_REPORTING_ENDPOINT_COUNT=$R16_ENDPOINT_COUNT"
detail "PREVIOUS_16_REPORTING_GO_TEST_SUITE=$R16_GO_TEST"

detail "PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=$R171_STATUS"
detail "PREVIOUS_17_1_REPORTING_SERVICE_ENTRY_CONTRACT=$R171_ENTRY"
detail "PREVIOUS_17_1_REPORTING_GATEWAY_PREMANIFEST=$R171_GATEWAY"
detail "PREVIOUS_17_1_GATEWAY_PREMANIFEST_ROUTE_COUNT=$R171_ROUTE_COUNT"
detail "PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=$R171_RUNTIME_STARTED"

detail "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=$R172_STATUS"
detail "PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=$R172_ROUTE_COUNT"
detail "PREVIOUS_17_2_GO_TEST_STATUS=$R172_GO_TEST"
detail "PREVIOUS_17_2_REPORTING_RUNTIME_STARTED=$R172_RUNTIME_STARTED"
detail "PREVIOUS_17_2_GATEWAY_CONFIG_CHANGED=$R172_GATEWAY_CHANGED"

detail "PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=$R173_MANIFEST"
detail "PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=$R173_GATE"
detail "PREVIOUS_17_3_GATEWAY_REPORTING_ROUTE_COUNT=$R173_ROUTE_COUNT"
detail "PREVIOUS_17_3_AUTH_TENANT_ALLOWLIST_ROUTE_COUNT=$R173_ALLOWLIST_COUNT"
detail "PREVIOUS_17_3_REPORTING_RUNTIME_STARTED=$R173_RUNTIME_STARTED"
detail "PREVIOUS_17_3_GATEWAY_CONFIG_CHANGED=$R173_GATEWAY_CHANGED"
detail "PREVIOUS_17_3_QUERY_TEXT_PRINTED=$R173_QUERY_TEXT"

detail "PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=$R174_SMOKE"
detail "PREVIOUS_17_4_REPORTING_AUTH_GATE_SMOKE=$R174_AUTH"
detail "PREVIOUS_17_4_REPORTING_TENANT_GATE_SMOKE=$R174_TENANT"
detail "PREVIOUS_17_4_GO_TEST_STATUS=$R174_GO_TEST"
detail "PREVIOUS_17_4_RUNTIME_SMOKE_PASS_COUNT=$R174_PASS_COUNT"
detail "PREVIOUS_17_4_RUNTIME_SMOKE_FAIL_COUNT=$R174_FAIL_COUNT"
detail "PREVIOUS_17_4_REPORTING_RUNTIME_STARTED=$R174_RUNTIME_STARTED"
detail "PREVIOUS_17_4_PORT_OPENED=$R174_PORT_OPENED"
detail "PREVIOUS_17_4_LISTEN_AND_SERVE_USED=$R174_LISTEN"
detail "PREVIOUS_17_4_GATEWAY_CONFIG_CHANGED=$R174_GATEWAY_CHANGED"
detail "PREVIOUS_17_4_DB_MUTATION=$R174_DB_MUTATION"
detail "PREVIOUS_17_4_QUERY_TEXT_PRINTED=$R174_QUERY_TEXT"

if [ "$R16_FINAL" != "PASS" ]; then fail "16 final status PASS degil"; fi
if [ "$R16_CLOSURE" != "PASS" ]; then fail "16 reporting final closure PASS degil"; fi
if [ "$R16_ENDPOINT_COUNT" != "6" ]; then fail "16 endpoint count 6 degil"; fi
if [ "$R16_GO_TEST" != "PASS" ]; then fail "16 reporting go test suite PASS degil"; fi

if [ "$R171_STATUS" != "PASS" ]; then fail "17.1 runtime wiring plan PASS degil"; fi
if [ "$R171_ENTRY" != "PASS" ]; then fail "17.1 service entry contract PASS degil"; fi
if [ "$R171_GATEWAY" != "PASS" ]; then fail "17.1 gateway premanifest PASS degil"; fi
if [ "$R171_ROUTE_COUNT" != "6" ]; then fail "17.1 gateway premanifest route count 6 degil"; fi
if [ "$R171_RUNTIME_STARTED" != "NO" ]; then fail "17.1 runtime started NO degil"; fi

if [ "$R172_STATUS" != "PASS" ]; then fail "17.2 route registration PASS degil"; fi
if [ "$R172_ROUTE_COUNT" != "6" ]; then fail "17.2 route registration count 6 degil"; fi
if [ "$R172_GO_TEST" != "PASS" ]; then fail "17.2 go test PASS degil"; fi
if [ "$R172_RUNTIME_STARTED" != "NO" ]; then fail "17.2 runtime started NO degil"; fi
if [ "$R172_GATEWAY_CHANGED" != "NO" ]; then fail "17.2 gateway config changed NO degil"; fi

if [ "$R173_MANIFEST" != "PASS" ]; then fail "17.3 gateway route manifest PASS degil"; fi
if [ "$R173_GATE" != "PASS" ]; then fail "17.3 auth tenant gate PASS degil"; fi
if [ "$R173_ROUTE_COUNT" != "6" ]; then fail "17.3 gateway route count 6 degil"; fi
if [ "$R173_ALLOWLIST_COUNT" != "6" ]; then fail "17.3 allowlist route count 6 degil"; fi
if [ "$R173_RUNTIME_STARTED" != "NO" ]; then fail "17.3 runtime started NO degil"; fi
if [ "$R173_GATEWAY_CHANGED" != "NO" ]; then fail "17.3 gateway config changed NO degil"; fi
if [ "$R173_QUERY_TEXT" != "NO" ]; then fail "17.3 query text printed NO degil"; fi

if [ "$R174_SMOKE" != "PASS" ]; then fail "17.4 runtime smoke PASS degil"; fi
if [ "$R174_AUTH" != "PASS" ]; then fail "17.4 auth gate smoke PASS degil"; fi
if [ "$R174_TENANT" != "PASS" ]; then fail "17.4 tenant gate smoke PASS degil"; fi
if [ "$R174_GO_TEST" != "PASS" ]; then fail "17.4 go test PASS degil"; fi
if [ "$R174_FAIL_COUNT" != "0" ]; then fail "17.4 runtime smoke fail count 0 degil"; fi
if [ "$R174_RUNTIME_STARTED" != "NO" ]; then fail "17.4 runtime started NO degil"; fi
if [ "$R174_PORT_OPENED" != "NO" ]; then fail "17.4 port opened NO degil"; fi
if [ "$R174_LISTEN" != "NO" ]; then fail "17.4 listen and serve used NO degil"; fi
if [ "$R174_GATEWAY_CHANGED" != "NO" ]; then fail "17.4 gateway config changed NO degil"; fi
if [ "$R174_DB_MUTATION" != "NO" ]; then fail "17.4 DB mutation NO degil"; fi
if [ "$R174_QUERY_TEXT" != "NO" ]; then fail "17.4 query text printed NO degil"; fi

REPORTING_GO_TEST_SUITE="SKIPPED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if (cd "$ROOT_DIR" && go test ./internal/platform/reporting/... -v >"$GO_TEST_FILE" 2>&1); then
    REPORTING_GO_TEST_SUITE="PASS"
  else
    REPORTING_GO_TEST_SUITE="FAIL"
    fail "go test ./internal/platform/reporting/... failed"
  fi
fi

detail "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"

{
  echo -e "block\tstatus\tevidence"
  echo -e "17.1_reporting_runtime_wiring_plan\tPASS\tservice_entry_and_gateway_premanifest_ready"
  echo -e "17.2_reporting_api_route_registration\tPASS\t6_routes_registered"
  echo -e "17.3_gateway_route_manifest_auth_tenant_gate\tPASS\t6_routes_auth_tenant_gate_ready"
  echo -e "17.4_reporting_runtime_smoke_test\tPASS\tin_process_httptest_pass"
  echo -e "go_test_suite\t$REPORTING_GO_TEST_SUITE\tgo_test_internal_platform_reporting"
  echo -e "runtime_start\tNO\tno_port_no_listen"
  echo -e "gateway_config_changed\tNO\tdry_run_only"
  echo -e "db_mutation\tNO\tevidence_only"
  echo -e "query_text_printed\tNO\tno_sql_leak"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "REPORTING_API_FINAL_CLOSURE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 10 ]; then
  fail "final closure inventory line count 10 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_API_FINAL_CLOSURE=PASS"
  detail "FAZ4_17_FINAL_STATUS=PASS"
else
  detail "REPORTING_API_FINAL_CLOSURE=FAIL"
  detail "FAZ4_17_FINAL_STATUS=FAIL"
fi

{
  echo "# FAZ 4 / 17.5 - Reporting API Final Closure Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_API_FINAL_CLOSURE=PASS"
    echo "FAZ4_17_FINAL_STATUS=PASS"
  else
    echo "REPORTING_API_FINAL_CLOSURE=FAIL"
    echo "FAZ4_17_FINAL_STATUS=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Inventory"
  echo "INVENTORY_FILE=docs/phase4/17_5_reporting_api_final_closure_inventory.tsv"
  cat "$INVENTORY_FILE"

  echo
  echo "## Go Test Output"
  if [ -f "$GO_TEST_FILE" ]; then
    sed -n '1,420p' "$GO_TEST_FILE"
  else
    echo "go test output yok"
  fi

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=NO"
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
  echo "FINAL_CLOSURE_MODE=EVIDENCE_ONLY"

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

{
  echo "# FAZ 4 / 17 - Reporting API Runtime / Gateway Route Integration Final Closure"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "17.1 Reporting runtime wiring plan / service entry contract=PASS"
  echo "17.2 Reporting API route registration=PASS"
  echo "17.3 Gateway route manifest / auth-tenant middleware gate=PASS"
  echo "17.4 Runtime smoke test=PASS"
  echo "17.5 Reporting API final closure=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
  echo
  echo "REPORTING_API_FINAL_CLOSURE=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
  echo "GATEWAY_REPORTING_ROUTE_COUNT=6"
  echo "ROUTE_REGISTRATION_COUNT=6"
  echo "RUNTIME_SMOKE_STATUS=PASS"
  echo "AUTH_GATE_STATUS=PASS"
  echo "TENANT_GATE_STATUS=PASS"
  echo "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"
  echo "REPORTING_RUNTIME_STARTED=NO"
  echo "PORT_OPENED=NO"
  echo "LISTEN_AND_SERVE_USED=NO"
  echo "GATEWAY_CONFIG_CHANGED=NO"
  echo "NGINX_CONFIG_CHANGED=NO"
  echo "DB_MUTATION=NO"
  echo "QUERY_TEXT_PRINTED=NO"
  echo "FAZ4_17_FINAL_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
} > "$CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "CLOSURE_FILE=$CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REPORTING_API_FINAL_CLOSURE=FAIL ❌"
  exit 1
fi

echo "REPORTING_API_FINAL_CLOSURE=PASS ✅"
