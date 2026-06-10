#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
CONNECTION_METRICS_FILE="$REPORT_DIR/14_4_4_connection_state_metrics.tsv"
LOCK_METRICS_FILE="$REPORT_DIR/14_4_4_lock_wait_metrics.tsv"

PREV_REPORT="$REPORT_DIR/14_4_3_vacuum_bloat_readiness_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE"' EXIT

detail() {
  echo "$1" >> "$DETAILS_FILE"
}

warn() {
  echo "WARN ⚠️ $1" >> "$ISSUES_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL ❌ $1" >> "$ISSUES_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

risk() {
  echo "$1" >> "$RISK_FILE"
}

strip_quotes() {
  local v="$1"
  v="${v%$'\r'}"

  case "$v" in
    \"*\")
      v="${v#\"}"
      v="${v%\"}"
      ;;
    \'*\')
      v="${v#\'}"
      v="${v%\'}"
      ;;
  esac

  echo "$v"
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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_4_4_sql_err.log || echo "error"
}

is_number() {
  local v="$1"
  case "$v" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

LONG_QUERY_WARN_SECONDS="${LONG_QUERY_WARN_SECONDS:-60}"
MAX_XACT_WARN_SECONDS="${MAX_XACT_WARN_SECONDS:-300}"
IDLE_TX_WARN_SECONDS="${IDLE_TX_WARN_SECONDS:-60}"
CONNECTION_USAGE_WARN_PERCENT="${CONNECTION_USAGE_WARN_PERCENT:-70}"

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "CONNECTION_METRICS_FILE=docs/phase4/14_4_4_connection_state_metrics.tsv"
detail "LOCK_METRICS_FILE=docs/phase4/14_4_4_lock_wait_metrics.tsv"
detail "LONG_QUERY_WARN_SECONDS=$LONG_QUERY_WARN_SECONDS"
detail "MAX_XACT_WARN_SECONDS=$MAX_XACT_WARN_SECONDS"
detail "IDLE_TX_WARN_SECONDS=$IDLE_TX_WARN_SECONDS"
detail "CONNECTION_USAGE_WARN_PERCENT=$CONNECTION_USAGE_WARN_PERCENT"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_STATUS="$(get_report_value "$PREV_REPORT" "VACUUM_BLOAT_READINESS")"
detail "PREVIOUS_14_4_3_VACUUM_BLOAT_READINESS=$PREV_STATUS"

if [ "$PREV_STATUS" != "PASS" ]; then
  fail "14.4.3 vacuum/bloat readiness PASS degil"
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

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_4_4_psql_ok.log 2>/tmp/pix2pi_14_4_4_psql_err.log; then
    detail "DB_CONNECTION_CHECK=PASS"
  else
    fail "DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"
  detail "PG_IS_IN_RECOVERY=$IN_RECOVERY"

  case "$IN_RECOVERY" in
    f)
      detail "DB_ROLE=PRIMARY_WRITE"
      ;;
    t)
      detail "DB_ROLE=REPLICA_READ_ONLY"
      fail "DB replica/read-only gorunuyor"
      ;;
    *)
      fail "pg_is_in_recovery okunamadi"
      ;;
  esac
fi

