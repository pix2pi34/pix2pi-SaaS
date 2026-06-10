#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_4_5_db_performance_final_closure_report.md"
CLOSURE_FILE="$REPORT_DIR/14_4_final_db_performance_closure_report.md"

R_1441="$REPORT_DIR/14_4_1_query_performance_baseline_report.md"
R_1442="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"
R_1443="$REPORT_DIR/14_4_3_vacuum_bloat_readiness_report.md"
R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
CLOSURE_EVIDENCE_FILE="$(mktemp)"

trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$CLOSURE_EVIDENCE_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "$1" >> "$RISK_FILE"; }
closure() { echo "$1" >> "$CLOSURE_EVIDENCE_FILE"; }

strip_quotes() {
  local v="$1"
  v="${v%$'\r'}"
  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}" ;;
    \'*\') v="${v#\'}"; v="${v%\'}" ;;
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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_4_5_sql_err.log || echo "error"
}

risk_weight() {
  case "$1" in
    HIGH) echo 3 ;;
    MEDIUM) echo 2 ;;
    LOW) echo 1 ;;
    *) echo 0 ;;
  esac
}

risk_max() {
  local a="$1"
  local b="$2"
  local aw=""
  local bw=""

  aw="$(risk_weight "$a")"
  bw="$(risk_weight "$b")"

  if [ "$bw" -gt "$aw" ]; then
    echo "$b"
  else
    echo "$a"
  fi
}

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "LOCK_TERMINATION_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "INDEX_DROP_EXECUTED=NO"
detail "INDEX_CREATE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

for f in "$R_1441" "$R_1442" "$R_1443" "$R_1444"; do
  if [ ! -f "$f" ]; then
    fail "gerekli rapor bulunamadi: ${f#$ROOT_DIR/}"
  fi
done

S_1441="$(get_report_value "$R_1441" "QUERY_PERFORMANCE_BASELINE")"
S_1442="$(get_report_value "$R_1442" "INDEX_USAGE_BASELINE")"
S_1443="$(get_report_value "$R_1443" "VACUUM_BLOAT_READINESS")"
S_1444="$(get_report_value "$R_1444" "DB_HEALTH_BASELINE")"

RISK_1441="$(get_report_value "$R_1441" "QUERY_PERF_RISK_LEVEL")"
RISK_1442="$(get_report_value "$R_1442" "INDEX_USAGE_RISK_LEVEL")"
RISK_1443="$(get_report_value "$R_1443" "VACUUM_RISK_LEVEL")"
RISK_1444="$(get_report_value "$R_1444" "DB_HEALTH_RISK_LEVEL")"

detail "14_4_1_QUERY_PERFORMANCE_BASELINE=$S_1441"
detail "14_4_2_INDEX_USAGE_BASELINE=$S_1442"
detail "14_4_3_VACUUM_BLOAT_READINESS=$S_1443"
detail "14_4_4_DB_HEALTH_BASELINE=$S_1444"

detail "14_4_1_QUERY_PERF_RISK_LEVEL=$RISK_1441"
detail "14_4_2_INDEX_USAGE_RISK_LEVEL=$RISK_1442"
detail "14_4_3_VACUUM_RISK_LEVEL=$RISK_1443"
detail "14_4_4_DB_HEALTH_RISK_LEVEL=$RISK_1444"

if [ "$S_1441" != "PASS" ]; then fail "14.4.1 PASS degil"; fi
if [ "$S_1442" != "PASS" ]; then fail "14.4.2 PASS degil"; fi
if [ "$S_1443" != "PASS" ]; then fail "14.4.3 PASS degil"; fi
if [ "$S_1444" != "PASS" ]; then fail "14.4.4 PASS degil"; fi

FINAL_RISK="LOW"
FINAL_RISK="$(risk_max "$FINAL_RISK" "$RISK_1441")"
FINAL_RISK="$(risk_max "$FINAL_RISK" "$RISK_1442")"
FINAL_RISK="$(risk_max "$FINAL_RISK" "$RISK_1443")"
FINAL_RISK="$(risk_max "$FINAL_RISK" "$RISK_1444")"

detail "DB_PERFORMANCE_RISK_FINAL=$FINAL_RISK"

