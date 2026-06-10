#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MIGRATION_BASE="${2:-20260427_151001_readmodel_operational_tables}"

ENV_FILE="$ROOT_DIR/.env"
UP_FILE="$ROOT_DIR/db/migrations/${MIGRATION_BASE}.up.sql"
DOWN_FILE="$ROOT_DIR/db/migrations/${MIGRATION_BASE}.down.sql"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/15_2_readmodel_apply_gate_report.md"
PLAN_FILE="$REPORT_DIR/15_2_readmodel_apply_candidate_execution.sh"

PREV_REPORT="$REPORT_DIR/15_1_operational_readmodel_tables_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "RISK ⚠️ $1" >> "$RISK_FILE"; }

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
    f|false|0|no|off)
      echo "f"
      return 0
      ;;
    t|true|1|yes|on)
      echo "t"
      return 0
      ;;
    *)
      echo "$v"
      return 0
      ;;
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

count_pattern() {
  local file="$1"
  local pattern="$2"
  grep -E "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' '
}

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_15_2_sql_err.log || echo "error"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "MIGRATION_BASE=$MIGRATION_BASE"
detail "UP_FILE=db/migrations/${MIGRATION_BASE}.up.sql"
detail "DOWN_FILE=db/migrations/${MIGRATION_BASE}.down.sql"
detail "DB_APPLY_EXECUTED=NO"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "PLAN_FILE=docs/phase4/15_2_readmodel_apply_candidate_execution.sh"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true
tool_status "sha256sum" >/dev/null || true

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_STATUS="$(get_report_value "$PREV_REPORT" "OPERATIONAL_READMODEL_TABLES")"
PREV_PAIR="$(get_report_value "$PREV_REPORT" "READMODEL_MIGRATION_PAIR")"
PREV_APPLY="$(get_report_value "$PREV_REPORT" "DB_APPLY_EXECUTED")"

detail "PREVIOUS_15_1_OPERATIONAL_READMODEL_TABLES=$PREV_STATUS"
detail "PREVIOUS_15_1_READMODEL_MIGRATION_PAIR=$PREV_PAIR"
detail "PREVIOUS_15_1_DB_APPLY_EXECUTED=$PREV_APPLY"

if [ "$PREV_STATUS" != "PASS" ]; then
  fail "15.1 operational readmodel tables PASS degil"
fi

if [ "$PREV_PAIR" != "PASS" ]; then
  fail "15.1 migration pair PASS degil"
fi

if [ ! -f "$UP_FILE" ]; then
  fail "up migration yok: $UP_FILE"
fi

if [ ! -f "$DOWN_FILE" ]; then
  fail "down migration yok: $DOWN_FILE"
fi

UP_SHA256="missing"
DOWN_SHA256="missing"

if [ -f "$UP_FILE" ] && command -v sha256sum >/dev/null 2>&1; then
  UP_SHA256="$(sha256sum "$UP_FILE" | awk '{print $1}')"
fi

if [ -f "$DOWN_FILE" ] && command -v sha256sum >/dev/null 2>&1; then
  DOWN_SHA256="$(sha256sum "$DOWN_FILE" | awk '{print $1}')"
fi

detail "UP_FILE_SHA256=$UP_SHA256"
detail "DOWN_FILE_SHA256=$DOWN_SHA256"

CREATE_SCHEMA_COUNT=0
CREATE_TABLE_COUNT=0
CREATE_INDEX_COUNT=0
DROP_TABLE_IN_UP_COUNT=0
ALTER_SYSTEM_IN_UP_COUNT=0
DOCKER_IN_UP_COUNT=0
PSQL_IN_UP_COUNT=0
TENANT_ID_COUNT=0
DOWN_DROP_TABLE_COUNT=0

if [ -f "$UP_FILE" ]; then
  CREATE_SCHEMA_COUNT="$(count_pattern "$UP_FILE" "^CREATE SCHEMA IF NOT EXISTS readmodel;")"
  CREATE_TABLE_COUNT="$(count_pattern "$UP_FILE" "^CREATE TABLE IF NOT EXISTS readmodel\\.")"
  CREATE_INDEX_COUNT="$(count_pattern "$UP_FILE" "^CREATE INDEX IF NOT EXISTS")"
  DROP_TABLE_IN_UP_COUNT="$(count_pattern "$UP_FILE" "DROP TABLE|DROP SCHEMA")"
  ALTER_SYSTEM_IN_UP_COUNT="$(count_pattern "$UP_FILE" "ALTER SYSTEM")"
  DOCKER_IN_UP_COUNT="$(count_pattern "$UP_FILE" "docker ")"
  PSQL_IN_UP_COUNT="$(count_pattern "$UP_FILE" "psql ")"
  TENANT_ID_COUNT="$(count_pattern "$UP_FILE" "tenant_id text")"
fi

if [ -f "$DOWN_FILE" ]; then
  DOWN_DROP_TABLE_COUNT="$(count_pattern "$DOWN_FILE" "^DROP TABLE IF EXISTS readmodel\\.")"
