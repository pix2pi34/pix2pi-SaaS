#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_3_1_db_observability_performance_report.md"

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

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_3_1_sql_err.log || echo "error"
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
detail "ENV_FILE=$ENV_FILE"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
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
  if PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_3_1_psql_ok.log 2>/tmp/pix2pi_14_3_1_psql_err.log; then
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
  SCHEMA_EXISTS="$(run_sql "select to_regclass('public.schema_migrations') is not null;")"
  detail "SCHEMA_MIGRATIONS_EXISTS=$SCHEMA_EXISTS"

  if [ "$SCHEMA_EXISTS" = "t" ]; then
    DIRTY_STATE="$(run_sql "select coalesce(bool_or(dirty), false) from public.schema_migrations;")"
    detail "SCHEMA_MIGRATIONS_DIRTY_STATE=$DIRTY_STATE"

    if [ "$DIRTY_STATE" != "f" ]; then
      fail "schema_migrations dirty state temiz degil: $DIRTY_STATE"
    fi
  else
    warn "schema_migrations bulunamadi veya okunamadi"
  fi
fi

MAX_CONNECTIONS="error"
TOTAL_CONNECTIONS="error"
ACTIVE_CONNECTIONS="error"
IDLE_CONNECTIONS="error"
IDLE_TX_CONNECTIONS="error"
LONG_RUNNING_ACTIVE_QUERIES_30S="error"
LONG_RUNNING_ACTIVE_QUERIES_60S="error"
WAITING_LOCK_COUNT="error"
DEADLOCK_COUNT="error"
USER_TABLE_COUNT="error"
USER_INDEX_COUNT="error"
LIVE_TUPLE_ESTIMATE="error"
DEAD_TUPLE_ESTIMATE="error"
TABLES_WITH_DEAD_TUPLES="error"
SEQUENTIAL_SCAN_TOTAL="error"
INDEX_SCAN_TOTAL="error"
PG_STAT_STATEMENTS_EXTENSION="error"
PG_STAT_STATEMENTS_PRELOAD="NO"
TRACK_IO_TIMING="error"
AUTOVACUUM="error"
LOG_MIN_DURATION_STATEMENT="error"
SHARED_PRELOAD_LIBRARIES="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  MAX_CONNECTIONS="$(run_sql "show max_connections;")"
  TOTAL_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database();")"
  ACTIVE_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='active';")"
  IDLE_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='idle';")"
  IDLE_TX_CONNECTIONS="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  LONG_RUNNING_ACTIVE_QUERIES_30S="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '30 seconds';")"
  LONG_RUNNING_ACTIVE_QUERIES_60S="$(run_sql "select count(*) from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  WAITING_LOCK_COUNT="$(run_sql "select count(*) from pg_locks where not granted;")"
  DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"

  USER_TABLE_COUNT="$(run_sql "select count(*) from pg_stat_user_tables;")"
  USER_INDEX_COUNT="$(run_sql "select count(*) from pg_stat_user_indexes;")"
  LIVE_TUPLE_ESTIMATE="$(run_sql "select coalesce(sum(n_live_tup),0)::text from pg_stat_user_tables;")"
  DEAD_TUPLE_ESTIMATE="$(run_sql "select coalesce(sum(n_dead_tup),0)::text from pg_stat_user_tables;")"
  TABLES_WITH_DEAD_TUPLES="$(run_sql "select count(*) from pg_stat_user_tables where n_dead_tup > 0;")"
  SEQUENTIAL_SCAN_TOTAL="$(run_sql "select coalesce(sum(seq_scan),0)::text from pg_stat_user_tables;")"
  INDEX_SCAN_TOTAL="$(run_sql "select coalesce(sum(idx_scan),0)::text from pg_stat_user_tables;")"

  PG_STAT_STATEMENTS_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  SHARED_PRELOAD_LIBRARIES="$(run_sql "show shared_preload_libraries;")"
  TRACK_IO_TIMING="$(run_sql "show track_io_timing;")"
  AUTOVACUUM="$(run_sql "show autovacuum;")"
  LOG_MIN_DURATION_STATEMENT="$(run_sql "show log_min_duration_statement;")"

  if printf '%s' "$SHARED_PRELOAD_LIBRARIES" | grep -q "pg_stat_statements"; then
    PG_STAT_STATEMENTS_PRELOAD="YES"
  else
    PG_STAT_STATEMENTS_PRELOAD="NO"
  fi
fi

detail "POSTGRES_MAX_CONNECTIONS=$MAX_CONNECTIONS"
detail "DB_TOTAL_CONNECTIONS=$TOTAL_CONNECTIONS"
detail "DB_ACTIVE_CONNECTIONS=$ACTIVE_CONNECTIONS"
detail "DB_IDLE_CONNECTIONS=$IDLE_CONNECTIONS"
detail "DB_IDLE_IN_TRANSACTION_CONNECTIONS=$IDLE_TX_CONNECTIONS"
detail "DB_LONG_RUNNING_ACTIVE_QUERIES_30S=$LONG_RUNNING_ACTIVE_QUERIES_30S"
detail "DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$LONG_RUNNING_ACTIVE_QUERIES_60S"
detail "DB_WAITING_LOCK_COUNT=$WAITING_LOCK_COUNT"
detail "DB_DEADLOCK_COUNT=$DEADLOCK_COUNT"

