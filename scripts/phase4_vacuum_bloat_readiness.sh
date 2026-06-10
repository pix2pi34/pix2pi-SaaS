#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_4_3_vacuum_bloat_readiness_report.md"
TABLE_METRICS_FILE="$REPORT_DIR/14_4_3_table_vacuum_metrics.tsv"

PREV_REPORT="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"

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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_4_3_sql_err.log || echo "error"
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

TOP_LIMIT="${TOP_LIMIT:-100}"
HIGH_DEAD_TUPLE_THRESHOLD="${HIGH_DEAD_TUPLE_THRESHOLD:-10000}"
HIGH_DEAD_RATIO_THRESHOLD="${HIGH_DEAD_RATIO_THRESHOLD:-20}"
LOW_DATA_LIVE_TUPLE_THRESHOLD="${LOW_DATA_LIVE_TUPLE_THRESHOLD:-10000}"

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "ANALYZE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "BLOAT_APPROX_METHOD=DEAD_TUPLE_PROXY_NO_EXTENSION"
detail "TABLE_METRICS_FILE=docs/phase4/14_4_3_table_vacuum_metrics.tsv"
detail "TOP_LIMIT=$TOP_LIMIT"
detail "HIGH_DEAD_TUPLE_THRESHOLD=$HIGH_DEAD_TUPLE_THRESHOLD"
detail "HIGH_DEAD_RATIO_THRESHOLD=$HIGH_DEAD_RATIO_THRESHOLD"
detail "LOW_DATA_LIVE_TUPLE_THRESHOLD=$LOW_DATA_LIVE_TUPLE_THRESHOLD"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_STATUS="$(get_report_value "$PREV_REPORT" "INDEX_USAGE_BASELINE")"
detail "PREVIOUS_14_4_2_INDEX_USAGE_BASELINE=$PREV_STATUS"

if [ "$PREV_STATUS" != "PASS" ]; then
  fail "14.4.2 index usage baseline PASS degil"
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
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_4_3_psql_ok.log 2>/tmp/pix2pi_14_4_3_psql_err.log; then
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
AUTOVACUUM="error"
TRACK_COUNTS="error"
AUTOVACUUM_NAPTIME="error"
AUTOVACUUM_VACUUM_SCALE_FACTOR="error"
AUTOVACUUM_ANALYZE_SCALE_FACTOR="error"
AUTOVACUUM_VACUUM_THRESHOLD="error"
AUTOVACUUM_ANALYZE_THRESHOLD="error"
VACUUM_COST_DELAY="error"

