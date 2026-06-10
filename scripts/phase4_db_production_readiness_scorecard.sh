#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_5_2_db_production_readiness_scorecard_report.md"
SCORECARD_FILE="$REPORT_DIR/14_5_2_db_production_readiness_scorecard.tsv"

R_1451="$REPORT_DIR/14_5_1_db_master_evidence_collector_report.md"
R_1418="$REPORT_DIR/14_1_8_migration_reconciliation_final_report.md"
R_1421="$REPORT_DIR/14_2_1_db_backup_pitr_readiness_report.md"
R_1422="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"
R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
R_1425="$REPORT_DIR/14_2_5_pitr_design_wal_archive_report.md"
R_1426="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"
R_143="$REPORT_DIR/14_3_final_db_observability_closure_report.md"
R_144="$REPORT_DIR/14_4_final_db_performance_closure_report.md"
R_1445="$REPORT_DIR/14_4_5_db_performance_final_closure_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
DEFERRED_ACTION_COUNT=0
BLOCKER_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
DEFERRED_FILE="$(mktemp)"
BLOCKER_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$DEFERRED_FILE" "$BLOCKER_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "$1" >> "$RISK_FILE"; }
defer() { echo "DEFERRED ⏭ $1" >> "$DEFERRED_FILE"; DEFERRED_ACTION_COUNT=$((DEFERRED_ACTION_COUNT + 1)); }
blocker() { echo "BLOCKER ❌ $1" >> "$BLOCKER_FILE"; BLOCKER_COUNT=$((BLOCKER_COUNT + 1)); FAIL_COUNT=$((FAIL_COUNT + 1)); }

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

require_file() {
  local label="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    blocker "$label dosyasi bulunamadi: ${file#$ROOT_DIR/}"
    return 1
  fi

  return 0
}

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_5_2_sql_err.log || echo "error"
}