if [ "$FINAL_RISK" != "LOW" ]; then
  warn "14.4 final risk LOW degil: $FINAL_RISK"
  risk "RISK_FINAL_DB_PERFORMANCE_NOT_LOW=final risk $FINAL_RISK"
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
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_4_5_psql_ok.log 2>/tmp/pix2pi_14_4_5_psql_err.log; then
    detail "FINAL_DB_CONNECTION_CHECK=PASS"
  else
    fail "final DB connection failed"
  fi
fi

FINAL_DB_ROLE="unknown"
FINAL_WAITING_LOCK_COUNT="error"
FINAL_IDLE_TX_COUNT="error"
FINAL_LONG_QUERY_60S="error"
FINAL_DEADLOCK_COUNT="error"
FINAL_PREPARED_TX_COUNT="error"
FINAL_TOTAL_CONNECTIONS="error"
FINAL_DB_SIZE_BYTES="error"
FINAL_PG_STAT_EXTENSION="error"
FINAL_TRACK_IO="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"
  detail "FINAL_PG_IS_IN_RECOVERY=$IN_RECOVERY"

  case "$IN_RECOVERY" in
    f)
      FINAL_DB_ROLE="PRIMARY_WRITE"
      ;;
    t)
      FINAL_DB_ROLE="REPLICA_READ_ONLY"
      fail "final DB replica/read-only gorunuyor"
      ;;
    *)
      FINAL_DB_ROLE="UNKNOWN"
      fail "final pg_is_in_recovery okunamadi"
      ;;
  esac

  FINAL_TOTAL_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database();")"
  FINAL_IDLE_TX_COUNT="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  FINAL_LONG_QUERY_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  FINAL_WAITING_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where not granted;")"
  FINAL_DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
  FINAL_PREPARED_TX_COUNT="$(run_sql "select count(*)::text from pg_prepared_xacts;")"
  FINAL_DB_SIZE_BYTES="$(run_sql "select pg_database_size(current_database())::bigint::text;")"
  FINAL_PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  FINAL_TRACK_IO="$(run_sql "show track_io_timing;")"
fi

detail "FINAL_DB_ROLE=$FINAL_DB_ROLE"
detail "FINAL_DB_TOTAL_CONNECTIONS=$FINAL_TOTAL_CONNECTIONS"
detail "FINAL_DB_IDLE_IN_TRANSACTION_CONNECTIONS=$FINAL_IDLE_TX_COUNT"
detail "FINAL_DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$FINAL_LONG_QUERY_60S"
detail "FINAL_DB_WAITING_LOCK_COUNT=$FINAL_WAITING_LOCK_COUNT"
detail "FINAL_DB_DEADLOCK_COUNT=$FINAL_DEADLOCK_COUNT"
detail "FINAL_DB_PREPARED_TRANSACTION_COUNT=$FINAL_PREPARED_TX_COUNT"
detail "FINAL_DATABASE_SIZE_BYTES=$FINAL_DB_SIZE_BYTES"
detail "FINAL_PG_STAT_STATEMENTS_EXTENSION=$FINAL_PG_STAT_EXTENSION"
detail "FINAL_TRACK_IO_TIMING=$FINAL_TRACK_IO"

if [ "$FINAL_DB_ROLE" != "PRIMARY_WRITE" ]; then
  fail "final DB role PRIMARY_WRITE degil"
fi

if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then
  fail "final pg_stat_statements extension aktif degil"
fi

if [ "$FINAL_TRACK_IO" != "on" ]; then
  fail "final track_io_timing on degil"
fi

if [ "$FINAL_WAITING_LOCK_COUNT" != "0" ]; then
  warn "final waiting lock count sifir degil: $FINAL_WAITING_LOCK_COUNT"
  risk "RISK_FINAL_WAITING_LOCK_COUNT=$FINAL_WAITING_LOCK_COUNT"
fi

if [ "$FINAL_IDLE_TX_COUNT" != "0" ]; then
  warn "final idle in transaction count sifir degil: $FINAL_IDLE_TX_COUNT"
  risk "RISK_FINAL_IDLE_TX_COUNT=$FINAL_IDLE_TX_COUNT"
fi

