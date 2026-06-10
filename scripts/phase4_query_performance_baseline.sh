#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_4_1_query_performance_baseline_report.md"
TOP_QUERY_FILE="$REPORT_DIR/14_4_1_query_performance_top_queries.tsv"

CLOSURE_14_3="$REPORT_DIR/14_3_final_db_observability_closure_report.md"

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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_4_1_sql_err.log || echo "error"
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

is_decimal_number() {
  local v="$1"
  case "$v" in
    ''|*[!0-9.]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

int_part() {
  local v="$1"
  echo "${v%%.*}"
}

MEAN_EXEC_WARN_MS="${MEAN_EXEC_WARN_MS:-100}"
TOTAL_EXEC_WARN_MS="${TOTAL_EXEC_WARN_MS:-1000}"
TOP_LIMIT="${TOP_LIMIT:-30}"

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "TOP_QUERY_FILE=docs/phase4/14_4_1_query_performance_top_queries.tsv"
detail "MEAN_EXEC_WARN_MS=$MEAN_EXEC_WARN_MS"
detail "TOTAL_EXEC_WARN_MS=$TOTAL_EXEC_WARN_MS"
detail "TOP_LIMIT=$TOP_LIMIT"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_14_3_STATUS="$(get_report_value "$CLOSURE_14_3" "FAZ4_14_3_FINAL_STATUS")"
detail "PREVIOUS_14_3_FINAL_STATUS=$PREV_14_3_STATUS"

if [ "$PREV_14_3_STATUS" != "PASS" ]; then
  fail "14.3 final closure PASS degil"
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
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_4_1_psql_ok.log 2>/tmp/pix2pi_14_4_1_psql_err.log; then
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

if [ "$FAIL_COUNT" -eq 0 ]; then
  # Query text basmadan pg_stat_statements icin okuma sinyali uretir.
  psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select count(*) from information_schema.tables;" >/tmp/pix2pi_14_4_1_seed.log 2>/tmp/pix2pi_14_4_1_seed_err.log || true
  detail "READ_ONLY_BASELINE_SEED_QUERY=EXECUTED"
fi

SERVER_VERSION="error"
PRELOAD="error"
TRACK_IO="error"
LOG_MIN="error"
EXT_EXISTS="error"
VIEW_EXISTS="error"

TOTAL_ROWS="error"
TOTAL_CALLS="error"
TOTAL_EXEC_TIME_MS="error"
MAX_MEAN_EXEC_TIME_MS="error"
MAX_TOTAL_EXEC_TIME_MS="error"
MEAN_OVER_WARN_COUNT="error"
TOTAL_OVER_WARN_COUNT="error"
TEMP_BLOCK_QUERY_COUNT="error"
SHARED_READ_QUERY_COUNT="error"
ROWS_RETURNED_TOTAL="error"
SHARED_BLKS_HIT_TOTAL="error"
SHARED_BLKS_READ_TOTAL="error"
TEMP_BLKS_WRITTEN_TOTAL="error"
BLK_READ_TIME_TOTAL="error"
BLK_WRITE_TIME_TOTAL="error"

TOTAL_CONNECTIONS="error"
IDLE_TX_CONNECTIONS="error"
LONG_RUNNING_ACTIVE_QUERIES_60S="error"
WAITING_LOCK_COUNT="error"
DEADLOCK_COUNT="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION="$(run_sql "show server_version;")"
  PRELOAD="$(run_sql "show shared_preload_libraries;")"
  TRACK_IO="$(run_sql "show track_io_timing;")"
  LOG_MIN="$(run_sql "show log_min_duration_statement;")"
  EXT_EXISTS="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  VIEW_EXISTS="$(run_sql "select to_regclass('public.pg_stat_statements') is not null or to_regclass('pg_catalog.pg_stat_statements') is not null;")"

  TOTAL_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database();")"
  IDLE_TX_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  LONG_RUNNING_ACTIVE_QUERIES_60S="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  WAITING_LOCK_COUNT="$(run_sql "select count(*) from pg_locks where not granted;")"
  DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"

  if [ "$EXT_EXISTS" = "t" ]; then
    TOTAL_ROWS="$(run_sql "select count(*)::text from pg_stat_statements;")"
    TOTAL_CALLS="$(run_sql "select coalesce(sum(calls),0)::bigint::text from pg_stat_statements;")"
    TOTAL_EXEC_TIME_MS="$(run_sql "select round(coalesce(sum(total_exec_time),0)::numeric,3)::text from pg_stat_statements;")"
    MAX_MEAN_EXEC_TIME_MS="$(run_sql "select round(coalesce(max(mean_exec_time),0)::numeric,3)::text from pg_stat_statements;")"
    MAX_TOTAL_EXEC_TIME_MS="$(run_sql "select round(coalesce(max(total_exec_time),0)::numeric,3)::text from pg_stat_statements;")"
    MEAN_OVER_WARN_COUNT="$(run_sql "select count(*)::text from pg_stat_statements where mean_exec_time >= ${MEAN_EXEC_WARN_MS};")"
    TOTAL_OVER_WARN_COUNT="$(run_sql "select count(*)::text from pg_stat_statements where total_exec_time >= ${TOTAL_EXEC_WARN_MS};")"
    TEMP_BLOCK_QUERY_COUNT="$(run_sql "select count(*)::text from pg_stat_statements where temp_blks_written > 0 or temp_blks_read > 0;")"
    SHARED_READ_QUERY_COUNT="$(run_sql "select count(*)::text from pg_stat_statements where shared_blks_read > 0;")"
    ROWS_RETURNED_TOTAL="$(run_sql "select coalesce(sum(rows),0)::bigint::text from pg_stat_statements;")"
    SHARED_BLKS_HIT_TOTAL="$(run_sql "select coalesce(sum(shared_blks_hit),0)::bigint::text from pg_stat_statements;")"
    SHARED_BLKS_READ_TOTAL="$(run_sql "select coalesce(sum(shared_blks_read),0)::bigint::text from pg_stat_statements;")"
    TEMP_BLKS_WRITTEN_TOTAL="$(run_sql "select coalesce(sum(temp_blks_written),0)::bigint::text from pg_stat_statements;")"
    BLK_READ_TIME_TOTAL="$(run_sql "select round(coalesce(sum(blk_read_time),0)::numeric,3)::text from pg_stat_statements;")"
    BLK_WRITE_TIME_TOTAL="$(run_sql "select round(coalesce(sum(blk_write_time),0)::numeric,3)::text from pg_stat_statements;")"
  fi
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "SHARED_PRELOAD_LIBRARIES=$PRELOAD"
detail "TRACK_IO_TIMING=$TRACK_IO"
detail "LOG_MIN_DURATION_STATEMENT=$LOG_MIN"
detail "PG_STAT_STATEMENTS_EXTENSION=$EXT_EXISTS"
detail "PG_STAT_STATEMENTS_VIEW_CHECK=$VIEW_EXISTS"

detail "PG_STAT_TOTAL_ROWS=$TOTAL_ROWS"
detail "PG_STAT_TOTAL_CALLS=$TOTAL_CALLS"
detail "PG_STAT_TOTAL_EXEC_TIME_MS=$TOTAL_EXEC_TIME_MS"
detail "PG_STAT_MAX_MEAN_EXEC_TIME_MS=$MAX_MEAN_EXEC_TIME_MS"
detail "PG_STAT_MAX_TOTAL_EXEC_TIME_MS=$MAX_TOTAL_EXEC_TIME_MS"
detail "PG_STAT_MEAN_OVER_WARN_COUNT=$MEAN_OVER_WARN_COUNT"
detail "PG_STAT_TOTAL_OVER_WARN_COUNT=$TOTAL_OVER_WARN_COUNT"
detail "PG_STAT_TEMP_BLOCK_QUERY_COUNT=$TEMP_BLOCK_QUERY_COUNT"
detail "PG_STAT_SHARED_READ_QUERY_COUNT=$SHARED_READ_QUERY_COUNT"
detail "PG_STAT_ROWS_RETURNED_TOTAL=$ROWS_RETURNED_TOTAL"
detail "PG_STAT_SHARED_BLKS_HIT_TOTAL=$SHARED_BLKS_HIT_TOTAL"
detail "PG_STAT_SHARED_BLKS_READ_TOTAL=$SHARED_BLKS_READ_TOTAL"
detail "PG_STAT_TEMP_BLKS_WRITTEN_TOTAL=$TEMP_BLKS_WRITTEN_TOTAL"
detail "PG_STAT_BLK_READ_TIME_TOTAL_MS=$BLK_READ_TIME_TOTAL"
detail "PG_STAT_BLK_WRITE_TIME_TOTAL_MS=$BLK_WRITE_TIME_TOTAL"

detail "DB_TOTAL_CONNECTIONS=$TOTAL_CONNECTIONS"
detail "DB_IDLE_IN_TRANSACTION_CONNECTIONS=$IDLE_TX_CONNECTIONS"
detail "DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$LONG_RUNNING_ACTIVE_QUERIES_60S"
detail "DB_WAITING_LOCK_COUNT=$WAITING_LOCK_COUNT"
detail "DB_DEADLOCK_COUNT=$DEADLOCK_COUNT"

if ! printf '%s' "$PRELOAD" | grep -q "pg_stat_statements"; then
  fail "pg_stat_statements shared_preload_libraries icinde yok"
fi

if [ "$TRACK_IO" != "on" ]; then
  fail "track_io_timing on degil"
fi

if [ "$LOG_MIN" = "-1" ] || [ "$LOG_MIN" = "error" ] || [ -z "$LOG_MIN" ]; then
  fail "log_min_duration_statement aktif degil"
fi

if [ "$EXT_EXISTS" != "t" ]; then
  fail "pg_stat_statements extension kurulu degil"
fi

if [ "$VIEW_EXISTS" != "t" ]; then
  fail "pg_stat_statements view okunabilir degil"
fi

if ! is_number "$TOTAL_ROWS" || [ "$TOTAL_ROWS" -le 0 ]; then
  fail "pg_stat_statements total rows pozitif degil"
fi

if ! is_number "$TOTAL_CALLS" || [ "$TOTAL_CALLS" -le 0 ]; then
  fail "pg_stat_statements total calls pozitif degil"
fi

{
  echo -e "rank\tqueryid\tcalls\ttotal_exec_time_ms\tmean_exec_time_ms\tmax_exec_time_ms\trows\tshared_blks_hit\tshared_blks_read\ttemp_blks_read\ttemp_blks_written\tblk_read_time_ms\tblk_write_time_ms"
} > "$TOP_QUERY_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  row_number() over (order by total_exec_time desc) as rank,
  coalesce(queryid::text, 'NO_QUERYID') as queryid,
  calls::bigint::text,
  round(total_exec_time::numeric,3)::text,
  round(mean_exec_time::numeric,3)::text,
  round(max_exec_time::numeric,3)::text,
  rows::bigint::text,
  shared_blks_hit::bigint::text,
  shared_blks_read::bigint::text,
  temp_blks_read::bigint::text,
  temp_blks_written::bigint::text,
  round(blk_read_time::numeric,3)::text,
  round(blk_write_time::numeric,3)::text
from pg_stat_statements
order by total_exec_time desc
limit ${TOP_LIMIT};
" >> "$TOP_QUERY_FILE" 2>/tmp/pix2pi_14_4_1_top_query_err.log || {
    fail "top queryid performance list uretilemedi"
  }
