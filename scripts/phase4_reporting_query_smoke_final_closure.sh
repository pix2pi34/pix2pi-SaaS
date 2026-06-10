#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/16_5_reporting_query_smoke_final_closure_report.md"
INVENTORY_FILE="$REPORT_DIR/16_5_reporting_query_smoke_inventory.tsv"
CLOSURE_FILE="$REPORT_DIR/16_reporting_final_closure_report.md"

R15="$REPORT_DIR/15_readmodel_final_closure_report.md"
R161="$REPORT_DIR/16_1_reporting_query_contract_report.md"
R162="$REPORT_DIR/16_2_readmodel_repository_layer_report.md"
R163="$REPORT_DIR/16_3_reporting_service_layer_report.md"
R164="$REPORT_DIR/16_4_reporting_api_endpoint_skeleton_report.md"

FAIL_COUNT=0
WARN_COUNT=0

mkdir -p "$REPORT_DIR"

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
SMOKE_FILE="$(mktemp)"
GO_TEST_FILE="/tmp/pix2pi_16_5_reporting_go_test.log"

trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$SMOKE_FILE"' EXIT

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

strip_quotes() {
  local v="$1"
  v="${v%$'\r'}"

  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}" ;;
    \'*\') v="${v#\'}"; v="${v%\'}" ;;
  esac

  echo "$v"
}

normalize_pg_bool_false() {
  local v="$1"
  v="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

  case "$v" in
    f|false|0|no|off) echo "f" ;;
    t|true|1|yes|on) echo "t" ;;
    *) echo "$v" ;;
  esac
}

extract_env() {
  local file="$1"
  local key="$2"
  local line=""
  local value=""

  [ -r "$file" ] || return 1

  line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key}=" "$file" 2>/dev/null | tail -n 1 || true)"
  [ -n "$line" ] || return 1

  value="${line#*=}"
  value="$(strip_quotes "$value")"
  [ -n "$value" ] || return 1

  printf '%s' "$value"
  return 0
}

mask_secret() {
  local v="$1"
  v="$(printf '%s' "$v" | sed -E 's#(://[^:/@]+:)[^@]+@#\1***@#g')"
  v="$(printf '%s' "$v" | sed -E 's#(password=)[^[:space:]]+#\1***#Ig')"
  v="$(printf '%s' "$v" | sed -E 's#(PGPASSWORD=)[^[:space:]]+#\1***#Ig')"
  echo "$v"
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

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_16_5_sql_err.log || echo "error"
}

