#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MIGRATION_BASE="${2:-20260427_151001_readmodel_operational_tables}"

ENV_FILE="$ROOT_DIR/.env"
UP_FILE="$ROOT_DIR/db/migrations/${MIGRATION_BASE}.up.sql"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/15_3_readmodel_controlled_apply_report.md"
INVENTORY_FILE="$REPORT_DIR/15_3_readmodel_post_apply_inventory.tsv"

GATE_REPORT="$REPORT_DIR/15_2_readmodel_apply_gate_report.md"
BACKUP_REPORT="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
APPLY_STDOUT="$(mktemp)"
APPLY_STDERR="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$APPLY_STDOUT" "$APPLY_STDERR"' EXIT

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

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_15_3_sql_err.log || echo "error"
}

write_report_and_exit() {
  local status="$1"

  {
    echo "# FAZ 4 / 15.3 - Operational Readmodel Controlled Apply Report"
    echo
    echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo
    echo "## Summary"
    cat "$DETAILS_FILE"
    echo "FAIL_COUNT=$FAIL_COUNT"
    echo "WARN_COUNT=$WARN_COUNT"
    echo "READMODEL_CONTROLLED_APPLY=$status"
    echo
    echo "## Tool Status"
    cat "$TOOL_FILE"
    echo
    echo "## Evidence Files"
    echo "POST_APPLY_INVENTORY_FILE=docs/phase4/15_3_readmodel_post_apply_inventory.tsv"
    echo
    echo "## Risks"
    if [ -s "$RISK_FILE" ]; then
      cat "$RISK_FILE"
    else
      echo "OK ✅ readmodel controlled apply major risk yok"
    fi
    echo
    echo "## Safety Decision"
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
  echo "INVENTORY_FILE=$INVENTORY_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "READMODEL_CONTROLLED_APPLY=$status"

  case "$status" in
    PASS)
      echo "READMODEL_CONTROLLED_APPLY=PASS ✅"
      exit 0
      ;;
    DRY_RUN_PASS)
      echo "READMODEL_CONTROLLED_APPLY=DRY_RUN_PASS ✅"
      exit 0
      ;;
    *)
      echo "READMODEL_CONTROLLED_APPLY=$status ❌"
      exit 1
      ;;
  esac
}

detail "ROOT_DIR=$ROOT_DIR"
detail "MIGRATION_BASE=$MIGRATION_BASE"
detail "UP_FILE=db/migrations/${MIGRATION_BASE}.up.sql"
detail "APPLY_READMODEL=${APPLY_READMODEL:-0}"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

if [ ! -f "$UP_FILE" ]; then
  fail "up migration bulunamadi: $UP_FILE"
fi

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

if [ "${APPLY_READMODEL:-0}" != "1" ]; then
  detail "DB_APPLY_EXECUTED=NO"
  detail "DB_MUTATION=NO"
  detail "READMODEL_APPLY_MODE=DRY_RUN_BLOCKED_BY_DEFAULT"
  detail "READMODEL_CONTROLLED_APPLY=DRY_RUN_PASS"
  write_report_and_exit "DRY_RUN_PASS"
fi

detail "READMODEL_APPLY_MODE=CONTROLLED_APPLY"

echo -e "object_type\tobject_name\tstatus" > "$INVENTORY_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ -x "$ROOT_DIR/scripts/phase4_logical_backup_smoke.sh" ]; then
    if bash "$ROOT_DIR/scripts/phase4_logical_backup_smoke.sh" "$ROOT_DIR" >/tmp/pix2pi_15_3_backup_smoke.log 2>&1; then
      detail "FRESH_LOGICAL_BACKUP_SMOKE_RUN=PASS"
    else
      fail "fresh logical backup smoke failed"
    fi
  else
    fail "phase4_logical_backup_smoke.sh bulunamadi"
  fi
fi

FRESH_BACKUP_STATUS="$(get_report_value "$BACKUP_REPORT" "LOGICAL_BACKUP_SMOKE")"
detail "FRESH_LOGICAL_BACKUP_SMOKE=$FRESH_BACKUP_STATUS"

if [ "$FRESH_BACKUP_STATUS" != "PASS" ]; then
  fail "fresh logical backup smoke PASS degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  if [ -x "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" ]; then
    if bash "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" "$ROOT_DIR" "$MIGRATION_BASE" >/tmp/pix2pi_15_3_pre_gate.log 2>&1; then
      detail "PRE_APPLY_READMODEL_GATE_RUN=PASS"
    else
      fail "pre-apply readmodel gate failed"
    fi
  else
    fail "phase4_readmodel_apply_gate.sh bulunamadi"
  fi
fi

PRE_GATE_STATUS="$(get_report_value "$GATE_REPORT" "READMODEL_APPLY_GATE")"
PRE_GATE_ALREADY_APPLIED="$(get_report_value "$GATE_REPORT" "READMODEL_ALREADY_APPLIED")"
PRE_GATE_TARGET_COUNT="$(get_report_value "$GATE_REPORT" "READMODEL_TARGET_TABLE_COUNT")"
PRE_GATE_DIRTY="$(get_report_value "$GATE_REPORT" "SCHEMA_MIGRATIONS_DIRTY_STATE")"