fi

TOP_QUERY_LINE_COUNT=0
if [ -f "$TOP_QUERY_FILE" ]; then
  TOP_QUERY_LINE_COUNT="$(wc -l < "$TOP_QUERY_FILE" | tr -d ' ')"
fi

detail "TOP_QUERY_FILE=docs/phase4/14_4_1_query_performance_top_queries.tsv"
detail "TOP_QUERY_LINE_COUNT=$TOP_QUERY_LINE_COUNT"

BASELINE_RISK_SCORE=0

if is_number "$MEAN_OVER_WARN_COUNT" && [ "$MEAN_OVER_WARN_COUNT" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 2))
  risk "RISK_MEAN_EXEC_WARN=query mean_exec_time ${MEAN_EXEC_WARN_MS}ms uzeri query var"
fi

if is_number "$TOTAL_OVER_WARN_COUNT" && [ "$TOTAL_OVER_WARN_COUNT" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 1))
  risk "RISK_TOTAL_EXEC_WARN=query total_exec_time ${TOTAL_EXEC_WARN_MS}ms uzeri query var"
fi

if is_number "$TEMP_BLOCK_QUERY_COUNT" && [ "$TEMP_BLOCK_QUERY_COUNT" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 1))
  risk "RISK_TEMP_BLOCKS=temp block kullanan query var"