SERVER_VERSION="error"
MAX_CONNECTIONS="error"
SUPERUSER_RESERVED_CONNECTIONS="error"
TOTAL_CONNECTIONS="error"
ACTIVE_CONNECTIONS="error"
IDLE_CONNECTIONS="error"
IDLE_TX_CONNECTIONS="error"
DISABLED_CONNECTIONS="error"
CONNECTION_USAGE_PERCENT="error"
LONG_RUNNING_ACTIVE_QUERIES_60S="error"
MAX_ACTIVE_QUERY_AGE_SECONDS="error"
MAX_XACT_AGE_SECONDS="error"
MAX_IDLE_TX_AGE_SECONDS="error"
WAITING_LOCK_COUNT="error"
GRANTED_LOCK_COUNT="error"
TOTAL_LOCK_COUNT="error"
BLOCKED_PID_COUNT="error"
DEADLOCK_COUNT="error"
PREPARED_TRANSACTION_COUNT="error"
REPLICATION_CLIENT_COUNT="error"
REPLICATION_SLOT_COUNT="error"
ACTIVE_REPLICATION_SLOT_COUNT="error"
DATABASE_SIZE_BYTES="error"
STATS_RESET="error"
PG_STAT_EXTENSION="error"
TRACK_IO="error"
LOG_MIN="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION="$(run_sql "show server_version;")"
  MAX_CONNECTIONS="$(run_sql "show max_connections;")"
  SUPERUSER_RESERVED_CONNECTIONS="$(run_sql "show superuser_reserved_connections;")"
  TRACK_IO="$(run_sql "show track_io_timing;")"
  LOG_MIN="$(run_sql "show log_min_duration_statement;")"
  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"

  TOTAL_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database();")"
  ACTIVE_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active';")"
  IDLE_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle';")"
  IDLE_TX_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  DISABLED_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='disabled';")"

  if is_number "$MAX_CONNECTIONS" && is_number "$TOTAL_CONNECTIONS" && [ "$MAX_CONNECTIONS" -gt 0 ]; then
    CONNECTION_USAGE_PERCENT="$(( TOTAL_CONNECTIONS * 100 / MAX_CONNECTIONS ))"
  fi

  LONG_RUNNING_ACTIVE_QUERIES_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '${LONG_QUERY_WARN_SECONDS} seconds';")"
  MAX_ACTIVE_QUERY_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - query_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and state='active' and query_start is not null;")"
  MAX_XACT_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - xact_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and xact_start is not null;")"
  MAX_IDLE_TX_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - xact_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and state='idle in transaction' and xact_start is not null;")"

  WAITING_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where not granted;")"
  GRANTED_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where granted;")"
  TOTAL_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks;")"
  BLOCKED_PID_COUNT="$(run_sql "select count(distinct pid)::text from pg_locks where not granted;")"

  DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
  PREPARED_TRANSACTION_COUNT="$(run_sql "select count(*)::text from pg_prepared_xacts;")"
  REPLICATION_CLIENT_COUNT="$(run_sql "select count(*)::text from pg_stat_replication;")"
  REPLICATION_SLOT_COUNT="$(run_sql "select count(*)::text from pg_replication_slots;")"
  ACTIVE_REPLICATION_SLOT_COUNT="$(run_sql "select count(*)::text from pg_replication_slots where active;")"
  DATABASE_SIZE_BYTES="$(run_sql "select pg_database_size(current_database())::bigint::text;")"
  STATS_RESET="$(run_sql "select coalesce(stats_reset::text,'NULL') from pg_stat_database where datname=current_database();")"
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "POSTGRES_MAX_CONNECTIONS=$MAX_CONNECTIONS"
detail "POSTGRES_SUPERUSER_RESERVED_CONNECTIONS=$SUPERUSER_RESERVED_CONNECTIONS"
detail "TRACK_IO_TIMING=$TRACK_IO"
detail "LOG_MIN_DURATION_STATEMENT=$LOG_MIN"
detail "PG_STAT_STATEMENTS_EXTENSION=$PG_STAT_EXTENSION"
detail "PG_STAT_DATABASE_STATS_RESET=$STATS_RESET"
detail "DATABASE_SIZE_BYTES=$DATABASE_SIZE_BYTES"

