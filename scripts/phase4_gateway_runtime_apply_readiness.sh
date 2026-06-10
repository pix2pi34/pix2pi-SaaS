#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
STANDARD_FILE="$REPORT_DIR/18_1_gateway_runtime_apply_readiness_standard.md"
REPORT_FILE="$REPORT_DIR/18_1_gateway_runtime_apply_readiness_report.md"
INVENTORY_FILE="$REPORT_DIR/18_1_gateway_runtime_discovery_inventory.tsv"
MATRIX_FILE="$REPORT_DIR/18_1_gateway_runtime_apply_readiness_matrix.tsv"

R16="$REPORT_DIR/16_reporting_final_closure_report.md"
R17="$REPORT_DIR/17_reporting_api_final_closure_report.md"
R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
R174="$REPORT_DIR/17_4_reporting_runtime_smoke_test_report.md"
R175="$REPORT_DIR/17_5_reporting_api_final_closure_report.md"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_18_1_reporting_go_test.log"

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

path_status() {
  local path="$1"

  if [ -e "$path" ]; then
    echo "FOUND"
  else
    echo "NOT_FOUND"
  fi
}

count_files() {
  local pattern="$1"
  find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -path "$ROOT_DIR/backups" -prune -o -path "$ROOT_DIR/vendor" -prune -o -type f -path "$pattern" -print 2>/dev/null | wc -l | tr -d ' '
}

grep_count() {
  local pattern="$1"
  local include="$2"

  grep -RIl --include="$include" "$pattern" "$ROOT_DIR" 2>/dev/null \
    | grep -v "/.git/" \
    | grep -v "/backups/" \
    | grep -v "/vendor/" \
    | wc -l | tr -d ' '
}

