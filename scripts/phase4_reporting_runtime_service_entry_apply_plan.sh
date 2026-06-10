#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/18_2_reporting_runtime_service_entry_apply_plan_standard.md"
REPORT_FILE="$REPORT_DIR/18_2_reporting_runtime_service_entry_apply_plan_report.md"
INVENTORY_FILE="$REPORT_DIR/18_2_reporting_runtime_service_entry_candidate_inventory.tsv"
MATRIX_FILE="$REPORT_DIR/18_2_reporting_runtime_service_entry_apply_matrix.tsv"
EXECUTION_FILE="$REPORT_DIR/18_2_reporting_runtime_service_entry_candidate_execution.sh"

R181="$REPORT_DIR/18_1_gateway_runtime_apply_readiness_report.md"
R17="$REPORT_DIR/17_reporting_api_final_closure_report.md"
R172="$REPORT_DIR/17_2_reporting_api_route_registration_report.md"
R174="$REPORT_DIR/17_4_reporting_runtime_smoke_test_report.md"

RUNTIME_REG_FILE="$ROOT_DIR/internal/platform/reporting/runtime/registration.go"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
CANDIDATE_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_18_2_reporting_apply_plan_go_test.log"

trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$CANDIDATE_FILE"' EXIT

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

path_status() {
  local p="$1"

  if [ -e "$p" ]; then
    echo "FOUND"
  else
    echo "NOT_FOUND"
  fi
}

safe_rel() {
  local p="$1"
  echo "$p" | sed "s#^$ROOT_DIR/##"
}

count_lines() {
  local file="$1"

  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    echo "0"
  fi
}

detail "ROOT_DIR=$ROOT_DIR"
detail "APPLY_EXECUTED=NO"
detail "DB_MUTATION=NO"
detail "DB_MIGRATION_CREATED=NO"
detail "DB_APPLY_EXECUTED=NO"
detail "SERVICE_CODE_CREATED=NO"
detail "HTTP_HANDLER_CREATED=NO"
detail "ROUTE_REGISTRATION_CREATED=NO"
detail "REPORTING_RUNTIME_STARTED=NO"
detail "SERVICE_RUNTIME_STARTED=NO"
detail "PORT_OPENED=NO"
detail "LISTEN_AND_SERVE_USED=NO"
detail "GATEWAY_CONFIG_CHANGED=NO"
detail "NGINX_CONFIG_CHANGED=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "PLAN_MODE=APPLY_PLAN_ONLY"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "find" >/dev/null || true
tool_status "wc" >/dev/null || true
tool_status "sha256sum" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

if [ ! -f "$STANDARD_FILE" ]; then
  fail "standard doc yok"
fi

R181_STATUS="$(get_report_value "$R181" "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY")"
R181_READY="$(get_report_value "$R181" "APPLY_READINESS_STATUS")"
R181_BLOCKERS="$(get_report_value "$R181" "APPLY_READINESS_BLOCKER_COUNT")"
R181_WARNINGS="$(get_report_value "$R181" "APPLY_READINESS_WARN_COUNT")"
R181_GO_TEST="$(get_report_value "$R181" "REPORTING_GO_TEST_SUITE")"
R181_CMD_GATEWAY="$(get_report_value "$R181" "CMD_API_GATEWAY_CANDIDATE_COUNT")"
R181_COMPOSE="$(get_report_value "$R181" "COMPOSE_FILE_COUNT")"
R181_ENV="$(get_report_value "$R181" "ENV_FILE_COUNT")"
R181_NGINX="$(get_report_value "$R181" "NGINX_FILE_COUNT")"
R181_SYSTEMD="$(get_report_value "$R181" "SYSTEMD_PIX2PI_SERVICE_COUNT")"