read_smoke_query() {
  local label="$1"
  local sql="$2"
  local result=""

  result="$(run_sql "$sql")"

  if [[ "$result" =~ ^[0-9]+$ ]]; then
    echo -e "${label}\tPASS\t${result}" >> "$SMOKE_FILE"
    return 0
  fi

  echo -e "${label}\tFAIL\t${result}" >> "$SMOKE_FILE"
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
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "REPORTING_FINAL_CLOSURE_FILE=docs/phase4/16_reporting_final_closure_report.md"

GO_FOUND=0
PSQL_FOUND=0

if tool_status "go"; then GO_FOUND=1; fi
if tool_status "psql"; then PSQL_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$GO_FOUND" -ne 1 ]; then
  fail "go bulunamadi"
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

R15_STATUS="$(get_report_value "$R15" "FAZ4_15_FINAL_STATUS")"
R15_CLOSURE="$(get_report_value "$R15" "READMODEL_FINAL_CLOSURE")"
R15_TABLE_COUNT="$(get_report_value "$R15" "READMODEL_TARGET_TABLE_COUNT")"

R161_STATUS="$(get_report_value "$R161" "REPORTING_QUERY_CONTRACT")"
R161_ENDPOINT_COUNT="$(get_report_value "$R161" "REPORTING_ENDPOINT_COUNT")"

R162_STATUS="$(get_report_value "$R162" "READMODEL_REPOSITORY_LAYER")"
R162_METHOD_COUNT="$(get_report_value "$R162" "REPOSITORY_METHOD_COUNT")"
R162_GO_TEST="$(get_report_value "$R162" "GO_TEST_STATUS")"

R163_STATUS="$(get_report_value "$R163" "REPORTING_SERVICE_LAYER")"
R163_METHOD_COUNT="$(get_report_value "$R163" "SERVICE_METHOD_COUNT")"
R163_GO_TEST="$(get_report_value "$R163" "GO_TEST_STATUS")"

R164_STATUS="$(get_report_value "$R164" "REPORTING_API_ENDPOINT_SKELETON")"
R164_ENDPOINT_COUNT="$(get_report_value "$R164" "API_ENDPOINT_COUNT")"
R164_ROUTE_COUNT="$(get_report_value "$R164" "HANDLER_ROUTE_CASE_COUNT")"
R164_GO_TEST="$(get_report_value "$R164" "GO_TEST_STATUS")"

detail "PREVIOUS_15_READMODEL_FINAL_STATUS=$R15_STATUS"
detail "PREVIOUS_15_READMODEL_FINAL_CLOSURE=$R15_CLOSURE"
detail "PREVIOUS_15_READMODEL_TARGET_TABLE_COUNT=$R15_TABLE_COUNT"

detail "PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=$R161_STATUS"
detail "PREVIOUS_16_1_REPORTING_ENDPOINT_COUNT=$R161_ENDPOINT_COUNT"

detail "PREVIOUS_16_2_READMODEL_REPOSITORY_LAYER=$R162_STATUS"
detail "PREVIOUS_16_2_REPOSITORY_METHOD_COUNT=$R162_METHOD_COUNT"
detail "PREVIOUS_16_2_GO_TEST_STATUS=$R162_GO_TEST"

detail "PREVIOUS_16_3_REPORTING_SERVICE_LAYER=$R163_STATUS"
detail "PREVIOUS_16_3_SERVICE_METHOD_COUNT=$R163_METHOD_COUNT"
detail "PREVIOUS_16_3_GO_TEST_STATUS=$R163_GO_TEST"

detail "PREVIOUS_16_4_REPORTING_API_ENDPOINT_SKELETON=$R164_STATUS"
detail "PREVIOUS_16_4_API_ENDPOINT_COUNT=$R164_ENDPOINT_COUNT"
detail "PREVIOUS_16_4_HANDLER_ROUTE_CASE_COUNT=$R164_ROUTE_COUNT"
detail "PREVIOUS_16_4_GO_TEST_STATUS=$R164_GO_TEST"

if [ "$R15_STATUS" != "PASS" ]; then fail "15 readmodel final status PASS degil"; fi
if [ "$R15_CLOSURE" != "PASS" ]; then fail "15 readmodel closure PASS degil"; fi
if [ "$R15_TABLE_COUNT" != "6" ]; then fail "15 readmodel target table count 6 degil"; fi

if [ "$R161_STATUS" != "PASS" ]; then fail "16.1 reporting query contract PASS degil"; fi
if [ "$R161_ENDPOINT_COUNT" != "6" ]; then fail "16.1 endpoint count 6 degil"; fi

if [ "$R162_STATUS" != "PASS" ]; then fail "16.2 repository layer PASS degil"; fi
if [ "$R162_METHOD_COUNT" != "6" ]; then fail "16.2 repository method count 6 degil"; fi
if [ "$R162_GO_TEST" != "PASS" ]; then fail "16.2 go test PASS degil"; fi

if [ "$R163_STATUS" != "PASS" ]; then fail "16.3 service layer PASS degil"; fi
if [ "$R163_METHOD_COUNT" != "6" ]; then fail "16.3 service method count 6 degil"; fi
if [ "$R163_GO_TEST" != "PASS" ]; then fail "16.3 go test PASS degil"; fi

if [ "$R164_STATUS" != "PASS" ]; then fail "16.4 api endpoint skeleton PASS degil"; fi
if [ "$R164_ENDPOINT_COUNT" != "6" ]; then fail "16.4 api endpoint count 6 degil"; fi
if [ "$R164_ROUTE_COUNT" != "6" ]; then fail "16.4 handler route case count 6 degil"; fi
if [ "$R164_GO_TEST" != "PASS" ]; then fail "16.4 go test PASS degil"; fi

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

DB_DSN="${DB_DSN:-${DB_WRITE_DSN:-${DATABASE_URL:-}}}"

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_WRITE_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  fail "DB DSN bulunamadi"
else
  detail "DB_DSN_STATUS=CONFIGURED"
  detail "DB_DSN_MASKED=$(mask_secret "$DB_DSN")"
fi

DB_CONNECTION_CHECK="FAIL"
DB_ROLE="UNKNOWN"
READMODEL_SCHEMA_EXISTS="error"
READMODEL_TARGET_TABLE_COUNT="error"
READMODEL_PRIMARY_KEY_COUNT="error"
READMODEL_INDEX_COUNT="error"
READMODEL_TENANT_ID_COLUMN_COUNT="error"
READMODEL_NOT_NULL_TENANT_COUNT="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_16_5_psql_ok.log 2>/tmp/pix2pi_16_5_psql_err.log; then
    DB_CONNECTION_CHECK="PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"
  IN_RECOVERY="$(normalize_pg_bool_false "$IN_RECOVERY")"

  case "$IN_RECOVERY" in
    f) DB_ROLE="PRIMARY_WRITE" ;;
    t) DB_ROLE="REPLICA_READ_ONLY"; fail "DB replica/read-only gorunuyor" ;;
    *) DB_ROLE="UNKNOWN"; fail "pg_is_in_recovery okunamadi" ;;
  esac

  READMODEL_SCHEMA_EXISTS="$(run_sql "select exists(select 1 from information_schema.schemata where schema_name='readmodel')::text;")"
  READMODEL_SCHEMA_EXISTS="$(normalize_pg_bool_false "$READMODEL_SCHEMA_EXISTS")"

  READMODEL_TARGET_TABLE_COUNT="$(run_sql "
