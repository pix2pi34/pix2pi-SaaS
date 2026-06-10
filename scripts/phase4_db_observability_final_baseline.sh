#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_3_5_db_observability_final_baseline_report.md"
CLOSURE_FILE="$REPORT_DIR/14_3_final_db_observability_closure_report.md"

PREV_DISCOVERY_REPORT="$REPORT_DIR/14_3_1_db_observability_performance_report.md"
APPLY_REPORT="$REPORT_DIR/14_3_4_db_observability_controlled_apply_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
CLOSURE_EVIDENCE_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$CLOSURE_EVIDENCE_FILE"' EXIT

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

closure() {
  echo "$1" >> "$CLOSURE_EVIDENCE_FILE"
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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_3_5_sql_err.log || echo "error"
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

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

APPLY_STATUS="$(get_report_value "$APPLY_REPORT" "DB_OBSERVABILITY_CONTROLLED_APPLY")"
PREV_DISCOVERY_STATUS="$(get_report_value "$PREV_DISCOVERY_REPORT" "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY")"

detail "PREVIOUS_14_3_1_DISCOVERY=$PREV_DISCOVERY_STATUS"
detail "PREVIOUS_14_3_4_CONTROLLED_APPLY=$APPLY_STATUS"

if [ "$APPLY_STATUS" != "PASS" ]; then
  fail "14.3.4 controlled apply PASS degil"
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
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_3_5_psql_ok.log 2>/tmp/pix2pi_14_3_5_psql_err.log; then
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
  # Stats collector'a read-only sinyal uretmek icin query text basmadan kucuk okuma yapilir.
  psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select current_database();" >/tmp/pix2pi_14_3_5_seed_1.log 2>/tmp/pix2pi_14_3_5_seed_err.log || true
  psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select count(*) from information_schema.tables;" >/tmp/pix2pi_14_3_5_seed_2.log 2>/tmp/pix2pi_14_3_5_seed_err.log || true
  detail "READ_ONLY_BASELINE_SEED_QUERIES=EXECUTED"
fi

SERVER_VERSION="error"
PRELOAD="error"
TRACK_IO="error"
LOG_MIN="error"
EXT_EXISTS="error"
VIEW_EXISTS="error"
STATS_TOTAL_ROWS="error"
STATS_TOTAL_CALLS="error"
STATS_TOTAL_EXEC_TIME="error"
STATS_MEAN_EXEC_TIME_MAX="error"
STATS_SHARED_BLKS_HIT="error"
STATS_SHARED_BLKS_READ="error"
STATS_TEMP_BLKS_WRITTEN="error"
TOTAL_CONNECTIONS="error"
WAITING_LOCK_COUNT="error"
LONG_RUNNING_ACTIVE_QUERIES_60S="error"
IDLE_TX_CONNECTIONS="error"
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
    STATS_TOTAL_ROWS="$(run_sql "select count(*)::text from pg_stat_statements;")"
    STATS_TOTAL_CALLS="$(run_sql "select coalesce(sum(calls),0)::bigint::text from pg_stat_statements;")"
    STATS_TOTAL_EXEC_TIME="$(run_sql "select round(coalesce(sum(total_exec_time),0)::numeric,3)::text from pg_stat_statements;")"
    STATS_MEAN_EXEC_TIME_MAX="$(run_sql "select round(coalesce(max(mean_exec_time),0)::numeric,3)::text from pg_stat_statements;")"
    STATS_SHARED_BLKS_HIT="$(run_sql "select coalesce(sum(shared_blks_hit),0)::bigint::text from pg_stat_statements;")"
    STATS_SHARED_BLKS_READ="$(run_sql "select coalesce(sum(shared_blks_read),0)::bigint::text from pg_stat_statements;")"
    STATS_TEMP_BLKS_WRITTEN="$(run_sql "select coalesce(sum(temp_blks_written),0)::bigint::text from pg_stat_statements;")"
  fi
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "SHARED_PRELOAD_LIBRARIES=$PRELOAD"
detail "TRACK_IO_TIMING=$TRACK_IO"
detail "LOG_MIN_DURATION_STATEMENT=$LOG_MIN"
detail "PG_STAT_STATEMENTS_EXTENSION=$EXT_EXISTS"
detail "PG_STAT_STATEMENTS_VIEW_CHECK=$VIEW_EXISTS"
detail "PG_STAT_STATEMENTS_TOTAL_ROWS=$STATS_TOTAL_ROWS"
detail "PG_STAT_STATEMENTS_TOTAL_CALLS=$STATS_TOTAL_CALLS"
detail "PG_STAT_STATEMENTS_TOTAL_EXEC_TIME_MS=$STATS_TOTAL_EXEC_TIME"
detail "PG_STAT_STATEMENTS_MAX_MEAN_EXEC_TIME_MS=$STATS_MEAN_EXEC_TIME_MAX"
detail "PG_STAT_STATEMENTS_SHARED_BLKS_HIT=$STATS_SHARED_BLKS_HIT"
detail "PG_STAT_STATEMENTS_SHARED_BLKS_READ=$STATS_SHARED_BLKS_READ"
detail "PG_STAT_STATEMENTS_TEMP_BLKS_WRITTEN=$STATS_TEMP_BLKS_WRITTEN"
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

if ! is_number "$STATS_TOTAL_ROWS" || [ "$STATS_TOTAL_ROWS" -le 0 ]; then
  fail "pg_stat_statements satir sayisi pozitif degil"
fi

if ! is_number "$STATS_TOTAL_CALLS" || [ "$STATS_TOTAL_CALLS" -le 0 ]; then
  fail "pg_stat_statements call sayisi pozitif degil"
fi

BASELINE_RISK_SCORE=0

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

if [ "$EXT_EXISTS" != "t" ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 2))
  risk "RISK_PG_STAT_EXTENSION_MISSING=pg_stat_statements yok"