fi

if is_number "$IDLE_TX_CONNECTIONS" && [ "$IDLE_TX_CONNECTIONS" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 2))
  risk "RISK_IDLE_IN_TRANSACTION=idle in transaction var"
fi

if is_number "$LONG_RUNNING_ACTIVE_QUERIES_60S" && [ "$LONG_RUNNING_ACTIVE_QUERIES_60S" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 2))
  risk "RISK_LONG_RUNNING_QUERY_60S=60 saniyeyi asan aktif query var"
fi

if is_number "$WAITING_LOCK_COUNT" && [ "$WAITING_LOCK_COUNT" -gt 0 ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 3))
  risk "RISK_WAITING_LOCK=waiting lock var"
fi

QUERY_PERF_RISK_LEVEL="LOW"

if [ "$BASELINE_RISK_SCORE" -ge 5 ]; then
  QUERY_PERF_RISK_LEVEL="HIGH"
elif [ "$BASELINE_RISK_SCORE" -ge 2 ]; then
  QUERY_PERF_RISK_LEVEL="MEDIUM"
fi

detail "QUERY_PERF_RISK_SCORE=$BASELINE_RISK_SCORE"
detail "QUERY_PERF_RISK_LEVEL=$QUERY_PERF_RISK_LEVEL"

if [ "$QUERY_PERF_RISK_LEVEL" != "LOW" ]; then
  warn "query performance risk seviyesi $QUERY_PERF_RISK_LEVEL"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "PG_STAT_STATEMENTS_QUERY_BASELINE=PASS"
  detail "QUERY_PERFORMANCE_BASELINE=PASS"
else
  detail "PG_STAT_STATEMENTS_QUERY_BASELINE=FAIL"
  detail "QUERY_PERFORMANCE_BASELINE=FAIL"
fi

{
  echo "# FAZ 4 / 14.4.1 - Query Performance Baseline Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "QUERY_PERFORMANCE_BASELINE=PASS"
  else
    echo "QUERY_PERFORMANCE_BASELINE=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Top Query File"
  echo "QUERY_TEXT_INCLUDED=NO"
  echo "TOP_QUERY_FILE=docs/phase4/14_4_1_query_performance_top_queries.tsv"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ query performance major risk yok"
  fi

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
echo "TOP_QUERY_FILE=$TOP_QUERY_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "QUERY_PERF_RISK_LEVEL=$QUERY_PERF_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "QUERY_PERFORMANCE_BASELINE=FAIL ❌"
  exit 1
fi

echo "QUERY_PERFORMANCE_BASELINE=PASS ✅"