select count(*)::text
from information_schema.tables
where table_schema='readmodel'
and table_name in (
  'projection_state',
  'tenant_operational_snapshot',
  'daily_operational_metrics',
  'inventory_status_snapshot',
  'document_work_queue',
  'reconciliation_status_snapshot'
);
")"

  READMODEL_PRIMARY_KEY_COUNT="$(run_sql "
select count(distinct tc.table_name)::text
from information_schema.table_constraints tc
where tc.table_schema='readmodel'
and tc.constraint_type='PRIMARY KEY'
and tc.table_name in (
  'projection_state',
  'tenant_operational_snapshot',
  'daily_operational_metrics',
  'inventory_status_snapshot',
  'document_work_queue',
  'reconciliation_status_snapshot'
);
")"

  READMODEL_INDEX_COUNT="$(run_sql "select count(*)::text from pg_indexes where schemaname='readmodel';")"

  READMODEL_TENANT_ID_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and column_name='tenant_id'
and table_name in (
  'projection_state',
  'tenant_operational_snapshot',
  'daily_operational_metrics',
  'inventory_status_snapshot',
  'document_work_queue',
  'reconciliation_status_snapshot'
);
")"

  READMODEL_NOT_NULL_TENANT_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and column_name='tenant_id'
and is_nullable='NO'
and table_name in (
  'projection_state',
  'tenant_operational_snapshot',
  'daily_operational_metrics',
  'inventory_status_snapshot',
  'document_work_queue',
  'reconciliation_status_snapshot'
);
")"
fi

detail "DB_CONNECTION_CHECK=$DB_CONNECTION_CHECK"
detail "DB_ROLE=$DB_ROLE"
detail "READMODEL_SCHEMA_EXISTS=$READMODEL_SCHEMA_EXISTS"
detail "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
detail "READMODEL_PRIMARY_KEY_COUNT=$READMODEL_PRIMARY_KEY_COUNT"
detail "READMODEL_INDEX_COUNT=$READMODEL_INDEX_COUNT"
detail "READMODEL_TENANT_ID_COLUMN_COUNT=$READMODEL_TENANT_ID_COLUMN_COUNT"
detail "READMODEL_NOT_NULL_TENANT_COUNT=$READMODEL_NOT_NULL_TENANT_COUNT"

if [ "$DB_CONNECTION_CHECK" != "PASS" ]; then fail "DB connection PASS degil"; fi
if [ "$DB_ROLE" != "PRIMARY_WRITE" ]; then fail "DB role PRIMARY_WRITE degil"; fi
if [ "$READMODEL_SCHEMA_EXISTS" != "t" ]; then fail "readmodel schema yok"; fi
if [ "$READMODEL_TARGET_TABLE_COUNT" != "6" ]; then fail "readmodel target table count 6 degil"; fi
if [ "$READMODEL_PRIMARY_KEY_COUNT" != "6" ]; then fail "readmodel primary key count 6 degil"; fi
if [ "$READMODEL_INDEX_COUNT" -lt 13 ]; then fail "readmodel index count 13 altinda"; fi
if [ "$READMODEL_TENANT_ID_COLUMN_COUNT" != "6" ]; then fail "readmodel tenant_id column count 6 degil"; fi
if [ "$READMODEL_NOT_NULL_TENANT_COUNT" != "6" ]; then fail "readmodel not null tenant count 6 degil"; fi

{
  echo -e "smoke_name\tstatus\tresult_count"
} > "$SMOKE_FILE"