if [ "$FINAL_LONG_QUERY_60S" != "0" ]; then
  warn "final long query 60s count sifir degil: $FINAL_LONG_QUERY_60S"
  risk "RISK_FINAL_LONG_QUERY_60S=$FINAL_LONG_QUERY_60S"
fi

if [ "$FINAL_PREPARED_TX_COUNT" != "0" ]; then
  warn "final prepared transaction count sifir degil: $FINAL_PREPARED_TX_COUNT"
  risk "RISK_FINAL_PREPARED_TX_COUNT=$FINAL_PREPARED_TX_COUNT"
fi

closure "14.4.1 Query performance baseline=$S_1441"
closure "14.4.2 Index usage baseline=$S_1442"
closure "14.4.3 Vacuum/bloat readiness=$S_1443"
closure "14.4.4 DB health baseline=$S_1444"
closure "14.4.5 Final closure=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
closure "DB_PERFORMANCE_RISK_FINAL=$FINAL_RISK"
closure "FINAL_DB_ROLE=$FINAL_DB_ROLE"
closure "FINAL_DB_CONNECTION_CHECK=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo REVIEW)"
closure "FINAL_DB_WAITING_LOCK_COUNT=$FINAL_WAITING_LOCK_COUNT"
closure "FINAL_DB_DEADLOCK_COUNT=$FINAL_DEADLOCK_COUNT"
closure "FINAL_DB_IDLE_IN_TRANSACTION_CONNECTIONS=$FINAL_IDLE_TX_COUNT"
closure "FINAL_DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$FINAL_LONG_QUERY_60S"
closure "FINAL_DB_PREPARED_TRANSACTION_COUNT=$FINAL_PREPARED_TX_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_PERFORMANCE_FINAL_CLOSURE=PASS"
else
  detail "DB_PERFORMANCE_FINAL_CLOSURE=FAIL"
fi

{
  echo "# FAZ 4 / 14.4.5 - DB Performance Final Closure Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_PERFORMANCE_FINAL_CLOSURE=PASS"
  else
    echo "DB_PERFORMANCE_FINAL_CLOSURE=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Closure Evidence"
  cat "$CLOSURE_EVIDENCE_FILE"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ DB performance final risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "DB_MUTATION=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "EXTENSION_CREATED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "QUERY_KILL_EXECUTED=NO"
  echo "LOCK_TERMINATION_EXECUTED=NO"
  echo "VACUUM_EXECUTED=NO"
  echo "ANALYZE_EXECUTED=NO"
  echo "INDEX_DROP_EXECUTED=NO"
  echo "INDEX_CREATE_EXECUTED=NO"

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
  echo "# FAZ 4 / 14.4 - DB Query Performance / Index Usage / Vacuum Baseline Final Closure"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Closure Evidence"
  cat "$CLOSURE_EVIDENCE_FILE"
  echo
  echo "## Final Status"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ4_14_4_FINAL_STATUS=PASS"
    echo "DB_PERFORMANCE_STACK_STATUS=BASELINED"
    echo "DB_PERFORMANCE_RISK_FINAL=$FINAL_RISK"
    echo "DB_PERFORMANCE_FINAL_CLOSURE=PASS"
  else
    echo "FAZ4_14_4_FINAL_STATUS=FAIL"
    echo "DB_PERFORMANCE_STACK_STATUS=REVIEW_REQUIRED"
    echo "DB_PERFORMANCE_RISK_FINAL=$FINAL_RISK"
    echo "DB_PERFORMANCE_FINAL_CLOSURE=FAIL"
  fi
  echo
  echo "## Safety"
  echo "DB_MUTATION=NO"
  echo "POSTGRES_CONFIG_CHANGED=NO"
  echo "CONTAINER_RESTARTED=NO"
  echo "INDEX_DROP_EXECUTED=NO"
  echo "INDEX_CREATE_EXECUTED=NO"
  echo "VACUUM_EXECUTED=NO"
  echo "ANALYZE_EXECUTED=NO"
  echo "QUERY_TEXT_PRINTED=NO"
} > "$CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "CLOSURE_FILE=$CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_PERFORMANCE_RISK_FINAL=$FINAL_RISK"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_PERFORMANCE_FINAL_CLOSURE=FAIL ❌"
  exit 1
fi

echo "DB_PERFORMANCE_FINAL_CLOSURE=PASS ✅"