detail "PRE_APPLY_READMODEL_APPLY_GATE=$PRE_GATE_STATUS"
detail "PRE_APPLY_READMODEL_ALREADY_APPLIED=$PRE_GATE_ALREADY_APPLIED"
detail "PRE_APPLY_READMODEL_TARGET_TABLE_COUNT=$PRE_GATE_TARGET_COUNT"
detail "PRE_APPLY_SCHEMA_MIGRATIONS_DIRTY_STATE=$PRE_GATE_DIRTY"

if [ "$PRE_GATE_STATUS" != "PASS" ]; then
  fail "pre-apply gate PASS degil"
fi

if [ "$PRE_GATE_DIRTY" != "f" ]; then
  fail "pre-apply schema_migrations dirty state temiz degil"
fi

DB_CONNECTION_CHECK="FAIL"
DB_ROLE="UNKNOWN"
SCHEMA_MIGRATIONS_EXISTS="error"
SCHEMA_MIGRATIONS_DIRTY_STATE_RAW="error"
SCHEMA_MIGRATIONS_DIRTY_STATE="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_15_3_psql_ok.log 2>/tmp/pix2pi_15_3_psql_err.log; then
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

  SCHEMA_MIGRATIONS_EXISTS="$(run_sql "select to_regclass('public.schema_migrations') is not null;")"
  SCHEMA_MIGRATIONS_EXISTS="$(normalize_pg_bool_false "$SCHEMA_MIGRATIONS_EXISTS")"

  if [ "$SCHEMA_MIGRATIONS_EXISTS" = "t" ]; then
    SCHEMA_MIGRATIONS_DIRTY_STATE_RAW="$(run_sql "select coalesce(bool_or(dirty), false)::text from public.schema_migrations;")"
    SCHEMA_MIGRATIONS_DIRTY_STATE="$(normalize_pg_bool_false "$SCHEMA_MIGRATIONS_DIRTY_STATE_RAW")"
  fi
fi

detail "DB_CONNECTION_CHECK=$DB_CONNECTION_CHECK"
detail "DB_ROLE=$DB_ROLE"
detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_MIGRATIONS_EXISTS"
detail "SCHEMA_MIGRATIONS_DIRTY_STATE_RAW=$SCHEMA_MIGRATIONS_DIRTY_STATE_RAW"
detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$SCHEMA_MIGRATIONS_DIRTY_STATE"

if [ "$DB_CONNECTION_CHECK" != "PASS" ]; then fail "DB connection PASS degil"; fi
if [ "$DB_ROLE" != "PRIMARY_WRITE" ]; then fail "DB role PRIMARY_WRITE degil"; fi
if [ "$SCHEMA_MIGRATIONS_EXISTS" = "t" ] && [ "$SCHEMA_MIGRATIONS_DIRTY_STATE" != "f" ]; then
  fail "schema_migrations dirty state temiz degil"
fi

APPLY_STATUS="NOT_EXECUTED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if psql "$DB_DSN" -v ON_ERROR_STOP=1 -f "$UP_FILE" >"$APPLY_STDOUT" 2>"$APPLY_STDERR"; then
    APPLY_STATUS="PASS"
    detail "DB_APPLY_EXECUTED=YES"
    detail "DB_MUTATION=YES"
    detail "DB_MUTATION_SCOPE=READMODEL_SCHEMA_ONLY"
    detail "READMODEL_SQL_APPLY_STATUS=PASS"
  else
    APPLY_STATUS="FAIL"
    detail "DB_APPLY_EXECUTED=ATTEMPTED"
    detail "DB_MUTATION=UNKNOWN"
    detail "READMODEL_SQL_APPLY_STATUS=FAIL"
    fail "readmodel SQL apply failed"
  fi
else
  detail "DB_APPLY_EXECUTED=NO"
  detail "DB_MUTATION=NO"
fi

READMODEL_SCHEMA_EXISTS="error"
READMODEL_TARGET_TABLE_COUNT="error"
READMODEL_INDEX_COUNT="error"
READMODEL_TENANT_ID_COLUMN_COUNT="error"
POST_DB_HEALTH_WAITING_LOCK_COUNT="error"
POST_DB_HEALTH_IDLE_TX_COUNT="error"
POST_DB_HEALTH_LONG_QUERY_60S="error"
POST_DB_HEALTH_DEADLOCK_COUNT="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
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

  READMODEL_INDEX_COUNT="$(run_sql "