R17_FINAL="$(get_report_value "$R17" "FAZ4_17_FINAL_STATUS")"
R17_CLOSURE="$(get_report_value "$R17" "REPORTING_API_FINAL_CLOSURE")"
R17_ROUTE_COUNT="$(get_report_value "$R17" "GATEWAY_REPORTING_ROUTE_COUNT")"
R17_RUNTIME_STARTED="$(get_report_value "$R17" "REPORTING_RUNTIME_STARTED")"
R17_GATEWAY_CHANGED="$(get_report_value "$R17" "GATEWAY_CONFIG_CHANGED")"
R17_DB_MUTATION="$(get_report_value "$R17" "DB_MUTATION")"
R17_QUERY_TEXT="$(get_report_value "$R17" "QUERY_TEXT_PRINTED")"

R172_STATUS="$(get_report_value "$R172" "REPORTING_API_ROUTE_REGISTRATION")"
R172_ROUTE_COUNT="$(get_report_value "$R172" "ROUTE_REGISTRATION_COUNT")"

R174_SMOKE="$(get_report_value "$R174" "REPORTING_RUNTIME_SMOKE_TEST")"
R174_AUTH="$(get_report_value "$R174" "REPORTING_AUTH_GATE_SMOKE")"
R174_TENANT="$(get_report_value "$R174" "REPORTING_TENANT_GATE_SMOKE")"

detail "PREVIOUS_18_1_READINESS_DISCOVERY=$R181_STATUS"
detail "PREVIOUS_18_1_APPLY_READINESS_STATUS=$R181_READY"
detail "PREVIOUS_18_1_APPLY_READINESS_BLOCKER_COUNT=$R181_BLOCKERS"
detail "PREVIOUS_18_1_APPLY_READINESS_WARN_COUNT=$R181_WARNINGS"
detail "PREVIOUS_18_1_REPORTING_GO_TEST_SUITE=$R181_GO_TEST"
detail "PREVIOUS_18_1_CMD_API_GATEWAY_CANDIDATE_COUNT=$R181_CMD_GATEWAY"
detail "PREVIOUS_18_1_COMPOSE_FILE_COUNT=$R181_COMPOSE"
detail "PREVIOUS_18_1_ENV_FILE_COUNT=$R181_ENV"
detail "PREVIOUS_18_1_NGINX_FILE_COUNT=$R181_NGINX"
detail "PREVIOUS_18_1_SYSTEMD_PIX2PI_SERVICE_COUNT=$R181_SYSTEMD"

detail "PREVIOUS_17_FINAL_STATUS=$R17_FINAL"
detail "PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=$R17_CLOSURE"
detail "PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT=$R17_ROUTE_COUNT"
detail "PREVIOUS_17_REPORTING_RUNTIME_STARTED=$R17_RUNTIME_STARTED"
detail "PREVIOUS_17_GATEWAY_CONFIG_CHANGED=$R17_GATEWAY_CHANGED"
detail "PREVIOUS_17_DB_MUTATION=$R17_DB_MUTATION"
detail "PREVIOUS_17_QUERY_TEXT_PRINTED=$R17_QUERY_TEXT"

detail "PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=$R172_STATUS"
detail "PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=$R172_ROUTE_COUNT"

detail "PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=$R174_SMOKE"
detail "PREVIOUS_17_4_REPORTING_AUTH_GATE_SMOKE=$R174_AUTH"
detail "PREVIOUS_17_4_REPORTING_TENANT_GATE_SMOKE=$R174_TENANT"

if [ "$R181_STATUS" != "PASS" ]; then fail "18.1 readiness discovery PASS degil"; fi
if [ "$R181_READY" != "READY" ]; then fail "18.1 apply readiness READY degil"; fi
if [ "$R181_BLOCKERS" != "0" ]; then fail "18.1 blocker count 0 degil"; fi
if [ "$R181_GO_TEST" != "PASS" ]; then fail "18.1 reporting go test PASS degil"; fi

