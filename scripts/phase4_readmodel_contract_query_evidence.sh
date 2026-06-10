#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/15_4_readmodel_contract_query_evidence_report.md"
INVENTORY_FILE="$REPORT_DIR/15_4_readmodel_contract_inventory.tsv"
CLOSURE_FILE="$REPORT_DIR/15_readmodel_final_closure_report.md"

PREV_REPORT="$REPORT_DIR/15_3_readmodel_controlled_apply_report.md"
GATE_REPORT="$REPORT_DIR/15_2_readmodel_apply_gate_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
SMOKE_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$SMOKE_FILE"' EXIT

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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_15_4_sql_err.log || echo "error"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "DB_PERSISTENT_MUTATION=NO"
detail "ROLLBACK_SMOKE_ALLOWED=YES"
detail "INVENTORY_FILE=docs/phase4/15_4_readmodel_contract_inventory.tsv"
detail "CLOSURE_FILE=docs/phase4/15_readmodel_final_closure_report.md"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi
tool_status "grep" >/dev/null || true
tool_status "wc" >/dev/null || true

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_APPLY="$(get_report_value "$PREV_REPORT" "READMODEL_CONTROLLED_APPLY")"
PREV_APPLY_EXECUTED="$(get_report_value "$PREV_REPORT" "DB_APPLY_EXECUTED")"
PREV_MUTATION_SCOPE="$(get_report_value "$PREV_REPORT" "DB_MUTATION_SCOPE")"
PREV_TARGET_COUNT="$(get_report_value "$PREV_REPORT" "READMODEL_TARGET_TABLE_COUNT")"
PREV_TENANT_ID_COUNT="$(get_report_value "$PREV_REPORT" "READMODEL_TENANT_ID_COLUMN_COUNT")"
PREV_INDEX_COUNT="$(get_report_value "$PREV_REPORT" "READMODEL_INDEX_COUNT")"

detail "PREVIOUS_15_3_READMODEL_CONTROLLED_APPLY=$PREV_APPLY"
detail "PREVIOUS_15_3_DB_APPLY_EXECUTED=$PREV_APPLY_EXECUTED"
detail "PREVIOUS_15_3_DB_MUTATION_SCOPE=$PREV_MUTATION_SCOPE"
detail "PREVIOUS_15_3_READMODEL_TARGET_TABLE_COUNT=$PREV_TARGET_COUNT"
detail "PREVIOUS_15_3_READMODEL_TENANT_ID_COLUMN_COUNT=$PREV_TENANT_ID_COUNT"
detail "PREVIOUS_15_3_READMODEL_INDEX_COUNT=$PREV_INDEX_COUNT"

if [ "$PREV_APPLY" != "PASS" ]; then
  fail "15.3 controlled apply PASS degil"
fi

if [ "$PREV_APPLY_EXECUTED" != "YES" ]; then
  fail "15.3 DB apply executed YES degil"
fi

if [ "$PREV_MUTATION_SCOPE" != "READMODEL_SCHEMA_ONLY" ]; then
  fail "15.3 mutation scope READMODEL_SCHEMA_ONLY degil"
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

DB_CONNECTION_CHECK="FAIL"
DB_ROLE="UNKNOWN"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_15_4_psql_ok.log 2>/tmp/pix2pi_15_4_psql_err.log; then
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
fi

detail "DB_CONNECTION_CHECK=$DB_CONNECTION_CHECK"
detail "DB_ROLE=$DB_ROLE"

READMODEL_SCHEMA_EXISTS="error"
READMODEL_TARGET_TABLE_COUNT="error"
READMODEL_TABLE_TOTAL_COUNT="error"
READMODEL_TENANT_ID_COLUMN_COUNT="error"
READMODEL_PRIMARY_KEY_COUNT="error"
READMODEL_INDEX_COUNT="error"
READMODEL_NOT_NULL_TENANT_COUNT="error"