add_score() {
  local category="$1"
  local score="$2"
  local max="$3"
  local status="$4"
  local note="$5"

  echo -e "${category}\t${score}\t${max}\t${status}\t${note}" >> "$SCORECARD_FILE"
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
detail "SCORECARD_FILE=docs/phase4/14_5_2_db_production_readiness_scorecard.tsv"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  blocker "psql bulunamadi"
fi

require_file "14.5.1 master evidence" "$R_1451" || true
require_file "14.1 final reconciliation" "$R_1418" || true
require_file "14.2.1 backup readiness" "$R_1421" || true
require_file "14.2.2 logical backup" "$R_1422" || true
require_file "14.2.4 restore drill" "$R_1424" || true
require_file "14.2.5 PITR design" "$R_1425" || true
require_file "14.2.6 PITR enable gate" "$R_1426" || true
require_file "14.3 observability final" "$R_143" || true
require_file "14.4 performance final" "$R_144" || true
require_file "14.4.5 performance closure" "$R_1445" || true

{
  echo -e "category\tscore\tmax_score\tstatus\tnote"
} > "$SCORECARD_FILE"

MASTER_STATUS="$(get_report_value "$R_1451" "DB_MASTER_EVIDENCE_COLLECTOR")"
S_141="$(get_report_value "$R_1451" "FAZ4_14_1_STATUS")"
S_142="$(get_report_value "$R_1451" "FAZ4_14_2_STATUS")"
S_143="$(get_report_value "$R_1451" "FAZ4_14_3_STATUS")"
S_144="$(get_report_value "$R_1451" "FAZ4_14_4_STATUS")"

MIGRATION_FINAL="$(get_report_value "$R_1418" "MIGRATION_RECONCILIATION_FINAL")"
MIGRATION_DECISION="$(get_report_value "$R_1418" "FINAL_DECISION")"

BACKUP_READY="$(get_report_value "$R_1421" "DB_BACKUP_PITR_READINESS_ASSESSMENT")"
LOGICAL_BACKUP="$(get_report_value "$R_1422" "LOGICAL_BACKUP_SMOKE")"
RESTORE_DRILL="$(get_report_value "$R_1424" "RESTORE_DRILL_TEST")"

PITR_DESIGN="$(get_report_value "$R_1425" "PITR_DESIGN_WAL_ARCHIVE_PLAN")"
PITR_GATE="$(get_report_value "$R_1426" "PITR_ENABLE_GATE")"
PITR_CURRENT_READY="$(get_report_value "$R_1426" "PITR_CURRENT_READY")"
PITR_DECISION="$(get_report_value "$R_1426" "PITR_ENABLE_DECISION")"

OBS_FINAL="$(get_report_value "$R_143" "FAZ4_14_3_FINAL_STATUS")"
OBS_STACK="$(get_report_value "$R_143" "DB_OBSERVABILITY_STACK_STATUS")"
OBS_RISK="$(get_report_value "$R_143" "DB_PERFORMANCE_RISK_FINAL")"

PERF_FINAL="$(get_report_value "$R_144" "FAZ4_14_4_FINAL_STATUS")"
PERF_STACK="$(get_report_value "$R_144" "DB_PERFORMANCE_STACK_STATUS")"
PERF_RISK="$(get_report_value "$R_144" "DB_PERFORMANCE_RISK_FINAL")"
PERF_CLOSURE="$(get_report_value "$R_1445" "DB_PERFORMANCE_FINAL_CLOSURE")"

detail "MASTER_EVIDENCE_STATUS=$MASTER_STATUS"
detail "FAZ4_14_1_STATUS=$S_141"
detail "FAZ4_14_2_STATUS=$S_142"
detail "FAZ4_14_3_STATUS=$S_143"
detail "FAZ4_14_4_STATUS=$S_144"

if [ "$MASTER_STATUS" != "PASS" ]; then blocker "14.5.1 master evidence PASS degil"; fi
if [ "$S_141" != "PASS" ]; then blocker "14.1 status PASS degil"; fi
if [ "$S_142" != "PASS" ]; then blocker "14.2 status PASS degil"; fi
if [ "$S_143" != "PASS" ]; then blocker "14.3 status PASS degil"; fi
if [ "$S_144" != "PASS" ]; then blocker "14.4 status PASS degil"; fi

TOTAL_SCORE=0
MAX_SCORE=100

MIGRATION_SCORE=0
if [ "$MIGRATION_FINAL" = "PASS" ]; then
  MIGRATION_SCORE=15
  add_score "migration_readiness" "$MIGRATION_SCORE" "15" "PASS" "migration final reconciliation=${MIGRATION_DECISION}"
else
  add_score "migration_readiness" "$MIGRATION_SCORE" "15" "FAIL" "migration reconciliation not pass"
  blocker "migration readiness skoru 0"
fi
TOTAL_SCORE=$((TOTAL_SCORE + MIGRATION_SCORE))

BACKUP_SCORE=0
BACKUP_NOTE=""
if [ "$BACKUP_READY" = "PASS" ]; then BACKUP_SCORE=$((BACKUP_SCORE + 5)); fi
if [ "$LOGICAL_BACKUP" = "PASS" ]; then BACKUP_SCORE=$((BACKUP_SCORE + 7)); fi
if [ "$RESTORE_DRILL" = "PASS" ]; then BACKUP_SCORE=$((BACKUP_SCORE + 8)); fi
BACKUP_NOTE="readiness=${BACKUP_READY}, logical_backup=${LOGICAL_BACKUP}, restore_drill=${RESTORE_DRILL}"

if [ "$BACKUP_SCORE" -eq 20 ]; then
  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "PASS" "$BACKUP_NOTE"
else
  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "REVIEW" "$BACKUP_NOTE"
  blocker "backup/restore readiness tam puan degil"
fi
TOTAL_SCORE=$((TOTAL_SCORE + BACKUP_SCORE))

PITR_SCORE=0
PITR_STATUS="REVIEW"
PITR_NOTE="design=${PITR_DESIGN}, gate=${PITR_GATE}, current_ready=${PITR_CURRENT_READY}, decision=${PITR_DECISION}"

if [ "$PITR_DESIGN" = "PASS" ]; then PITR_SCORE=$((PITR_SCORE + 3)); fi
if [ "$PITR_GATE" = "PASS" ]; then PITR_SCORE=$((PITR_SCORE + 3)); fi

if [ "$PITR_CURRENT_READY" = "YES" ]; then
  PITR_SCORE=10
  PITR_STATUS="PASS"
else
  PITR_STATUS="DEFERRED"
  defer "PITR aktif degil; tasarim ve enable gate hazir, bakim penceresinde etkinlestirilecek"
  risk "RISK_PITR_NOT_ACTIVE=PITR current ready NO"
fi

add_score "pitr_readiness" "$PITR_SCORE" "10" "$PITR_STATUS" "$PITR_NOTE"
TOTAL_SCORE=$((TOTAL_SCORE + PITR_SCORE))

OBS_SCORE=0
OBS_NOTE="final=${OBS_FINAL}, stack=${OBS_STACK}, risk=${OBS_RISK}"
if [ "$OBS_FINAL" = "PASS" ] && [ "$OBS_STACK" = "ACTIVE" ] && [ "$OBS_RISK" = "LOW" ]; then
  OBS_SCORE=20
  add_score "observability_readiness" "$OBS_SCORE" "20" "PASS" "$OBS_NOTE"
else
  add_score "observability_readiness" "$OBS_SCORE" "20" "FAIL" "$OBS_NOTE"
  blocker "observability readiness PASS/ACTIVE/LOW degil"
fi
TOTAL_SCORE=$((TOTAL_SCORE + OBS_SCORE))

PERF_SCORE=0
PERF_NOTE="final=${PERF_FINAL}, stack=${PERF_STACK}, risk=${PERF_RISK}, closure=${PERF_CLOSURE}"
if [ "$PERF_FINAL" = "PASS" ] && [ "$PERF_STACK" = "BASELINED" ] && [ "$PERF_RISK" = "LOW" ] && [ "$PERF_CLOSURE" = "PASS" ]; then
  PERF_SCORE=25
  add_score "performance_health_baseline" "$PERF_SCORE" "25" "PASS" "$PERF_NOTE"
else
  add_score "performance_health_baseline" "$PERF_SCORE" "25" "FAIL" "$PERF_NOTE"
  blocker "performance/health baseline PASS/BASELINED/LOW degil"
fi
TOTAL_SCORE=$((TOTAL_SCORE + PERF_SCORE))

DB_DSN="${DB_DSN:-${DB_WRITE_DSN:-${DATABASE_URL:-}}}"

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_WRITE_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  DB_DSN="$(extract_env "$ENV_FILE" "DB_DSN" || true)"
fi

if [ -z "$DB_DSN" ]; then
  blocker "DB DSN bulunamadi"
else
  detail "DB_DSN_STATUS=CONFIGURED"
  detail "DB_DSN_MASKED=$(mask_secret "$DB_DSN")"
fi

FINAL_DB_CONNECTION_CHECK="FAIL"
FINAL_DB_ROLE="UNKNOWN"
FINAL_TOTAL_CONNECTIONS="error"
FINAL_IDLE_TX_COUNT="error"
FINAL_LONG_QUERY_60S="error"
FINAL_WAITING_LOCK_COUNT="error"
FINAL_DEADLOCK_COUNT="error"
FINAL_PREPARED_TX_COUNT="error"
FINAL_PG_STAT_EXTENSION="error"
FINAL_TRACK_IO="error"
FINAL_DATABASE_SIZE_BYTES="error"

if [ "$BLOCKER_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_5_2_psql_ok.log 2>/tmp/pix2pi_14_5_2_psql_err.log; then
    FINAL_DB_CONNECTION_CHECK="PASS"
  else
    blocker "final DB connection failed"
  fi
fi

if [ "$BLOCKER_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"
  case "$IN_RECOVERY" in
    f) FINAL_DB_ROLE="PRIMARY_WRITE" ;;
    t) FINAL_DB_ROLE="REPLICA_READ_ONLY"; blocker "final DB replica/read-only gorunuyor" ;;
    *) FINAL_DB_ROLE="UNKNOWN"; blocker "final pg_is_in_recovery okunamadi" ;;
  esac

  FINAL_TOTAL_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database();")"
  FINAL_IDLE_TX_COUNT="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
  FINAL_LONG_QUERY_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
  FINAL_WAITING_LOCK_COUNT="$(run_sql "select count(*)::text from pg_locks where not granted;")"
  FINAL_DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
  FINAL_PREPARED_TX_COUNT="$(run_sql "select count(*)::text from pg_prepared_xacts;")"
  FINAL_PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
  FINAL_TRACK_IO="$(run_sql "show track_io_timing;")"
  FINAL_DATABASE_SIZE_BYTES="$(run_sql "select pg_database_size(current_database())::bigint::text;")"