first_matches() {
  local pattern="$1"
  local include="$2"
  local limit="${3:-20}"

  grep -RIl --include="$include" "$pattern" "$ROOT_DIR" 2>/dev/null \
    | grep -v "/.git/" \
    | grep -v "/backups/" \
    | grep -v "/vendor/" \
    | sed "s#^$ROOT_DIR/##" \
    | head -n "$limit" || true
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
detail "DISCOVERY_MODE=READ_ONLY"

GO_FOUND=0
if tool_status "go"; then GO_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "find" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

if [ ! -f "$STANDARD_FILE" ]; then
  fail "standard doc yok"
fi

R16_FINAL="$(get_report_value "$R16" "FAZ4_16_FINAL_STATUS")"
R16_CLOSURE="$(get_report_value "$R16" "REPORTING_FINAL_CLOSURE")"

R17_FINAL="$(get_report_value "$R17" "FAZ4_17_FINAL_STATUS")"
R17_CLOSURE="$(get_report_value "$R17" "REPORTING_API_FINAL_CLOSURE")"
R17_ROUTE_COUNT="$(get_report_value "$R17" "GATEWAY_REPORTING_ROUTE_COUNT")"
R17_GO_TEST="$(get_report_value "$R17" "REPORTING_GO_TEST_SUITE")"
R17_RUNTIME_STARTED="$(get_report_value "$R17" "REPORTING_RUNTIME_STARTED")"
R17_GATEWAY_CHANGED="$(get_report_value "$R17" "GATEWAY_CONFIG_CHANGED")"
R17_DB_MUTATION="$(get_report_value "$R17" "DB_MUTATION")"
R17_QUERY_TEXT="$(get_report_value "$R17" "QUERY_TEXT_PRINTED")"

R173_MANIFEST="$(get_report_value "$R173" "GATEWAY_ROUTE_MANIFEST")"
R173_GATE="$(get_report_value "$R173" "AUTH_TENANT_MIDDLEWARE_GATE")"

R174_SMOKE="$(get_report_value "$R174" "REPORTING_RUNTIME_SMOKE_TEST")"
R174_AUTH="$(get_report_value "$R174" "REPORTING_AUTH_GATE_SMOKE")"
R174_TENANT="$(get_report_value "$R174" "REPORTING_TENANT_GATE_SMOKE")"

R175_CLOSURE="$(get_report_value "$R175" "REPORTING_API_FINAL_CLOSURE")"
R175_FINAL="$(get_report_value "$R175" "FAZ4_17_FINAL_STATUS")"

detail "PREVIOUS_16_FINAL_STATUS=$R16_FINAL"
detail "PREVIOUS_16_REPORTING_FINAL_CLOSURE=$R16_CLOSURE"

detail "PREVIOUS_17_FINAL_STATUS=$R17_FINAL"
detail "PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=$R17_CLOSURE"
detail "PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT=$R17_ROUTE_COUNT"
detail "PREVIOUS_17_REPORTING_GO_TEST_SUITE=$R17_GO_TEST"
detail "PREVIOUS_17_REPORTING_RUNTIME_STARTED=$R17_RUNTIME_STARTED"
detail "PREVIOUS_17_GATEWAY_CONFIG_CHANGED=$R17_GATEWAY_CHANGED"
detail "PREVIOUS_17_DB_MUTATION=$R17_DB_MUTATION"
detail "PREVIOUS_17_QUERY_TEXT_PRINTED=$R17_QUERY_TEXT"

detail "PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=$R173_MANIFEST"
detail "PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=$R173_GATE"

detail "PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=$R174_SMOKE"
detail "PREVIOUS_17_4_REPORTING_AUTH_GATE_SMOKE=$R174_AUTH"
detail "PREVIOUS_17_4_REPORTING_TENANT_GATE_SMOKE=$R174_TENANT"

detail "PREVIOUS_17_5_REPORTING_API_FINAL_CLOSURE=$R175_CLOSURE"
detail "PREVIOUS_17_5_FINAL_STATUS=$R175_FINAL"

if [ "$R16_FINAL" != "PASS" ]; then fail "16 final status PASS degil"; fi
if [ "$R16_CLOSURE" != "PASS" ]; then fail "16 reporting closure PASS degil"; fi

if [ "$R17_FINAL" != "PASS" ]; then fail "17 final status PASS degil"; fi
if [ "$R17_CLOSURE" != "PASS" ]; then fail "17 reporting api closure PASS degil"; fi
if [ "$R17_ROUTE_COUNT" != "6" ]; then fail "17 gateway route count 6 degil"; fi
if [ "$R17_GO_TEST" != "PASS" ]; then fail "17 go test suite PASS degil"; fi
if [ "$R17_RUNTIME_STARTED" != "NO" ]; then fail "17 runtime started NO degil"; fi
if [ "$R17_GATEWAY_CHANGED" != "NO" ]; then fail "17 gateway config changed NO degil"; fi
if [ "$R17_DB_MUTATION" != "NO" ]; then fail "17 DB mutation NO degil"; fi
if [ "$R17_QUERY_TEXT" != "NO" ]; then fail "17 query text printed NO degil"; fi

if [ "$R173_MANIFEST" != "PASS" ]; then fail "17.3 gateway route manifest PASS degil"; fi
if [ "$R173_GATE" != "PASS" ]; then fail "17.3 auth tenant gate PASS degil"; fi

if [ "$R174_SMOKE" != "PASS" ]; then fail "17.4 runtime smoke PASS degil"; fi
if [ "$R174_AUTH" != "PASS" ]; then fail "17.4 auth gate smoke PASS degil"; fi
if [ "$R174_TENANT" != "PASS" ]; then fail "17.4 tenant gate smoke PASS degil"; fi

if [ "$R175_CLOSURE" != "PASS" ]; then fail "17.5 final closure PASS degil"; fi
if [ "$R175_FINAL" != "PASS" ]; then fail "17.5 final status PASS degil"; fi

REPORTING_RUNTIME_DIR="$ROOT_DIR/internal/platform/reporting/runtime"
REPORTING_API_DIR="$ROOT_DIR/internal/platform/reporting/api"
REPORTING_SERVICE_DIR="$ROOT_DIR/internal/platform/reporting/service"
REPORTING_REPOSITORY_DIR="$ROOT_DIR/internal/platform/reporting/repository"

REPORTING_RUNTIME_DIR_STATUS="$(path_status "$REPORTING_RUNTIME_DIR")"
REPORTING_API_DIR_STATUS="$(path_status "$REPORTING_API_DIR")"
REPORTING_SERVICE_DIR_STATUS="$(path_status "$REPORTING_SERVICE_DIR")"
REPORTING_REPOSITORY_DIR_STATUS="$(path_status "$REPORTING_REPOSITORY_DIR")"

REGISTRATION_FILE="$REPORTING_RUNTIME_DIR/registration.go"
RUNTIME_SMOKE_TEST_FILE="$REPORTING_RUNTIME_DIR/runtime_smoke_test.go"

REGISTRATION_FILE_STATUS="$(path_status "$REGISTRATION_FILE")"
RUNTIME_SMOKE_TEST_FILE_STATUS="$(path_status "$RUNTIME_SMOKE_TEST_FILE")"

REGISTER_FUNCTION_COUNT="0"
ROUTES_FUNCTION_COUNT="0"
ROUTE_CONSTANT_USAGE_COUNT="0"

if [ -f "$REGISTRATION_FILE" ]; then
  REGISTER_FUNCTION_COUNT="$(grep -E "func RegisterReportingRoutes" "$REGISTRATION_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  ROUTES_FUNCTION_COUNT="$(grep -E "func Routes\\(\\)" "$REGISTRATION_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  ROUTE_CONSTANT_USAGE_COUNT="$(grep -E "Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)" "$REGISTRATION_FILE" 2>/dev/null | wc -l | tr -d ' ')"