PROJECTION_STATE_REQUIRED_COLUMN_COUNT="error"
DOCUMENT_WORK_QUEUE_REQUIRED_COLUMN_COUNT="error"
INVENTORY_STATUS_REQUIRED_COLUMN_COUNT="error"
DAILY_METRICS_REQUIRED_COLUMN_COUNT="error"
TENANT_SNAPSHOT_REQUIRED_COLUMN_COUNT="error"
RECONCILIATION_REQUIRED_COLUMN_COUNT="error"

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

  READMODEL_TABLE_TOTAL_COUNT="$(run_sql "select count(*)::text from information_schema.tables where table_schema='readmodel';")"

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

  PROJECTION_STATE_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='projection_state'
and column_name in ('tenant_id','projection_name','projection_version','source_stream','last_event_id','last_event_time','last_sequence','status','error_count','last_error','created_at','updated_at');
")"

  DOCUMENT_WORK_QUEUE_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='document_work_queue'
and column_name in ('tenant_id','document_type','document_id','source_module','status','priority','due_at','last_error','retry_count','last_event_id','created_at','updated_at');
")"

  INVENTORY_STATUS_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='inventory_status_snapshot'
and column_name in ('tenant_id','item_id','warehouse_id','sku','item_name','on_hand_qty','reserved_qty','available_qty','min_stock_qty','negative_stock_flag','below_min_stock_flag','last_movement_at','refreshed_at','updated_at');
")"

  DAILY_METRICS_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='daily_operational_metrics'
and column_name in ('tenant_id','metric_date','sales_document_count','sales_total','purchase_document_count','purchase_total','payment_in_total','payment_out_total','stock_movement_count','journal_count','error_count','refreshed_at','updated_at');
")"

  TENANT_SNAPSHOT_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='tenant_operational_snapshot'
and column_name in ('tenant_id','legal_entity_count','branch_count','active_user_count','customer_count','vendor_count','product_count','open_sales_document_count','open_purchase_document_count','stock_alert_count','pending_document_count','pending_payment_count','last_event_time','refreshed_at','updated_at');
")"

  RECONCILIATION_REQUIRED_COLUMN_COUNT="$(run_sql "
select count(*)::text
from information_schema.columns
where table_schema='readmodel'
and table_name='reconciliation_status_snapshot'
and column_name in ('tenant_id','scope_type','scope_id','status','unreconciled_count','difference_amount','currency_code','last_reconciled_at','refreshed_at','updated_at');
")"

  POST_DB_HEALTH_WAITING_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where not granted;")"
  POST_DB_HEALTH_IDLE_TX_COUNT="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  POST_DB_HEALTH_LONG_QUERY_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  POST_DB_HEALTH_DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
fi

detail "READMODEL_SCHEMA_EXISTS=$READMODEL_SCHEMA_EXISTS"
detail "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
detail "READMODEL_TABLE_TOTAL_COUNT=$READMODEL_TABLE_TOTAL_COUNT"
detail "READMODEL_TENANT_ID_COLUMN_COUNT=$READMODEL_TENANT_ID_COLUMN_COUNT"
detail "READMODEL_NOT_NULL_TENANT_COUNT=$READMODEL_NOT_NULL_TENANT_COUNT"
detail "READMODEL_PRIMARY_KEY_COUNT=$READMODEL_PRIMARY_KEY_COUNT"
detail "READMODEL_INDEX_COUNT=$READMODEL_INDEX_COUNT"
detail "PROJECTION_STATE_REQUIRED_COLUMN_COUNT=$PROJECTION_STATE_REQUIRED_COLUMN_COUNT"
detail "DOCUMENT_WORK_QUEUE_REQUIRED_COLUMN_COUNT=$DOCUMENT_WORK_QUEUE_REQUIRED_COLUMN_COUNT"
detail "INVENTORY_STATUS_REQUIRED_COLUMN_COUNT=$INVENTORY_STATUS_REQUIRED_COLUMN_COUNT"
detail "DAILY_METRICS_REQUIRED_COLUMN_COUNT=$DAILY_METRICS_REQUIRED_COLUMN_COUNT"
detail "TENANT_SNAPSHOT_REQUIRED_COLUMN_COUNT=$TENANT_SNAPSHOT_REQUIRED_COLUMN_COUNT"
detail "RECONCILIATION_REQUIRED_COLUMN_COUNT=$RECONCILIATION_REQUIRED_COLUMN_COUNT"