detail "DB_USER_TABLE_COUNT=$USER_TABLE_COUNT"
detail "DB_USER_INDEX_COUNT=$USER_INDEX_COUNT"
detail "DB_LIVE_TUPLE_ESTIMATE=$LIVE_TUPLE_ESTIMATE"
detail "DB_DEAD_TUPLE_ESTIMATE=$DEAD_TUPLE_ESTIMATE"
detail "DB_TABLES_WITH_DEAD_TUPLES=$TABLES_WITH_DEAD_TUPLES"
detail "DB_SEQUENTIAL_SCAN_TOTAL=$SEQUENTIAL_SCAN_TOTAL"
detail "DB_INDEX_SCAN_TOTAL=$INDEX_SCAN_TOTAL"

detail "PG_STAT_STATEMENTS_EXTENSION=$PG_STAT_STATEMENTS_EXTENSION"
detail "PG_STAT_STATEMENTS_PRELOAD=$PG_STAT_STATEMENTS_PRELOAD"
detail "TRACK_IO_TIMING=$TRACK_IO_TIMING"
detail "AUTOVACUUM=$AUTOVACUUM"
detail "LOG_MIN_DURATION_STATEMENT=$LOG_MIN_DURATION_STATEMENT"
detail "SHARED_PRELOAD_LIBRARIES=$SHARED_PRELOAD_LIBRARIES"

PERF_RISK_SCORE=0

if is_number "$IDLE_TX_CONNECTIONS" && [ "$IDLE_TX_CONNECTIONS" -gt 0 ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 2))
  risk "RISK_IDLE_IN_TRANSACTION=idle in transaction connection var"
fi

if is_number "$LONG_RUNNING_ACTIVE_QUERIES_60S" && [ "$LONG_RUNNING_ACTIVE_QUERIES_60S" -gt 0 ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 2))
  risk "RISK_LONG_RUNNING_QUERY_60S=60 saniyeyi asan aktif query var"
fi

if is_number "$WAITING_LOCK_COUNT" && [ "$WAITING_LOCK_COUNT" -gt 0 ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 3))
  risk "RISK_WAITING_LOCK=waiting lock var"
fi

if [ "$PG_STAT_STATEMENTS_EXTENSION" != "t" ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 1))
  risk "RISK_PG_STAT_STATEMENTS_EXTENSION_MISSING=pg_stat_statements extension yok"
fi

if [ "$PG_STAT_STATEMENTS_PRELOAD" != "YES" ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 1))
  risk "RISK_PG_STAT_STATEMENTS_PRELOAD_MISSING=shared_preload_libraries icinde pg_stat_statements yok"
fi

if [ "$TRACK_IO_TIMING" != "on" ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 1))
  risk "RISK_TRACK_IO_TIMING_OFF=track_io_timing off"
fi

if [ "$AUTOVACUUM" != "on" ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 3))
  risk "RISK_AUTOVACUUM_OFF=autovacuum off"
fi

DEAD_TUPLE_WARN="NO"

if is_number "$DEAD_TUPLE_ESTIMATE" && [ "$DEAD_TUPLE_ESTIMATE" -gt 10000 ]; then
  PERF_RISK_SCORE=$((PERF_RISK_SCORE + 1))
  DEAD_TUPLE_WARN="YES"
  risk "RISK_DEAD_TUPLES_HIGH=dead tuple estimate 10000 uzerinde"
fi

DB_PERF_RISK_LEVEL="LOW"

if [ "$PERF_RISK_SCORE" -ge 5 ]; then
  DB_PERF_RISK_LEVEL="HIGH"
elif [ "$PERF_RISK_SCORE" -ge 2 ]; then
  DB_PERF_RISK_LEVEL="MEDIUM"
fi

detail "DB_PERF_RISK_SCORE=$PERF_RISK_SCORE"
detail "DB_PERF_RISK_LEVEL=$DB_PERF_RISK_LEVEL"
detail "DEAD_TUPLE_WARN=$DEAD_TUPLE_WARN"

if [ "$DB_PERF_RISK_LEVEL" != "LOW" ]; then
  warn "DB performance risk seviyesi $DB_PERF_RISK_LEVEL"
fi

{
  echo "# FAZ 4 / 14.3.1 - DB Observability / Performance Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=PASS"
  else
    echo "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=FAIL"
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
    echo "OK ✅ performance major risk yok"
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
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_PERF_RISK_LEVEL=$DB_PERF_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=FAIL ❌"
  exit 1
fi

echo "DB_OBSERVABILITY_PERFORMANCE_DISCOVERY=PASS ✅"