fi

detail "REPORTING_RUNTIME_DIR_STATUS=$REPORTING_RUNTIME_DIR_STATUS"
detail "REPORTING_API_DIR_STATUS=$REPORTING_API_DIR_STATUS"
detail "REPORTING_SERVICE_DIR_STATUS=$REPORTING_SERVICE_DIR_STATUS"
detail "REPORTING_REPOSITORY_DIR_STATUS=$REPORTING_REPOSITORY_DIR_STATUS"
detail "REPORTING_REGISTRATION_FILE_STATUS=$REGISTRATION_FILE_STATUS"
detail "REPORTING_RUNTIME_SMOKE_TEST_FILE_STATUS=$RUNTIME_SMOKE_TEST_FILE_STATUS"
detail "REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=$REGISTER_FUNCTION_COUNT"
detail "REPORTING_ROUTES_FUNCTION_COUNT=$ROUTES_FUNCTION_COUNT"
detail "REPORTING_ROUTE_CONSTANT_USAGE_COUNT=$ROUTE_CONSTANT_USAGE_COUNT"

if [ "$REPORTING_RUNTIME_DIR_STATUS" != "FOUND" ]; then fail "reporting runtime dir yok"; fi
if [ "$REPORTING_API_DIR_STATUS" != "FOUND" ]; then fail "reporting api dir yok"; fi
if [ "$REPORTING_SERVICE_DIR_STATUS" != "FOUND" ]; then fail "reporting service dir yok"; fi
if [ "$REPORTING_REPOSITORY_DIR_STATUS" != "FOUND" ]; then fail "reporting repository dir yok"; fi
if [ "$REGISTRATION_FILE_STATUS" != "FOUND" ]; then fail "registration.go yok"; fi
if [ "$REGISTER_FUNCTION_COUNT" -lt 1 ]; then fail "RegisterReportingRoutes fonksiyonu yok"; fi
if [ "$ROUTES_FUNCTION_COUNT" -lt 1 ]; then fail "Routes fonksiyonu yok"; fi
if [ "$ROUTE_CONSTANT_USAGE_COUNT" -lt 6 ]; then fail "route constant usage count 6 altinda"; fi

CMD_API_GATEWAY_COUNT="$(find "$ROOT_DIR/cmd" -maxdepth 2 -type f \( -name "*.go" -o -name "*.env" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | grep -Ei "gateway|api-gateway|gateway_main|api_gateway" | wc -l | tr -d ' ' || true)"
CMD_REPORTING_COUNT="$(find "$ROOT_DIR/cmd" -maxdepth 3 -type f -name "*.go" 2>/dev/null | grep -Ei "reporting|report" | wc -l | tr -d ' ' || true)"

GATEWAY_STRING_FILE_COUNT="$(grep_count "api-gateway|api_gateway|gateway" "*.go")"
REPORTING_ROUTE_STRING_FILE_COUNT="$(grep_count "/api/v1/reporting" "*.go")"
REPORTING_RUNTIME_REGISTER_USAGE_COUNT="$(grep_count "RegisterReportingRoutes" "*.go")"

COMPOSE_FILE_COUNT="$(find "$ROOT_DIR" -maxdepth 4 -type f \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -o -name "compose*.yml" -o -name "compose*.yaml" \) 2>/dev/null | grep -v "/backups/" | wc -l | tr -d ' ')"
ENV_FILE_COUNT="$(find "$ROOT_DIR" -maxdepth 4 -type f \( -name ".env" -o -name "*.env" -o -name "ports.env" \) 2>/dev/null | grep -v "/backups/" | wc -l | tr -d ' ')"