if [ "$R17_FINAL" != "PASS" ]; then fail "17 final status PASS degil"; fi
if [ "$R17_CLOSURE" != "PASS" ]; then fail "17 closure PASS degil"; fi
if [ "$R17_ROUTE_COUNT" != "6" ]; then fail "17 route count 6 degil"; fi
if [ "$R17_RUNTIME_STARTED" != "NO" ]; then fail "17 runtime started NO degil"; fi
if [ "$R17_GATEWAY_CHANGED" != "NO" ]; then fail "17 gateway config changed NO degil"; fi
if [ "$R17_DB_MUTATION" != "NO" ]; then fail "17 DB mutation NO degil"; fi
if [ "$R17_QUERY_TEXT" != "NO" ]; then fail "17 query text printed NO degil"; fi

if [ "$R172_STATUS" != "PASS" ]; then fail "17.2 route registration PASS degil"; fi
if [ "$R172_ROUTE_COUNT" != "6" ]; then fail "17.2 route count 6 degil"; fi

if [ "$R174_SMOKE" != "PASS" ]; then fail "17.4 runtime smoke PASS degil"; fi
if [ "$R174_AUTH" != "PASS" ]; then fail "17.4 auth gate PASS degil"; fi
if [ "$R174_TENANT" != "PASS" ]; then fail "17.4 tenant gate PASS degil"; fi

RUNTIME_REG_FILE_STATUS="$(path_status "$RUNTIME_REG_FILE")"
REGISTER_FUNCTION_COUNT="0"
ROUTES_FUNCTION_COUNT="0"
ROUTE_CONSTANT_USAGE_COUNT="0"

if [ -f "$RUNTIME_REG_FILE" ]; then
  REGISTER_FUNCTION_COUNT="$(grep -E "func RegisterReportingRoutes" "$RUNTIME_REG_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  ROUTES_FUNCTION_COUNT="$(grep -E "func Routes\\(\\)" "$RUNTIME_REG_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  ROUTE_CONSTANT_USAGE_COUNT="$(grep -E "Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$RUNTIME_REG_FILE" 2>/dev/null | wc -l | tr -d ' ')"
fi

detail "REPORTING_REGISTRATION_FILE_STATUS=$RUNTIME_REG_FILE_STATUS"
detail "REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=$REGISTER_FUNCTION_COUNT"
detail "REPORTING_ROUTES_FUNCTION_COUNT=$ROUTES_FUNCTION_COUNT"
detail "REPORTING_ROUTE_CONSTANT_USAGE_COUNT=$ROUTE_CONSTANT_USAGE_COUNT"

if [ "$RUNTIME_REG_FILE_STATUS" != "FOUND" ]; then fail "runtime registration file yok"; fi
if [ "$REGISTER_FUNCTION_COUNT" -lt 1 ]; then fail "RegisterReportingRoutes yok"; fi
if [ "$ROUTES_FUNCTION_COUNT" -lt 1 ]; then fail "Routes fonksiyonu yok"; fi
if [ "$ROUTE_CONSTANT_USAGE_COUNT" -lt 6 ]; then fail "route constant count 6 altinda"; fi

: > "$CANDIDATE_FILE"

find "$ROOT_DIR/cmd" -maxdepth 4 -type f -name "*.go" 2>/dev/null \
  | grep -Ei "api-gateway|api_gateway|gateway|gateway_main|main.go|_main.go" \
  | grep -v "/backups/" \
  | sort \
  >> "$CANDIDATE_FILE" || true

find "$ROOT_DIR/internal" "$ROOT_DIR/pkg" "$ROOT_DIR/services" -maxdepth 6 -type f -name "*.go" 2>/dev/null \
  | grep -Ei "gateway|router|routes|server|http" \
  | grep -v "/backups/" \
  | sort \
  >> "$CANDIDATE_FILE" || true

sort -u "$CANDIDATE_FILE" -o "$CANDIDATE_FILE"

ENTRY_CANDIDATE_COUNT="$(count_lines "$CANDIDATE_FILE")"
SELECTED_ENTRY_TARGET=""
if [ -f "$ROOT_DIR/cmd/api-gateway/api_gateway_main.go" ]; then
  SELECTED_ENTRY_TARGET="$ROOT_DIR/cmd/api-gateway/api_gateway_main.go"