fi

detail "FINAL_DB_CONNECTION_CHECK=$FINAL_DB_CONNECTION_CHECK"
detail "FINAL_DB_ROLE=$FINAL_DB_ROLE"
detail "FINAL_DB_TOTAL_CONNECTIONS=$FINAL_TOTAL_CONNECTIONS"
detail "FINAL_DB_IDLE_IN_TRANSACTION_CONNECTIONS=$FINAL_IDLE_TX_COUNT"
detail "FINAL_DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$FINAL_LONG_QUERY_60S"
detail "FINAL_DB_WAITING_LOCK_COUNT=$FINAL_WAITING_LOCK_COUNT"
detail "FINAL_DB_DEADLOCK_COUNT=$FINAL_DEADLOCK_COUNT"
detail "FINAL_DB_PREPARED_TRANSACTION_COUNT=$FINAL_PREPARED_TX_COUNT"
detail "FINAL_PG_STAT_STATEMENTS_EXTENSION=$FINAL_PG_STAT_EXTENSION"
detail "FINAL_TRACK_IO_TIMING=$FINAL_TRACK_IO"
detail "FINAL_DATABASE_SIZE_BYTES=$FINAL_DATABASE_SIZE_BYTES"

LIVE_HEALTH_SCORE=0
LIVE_HEALTH_NOTE="connection=${FINAL_DB_CONNECTION_CHECK}, role=${FINAL_DB_ROLE}, lock=${FINAL_WAITING_LOCK_COUNT}, idle_tx=${FINAL_IDLE_TX_COUNT}, long_query_60s=${FINAL_LONG_QUERY_60S}, prepared_tx=${FINAL_PREPARED_TX_COUNT}"