detail "DB_TOTAL_CONNECTIONS=$TOTAL_CONNECTIONS"
detail "DB_ACTIVE_CONNECTIONS=$ACTIVE_CONNECTIONS"
detail "DB_IDLE_CONNECTIONS=$IDLE_CONNECTIONS"
detail "DB_IDLE_IN_TRANSACTION_CONNECTIONS=$IDLE_TX_CONNECTIONS"
detail "DB_DISABLED_CONNECTIONS=$DISABLED_CONNECTIONS"
detail "DB_CONNECTION_USAGE_PERCENT=$CONNECTION_USAGE_PERCENT"
detail "DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$LONG_RUNNING_ACTIVE_QUERIES_60S"
detail "DB_MAX_ACTIVE_QUERY_AGE_SECONDS=$MAX_ACTIVE_QUERY_AGE_SECONDS"
detail "DB_MAX_XACT_AGE_SECONDS=$MAX_XACT_AGE_SECONDS"
detail "DB_MAX_IDLE_TX_AGE_SECONDS=$MAX_IDLE_TX_AGE_SECONDS"

detail "DB_WAITING_LOCK_COUNT=$WAITING_LOCK_COUNT"
detail "DB_GRANTED_LOCK_COUNT=$GRANTED_LOCK_COUNT"
detail "DB_TOTAL_LOCK_COUNT=$TOTAL_LOCK_COUNT"
detail "DB_BLOCKED_PID_COUNT=$BLOCKED_PID_COUNT"
detail "DB_DEADLOCK_COUNT=$DEADLOCK_COUNT"
detail "DB_PREPARED_TRANSACTION_COUNT=$PREPARED_TRANSACTION_COUNT"

detail "DB_REPLICATION_CLIENT_COUNT=$REPLICATION_CLIENT_COUNT"
detail "DB_REPLICATION_SLOT_COUNT=$REPLICATION_SLOT_COUNT"
detail "DB_ACTIVE_REPLICATION_SLOT_COUNT=$ACTIVE_REPLICATION_SLOT_COUNT"

if [ "$TRACK_IO" != "on" ]; then
  fail "track_io_timing on degil"
fi

if [ "$PG_STAT_EXTENSION" != "t" ]; then
  fail "pg_stat_statements extension aktif degil"
fi

{
  echo -e "state\tconnection_count\tmax_query_age_seconds\tmax_xact_age_seconds"
} > "$CONNECTION_METRICS_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  coalesce(state,'unknown') as state,
  count(*)::text as connection_count,
  coalesce(floor(max(extract(epoch from now() - query_start)))::bigint,0)::text as max_query_age_seconds,
  coalesce(floor(max(extract(epoch from now() - xact_start)))::bigint,0)::text as max_xact_age_seconds
from pg_stat_activity
where datname=current_database()
group by coalesce(state,'unknown')
order by connection_count desc, state asc;
" >> "$CONNECTION_METRICS_FILE" 2>/tmp/pix2pi_14_4_4_connection_metrics_err.log || {
    fail "connection state metrics uretilemedi"
  }
fi

{
  echo -e "locktype\tmode\tgranted\tlock_count"
} > "$LOCK_METRICS_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  locktype,
  mode,
  granted::text,
  count(*)::text as lock_count
from pg_locks
group by locktype, mode, granted
order by granted asc, lock_count desc, locktype asc, mode asc;
" >> "$LOCK_METRICS_FILE" 2>/tmp/pix2pi_14_4_4_lock_metrics_err.log || {
    fail "lock wait metrics uretilemedi"
  }
fi

CONNECTION_METRICS_LINE_COUNT=0
LOCK_METRICS_LINE_COUNT=0

if [ -f "$CONNECTION_METRICS_FILE" ]; then
  CONNECTION_METRICS_LINE_COUNT="$(wc -l < "$CONNECTION_METRICS_FILE" | tr -d ' ')"
fi

if [ -f "$LOCK_METRICS_FILE" ]; then
  LOCK_METRICS_LINE_COUNT="$(wc -l < "$LOCK_METRICS_FILE" | tr -d ' ')"
fi

detail "CONNECTION_METRICS_FILE_LINE_COUNT=$CONNECTION_METRICS_LINE_COUNT"
detail "LOCK_METRICS_FILE_LINE_COUNT=$LOCK_METRICS_LINE_COUNT"

DB_HEALTH_RISK_SCORE=0