fi

detail "CREATE_SCHEMA_COUNT=$CREATE_SCHEMA_COUNT"
detail "CREATE_TABLE_COUNT=$CREATE_TABLE_COUNT"
detail "CREATE_INDEX_COUNT=$CREATE_INDEX_COUNT"
detail "TENANT_ID_COLUMN_COUNT=$TENANT_ID_COUNT"
detail "DOWN_DROP_TABLE_COUNT=$DOWN_DROP_TABLE_COUNT"
detail "DROP_TABLE_IN_UP_COUNT=$DROP_TABLE_IN_UP_COUNT"
detail "ALTER_SYSTEM_IN_UP_COUNT=$ALTER_SYSTEM_IN_UP_COUNT"
detail "DOCKER_IN_UP_COUNT=$DOCKER_IN_UP_COUNT"
detail "PSQL_IN_UP_COUNT=$PSQL_IN_UP_COUNT"

if [ "$CREATE_SCHEMA_COUNT" -ne 1 ]; then
  fail "readmodel schema create count 1 degil"
fi

if [ "$CREATE_TABLE_COUNT" -ne 6 ]; then
  fail "readmodel create table count 6 degil"
fi

if [ "$CREATE_INDEX_COUNT" -lt 7 ]; then
  fail "readmodel index count 7 altinda"
fi

if [ "$TENANT_ID_COUNT" -lt 6 ]; then
  fail "tenant_id column count 6 altinda"
fi

if [ "$DOWN_DROP_TABLE_COUNT" -ne 6 ]; then
  fail "down migration drop table count 6 degil"
fi

if [ "$DROP_TABLE_IN_UP_COUNT" -ne 0 ]; then
  fail "up migration icinde DROP bulundu"
fi

if [ "$ALTER_SYSTEM_IN_UP_COUNT" -ne 0 ]; then
  fail "up migration icinde ALTER SYSTEM bulundu"
fi

if [ "$DOCKER_IN_UP_COUNT" -ne 0 ] || [ "$PSQL_IN_UP_COUNT" -ne 0 ]; then
  fail "up migration icinde shell/psql ifadesi bulundu"
fi

CHAIN_VALIDATOR_STATUS="SKIPPED"

if [ -x "$ROOT_DIR/scripts/phase4_validate_migration_chain.sh" ]; then
  if bash "$ROOT_DIR/scripts/phase4_validate_migration_chain.sh" "$ROOT_DIR" "$ROOT_DIR/db/migrations" >/tmp/pix2pi_15_2_chain_validator.log 2>&1; then
    CHAIN_VALIDATOR_STATUS="PASS"
  else
    CHAIN_VALIDATOR_STATUS="FAIL"
    fail "migration chain validator failed"
  fi
fi

detail "MIGRATION_CHAIN_VALIDATOR_STATUS=$CHAIN_VALIDATOR_STATUS"

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
SCHEMA_MIGRATIONS_EXISTS="error"
SCHEMA_MIGRATIONS_DIRTY_STATE_RAW="error"
SCHEMA_MIGRATIONS_DIRTY_STATE="error"
DB_CURRENT_VERSION="error"
READMODEL_SCHEMA_EXISTS="error"
READMODEL_TABLE_COUNT="error"
READMODEL_TARGET_TABLE_COUNT="error"
READMODEL_ALREADY_APPLIED="UNKNOWN"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_15_2_psql_ok.log 2>/tmp/pix2pi_15_2_psql_err.log; then
    DB_CONNECTION_CHECK="PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"

  case "$IN_RECOVERY" in
    f|false)
      DB_ROLE="PRIMARY_WRITE"
      ;;
    t|true)
      DB_ROLE="REPLICA_READ_ONLY"
      fail "DB replica/read-only gorunuyor"
      ;;
    *)
      DB_ROLE="UNKNOWN"
      fail "pg_is_in_recovery okunamadi"
      ;;
  esac

  SCHEMA_MIGRATIONS_EXISTS="$(run_sql "select to_regclass('public.schema_migrations') is not null;")"
  SCHEMA_MIGRATIONS_EXISTS="$(normalize_pg_bool_false "$SCHEMA_MIGRATIONS_EXISTS")"

  if [ "$SCHEMA_MIGRATIONS_EXISTS" = "t" ]; then
    SCHEMA_MIGRATIONS_DIRTY_STATE_RAW="$(run_sql "select coalesce(bool_or(dirty), false)::text from public.schema_migrations;")"
    SCHEMA_MIGRATIONS_DIRTY_STATE="$(normalize_pg_bool_false "$SCHEMA_MIGRATIONS_DIRTY_STATE_RAW")"
    DB_CURRENT_VERSION="$(run_sql "select coalesce(max(version),0)::text from public.schema_migrations;")"
  else
    warn "schema_migrations yok; apply gate raporladi"
  fi

  READMODEL_SCHEMA_EXISTS="$(run_sql "select exists(select 1 from information_schema.schemata where schema_name='readmodel')::text;")"
  READMODEL_SCHEMA_EXISTS="$(normalize_pg_bool_false "$READMODEL_SCHEMA_EXISTS")"

  READMODEL_TABLE_COUNT="$(run_sql "select count(*)::text from information_schema.tables where table_schema='readmodel';")"
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

  if [ "$READMODEL_TARGET_TABLE_COUNT" = "6" ]; then
    READMODEL_ALREADY_APPLIED="YES"
    warn "readmodel target tablolar DB uzerinde zaten mevcut gorunuyor"
  else
    READMODEL_ALREADY_APPLIED="NO"
  fi