READ_SMOKE_PASS_COUNT=0
READ_SMOKE_FAIL_COUNT=0

if [ "$FAIL_COUNT" -eq 0 ]; then
  if read_smoke_query "operational_summary" "select count(*)::text from readmodel.tenant_operational_snapshot where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi

  if read_smoke_query "daily_metrics" "select count(*)::text from readmodel.daily_operational_metrics where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi

  if read_smoke_query "inventory_status" "select count(*)::text from readmodel.inventory_status_snapshot where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi

  if read_smoke_query "document_work_queue" "select count(*)::text from readmodel.document_work_queue where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi

  if read_smoke_query "reconciliation_status" "select count(*)::text from readmodel.reconciliation_status_snapshot where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi

  if read_smoke_query "projection_state" "select count(*)::text from readmodel.projection_state where tenant_id='tenant_smoke_16_5';"; then
    READ_SMOKE_PASS_COUNT=$((READ_SMOKE_PASS_COUNT + 1))
  else
    READ_SMOKE_FAIL_COUNT=$((READ_SMOKE_FAIL_COUNT + 1))
  fi
fi

detail "READMODEL_READ_SMOKE_PASS_COUNT=$READ_SMOKE_PASS_COUNT"
detail "READMODEL_READ_SMOKE_FAIL_COUNT=$READ_SMOKE_FAIL_COUNT"

if [ "$READ_SMOKE_PASS_COUNT" -ne 6 ]; then
  fail "readmodel read smoke pass count 6 degil"
fi

if [ "$READ_SMOKE_FAIL_COUNT" -ne 0 ]; then
  fail "readmodel read smoke fail count 0 degil"
fi

cp "$SMOKE_FILE" "$INVENTORY_FILE"

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "REPORTING_QUERY_SMOKE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

if [ "$INVENTORY_LINE_COUNT" -ne 7 ]; then
  fail "smoke inventory line count 7 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "REPORTING_QUERY_SMOKE=PASS"
  detail "REPORTING_FINAL_CLOSURE=PASS"
else
  detail "REPORTING_QUERY_SMOKE=FAIL"
  detail "REPORTING_FINAL_CLOSURE=FAIL"
fi

{
  echo "# FAZ 4 / 16.5 - Reporting Query Smoke / Final Closure Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "REPORTING_QUERY_SMOKE=PASS"
  else
    echo "REPORTING_QUERY_SMOKE=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Read Smoke Inventory"
  echo "INVENTORY_FILE=docs/phase4/16_5_reporting_query_smoke_inventory.tsv"
  cat "$INVENTORY_FILE"

  echo
  echo "## Go Test Output"
  if [ -f "$GO_TEST_FILE" ]; then
    sed -n '1,360p' "$GO_TEST_FILE"
  else
    echo "go test output yok"
  fi

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
  echo "QUERY_KILL_EXECUTED=NO"
  echo "VACUUM_EXECUTED=NO"
  echo "ANALYZE_EXECUTED=NO"
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

{
  echo "# FAZ 4 / 16 - Reporting Query Layer Final Closure Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "16.1 Reporting query contract / endpoint manifest=PASS"
  echo "16.2 Readmodel repository layer=PASS"
  echo "16.3 Reporting service layer=PASS"
  echo "16.4 API endpoint skeleton=PASS"
  echo "16.5 Query smoke tests / final closure=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
  echo
  echo "REPORTING_FINAL_CLOSURE=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
  echo "REPORTING_ENDPOINT_COUNT=6"
  echo "REPOSITORY_METHOD_COUNT=6"
  echo "SERVICE_METHOD_COUNT=6"
  echo "API_ENDPOINT_COUNT=6"
  echo "READMODEL_READ_SMOKE_PASS_COUNT=$READ_SMOKE_PASS_COUNT"
  echo "READMODEL_READ_SMOKE_FAIL_COUNT=$READ_SMOKE_FAIL_COUNT"
  echo "REPORTING_GO_TEST_SUITE=$REPORTING_GO_TEST_SUITE"
  echo "DB_CONNECTION_CHECK=$DB_CONNECTION_CHECK"
  echo "DB_ROLE=$DB_ROLE"
  echo "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
  echo "DB_MUTATION=NO"
  echo "SERVICE_RUNTIME_STARTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
  echo "FAZ4_16_FINAL_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
} > "$CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "CLOSURE_FILE=$CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "REPORTING_QUERY_SMOKE=FAIL ❌"
  exit 1
fi

echo "REPORTING_QUERY_SMOKE=PASS ✅"