if is_number "$CONNECTION_USAGE_PERCENT" && [ "$CONNECTION_USAGE_PERCENT" -ge "$CONNECTION_USAGE_WARN_PERCENT" ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
  risk "RISK_CONNECTION_USAGE_HIGH=max_connections kullanim orani yuksek"
fi

if is_number "$IDLE_TX_CONNECTIONS" && [ "$IDLE_TX_CONNECTIONS" -gt 0 ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
  risk "RISK_IDLE_IN_TRANSACTION=idle in transaction connection var"
fi

if is_number "$LONG_RUNNING_ACTIVE_QUERIES_60S" && [ "$LONG_RUNNING_ACTIVE_QUERIES_60S" -gt 0 ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
  risk "RISK_LONG_RUNNING_QUERY=uzun suren aktif query var"
fi

if is_number "$MAX_XACT_AGE_SECONDS" && [ "$MAX_XACT_AGE_SECONDS" -ge "$MAX_XACT_WARN_SECONDS" ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
  risk "RISK_LONG_TRANSACTION=max transaction age esik ustunde"
fi

if is_number "$MAX_IDLE_TX_AGE_SECONDS" && [ "$MAX_IDLE_TX_AGE_SECONDS" -ge "$IDLE_TX_WARN_SECONDS" ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
  risk "RISK_LONG_IDLE_TRANSACTION=max idle transaction age esik ustunde"
fi

if is_number "$WAITING_LOCK_COUNT" && [ "$WAITING_LOCK_COUNT" -gt 0 ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 3))
  risk "RISK_WAITING_LOCK=waiting lock var"
fi

if is_number "$PREPARED_TRANSACTION_COUNT" && [ "$PREPARED_TRANSACTION_COUNT" -gt 0 ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 3))
  risk "RISK_PREPARED_TRANSACTION=prepared transaction var"
fi

if is_number "$DEADLOCK_COUNT" && [ "$DEADLOCK_COUNT" -gt 0 ]; then
  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 1))
  risk "RISK_DEADLOCK_HISTORY=deadlock sayaci sifir degil; historical olabilir"
fi

DB_HEALTH_RISK_LEVEL="LOW"

if [ "$DB_HEALTH_RISK_SCORE" -ge 5 ]; then
  DB_HEALTH_RISK_LEVEL="HIGH"
elif [ "$DB_HEALTH_RISK_SCORE" -ge 2 ]; then
  DB_HEALTH_RISK_LEVEL="MEDIUM"
fi

detail "DB_HEALTH_RISK_SCORE=$DB_HEALTH_RISK_SCORE"
detail "DB_HEALTH_RISK_LEVEL=$DB_HEALTH_RISK_LEVEL"

if [ "$DB_HEALTH_RISK_LEVEL" != "LOW" ]; then
  warn "DB health risk seviyesi $DB_HEALTH_RISK_LEVEL"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_HEALTH_BASELINE=PASS"
else
  detail "DB_HEALTH_BASELINE=FAIL"
fi

{
  echo "# FAZ 4 / 14.4.4 - Connection / Lock / Deadlock Final DB Health Baseline Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_HEALTH_BASELINE=PASS"
  else
    echo "DB_HEALTH_BASELINE=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Evidence Files"
  echo "CONNECTION_METRICS_FILE=docs/phase4/14_4_4_connection_state_metrics.tsv"
  echo "LOCK_METRICS_FILE=docs/phase4/14_4_4_lock_wait_metrics.tsv"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ DB health major risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "QUERY_KILL_EXECUTED=NO"
  echo "LOCK_TERMINATION_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "VACUUM_EXECUTED=NO"
  echo "ANALYZE_EXECUTED=NO"

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
echo "CONNECTION_METRICS_FILE=$CONNECTION_METRICS_FILE"
echo "LOCK_METRICS_FILE=$LOCK_METRICS_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_HEALTH_RISK_LEVEL=$DB_HEALTH_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_HEALTH_BASELINE=FAIL ❌"
  exit 1
fi

echo "DB_HEALTH_BASELINE=PASS ✅"