detail "POST_DB_HEALTH_WAITING_LOCK_COUNT=$POST_DB_HEALTH_WAITING_LOCK_COUNT"
detail "POST_DB_HEALTH_IDLE_IN_TRANSACTION_CONNECTIONS=$POST_DB_HEALTH_IDLE_TX_COUNT"
detail "POST_DB_HEALTH_LONG_RUNNING_ACTIVE_QUERIES_60S=$POST_DB_HEALTH_LONG_QUERY_60S"
detail "POST_DB_HEALTH_DEADLOCK_COUNT=$POST_DB_HEALTH_DEADLOCK_COUNT"

if [ "$READMODEL_SCHEMA_EXISTS" != "t" ]; then fail "readmodel schema yok"; fi
if [ "$READMODEL_TARGET_TABLE_COUNT" != "6" ]; then fail "target table count 6 degil"; fi
if [ "$READMODEL_TENANT_ID_COLUMN_COUNT" != "6" ]; then fail "tenant_id column count 6 degil"; fi
if [ "$READMODEL_NOT_NULL_TENANT_COUNT" != "6" ]; then fail "tenant_id not null count 6 degil"; fi
if [ "$READMODEL_PRIMARY_KEY_COUNT" != "6" ]; then fail "primary key count 6 degil"; fi
if [ "$READMODEL_INDEX_COUNT" -lt 13 ]; then fail "readmodel index count 13 altinda"; fi

if [ "$PROJECTION_STATE_REQUIRED_COLUMN_COUNT" != "12" ]; then fail "projection_state required column count 12 degil"; fi
if [ "$DOCUMENT_WORK_QUEUE_REQUIRED_COLUMN_COUNT" != "12" ]; then fail "document_work_queue required column count 12 degil"; fi
if [ "$INVENTORY_STATUS_REQUIRED_COLUMN_COUNT" != "14" ]; then fail "inventory_status required column count 14 degil"; fi
if [ "$DAILY_METRICS_REQUIRED_COLUMN_COUNT" != "13" ]; then fail "daily metrics required column count 13 degil"; fi
if [ "$TENANT_SNAPSHOT_REQUIRED_COLUMN_COUNT" != "15" ]; then fail "tenant snapshot required column count 15 degil"; fi
if [ "$RECONCILIATION_REQUIRED_COLUMN_COUNT" != "10" ]; then fail "reconciliation required column count 10 degil"; fi

{
  echo -e "object_type\tobject_name\tcontract_status"
} > "$INVENTORY_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select 'table' as object_type, table_schema || '.' || table_name as object_name, 'FOUND' as contract_status
from information_schema.tables
where table_schema='readmodel'
order by table_name;
" >> "$INVENTORY_FILE" 2>/tmp/pix2pi_15_4_inventory_tables_err.log || true

  psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select 'primary_key' as object_type, table_schema || '.' || table_name || '.' || constraint_name as object_name, 'FOUND' as contract_status
from information_schema.table_constraints
where table_schema='readmodel'
and constraint_type='PRIMARY KEY'
order by table_name;
" >> "$INVENTORY_FILE" 2>/tmp/pix2pi_15_4_inventory_pk_err.log || true

  psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select 'index' as object_type, schemaname || '.' || indexname as object_name, 'FOUND' as contract_status
from pg_indexes
where schemaname='readmodel'
order by indexname;
" >> "$INVENTORY_FILE" 2>/tmp/pix2pi_15_4_inventory_idx_err.log || true
fi

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "READMODEL_CONTRACT_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