NGINX_FILE_COUNT="$(find /etc/nginx /opt/pix2pi 2>/dev/null -type f \( -name "*.conf" -o -name "nginx.conf" \) | wc -l | tr -d ' ' || true)"
SYSTEMD_PIX2PI_COUNT="$(find /etc/systemd/system 2>/dev/null -type f -name "*pix2pi*.service" | wc -l | tr -d ' ' || true)"

detail "CMD_API_GATEWAY_CANDIDATE_COUNT=$CMD_API_GATEWAY_COUNT"
detail "CMD_REPORTING_CANDIDATE_COUNT=$CMD_REPORTING_COUNT"
detail "GATEWAY_STRING_FILE_COUNT=$GATEWAY_STRING_FILE_COUNT"
detail "REPORTING_ROUTE_STRING_FILE_COUNT=$REPORTING_ROUTE_STRING_FILE_COUNT"
detail "REPORTING_RUNTIME_REGISTER_USAGE_COUNT=$REPORTING_RUNTIME_REGISTER_USAGE_COUNT"
detail "COMPOSE_FILE_COUNT=$COMPOSE_FILE_COUNT"
detail "ENV_FILE_COUNT=$ENV_FILE_COUNT"
detail "NGINX_FILE_COUNT=$NGINX_FILE_COUNT"
detail "SYSTEMD_PIX2PI_SERVICE_COUNT=$SYSTEMD_PIX2PI_COUNT"

if [ "$REPORTING_RUNTIME_REGISTER_USAGE_COUNT" -lt 1 ]; then
  fail "RegisterReportingRoutes usage count 1 altinda"
fi

if [ "$REPORTING_ROUTE_STRING_FILE_COUNT" -lt 1 ]; then
  warn "reporting route string sadece API constants tarafinda olabilir; 18.2 apply planinda hedef runtime netlestirilmeli"
fi

if [ "$CMD_API_GATEWAY_COUNT" -lt 1 ]; then
  warn "cmd/api-gateway adayi net bulunamadi; 18.2 service entry hedefi discovery ile secilmeli"
fi

if [ "$NGINX_FILE_COUNT" -lt 1 ]; then
  warn "nginx config adayi bulunamadi veya erisim yok; gateway apply oncesi elle dogrulanmali"
fi

if [ "$SYSTEMD_PIX2PI_COUNT" -lt 1 ]; then
  warn "pix2pi systemd service adayi bulunamadi; runtime apply target 18.2'de netlestirilmeli"
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

APPLY_READINESS_BLOCKER_COUNT="$FAIL_COUNT"
APPLY_READINESS_WARN_COUNT="$WARN_COUNT"
APPLY_READINESS_STATUS="UNKNOWN"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  APPLY_READINESS_STATUS="READY"
elif [ "$FAIL_COUNT" -eq 0 ]; then
  APPLY_READINESS_STATUS="READY_WITH_WARNINGS"
else
  APPLY_READINESS_STATUS="BLOCKED"
fi

detail "APPLY_READINESS_BLOCKER_COUNT=$APPLY_READINESS_BLOCKER_COUNT"
detail "APPLY_READINESS_WARN_COUNT=$APPLY_READINESS_WARN_COUNT"
detail "APPLY_READINESS_STATUS=$APPLY_READINESS_STATUS"

{
  echo -e "area\titem\tstatus\tcount_or_value"
  echo -e "reporting_runtime\tdirectory\t$REPORTING_RUNTIME_DIR_STATUS\tinternal/platform/reporting/runtime"
  echo -e "reporting_api\tdirectory\t$REPORTING_API_DIR_STATUS\tinternal/platform/reporting/api"
  echo -e "reporting_service\tdirectory\t$REPORTING_SERVICE_DIR_STATUS\tinternal/platform/reporting/service"
  echo -e "reporting_repository\tdirectory\t$REPORTING_REPOSITORY_DIR_STATUS\tinternal/platform/reporting/repository"
  echo -e "runtime_registration\tfile\t$REGISTRATION_FILE_STATUS\tinternal/platform/reporting/runtime/registration.go"
  echo -e "runtime_smoke_test\tfile\t$RUNTIME_SMOKE_TEST_FILE_STATUS\tinternal/platform/reporting/runtime/runtime_smoke_test.go"
  echo -e "register_function\tRegisterReportingRoutes\tFOUND\t$REGISTER_FUNCTION_COUNT"
  echo -e "routes_function\tRoutes\tFOUND\t$ROUTES_FUNCTION_COUNT"
  echo -e "route_constants\treporting_routes\tFOUND\t$ROUTE_CONSTANT_USAGE_COUNT"
  echo -e "cmd_gateway_candidates\tcmd\tDISCOVERED\t$CMD_API_GATEWAY_COUNT"
  echo -e "cmd_reporting_candidates\tcmd\tDISCOVERED\t$CMD_REPORTING_COUNT"
  echo -e "compose_files\tcompose\tDISCOVERED\t$COMPOSE_FILE_COUNT"
  echo -e "env_files\tenv\tDISCOVERED\t$ENV_FILE_COUNT"
  echo -e "nginx_files\tnginx\tDISCOVERED\t$NGINX_FILE_COUNT"
  echo -e "systemd_pix2pi_services\tsystemd\tDISCOVERED\t$SYSTEMD_PIX2PI_COUNT"
} > "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "DISCOVERY_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

