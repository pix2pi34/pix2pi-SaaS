#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"
TABLE_SCAN_FILE="$REPORT_DIR/14_4_2_table_scan_metrics.tsv"
INDEX_USAGE_FILE="$REPORT_DIR/14_4_2_index_usage_metrics.tsv"

PREV_REPORT="$REPORT_DIR/14_4_1_query_performance_baseline_report.md"

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
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_4_2_sql_err.log || echo "error"
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

TOP_LIMIT="${TOP_LIMIT:-80}"
HIGH_ROW_TABLE_THRESHOLD="${HIGH_ROW_TABLE_THRESHOLD:-10000}"
UNUSED_INDEX_WARN_THRESHOLD="${UNUSED_INDEX_WARN_THRESHOLD:-50}"

detail "ROOT_DIR=$ROOT_DIR"
detail "DB_MUTATION=NO"
detail "POSTGRES_CONFIG_CHANGED=NO"
detail "EXTENSION_CREATED=NO"
detail "CONTAINER_RESTARTED=NO"
detail "QUERY_KILL_EXECUTED=NO"
detail "VACUUM_EXECUTED=NO"
detail "INDEX_DROP_EXECUTED=NO"
detail "INDEX_CREATE_EXECUTED=NO"
detail "QUERY_TEXT_PRINTED=NO"
detail "TABLE_SCAN_FILE=docs/phase4/14_4_2_table_scan_metrics.tsv"
detail "INDEX_USAGE_FILE=docs/phase4/14_4_2_index_usage_metrics.tsv"
detail "TOP_LIMIT=$TOP_LIMIT"
detail "HIGH_ROW_TABLE_THRESHOLD=$HIGH_ROW_TABLE_THRESHOLD"
detail "UNUSED_INDEX_WARN_THRESHOLD=$UNUSED_INDEX_WARN_THRESHOLD"

PSQL_FOUND=0

if tool_status "psql"; then
  PSQL_FOUND=1
fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

PREV_STATUS="$(get_report_value "$PREV_REPORT" "QUERY_PERFORMANCE_BASELINE")"
detail "PREVIOUS_14_4_1_QUERY_PERFORMANCE_BASELINE=$PREV_STATUS"