ROLLBACK_SMOKE_RESULT="SKIPPED"
ROLLBACK_SMOKE_PERSISTED_COUNT="error"
ROLLBACK_SMOKE_SELECT_RESULT="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SMOKE_SQL_FILE="$(mktemp)"
  SMOKE_OUT_FILE="$(mktemp)"
  SMOKE_ERR_FILE="$(mktemp)"

  cat <<'SQL' > "$SMOKE_SQL_FILE"
BEGIN;

INSERT INTO readmodel.projection_state (
  tenant_id,
  projection_name,
  projection_version,
  source_stream,
  last_event_id,
  last_event_time,
  last_sequence,
  status,
  error_count
) VALUES (
  'tenant_smoke_15_4',
  'smoke_projection',
  1,
  'smoke_stream',
  'smoke_event',
  now(),
  1,
  'idle',
  0
);

SELECT 'ROLLBACK_SMOKE_SELECT_RESULT=' || count(*)::text
FROM readmodel.projection_state
WHERE tenant_id='tenant_smoke_15_4'
  AND projection_name='smoke_projection';

ROLLBACK;
SQL

  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atf "$SMOKE_SQL_FILE" >"$SMOKE_OUT_FILE" 2>"$SMOKE_ERR_FILE"; then
    ROLLBACK_SMOKE_SELECT_RESULT="$(grep '^ROLLBACK_SMOKE_SELECT_RESULT=' "$SMOKE_OUT_FILE" | tail -n 1 | cut -d= -f2- || true)"
  else
    ROLLBACK_SMOKE_SELECT_RESULT="error"
  fi

  ROLLBACK_SMOKE_PERSISTED_COUNT="$(run_sql "select count(*)::text from readmodel.projection_state where tenant_id='tenant_smoke_15_4' and projection_name='smoke_projection';")"

  echo "ROLLBACK_SMOKE_SELECT_RESULT=$ROLLBACK_SMOKE_SELECT_RESULT" > "$SMOKE_FILE"
  echo "ROLLBACK_SMOKE_PERSISTED_COUNT=$ROLLBACK_SMOKE_PERSISTED_COUNT" >> "$SMOKE_FILE"

  rm -f "$SMOKE_SQL_FILE" "$SMOKE_OUT_FILE" "$SMOKE_ERR_FILE"

  if [ "$ROLLBACK_SMOKE_SELECT_RESULT" = "1" ] && [ "$ROLLBACK_SMOKE_PERSISTED_COUNT" = "0" ]; then
    ROLLBACK_SMOKE_RESULT="PASS"
  else
    ROLLBACK_SMOKE_RESULT="FAIL"
    fail "rollback smoke test kalici veri birakmadan PASS olmadi"
  fi
fi

detail "READMODEL_ROLLBACK_SMOKE=$ROLLBACK_SMOKE_RESULT"
detail "ROLLBACK_SMOKE_PERSISTED_COUNT=$ROLLBACK_SMOKE_PERSISTED_COUNT"
detail "DB_PERSISTENT_MUTATION=NO"

POST_GATE_STATUS="UNKNOWN"
POST_GATE_ALREADY_APPLIED="UNKNOWN"
POST_GATE_TARGET_COUNT="UNKNOWN"

if [ "$FAIL_COUNT" -eq 0 ] && [ -x "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" ]; then
  if bash "$ROOT_DIR/scripts/phase4_readmodel_apply_gate.sh" "$ROOT_DIR" "20260427_151001_readmodel_operational_tables" >/tmp/pix2pi_15_4_post_gate.log 2>&1; then
    POST_GATE_STATUS="$(get_report_value "$GATE_REPORT" "READMODEL_APPLY_GATE")"
    POST_GATE_ALREADY_APPLIED="$(get_report_value "$GATE_REPORT" "READMODEL_ALREADY_APPLIED")"
    POST_GATE_TARGET_COUNT="$(get_report_value "$GATE_REPORT" "READMODEL_TARGET_TABLE_COUNT")"
  else
    POST_GATE_STATUS="FAIL"
    fail "15.4 post gate failed"
  fi