{
  echo -e "gate\tstatus\tnote"
  echo -e "previous_16_final\t$R16_FINAL\treporting query layer closure"
  echo -e "previous_17_final\t$R17_FINAL\treporting api runtime closure"
  echo -e "route_registration\tPASS\tRegisterReportingRoutes available"
  echo -e "gateway_manifest\t$R173_MANIFEST\tgateway dry-run manifest"
  echo -e "auth_tenant_gate\t$R173_GATE\tbearer and tenant gate"
  echo -e "runtime_smoke\t$R174_SMOKE\tin-process httptest"
  echo -e "go_test_suite\t$REPORTING_GO_TEST_SUITE\tinternal platform reporting"
  echo -e "runtime_started\tNO\tno runtime start in 18.1"
  echo -e "gateway_config_changed\tNO\tread-only discovery"
  echo -e "db_mutation\tNO\tread-only discovery"
  echo -e "apply_readiness\t$APPLY_READINESS_STATUS\tblockers=$APPLY_READINESS_BLOCKER_COUNT warnings=$APPLY_READINESS_WARN_COUNT"
} > "$MATRIX_FILE"

MATRIX_LINE_COUNT="$(wc -l < "$MATRIX_FILE" | tr -d ' ')"
detail "APPLY_READINESS_MATRIX_LINE_COUNT=$MATRIX_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -lt 10 ]; then
  fail "discovery inventory line count 10 altinda"
fi

if [ "$MATRIX_LINE_COUNT" -lt 10 ]; then
  fail "apply readiness matrix line count 10 altinda"
fi

if [ "$REPORTING_GO_TEST_SUITE" != "PASS" ]; then
  fail "reporting go test suite PASS degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS"
else
  detail "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=FAIL"
fi

{
  echo "# FAZ 4 / 18.1 - Gateway / Runtime Apply Readiness Discovery Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS"
  else
    echo "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Discovery Inventory"
  echo "INVENTORY_FILE=docs/phase4/18_1_gateway_runtime_discovery_inventory.tsv"
  cat "$INVENTORY_FILE"

  echo
  echo "## Apply Readiness Matrix"
  echo "MATRIX_FILE=docs/phase4/18_1_gateway_runtime_apply_readiness_matrix.tsv"
  cat "$MATRIX_FILE"

  echo
  echo "## Candidate Files"
  echo "### Gateway related Go files"
  first_matches "api-gateway|api_gateway|gateway" "*.go" 30
  echo
  echo "### Reporting route Go files"
  first_matches "/api/v1/reporting|RegisterReportingRoutes" "*.go" 30
  echo
  echo "### Compose files"
  find "$ROOT_DIR" -maxdepth 4 -type f \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -o -name "compose*.yml" -o -name "compose*.yaml" \) 2>/dev/null | grep -v "/backups/" | sed "s#^$ROOT_DIR/##" | head -n 30 || true
  echo
  echo "### Env files"
  find "$ROOT_DIR" -maxdepth 4 -type f \( -name ".env" -o -name "*.env" -o -name "ports.env" \) 2>/dev/null | grep -v "/backups/" | sed "s#^$ROOT_DIR/##" | head -n 30 || true

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
  echo "DISCOVERY_MODE=READ_ONLY"

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
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "APPLY_READINESS_STATUS=$APPLY_READINESS_STATUS"
echo "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=FAIL ❌"
  exit 1
fi

echo "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS ✅"