elif grep -q "/cmd/api-gateway/.*\.go$" "$CANDIDATE_FILE" 2>/dev/null; then
  SELECTED_ENTRY_TARGET="$(grep "/cmd/api-gateway/.*\.go$" "$CANDIDATE_FILE" | head -n 1 || true)"
elif grep -qi "api-gateway\|api_gateway" "$CANDIDATE_FILE" 2>/dev/null; then
  SELECTED_ENTRY_TARGET="$(grep -Ei "api-gateway|api_gateway" "$CANDIDATE_FILE" | head -n 1 || true)"
else
  SELECTED_ENTRY_TARGET="$(head -n 1 "$CANDIDATE_FILE" || true)"
fi

SELECTED_ENTRY_TARGET_REL=""

if [ -n "$SELECTED_ENTRY_TARGET" ]; then
  SELECTED_ENTRY_TARGET_REL="$(safe_rel "$SELECTED_ENTRY_TARGET")"
fi

SELECTED_ENTRY_TARGET_STATUS="NOT_SELECTED"
SELECTED_ENTRY_TARGET_KIND="UNKNOWN"


if [ -n "$SELECTED_ENTRY_TARGET_REL" ]; then
  SELECTED_ENTRY_TARGET_STATUS="SELECTED"

  case "$SELECTED_ENTRY_TARGET_REL" in
    cmd/api-gateway/*)
      SELECTED_ENTRY_TARGET_KIND="API_GATEWAY"
      ;;
    *)
      SELECTED_ENTRY_TARGET_KIND="NON_GATEWAY"
      warn "selected entry target api-gateway degil; 18.3 oncesi hedef dogrulanmali"
      ;;
  esac
else
  warn "entry target otomatik secilemedi; 18.3 apply gate oncesi elle hedef dosya secilmeli"
fi

COMPOSE_API_GATEWAY_CANDIDATES="$(find "$ROOT_DIR" -maxdepth 5 -type f \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -o -name "compose*.yml" -o -name "compose*.yaml" \) 2>/dev/null | grep -Ei "api-gateway|gateway|deploy/docker-compose|deploy/api-gateway" | grep -v "/backups/" | wc -l | tr -d ' ' || true)"
ENV_CANDIDATES="$(find "$ROOT_DIR" -maxdepth 5 -type f \( -name ".env" -o -name "*.env" -o -name "ports.env" \) 2>/dev/null | grep -v "/backups/" | wc -l | tr -d ' ' || true)"

detail "ENTRY_CANDIDATE_COUNT=$ENTRY_CANDIDATE_COUNT"
detail "SELECTED_ENTRY_TARGET_STATUS=$SELECTED_ENTRY_TARGET_STATUS"
detail "SELECTED_ENTRY_TARGET_KIND=$SELECTED_ENTRY_TARGET_KIND"
detail "SELECTED_ENTRY_TARGET=$SELECTED_ENTRY_TARGET_REL"
detail "COMPOSE_API_GATEWAY_CANDIDATE_COUNT=$COMPOSE_API_GATEWAY_CANDIDATES"
detail "ENV_CANDIDATE_COUNT=$ENV_CANDIDATES"

if [ "$ENTRY_CANDIDATE_COUNT" -lt 1 ]; then
  fail "entry candidate bulunamadi"
fi

if [ "$SELECTED_ENTRY_TARGET_KIND" != "API_GATEWAY" ]; then
  fail "selected entry target api-gateway degil"
fi

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

if [ "$REPORTING_GO_TEST_SUITE" != "PASS" ]; then
  fail "reporting go test suite PASS degil"
fi

{
  echo "#!/usr/bin/env bash"
  echo "set -euo pipefail"
  echo "echo \"DO_NOT_RUN_AUTOMATICALLY=YES\""
  echo "echo \"This is only the 18.2 reporting runtime service entry candidate execution plan.\""
  echo "echo \"18.2 does not apply runtime/gateway changes.\""
  echo "echo \"Actual controlled apply belongs to 18.3 or later.\""
  echo "exit 99"
  echo
  echo "# FAZ 4 / 18.2 - Reporting Runtime Service Entry Candidate Execution"
  echo "# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "# This file is intentionally blocked by exit 99 above."
  echo
  echo "ROOT_DIR=\"${ROOT_DIR}\""
  echo "SELECTED_ENTRY_TARGET=\"${SELECTED_ENTRY_TARGET_REL}\""
  echo "REPORTING_RUNTIME_REGISTRATION=\"internal/platform/reporting/runtime/registration.go\""
  echo
  echo "# Candidate import to add if target is Go-based:"
  echo "# reportingruntime \"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime\""
  echo
  echo "# Candidate registration call:"
  echo "# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {"
  echo "#   return err"
  echo "# }"
  echo
  echo "# High-level controlled apply sequence:"
  echo "# 1. Backup selected gateway/service entry file."
  echo "# 2. Add reporting runtime import."
  echo "# 3. Add RegisterReportingRoutes(mux) after base mux/router creation."
  echo "# 4. Run gofmt on changed Go file."
  echo "# 5. Run go test ./internal/platform/reporting/... ./cmd/... where applicable."
  echo "# 6. Do not restart runtime in 18.2."
  echo "# 7. 18.3 will perform controlled apply gate."
  echo
  echo "# Rollback plan:"
  echo "# 1. Restore backed-up gateway/service entry file."
  echo "# 2. Run gofmt."
  echo "# 3. Run go test."
  echo "# 4. Confirm reporting route registration reverts to previous state."
} > "$EXECUTION_FILE"

chmod 600 "$EXECUTION_FILE"

CANDIDATE_EXECUTION_CREATED="NO"
CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT="NO"

if [ -f "$EXECUTION_FILE" ]; then
  CANDIDATE_EXECUTION_CREATED="YES"
fi

if grep -q "exit 99" "$EXECUTION_FILE" && grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$EXECUTION_FILE"; then
  CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT="YES"
fi

detail "CANDIDATE_EXECUTION_FILE=docs/phase4/18_2_reporting_runtime_service_entry_candidate_execution.sh"
detail "CANDIDATE_EXECUTION_CREATED=$CANDIDATE_EXECUTION_CREATED"
detail "CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=$CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT"

if [ "$CANDIDATE_EXECUTION_CREATED" != "YES" ]; then
  fail "candidate execution dosyasi olusmadi"
fi

if [ "$CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT" != "YES" ]; then
  fail "candidate execution blocked by default degil"
fi

{
  echo -e "candidate_type\tpath_or_name\tstatus\tnote"
  echo -e "selected_entry_target\t${SELECTED_ENTRY_TARGET_REL:-NOT_SELECTED}\t$SELECTED_ENTRY_TARGET_STATUS\ttype=$SELECTED_ENTRY_TARGET_KIND"
  echo -e "runtime_registration\tinternal/platform/reporting/runtime/registration.go\tFOUND\tRegisterReportingRoutes available"
  echo -e "candidate_execution\tdocs/phase4/18_2_reporting_runtime_service_entry_candidate_execution.sh\t$CANDIDATE_EXECUTION_CREATED\tblocked_by_default=$CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT"
  echo -e "compose_candidates\tdeploy/api-gateway_or_gateway\tDISCOVERED\t$COMPOSE_API_GATEWAY_CANDIDATES"
  echo -e "env_candidates\tenv_files\tDISCOVERED\t$ENV_CANDIDATES"
  echo -e "entry_candidate_total\tgo_files\tDISCOVERED\t$ENTRY_CANDIDATE_COUNT"
  echo -e "apply_mode\tplan_only\tNO_APPLY\t18.2 does not mutate code"
} > "$INVENTORY_FILE"

echo -e "candidate_index\tpath" >> "$INVENTORY_FILE"
awk 'BEGIN{n=0} {n++; print n "\t" $0}' "$CANDIDATE_FILE" | head -n 40 >> "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "SERVICE_ENTRY_CANDIDATE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

{
  echo -e "gate\tstatus\tnote"
  echo -e "previous_18_1_readiness\t$R181_STATUS\treadiness=$R181_READY blockers=$R181_BLOCKERS"
  echo -e "previous_17_final\t$R17_FINAL\treporting api closure"
  echo -e "runtime_registration\tPASS\tRegisterReportingRoutes available"
  echo -e "entry_candidate_selection\t$SELECTED_ENTRY_TARGET_STATUS\t${SELECTED_ENTRY_TARGET_REL:-manual_selection_required}"
  echo -e "candidate_execution_created\t$CANDIDATE_EXECUTION_CREATED\tblocked_by_default=$CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT"
  echo -e "reporting_go_test_suite\t$REPORTING_GO_TEST_SUITE\tinternal platform reporting"
  echo -e "apply_executed\tNO\tplan only"
  echo -e "gateway_config_changed\tNO\tplan only"
  echo -e "runtime_started\tNO\tplan only"
  echo -e "db_mutation\tNO\tplan only"
} > "$MATRIX_FILE"

MATRIX_LINE_COUNT="$(wc -l < "$MATRIX_FILE" | tr -d ' ')"
detail "SERVICE_ENTRY_APPLY_MATRIX_LINE_COUNT=$MATRIX_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -lt 8 ]; then
  fail "candidate inventory line count 8 altinda"
fi

if [ "$MATRIX_LINE_COUNT" -lt 10 ]; then
  fail "apply matrix line count 10 altinda"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS"
else
  detail "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=FAIL"
fi

{
  echo "# FAZ 4 / 18.2 - Reporting Runtime Service Entry Apply Plan Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS"
  else
    echo "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Candidate Inventory"
  echo "INVENTORY_FILE=docs/phase4/18_2_reporting_runtime_service_entry_candidate_inventory.tsv"
  cat "$INVENTORY_FILE"

  echo
  echo "## Apply Matrix"
  echo "MATRIX_FILE=docs/phase4/18_2_reporting_runtime_service_entry_apply_matrix.tsv"
  cat "$MATRIX_FILE"

  echo
  echo "## Candidate Execution First 120 Lines"
  sed -n '1,120p' "$EXECUTION_FILE" 2>/dev/null || true

  echo
  echo "## Go Test Output"
  if [ -f "$GO_TEST_FILE" ]; then
    sed -n '1,420p' "$GO_TEST_FILE"
  else
    echo "go test output yok"
  fi

  echo
  echo "## Safety Decision"
  echo "APPLY_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "DB_MIGRATION_CREATED=NO"
  echo "DB_APPLY_EXECUTED=NO"
  echo "SERVICE_CODE_CREATED=NO"
  echo "HTTP_HANDLER_CREATED=NO"
  echo "ROUTE_REGISTRATION_CREATED=NO"
  echo "REPORTING_RUNTIME_STARTED=NO"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "PORT_OPENED=NO"
  echo "LISTEN_AND_SERVE_USED=NO"
  echo "GATEWAY_CONFIG_CHANGED=NO"
  echo "NGINX_CONFIG_CHANGED=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
  echo "PLAN_MODE=APPLY_PLAN_ONLY"

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
echo "MATRIX_FILE=$MATRIX_FILE"
echo "EXECUTION_FILE=$EXECUTION_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SELECTED_ENTRY_TARGET_STATUS=$SELECTED_ENTRY_TARGET_STATUS"
echo "SELECTED_ENTRY_TARGET=$SELECTED_ENTRY_TARGET_REL"
echo "CANDIDATE_EXECUTION_CREATED=$CANDIDATE_EXECUTION_CREATED"
echo "CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=$CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT"
echo "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=FAIL ❌"
  exit 1
fi

echo "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS ✅"