select count(*)::text
from pg_indexes
where schemaname='readmodel'
and indexname in (
  'projection_state_pkey',
  'tenant_operational_snapshot_pkey',
  'daily_operational_metrics_pkey',
  'inventory_status_snapshot_pkey',
  'document_work_queue_pkey',
  'reconciliation_status_snapshot_pkey',
  'idx_projection_state_status',
  'idx_tenant_operational_snapshot_refreshed',
  'idx_daily_operational_metrics_date',
  'idx_inventory_status_alerts',
  'idx_document_work_queue_status_priority',
  'idx_document_work_queue_source_module',
  'idx_reconciliation_status_snapshot_status'
);
")"

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

  POST_DB_HEALTH_WAITING_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where not granted;")"
  POST_DB_HEALTH_IDLE_TX_COUNT="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  POST_DB_HEALTH_LONG_QUERY_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  POST_DB_HEALTH_DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"

  psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select 'table' as object_type, table_schema || '.' || table_name as object_name, 'FOUND' as status
from information_schema.tables
where table_schema='readmodel'
order by table_name;
" >> "$INVENTORY_FILE" 2>/tmp/pix2pi_15_3_inventory_err.log || true

  psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select 'index' as object_type, schemaname || '.' || indexname as object_name, 'FOUND' as status
from pg_indexes
where schemaname='readmodel'
order by indexname;
" >> "$INVENTORY_FILE" 2>/tmp/pix2pi_15_3_inventory_idx_err.log || true
fi

detail "READMODEL_SCHEMA_EXISTS=$READMODEL_SCHEMA_EXISTS"
detail "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
detail "READMODEL_INDEX_COUNT=$READMODEL_INDEX_COUNT"
detail "READMODEL_TENANT_ID_COLUMN_COUNT=$READMODEL_TENANT_ID_COLUMN_COUNT"
detail "POST_DB_HEALTH_WAITING_LOCK_COUNT=$POST_DB_HEALTH_WAITING_LOCK_COUNT"
detail "POST_DB_HEALTH_IDLE_IN_TRANSACTION_CONNECTIONS=$POST_DB_HEALTH_IDLE_TX_COUNT"
detail "POST_DB_HEALTH_LONG_RUNNING_ACTIVE_QUERIES_60S=$POST_DB_HEALTH_LONG_QUERY_60S"
detail "POST_DB_HEALTH_DEADLOCK_COUNT=$POST_DB_HEALTH_DEADLOCK_COUNT"

if [ "$READMODEL_SCHEMA_EXISTS" != "t" ]; then fail "readmodel schema bulunamadi"; fi
if [ "$READMODEL_TARGET_TABLE_COUNT" != "6" ]; then fail "readmodel target table count 6 degil"; fi

if [ "$READMODEL_TENANT_ID_COLUMN_COUNT" != "6" ]; then
  fail "readmodel tenant_id column count 6 degil"
fi

if [ "$POST_DB_HEALTH_WAITING_LOCK_COUNT" != "0" ]; then
  warn "post apply waiting lock count sifir degil: $POST_DB_HEALTH_WAITING_LOCK_COUNT"
fi

if [ "$POST_DB_HEALTH_IDLE_TX_COUNT" != "0" ]; then
  warn "post apply idle transaction count sifir degil: $POST_DB_HEALTH_IDLE_TX_COUNT"
fi

if [ "$POST_DB_HEALTH_LONG_QUERY_60S" != "0" ]; then
  warn "post apply long query 60s count sifir degil: $POST_DB_HEALTH_LONG_QUERY_60S"
fi

POST_GATE_STATUS="SKIPPED"
POST_GATE_ALREADY_APPLIED="UNKNOWN"
POST_GATE_TARGET_COUNT="UNKNOWN"

if [ "$FAIL_COUNT" -eq 0 ] && [ -x "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" ]; then
  if bash "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" "$ROOT_DIR" "$MIGRATION_BASE" >/tmp/pix2pi_15_3_post_gate.log 2>&1; then
    POST_GATE_STATUS="$(get_report_value "$GATE_REPORT" "READMODEL_APPLY_GATE")"
    POST_GATE_ALREADY_APPLIED="$(get_report_value "$GATE_REPORT" "READMODEL_ALREADY_APPLIED")"
    POST_GATE_TARGET_COUNT="$(get_report_value "$GATE_REPORT" "READMODEL_TARGET_TABLE_COUNT")"
  else
    POST_GATE_STATUS="FAIL"
    fail "post-apply readmodel gate failed"
  fi
fi

detail "POST_APPLY_READMODEL_GATE=$POST_GATE_STATUS"
detail "POST_APPLY_READMODEL_ALREADY_APPLIED=$POST_GATE_ALREADY_APPLIED"
detail "POST_APPLY_READMODEL_TARGET_TABLE_COUNT=$POST_GATE_TARGET_COUNT"

if [ "$POST_GATE_STATUS" != "PASS" ]; then
  fail "post-apply gate PASS degil"
fi

if [ "$POST_GATE_ALREADY_APPLIED" != "YES" ]; then
  fail "post-apply readmodel already applied YES degil"
fi

if [ "$POST_GATE_TARGET_COUNT" != "6" ]; then
  fail "post-apply target table count 6 degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "READMODEL_CONTROLLED_APPLY=PASS"
  write_report_and_exit "PASS"
fi

detail "READMODEL_CONTROLLED_APPLY=FAIL"
write_report_and_exit "FAIL"