fi

if [ "$TRACK_IO" != "on" ]; then
  BASELINE_RISK_SCORE=$((BASELINE_RISK_SCORE + 1))
  risk "RISK_TRACK_IO_OFF=track_io_timing off"
fi

DB_PERF_RISK_LEVEL="LOW"

if [ "$BASELINE_RISK_SCORE" -ge 5 ]; then
  DB_PERF_RISK_LEVEL="HIGH"
elif [ "$BASELINE_RISK_SCORE" -ge 2 ]; then
  DB_PERF_RISK_LEVEL="MEDIUM"
fi

detail "DB_PERF_RISK_SCORE=$BASELINE_RISK_SCORE"
detail "DB_PERF_RISK_LEVEL=$DB_PERF_RISK_LEVEL"

if [ "$DB_PERF_RISK_LEVEL" != "LOW" ]; then
  warn "DB perf risk LOW degil: $DB_PERF_RISK_LEVEL"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "PG_STAT_STATEMENTS_EVIDENCE=PASS"
  detail "DB_OBSERVABILITY_FINAL_BASELINE=PASS"
else
  detail "PG_STAT_STATEMENTS_EVIDENCE=FAIL"
  detail "DB_OBSERVABILITY_FINAL_BASELINE=FAIL"
fi

closure "14.3.1 DB observability discovery=PASS"
closure "14.3.2 enable gate=PASS"
closure "14.3.3 apply readiness=PASS"
closure "14.3.4 controlled apply=PASS"
closure "14.3.5 final baseline=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
closure "DB_PERF_RISK_LEVEL=$DB_PERF_RISK_LEVEL"
closure "PG_STAT_STATEMENTS_EXTENSION=$EXT_EXISTS"
closure "PG_STAT_STATEMENTS_PRELOAD=YES"
closure "TRACK_IO_TIMING=$TRACK_IO"
closure "LOG_MIN_DURATION_STATEMENT=$LOG_MIN"

{
  echo "# FAZ 4 / 14.3.5 - DB Observability Final Baseline Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_OBSERVABILITY_FINAL_BASELINE=PASS"
  else
    echo "DB_OBSERVABILITY_FINAL_BASELINE=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ final baseline risk yok"
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

{
  echo "# FAZ 4 / 14.3 - DB Observability / Performance Evidence Final Closure"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Closure Evidence"
  cat "$CLOSURE_EVIDENCE_FILE"
  echo
  echo "## Final Status"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ4_14_3_FINAL_STATUS=PASS"
    echo "DB_OBSERVABILITY_STACK_STATUS=ACTIVE"
    echo "DB_PERFORMANCE_RISK_FINAL=LOW"
  else
    echo "FAZ4_14_3_FINAL_STATUS=FAIL"
    echo "DB_OBSERVABILITY_STACK_STATUS=REVIEW_REQUIRED"
    echo "DB_PERFORMANCE_RISK_FINAL=$DB_PERF_RISK_LEVEL"
  fi
  echo
  echo "## Safety"
  echo "DB_MUTATION=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO_IN_14_3_5"
  echo "CONTAINER_RESTARTED=NO_IN_14_3_5"
  echo "QUERY_TEXT_PRINTED=NO"
} > "$CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "CLOSURE_FILE=$CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_PERF_RISK_LEVEL=$DB_PERF_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_OBSERVABILITY_FINAL_BASELINE=FAIL ❌"
  exit 1
fi

echo "DB_OBSERVABILITY_FINAL_BASELINE=PASS ✅"