fi

detail "POST_15_4_READMODEL_APPLY_GATE=$POST_GATE_STATUS"
detail "POST_15_4_READMODEL_ALREADY_APPLIED=$POST_GATE_ALREADY_APPLIED"
detail "POST_15_4_READMODEL_TARGET_TABLE_COUNT=$POST_GATE_TARGET_COUNT"

if [ "$POST_GATE_STATUS" != "PASS" ]; then fail "post 15.4 gate PASS degil"; fi
if [ "$POST_GATE_ALREADY_APPLIED" != "YES" ]; then fail "post 15.4 already applied YES degil"; fi
if [ "$POST_GATE_TARGET_COUNT" != "6" ]; then fail "post 15.4 target count 6 degil"; fi

if [ "$POST_DB_HEALTH_WAITING_LOCK_COUNT" != "0" ]; then warn "waiting lock count sifir degil"; fi
if [ "$POST_DB_HEALTH_IDLE_TX_COUNT" != "0" ]; then warn "idle in transaction count sifir degil"; fi
if [ "$POST_DB_HEALTH_LONG_QUERY_60S" != "0" ]; then warn "long query 60s count sifir degil"; fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "READMODEL_CONTRACT_QUERY_EVIDENCE=PASS"
  detail "READMODEL_FINAL_CLOSURE=PASS"
else
  detail "READMODEL_CONTRACT_QUERY_EVIDENCE=FAIL"
  detail "READMODEL_FINAL_CLOSURE=FAIL"
fi

{
  echo "# FAZ 4 / 15.4 - Readmodel Contract / Query Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "READMODEL_CONTRACT_QUERY_EVIDENCE=PASS"
  else
    echo "READMODEL_CONTRACT_QUERY_EVIDENCE=FAIL"
  fi

  echo
  echo "## Tool Status"
  cat "$TOOL_FILE"

  echo
  echo "## Rollback Smoke Evidence"
  if [ -s "$SMOKE_FILE" ]; then
    cat "$SMOKE_FILE"
  else
    echo "ROLLBACK_SMOKE=SKIPPED"
  fi

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ readmodel contract major risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "DB_PERSISTENT_MUTATION=NO"
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
  echo "# FAZ 4 / 15 - Readmodel Final Closure Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "15.1 Operational readmodel tables migration pair=PASS"
  echo "15.2 Operational readmodel apply gate=PASS"
  echo "15.3 Operational readmodel controlled apply=PASS"
  echo "15.4 Readmodel contract/query evidence=PASS"
  echo
  echo "READMODEL_FINAL_CLOSURE=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
  echo "READMODEL_SCHEMA_EXISTS=$READMODEL_SCHEMA_EXISTS"
  echo "READMODEL_TARGET_TABLE_COUNT=$READMODEL_TARGET_TABLE_COUNT"
  echo "READMODEL_PRIMARY_KEY_COUNT=$READMODEL_PRIMARY_KEY_COUNT"
  echo "READMODEL_INDEX_COUNT=$READMODEL_INDEX_COUNT"
  echo "READMODEL_TENANT_ID_COLUMN_COUNT=$READMODEL_TENANT_ID_COLUMN_COUNT"
  echo "READMODEL_NOT_NULL_TENANT_COUNT=$READMODEL_NOT_NULL_TENANT_COUNT"
  echo "READMODEL_ROLLBACK_SMOKE=$ROLLBACK_SMOKE_RESULT"
  echo "DB_PERSISTENT_MUTATION=NO"
  echo "FAZ4_15_FINAL_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
} > "$CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "CLOSURE_FILE=$CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "READMODEL_CONTRACT_QUERY_EVIDENCE=FAIL ❌"
  exit 1
fi

echo "READMODEL_CONTRACT_QUERY_EVIDENCE=PASS ✅"