if [ "$FINAL_DB_CONNECTION_CHECK" = "PASS" ] && \
   [ "$FINAL_DB_ROLE" = "PRIMARY_WRITE" ] && \
   [ "$FINAL_WAITING_LOCK_COUNT" = "0" ] && \
   [ "$FINAL_IDLE_TX_COUNT" = "0" ] && \
   [ "$FINAL_LONG_QUERY_60S" = "0" ] && \
   [ "$FINAL_PREPARED_TX_COUNT" = "0" ] && \
   [ "$FINAL_PG_STAT_EXTENSION" = "t" ] && \
   [ "$FINAL_TRACK_IO" = "on" ]; then
  LIVE_HEALTH_SCORE=10
  add_score "final_live_db_health" "$LIVE_HEALTH_SCORE" "10" "PASS" "$LIVE_HEALTH_NOTE"
else
  add_score "final_live_db_health" "$LIVE_HEALTH_SCORE" "10" "FAIL" "$LIVE_HEALTH_NOTE"
  blocker "final live DB health tam PASS degil"
fi
TOTAL_SCORE=$((TOTAL_SCORE + LIVE_HEALTH_SCORE))

GRADE="D"
READINESS_STATUS="NOT_READY"

if [ "$TOTAL_SCORE" -ge 95 ]; then
  GRADE="A"
elif [ "$TOTAL_SCORE" -ge 90 ]; then
  GRADE="A-"
elif [ "$TOTAL_SCORE" -ge 80 ]; then
  GRADE="B"
elif [ "$TOTAL_SCORE" -ge 70 ]; then
  GRADE="C"
else
  GRADE="D"
fi

if [ "$BLOCKER_COUNT" -gt 0 ]; then
  READINESS_STATUS="BLOCKED"
elif [ "$DEFERRED_ACTION_COUNT" -gt 0 ]; then
  READINESS_STATUS="READY_WITH_DEFERRED_ACTIONS"
else
  READINESS_STATUS="READY"
fi

detail "DB_PRODUCTION_READINESS_SCORE=$TOTAL_SCORE"
detail "DB_PRODUCTION_READINESS_MAX_SCORE=$MAX_SCORE"
detail "DB_PRODUCTION_READINESS_GRADE=$GRADE"
detail "DB_PRODUCTION_READINESS_STATUS=$READINESS_STATUS"
detail "BLOCKER_COUNT=$BLOCKER_COUNT"
detail "DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"

if [ "$READINESS_STATUS" = "BLOCKED" ]; then
  fail "production readiness blocked"
fi

if [ "$READINESS_STATUS" = "READY_WITH_DEFERRED_ACTIONS" ]; then
  warn "production readiness deferred action ile hazir"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_PRODUCTION_READINESS_SCORECARD=PASS"
else
  detail "DB_PRODUCTION_READINESS_SCORECARD=FAIL"
fi

{
  echo "# FAZ 4 / 14.5.2 - DB Production Readiness Scorecard Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_PRODUCTION_READINESS_SCORECARD=PASS"
  else
    echo "DB_PRODUCTION_READINESS_SCORECARD=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Scorecard File"
  echo "SCORECARD_FILE=docs/phase4/14_5_2_db_production_readiness_scorecard.tsv"

  echo
  echo "## Deferred Actions"
  if [ -s "$DEFERRED_FILE" ]; then
    cat "$DEFERRED_FILE"
  else
    echo "OK ✅ deferred action yok"
  fi

  echo
  echo "## Blockers"
  if [ -s "$BLOCKER_FILE" ]; then
    cat "$BLOCKER_FILE"
  else
    echo "OK ✅ blocker yok"
  fi

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ scorecard major risk yok"
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

echo "REPORT_FILE=$REPORT_FILE"
echo "SCORECARD_FILE=$SCORECARD_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "DB_PRODUCTION_READINESS_SCORE=$TOTAL_SCORE"
echo "DB_PRODUCTION_READINESS_GRADE=$GRADE"
echo "DB_PRODUCTION_READINESS_STATUS=$READINESS_STATUS"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_PRODUCTION_READINESS_SCORECARD=FAIL ❌"
  exit 1
fi

echo "DB_PRODUCTION_READINESS_SCORECARD=PASS ✅"