USER_TABLE_COUNT="error"
TOTAL_LIVE_TUPLES="error"
TOTAL_DEAD_TUPLES="error"
TABLES_WITH_DEAD_TUPLES="error"
HIGH_DEAD_TUPLE_TABLE_COUNT="error"
HIGH_DEAD_RATIO_TABLE_COUNT="error"
LAST_AUTOVACUUM_NULL_COUNT="error"
LAST_AUTOANALYZE_NULL_COUNT="error"
AUTOVACUUMED_TABLE_COUNT="error"
AUTOANALYZED_TABLE_COUNT="error"
TOTAL_VACUUM_COUNT="error"
TOTAL_AUTOVACUUM_COUNT="error"
TOTAL_ANALYZE_COUNT="error"
TOTAL_AUTOANALYZE_COUNT="error"
MAX_DEAD_TUPLES="error"
MAX_DEAD_RATIO_PCT="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION="$(run_sql "show server_version;")"
  AUTOVACUUM="$(run_sql "show autovacuum;")"
  TRACK_COUNTS="$(run_sql "show track_counts;")"
  AUTOVACUUM_NAPTIME="$(run_sql "show autovacuum_naptime;")"
  AUTOVACUUM_VACUUM_SCALE_FACTOR="$(run_sql "show autovacuum_vacuum_scale_factor;")"
  AUTOVACUUM_ANALYZE_SCALE_FACTOR="$(run_sql "show autovacuum_analyze_scale_factor;")"
  AUTOVACUUM_VACUUM_THRESHOLD="$(run_sql "show autovacuum_vacuum_threshold;")"
  AUTOVACUUM_ANALYZE_THRESHOLD="$(run_sql "show autovacuum_analyze_threshold;")"
  VACUUM_COST_DELAY="$(run_sql "show vacuum_cost_delay;")"

  USER_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables;")"
  TOTAL_LIVE_TUPLES="$(run_sql "select coalesce(sum(n_live_tup),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_DEAD_TUPLES="$(run_sql "select coalesce(sum(n_dead_tup),0)::bigint::text from pg_stat_user_tables;")"
  TABLES_WITH_DEAD_TUPLES="$(run_sql "select count(*)::text from pg_stat_user_tables where n_dead_tup > 0;")"
  HIGH_DEAD_TUPLE_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where n_dead_tup >= ${HIGH_DEAD_TUPLE_THRESHOLD};")"
  HIGH_DEAD_RATIO_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where (n_live_tup + n_dead_tup) > 0 and ((n_dead_tup::numeric / (n_live_tup + n_dead_tup)::numeric) * 100) >= ${HIGH_DEAD_RATIO_THRESHOLD};")"
  LAST_AUTOVACUUM_NULL_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where last_autovacuum is null;")"
  LAST_AUTOANALYZE_NULL_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where last_autoanalyze is null;")"
  AUTOVACUUMED_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where last_autovacuum is not null;")"
  AUTOANALYZED_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where last_autoanalyze is not null;")"
  TOTAL_VACUUM_COUNT="$(run_sql "select coalesce(sum(vacuum_count),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_AUTOVACUUM_COUNT="$(run_sql "select coalesce(sum(autovacuum_count),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_ANALYZE_COUNT="$(run_sql "select coalesce(sum(analyze_count),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_AUTOANALYZE_COUNT="$(run_sql "select coalesce(sum(autoanalyze_count),0)::bigint::text from pg_stat_user_tables;")"
  MAX_DEAD_TUPLES="$(run_sql "select coalesce(max(n_dead_tup),0)::bigint::text from pg_stat_user_tables;")"
  MAX_DEAD_RATIO_PCT="$(run_sql "select round(coalesce(max(case when (n_live_tup+n_dead_tup)>0 then (n_dead_tup::numeric/(n_live_tup+n_dead_tup)::numeric)*100 else 0 end),0),2)::text from pg_stat_user_tables;")"
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "AUTOVACUUM=$AUTOVACUUM"
detail "TRACK_COUNTS=$TRACK_COUNTS"
detail "AUTOVACUUM_NAPTIME=$AUTOVACUUM_NAPTIME"
detail "AUTOVACUUM_VACUUM_SCALE_FACTOR=$AUTOVACUUM_VACUUM_SCALE_FACTOR"
detail "AUTOVACUUM_ANALYZE_SCALE_FACTOR=$AUTOVACUUM_ANALYZE_SCALE_FACTOR"
detail "AUTOVACUUM_VACUUM_THRESHOLD=$AUTOVACUUM_VACUUM_THRESHOLD"
detail "AUTOVACUUM_ANALYZE_THRESHOLD=$AUTOVACUUM_ANALYZE_THRESHOLD"
detail "VACUUM_COST_DELAY=$VACUUM_COST_DELAY"

detail "DB_USER_TABLE_COUNT=$USER_TABLE_COUNT"
detail "DB_TOTAL_LIVE_TUPLES=$TOTAL_LIVE_TUPLES"
detail "DB_TOTAL_DEAD_TUPLES=$TOTAL_DEAD_TUPLES"
detail "DB_TABLES_WITH_DEAD_TUPLES=$TABLES_WITH_DEAD_TUPLES"
detail "DB_HIGH_DEAD_TUPLE_TABLE_COUNT=$HIGH_DEAD_TUPLE_TABLE_COUNT"
detail "DB_HIGH_DEAD_RATIO_TABLE_COUNT=$HIGH_DEAD_RATIO_TABLE_COUNT"
detail "DB_LAST_AUTOVACUUM_NULL_COUNT=$LAST_AUTOVACUUM_NULL_COUNT"
detail "DB_LAST_AUTOANALYZE_NULL_COUNT=$LAST_AUTOANALYZE_NULL_COUNT"
detail "DB_AUTOVACUUMED_TABLE_COUNT=$AUTOVACUUMED_TABLE_COUNT"
detail "DB_AUTOANALYZED_TABLE_COUNT=$AUTOANALYZED_TABLE_COUNT"
detail "DB_TOTAL_VACUUM_COUNT=$TOTAL_VACUUM_COUNT"
detail "DB_TOTAL_AUTOVACUUM_COUNT=$TOTAL_AUTOVACUUM_COUNT"
detail "DB_TOTAL_ANALYZE_COUNT=$TOTAL_ANALYZE_COUNT"
detail "DB_TOTAL_AUTOANALYZE_COUNT=$TOTAL_AUTOANALYZE_COUNT"
detail "DB_MAX_DEAD_TUPLES=$MAX_DEAD_TUPLES"
detail "DB_MAX_DEAD_RATIO_PCT=$MAX_DEAD_RATIO_PCT"

LOW_DATA_CONTEXT="NO"
if is_number "$TOTAL_LIVE_TUPLES" && [ "$TOTAL_LIVE_TUPLES" -lt "$LOW_DATA_LIVE_TUPLE_THRESHOLD" ]; then
  LOW_DATA_CONTEXT="YES"
fi
detail "LOW_DATA_CONTEXT=$LOW_DATA_CONTEXT"

if [ "$AUTOVACUUM" != "on" ]; then
  fail "autovacuum off gorunuyor"
fi

if [ "$TRACK_COUNTS" != "on" ]; then
  fail "track_counts off gorunuyor"
fi

{
  echo -e "rank\tschemaname\ttable_name\tn_live_tup\tn_dead_tup\tdead_ratio_pct\tlast_vacuum\tlast_autovacuum\tlast_analyze\tlast_autoanalyze\tvacuum_count\tautovacuum_count\tanalyze_count\tautoanalyze_count\tvacuum_status"
} > "$TABLE_METRICS_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  row_number() over (
    order by
      n_dead_tup desc,
      case when (n_live_tup+n_dead_tup)>0 then (n_dead_tup::numeric/(n_live_tup+n_dead_tup)::numeric)*100 else 0 end desc,
      relname asc
  ) as rank,
  schemaname,
  relname as table_name,
  n_live_tup::bigint::text,
  n_dead_tup::bigint::text,
  round(
    case
      when (n_live_tup+n_dead_tup)>0
      then (n_dead_tup::numeric/(n_live_tup+n_dead_tup)::numeric)*100
      else 0
    end,
    2
  )::text as dead_ratio_pct,
  coalesce(last_vacuum::text,'NULL') as last_vacuum,
  coalesce(last_autovacuum::text,'NULL') as last_autovacuum,
  coalesce(last_analyze::text,'NULL') as last_analyze,
  coalesce(last_autoanalyze::text,'NULL') as last_autoanalyze,
  vacuum_count::bigint::text,
  autovacuum_count::bigint::text,
  analyze_count::bigint::text,
  autoanalyze_count::bigint::text,
  case
    when n_dead_tup >= ${HIGH_DEAD_TUPLE_THRESHOLD} then 'HIGH_DEAD_TUPLE_REVIEW'
    when (n_live_tup+n_dead_tup)>0 and ((n_dead_tup::numeric/(n_live_tup+n_dead_tup)::numeric)*100) >= ${HIGH_DEAD_RATIO_THRESHOLD} and (n_live_tup+n_dead_tup) >= ${LOW_DATA_LIVE_TUPLE_THRESHOLD} then 'HIGH_DEAD_RATIO_REVIEW'
    when n_dead_tup > 0 then 'DEAD_TUPLE_OBSERVE'
    when last_autovacuum is null and last_autoanalyze is null then 'NO_AUTOVACUUM_YET_OBSERVE'
    else 'OK'
  end as vacuum_status
from pg_stat_user_tables
order by
  n_dead_tup desc,
  case when (n_live_tup+n_dead_tup)>0 then (n_dead_tup::numeric/(n_live_tup+n_dead_tup)::numeric)*100 else 0 end desc,
  relname asc
limit ${TOP_LIMIT};
" >> "$TABLE_METRICS_FILE" 2>/tmp/pix2pi_14_4_3_table_metrics_err.log || {
    fail "table vacuum metrics uretilemedi"
  }
fi

TABLE_METRICS_LINE_COUNT=0

if [ -f "$TABLE_METRICS_FILE" ]; then
  TABLE_METRICS_LINE_COUNT="$(wc -l < "$TABLE_METRICS_FILE" | tr -d ' ')"
fi

detail "TABLE_METRICS_FILE_LINE_COUNT=$TABLE_METRICS_LINE_COUNT"

VACUUM_RISK_SCORE=0

if [ "$AUTOVACUUM" != "on" ]; then
  VACUUM_RISK_SCORE=$((VACUUM_RISK_SCORE + 5))
  risk "RISK_AUTOVACUUM_OFF=autovacuum kapali"
fi

if [ "$TRACK_COUNTS" != "on" ]; then
  VACUUM_RISK_SCORE=$((VACUUM_RISK_SCORE + 5))
  risk "RISK_TRACK_COUNTS_OFF=track_counts kapali"
fi

if is_number "$HIGH_DEAD_TUPLE_TABLE_COUNT" && [ "$HIGH_DEAD_TUPLE_TABLE_COUNT" -gt 0 ]; then
  VACUUM_RISK_SCORE=$((VACUUM_RISK_SCORE + 3))
  risk "RISK_HIGH_DEAD_TUPLE_TABLE=dead tuple sayisi yuksek tablo var"
fi

if is_number "$HIGH_DEAD_RATIO_TABLE_COUNT" && [ "$HIGH_DEAD_RATIO_TABLE_COUNT" -gt 0 ]; then
  if [ "$LOW_DATA_CONTEXT" = "YES" ]; then
    risk "RISK_HIGH_DEAD_RATIO_LOW_DATA_CONTEXT=dead ratio yuksek gorunebilir ama data hacmi dusuk; observe only"
  else
    VACUUM_RISK_SCORE=$((VACUUM_RISK_SCORE + 2))
    risk "RISK_HIGH_DEAD_RATIO_TABLE=dead tuple orani yuksek tablo var"
  fi
fi

if is_number "$LAST_AUTOVACUUM_NULL_COUNT" && is_number "$USER_TABLE_COUNT" && [ "$USER_TABLE_COUNT" -gt 0 ]; then
  if [ "$LAST_AUTOVACUUM_NULL_COUNT" -eq "$USER_TABLE_COUNT" ]; then
    if [ "$LOW_DATA_CONTEXT" = "YES" ]; then
      risk "RISK_NO_AUTOVACUUM_YET_LOW_DATA_CONTEXT=tablolarin cogunda autovacuum gorunmemis ama data hacmi dusuk"
    else
      VACUUM_RISK_SCORE=$((VACUUM_RISK_SCORE + 2))
      risk "RISK_NO_AUTOVACUUM_YET=autovacuum henuz tablo bazinda gorunmuyor"
    fi
  fi
fi

VACUUM_RISK_LEVEL="LOW"

if [ "$VACUUM_RISK_SCORE" -ge 5 ]; then
  VACUUM_RISK_LEVEL="HIGH"
elif [ "$VACUUM_RISK_SCORE" -ge 2 ]; then
  VACUUM_RISK_LEVEL="MEDIUM"
fi

detail "VACUUM_RISK_SCORE=$VACUUM_RISK_SCORE"
detail "VACUUM_RISK_LEVEL=$VACUUM_RISK_LEVEL"

if [ "$VACUUM_RISK_LEVEL" != "LOW" ]; then
  warn "vacuum/bloat risk seviyesi $VACUUM_RISK_LEVEL"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "VACUUM_BLOAT_READINESS=PASS"
else
  detail "VACUUM_BLOAT_READINESS=FAIL"
fi

{
  echo "# FAZ 4 / 14.4.3 - Table Bloat / Dead Tuple / Vacuum Readiness Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "VACUUM_BLOAT_READINESS=PASS"
  else
    echo "VACUUM_BLOAT_READINESS=FAIL"
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
  echo "TABLE_METRICS_FILE=docs/phase4/14_4_3_table_vacuum_metrics.tsv"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ vacuum/bloat major risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "VACUUM_EXECUTED=NO"
  echo "ANALYZE_EXECUTED=NO"
  echo "DB_MUTATION=NO"
  echo "BLOAT_APPROX_METHOD=DEAD_TUPLE_PROXY_NO_EXTENSION"
  echo "PGSTATTUPLE_EXTENSION_CREATED=NO"

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
echo "TABLE_METRICS_FILE=$TABLE_METRICS_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "VACUUM_RISK_LEVEL=$VACUUM_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "VACUUM_BLOAT_READINESS=FAIL ❌"
  exit 1
fi

echo "VACUUM_BLOAT_READINESS=PASS ✅"