fi

detail "DB_CONNECTION_CHECK=$DB_CONNECTION_CHECK"
detail "DB_ROLE=$DB_ROLE"
detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_MIGRATIONS_EXISTS"
detail "SCHEMA_MIGRATIONS_DIRTY_STATE_RAW=$SCHEMA_MIGRATIONS_DIRTY_STATE_RAW"
detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$SCHEMA_MIGRATIONS_DIRTY_STATE"
detail "DB_CURRENT_VERSION=$DB_CURRENT_VERSION"
detail "READMODEL_SCHEMA_EXISTS=$READMODEL_SCHEMA_EXISTS"
detail "READMODEL_TABLE_COUNT=$READMODEL_TABLE_COUNT"
detail "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
detail "READMODEL_ALREADY_APPLIED=$READMODEL_ALREADY_APPLIED"

if [ "$DB_CONNECTION_CHECK" != "PASS" ]; then
  fail "DB connection PASS degil"
fi

if [ "$DB_ROLE" != "PRIMARY_WRITE" ]; then
  fail "DB role PRIMARY_WRITE degil"
fi

if [ "$SCHEMA_MIGRATIONS_EXISTS" = "t" ] && [ "$SCHEMA_MIGRATIONS_DIRTY_STATE" != "f" ]; then
  fail "schema_migrations dirty state temiz degil"
fi

cat <<PLAN > "$PLAN_FILE"
#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the FAZ 4 / 15.2 readmodel apply candidate execution file."
echo "15.2 gate does not execute migration apply."
echo "Actual apply belongs to FAZ 4 / 15.3 with explicit approval."
exit 99

# FAZ 4 / 15.2 - Readmodel Apply Candidate Execution
# Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')
# This file is intentionally blocked by exit 99 above.

cd ~/pix2pi/pix2pi-SaaS

MIGRATION_BASE="${MIGRATION_BASE}"
UP_FILE="db/migrations/${MIGRATION_BASE}.up.sql"
DOWN_FILE="db/migrations/${MIGRATION_BASE}.down.sql"

# Required explicit env:
# export APPLY_READMODEL=1
# export DB_WRITE_DSN='***'

if [ "\${APPLY_READMODEL:-0}" != "1" ]; then
  echo "APPLY_READMODEL_NOT_CONFIRMED"
  exit 2
fi

# Mandatory pre-checks:
bash scripts/phase4_readmodel_apply_gate.sh . "\$MIGRATION_BASE"

# Candidate apply command:
# psql "\${DB_WRITE_DSN:?DB_WRITE_DSN required}" -v ON_ERROR_STOP=1 -f "\$UP_FILE"

# Mandatory post-checks after actual apply:
# bash scripts/phase4_readmodel_apply_gate.sh . "\$MIGRATION_BASE"
# Verify READMODEL_TARGET_TABLE_COUNT=6
PLAN

chmod 600 "$PLAN_FILE"

detail "READMODEL_APPLY_CANDIDATE_PLAN_CREATED=YES"
detail "READMODEL_APPLY_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT=YES"
detail "READMODEL_APPLY_DECISION=PLAN_READY_APPLY_NOT_EXECUTED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "READMODEL_APPLY_GATE=PASS"
else
  detail "READMODEL_APPLY_GATE=FAIL"
fi

{
  echo "# FAZ 4 / 15.2 - Operational Readmodel Apply Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "READMODEL_APPLY_GATE=PASS"
  else
    echo "READMODEL_APPLY_GATE=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Planned Execution"
  echo "DB_APPLY_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "READMODEL_APPLY_DECISION=PLAN_READY_APPLY_NOT_EXECUTED"
  echo "PLAN_FILE=docs/phase4/15_2_readmodel_apply_candidate_execution.sh"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ readmodel apply gate major risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "DB_APPLY_EXECUTED=NO"
  echo "DB_MUTATION=NO"
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

echo "REPORT_FILE=$REPORT_FILE"
echo "PLAN_FILE=$PLAN_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "READMODEL_APPLY_DECISION=PLAN_READY_APPLY_NOT_EXECUTED"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "READMODEL_APPLY_GATE=FAIL ❌"
  exit 1
fi

echo "READMODEL_APPLY_GATE=PASS ✅"