if [ "$PREV_STATUS" != "PASS" ]; then
  fail "14.4.1 query performance baseline PASS degil"
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
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_4_2_psql_ok.log 2>/tmp/pix2pi_14_4_2_psql_err.log; then
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
PRELOAD="error"
TRACK_IO="error"
PG_STAT_EXTENSION="error"
PG_STAT_VIEW_CHECK="error"
USER_TABLE_COUNT="error"
USER_INDEX_COUNT="error"
TOTAL_SEQ_SCAN="error"
TOTAL_IDX_SCAN="error"
TOTAL_SEQ_TUP_READ="error"
TOTAL_IDX_TUP_FETCH="error"
TOTAL_LIVE_TUPLES="error"
TOTAL_DEAD_TUPLES="error"
TABLES_WITH_SEQ_SCAN_COUNT="error"
TABLES_SEQ_GT_IDX_COUNT="error"
HIGH_ROW_SEQ_SCAN_RISK_COUNT="error"
UNUSED_INDEX_COUNT="error"
UNUSED_NON_UNIQUE_INDEX_COUNT="error"
UNUSED_PRIMARY_OR_UNIQUE_INDEX_COUNT="error"
TOTAL_INDEX_SIZE_BYTES="error"
LARGEST_INDEX_SIZE_BYTES="error"
INDEXES_WITH_SCANS_COUNT="error"
STATS_RESET="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  SERVER_VERSION="$(run_sql "show server_version;")"
  PRELOAD="$(run_sql "show shared_preload_libraries;")"
  TRACK_IO="$(run_sql "show track_io_timing;")"
  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  PG_STAT_VIEW_CHECK="$(run_sql "select to_regclass('public.pg_stat_statements') is not null or to_regclass('pg_catalog.pg_stat_statements') is not null;")"
  STATS_RESET="$(run_sql "select coalesce(stats_reset::text,'NULL') from pg_stat_database where datname=current_database();")"

  USER_TABLE_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables;")"
  USER_INDEX_COUNT="$(run_sql "select count(*)::text from pg_stat_user_indexes;")"
  TOTAL_SEQ_SCAN="$(run_sql "select coalesce(sum(seq_scan),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_IDX_SCAN="$(run_sql "select coalesce(sum(idx_scan),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_SEQ_TUP_READ="$(run_sql "select coalesce(sum(seq_tup_read),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_IDX_TUP_FETCH="$(run_sql "select coalesce(sum(idx_tup_fetch),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_LIVE_TUPLES="$(run_sql "select coalesce(sum(n_live_tup),0)::bigint::text from pg_stat_user_tables;")"
  TOTAL_DEAD_TUPLES="$(run_sql "select coalesce(sum(n_dead_tup),0)::bigint::text from pg_stat_user_tables;")"
  TABLES_WITH_SEQ_SCAN_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where seq_scan > 0;")"
  TABLES_SEQ_GT_IDX_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where seq_scan > idx_scan and seq_scan > 0;")"
  HIGH_ROW_SEQ_SCAN_RISK_COUNT="$(run_sql "select count(*)::text from pg_stat_user_tables where n_live_tup >= ${HIGH_ROW_TABLE_THRESHOLD} and seq_scan > idx_scan and seq_scan > 0;")"

  UNUSED_INDEX_COUNT="$(run_sql "select count(*)::text from pg_stat_user_indexes sui join pg_index ix on ix.indexrelid=sui.indexrelid where sui.idx_scan=0;")"
  UNUSED_NON_UNIQUE_INDEX_COUNT="$(run_sql "select count(*)::text from pg_stat_user_indexes sui join pg_index ix on ix.indexrelid=sui.indexrelid where sui.idx_scan=0 and ix.indisprimary=false and ix.indisunique=false;")"
  UNUSED_PRIMARY_OR_UNIQUE_INDEX_COUNT="$(run_sql "select count(*)::text from pg_stat_user_indexes sui join pg_index ix on ix.indexrelid=sui.indexrelid where sui.idx_scan=0 and (ix.indisprimary=true or ix.indisunique=true);")"
  TOTAL_INDEX_SIZE_BYTES="$(run_sql "select coalesce(sum(pg_relation_size(indexrelid)),0)::bigint::text from pg_stat_user_indexes;")"
  LARGEST_INDEX_SIZE_BYTES="$(run_sql "select coalesce(max(pg_relation_size(indexrelid)),0)::bigint::text from pg_stat_user_indexes;")"
  INDEXES_WITH_SCANS_COUNT="$(run_sql "select count(*)::text from pg_stat_user_indexes where idx_scan > 0;")"
fi

detail "POSTGRES_SERVER_VERSION=$SERVER_VERSION"
detail "SHARED_PRELOAD_LIBRARIES=$PRELOAD"
detail "TRACK_IO_TIMING=$TRACK_IO"
detail "PG_STAT_STATEMENTS_EXTENSION=$PG_STAT_EXTENSION"
detail "PG_STAT_STATEMENTS_VIEW_CHECK=$PG_STAT_VIEW_CHECK"
detail "PG_STAT_DATABASE_STATS_RESET=$STATS_RESET"

detail "DB_USER_TABLE_COUNT=$USER_TABLE_COUNT"
detail "DB_USER_INDEX_COUNT=$USER_INDEX_COUNT"
detail "DB_TOTAL_SEQ_SCAN=$TOTAL_SEQ_SCAN"
detail "DB_TOTAL_IDX_SCAN=$TOTAL_IDX_SCAN"
detail "DB_TOTAL_SEQ_TUP_READ=$TOTAL_SEQ_TUP_READ"
detail "DB_TOTAL_IDX_TUP_FETCH=$TOTAL_IDX_TUP_FETCH"
detail "DB_TOTAL_LIVE_TUPLES=$TOTAL_LIVE_TUPLES"
detail "DB_TOTAL_DEAD_TUPLES=$TOTAL_DEAD_TUPLES"
detail "DB_TABLES_WITH_SEQ_SCAN_COUNT=$TABLES_WITH_SEQ_SCAN_COUNT"
detail "DB_TABLES_SEQ_GT_IDX_COUNT=$TABLES_SEQ_GT_IDX_COUNT"
detail "DB_HIGH_ROW_SEQ_SCAN_RISK_COUNT=$HIGH_ROW_SEQ_SCAN_RISK_COUNT"

detail "DB_UNUSED_INDEX_COUNT=$UNUSED_INDEX_COUNT"
detail "DB_UNUSED_NON_UNIQUE_INDEX_COUNT=$UNUSED_NON_UNIQUE_INDEX_COUNT"
detail "DB_UNUSED_PRIMARY_OR_UNIQUE_INDEX_COUNT=$UNUSED_PRIMARY_OR_UNIQUE_INDEX_COUNT"
detail "DB_INDEXES_WITH_SCANS_COUNT=$INDEXES_WITH_SCANS_COUNT"
detail "DB_TOTAL_INDEX_SIZE_BYTES=$TOTAL_INDEX_SIZE_BYTES"
detail "DB_LARGEST_INDEX_SIZE_BYTES=$LARGEST_INDEX_SIZE_BYTES"

LOW_DATA_CONTEXT="NO"
if is_number "$TOTAL_LIVE_TUPLES" && [ "$TOTAL_LIVE_TUPLES" -lt "$HIGH_ROW_TABLE_THRESHOLD" ]; then
  LOW_DATA_CONTEXT="YES"
fi
detail "LOW_DATA_CONTEXT=$LOW_DATA_CONTEXT"

if ! printf '%s' "$PRELOAD" | grep -q "pg_stat_statements"; then
  fail "pg_stat_statements preload aktif degil"
fi

if [ "$TRACK_IO" != "on" ]; then
  fail "track_io_timing on degil"
fi

if [ "$PG_STAT_EXTENSION" != "t" ]; then
  fail "pg_stat_statements extension aktif degil"
fi

if [ "$PG_STAT_VIEW_CHECK" != "t" ]; then
  fail "pg_stat_statements view okunamiyor"
fi

{
  echo -e "rank\tschemaname\ttable_name\tseq_scan\tidx_scan\tseq_tup_read\tidx_tup_fetch\tn_live_tup\tn_dead_tup\tscan_pattern"
} > "$TABLE_SCAN_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  row_number() over (order by seq_scan desc, seq_tup_read desc) as rank,
  schemaname,
  relname as table_name,
  seq_scan::bigint::text,
  idx_scan::bigint::text,
  seq_tup_read::bigint::text,
  idx_tup_fetch::bigint::text,
  n_live_tup::bigint::text,
  n_dead_tup::bigint::text,
  case
    when seq_scan > idx_scan and n_live_tup >= ${HIGH_ROW_TABLE_THRESHOLD} then 'HIGH_ROW_SEQ_SCAN_REVIEW'
    when seq_scan > idx_scan and seq_scan > 0 then 'LOW_DATA_SEQ_SCAN_OBSERVE'
    when idx_scan > 0 then 'INDEX_USED'
    else 'NO_SCAN_YET'
  end as scan_pattern
from pg_stat_user_tables
order by seq_scan desc, seq_tup_read desc, relname asc
limit ${TOP_LIMIT};
" >> "$TABLE_SCAN_FILE" 2>/tmp/pix2pi_14_4_2_table_scan_err.log || {
    fail "table scan metrics uretilemedi"
  }
fi

{
  echo -e "rank\tschemaname\ttable_name\tindex_name\tidx_scan\tidx_tup_read\tidx_tup_fetch\tindex_size_bytes\tis_primary\tis_unique\tusage_status"
} > "$INDEX_USAGE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -F $'\t' -Atqc "
select
  row_number() over (
    order by
      case when sui.idx_scan = 0 and ix.indisprimary=false and ix.indisunique=false then 0 else 1 end,
      pg_relation_size(sui.indexrelid) desc,
      sui.idx_scan asc,
      sui.indexrelname asc
  ) as rank,
  sui.schemaname,
  sui.relname as table_name,
  sui.indexrelname as index_name,
  sui.idx_scan::bigint::text,
  sui.idx_tup_read::bigint::text,
  sui.idx_tup_fetch::bigint::text,
  pg_relation_size(sui.indexrelid)::bigint::text,
  ix.indisprimary::text,
  ix.indisunique::text,
  case
    when sui.idx_scan = 0 and ix.indisprimary=true then 'UNUSED_PRIMARY_OBSERVE_ONLY'
    when sui.idx_scan = 0 and ix.indisunique=true then 'UNUSED_UNIQUE_OBSERVE_ONLY'
    when sui.idx_scan = 0 then 'UNUSED_NON_UNIQUE_REVIEW_ONLY'
    else 'INDEX_USED'
  end as usage_status
from pg_stat_user_indexes sui
join pg_index ix on ix.indexrelid = sui.indexrelid
order by
  case when sui.idx_scan = 0 and ix.indisprimary=false and ix.indisunique=false then 0 else 1 end,
  pg_relation_size(sui.indexrelid) desc,
  sui.idx_scan asc,
  sui.indexrelname asc
limit ${TOP_LIMIT};
" >> "$INDEX_USAGE_FILE" 2>/tmp/pix2pi_14_4_2_index_usage_err.log || {
    fail "index usage metrics uretilemedi"
  }
fi

TABLE_SCAN_LINE_COUNT=0
INDEX_USAGE_LINE_COUNT=0

if [ -f "$TABLE_SCAN_FILE" ]; then
  TABLE_SCAN_LINE_COUNT="$(wc -l < "$TABLE_SCAN_FILE" | tr -d ' ')"
fi

if [ -f "$INDEX_USAGE_FILE" ]; then
  INDEX_USAGE_LINE_COUNT="$(wc -l < "$INDEX_USAGE_FILE" | tr -d ' ')"
fi

detail "TABLE_SCAN_FILE_LINE_COUNT=$TABLE_SCAN_LINE_COUNT"
detail "INDEX_USAGE_FILE_LINE_COUNT=$INDEX_USAGE_LINE_COUNT"

INDEX_USAGE_RISK_SCORE=0

if is_number "$HIGH_ROW_SEQ_SCAN_RISK_COUNT" && [ "$HIGH_ROW_SEQ_SCAN_RISK_COUNT" -gt 0 ]; then
  INDEX_USAGE_RISK_SCORE=$((INDEX_USAGE_RISK_SCORE + 3))
  risk "RISK_HIGH_ROW_SEQ_SCAN=buyuk tabloda seq scan agirligi var"
fi

if is_number "$UNUSED_NON_UNIQUE_INDEX_COUNT" && [ "$UNUSED_NON_UNIQUE_INDEX_COUNT" -gt "$UNUSED_INDEX_WARN_THRESHOLD" ]; then
  if [ "$LOW_DATA_CONTEXT" = "YES" ]; then
    risk "RISK_UNUSED_INDEX_LOW_DATA_CONTEXT=unused non-unique index cok ama data hacmi dusuk; drop adayi degil, observe only"
  else
    INDEX_USAGE_RISK_SCORE=$((INDEX_USAGE_RISK_SCORE + 2))
    risk "RISK_UNUSED_NON_UNIQUE_INDEX_COUNT=unused non-unique index sayisi esik ustunde"
  fi
fi

if is_number "$TABLES_SEQ_GT_IDX_COUNT" && [ "$TABLES_SEQ_GT_IDX_COUNT" -gt 0 ]; then
  if [ "$LOW_DATA_CONTEXT" = "YES" ]; then
    risk "RISK_SEQ_GT_IDX_LOW_DATA_CONTEXT=seq scan agirlikli tablolar var ama data hacmi dusuk; observe only"
  else
    INDEX_USAGE_RISK_SCORE=$((INDEX_USAGE_RISK_SCORE + 1))
    risk "RISK_SEQ_GT_IDX=seq_scan > idx_scan olan tablolar var"
  fi
fi

INDEX_USAGE_RISK_LEVEL="LOW"

if [ "$INDEX_USAGE_RISK_SCORE" -ge 5 ]; then
  INDEX_USAGE_RISK_LEVEL="HIGH"
elif [ "$INDEX_USAGE_RISK_SCORE" -ge 2 ]; then
  INDEX_USAGE_RISK_LEVEL="MEDIUM"
fi

detail "INDEX_USAGE_RISK_SCORE=$INDEX_USAGE_RISK_SCORE"
detail "INDEX_USAGE_RISK_LEVEL=$INDEX_USAGE_RISK_LEVEL"

if [ "$INDEX_USAGE_RISK_LEVEL" != "LOW" ]; then
  warn "index usage risk seviyesi $INDEX_USAGE_RISK_LEVEL"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "INDEX_USAGE_BASELINE=PASS"
else
  detail "INDEX_USAGE_BASELINE=FAIL"
fi

{
  echo "# FAZ 4 / 14.4.2 - Index Usage / Unused Index / Scan Ratio Evidence Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "INDEX_USAGE_BASELINE=PASS"
  else
    echo "INDEX_USAGE_BASELINE=FAIL"
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
  echo "TABLE_SCAN_FILE=docs/phase4/14_4_2_table_scan_metrics.tsv"
  echo "INDEX_USAGE_FILE=docs/phase4/14_4_2_index_usage_metrics.tsv"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ index usage major risk yok"
  fi

  echo
  echo "## Safety Decision"
  echo "INDEX_DROP_EXECUTED=NO"
  echo "INDEX_CREATE_EXECUTED=NO"
  echo "UNUSED_INDEX_ACTION=REPORT_ONLY"
  echo "PRIMARY_UNIQUE_INDEX_ACTION=OBSERVE_ONLY"

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
echo "TABLE_SCAN_FILE=$TABLE_SCAN_FILE"
echo "INDEX_USAGE_FILE=$INDEX_USAGE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "INDEX_USAGE_RISK_LEVEL=$INDEX_USAGE_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "INDEX_USAGE_BASELINE=FAIL ❌"
  exit 1
fi

echo "INDEX_USAGE_BASELINE=PASS ✅"
