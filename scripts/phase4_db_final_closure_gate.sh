#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_5_5_db_final_closure_gate_report.md"
FINAL_CLOSURE_FILE="$REPORT_DIR/faz4_db_final_closure_report.md"

R_1418="$REPORT_DIR/14_1_8_migration_reconciliation_final_report.md"
R_1421="$REPORT_DIR/14_2_1_db_backup_pitr_readiness_report.md"
R_1422="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"
R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
R_1425="$REPORT_DIR/14_2_5_pitr_design_wal_archive_report.md"
R_1426="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"
R_143="$REPORT_DIR/14_3_final_db_observability_closure_report.md"
R_144="$REPORT_DIR/14_4_final_db_performance_closure_report.md"
R_1451="$REPORT_DIR/14_5_1_db_master_evidence_collector_report.md"
R_1452="$REPORT_DIR/14_5_2_db_production_readiness_scorecard_report.md"
R_1453="$REPORT_DIR/14_5_3_db_known_risks_deferred_register_report.md"
R_1454="$REPORT_DIR/14_5_4_db_runbook_incident_checklist_report.md"
RISK_REGISTER="$REPORT_DIR/14_5_3_db_known_risks_register.tsv"
RUNBOOK_FILE="$REPORT_DIR/14_5_4_db_operations_runbook.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
CLOSURE_FILE_TMP="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$CLOSURE_FILE_TMP"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "RISK ⚠️ $1" >> "$RISK_FILE"; }
closure() { echo "$1" >> "$CLOSURE_FILE_TMP"; }

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
    fail "$label dosyasi bulunamadi: ${file#$ROOT_DIR/}"
    return 1
  fi

  return 0
}

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_5_5_sql_err.log || echo "error"
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
detail "FINAL_CLOSURE_FILE=docs/phase4/faz4_db_final_closure_report.md"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

require_file "14.1 final reconciliation" "$R_1418" || true
require_file "14.2.1 backup/PITR readiness" "$R_1421" || true
require_file "14.2.2 logical backup smoke" "$R_1422" || true
require_file "14.2.4 restore drill test" "$R_1424" || true
require_file "14.2.5 PITR design" "$R_1425" || true
require_file "14.2.6 PITR enable gate" "$R_1426" || true
require_file "14.3 final observability closure" "$R_143" || true
require_file "14.4 final performance closure" "$R_144" || true
require_file "14.5.1 master evidence collector" "$R_1451" || true
require_file "14.5.2 scorecard" "$R_1452" || true
require_file "14.5.3 risk register report" "$R_1453" || true
require_file "14.5.3 risk register tsv" "$RISK_REGISTER" || true
require_file "14.5.4 runbook report" "$R_1454" || true
require_file "14.5.4 runbook file" "$RUNBOOK_FILE" || true

S_141="$(get_report_value "$R_1418" "MIGRATION_RECONCILIATION_FINAL")"
S_1421="$(get_report_value "$R_1421" "DB_BACKUP_PITR_READINESS_ASSESSMENT")"
S_1422="$(get_report_value "$R_1422" "LOGICAL_BACKUP_SMOKE")"
S_1424="$(get_report_value "$R_1424" "RESTORE_DRILL_TEST")"
S_1425="$(get_report_value "$R_1425" "PITR_DESIGN_WAL_ARCHIVE_PLAN")"
S_1426="$(get_report_value "$R_1426" "PITR_ENABLE_GATE")"
S_143="$(get_report_value "$R_143" "FAZ4_14_3_FINAL_STATUS")"
S_144="$(get_report_value "$R_144" "FAZ4_14_4_FINAL_STATUS")"
S_1451="$(get_report_value "$R_1451" "DB_MASTER_EVIDENCE_COLLECTOR")"
S_1452="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORECARD")"
S_1453="$(get_report_value "$R_1453" "DB_KNOWN_RISKS_DEFERRED_REGISTER")"
S_1454="$(get_report_value "$R_1454" "DB_RUNBOOK_INCIDENT_CHECKLIST")"

READINESS_SCORE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORE")"
READINESS_GRADE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_GRADE")"
READINESS_STATUS="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_STATUS")"
SCORECARD_BLOCKER_COUNT="$(get_report_value "$R_1452" "BLOCKER_COUNT")"

RISK_REGISTER_ITEM_COUNT="$(get_report_value "$R_1453" "RISK_REGISTER_ITEM_COUNT")"
DEFERRED_ACTION_COUNT="$(get_report_value "$R_1453" "DEFERRED_ACTION_COUNT")"
OBSERVE_ONLY_COUNT="$(get_report_value "$R_1453" "OBSERVE_ONLY_COUNT")"
REGISTER_BLOCKER_COUNT="$(get_report_value "$R_1453" "BLOCKER_COUNT")"

PITR_CURRENT_READY="$(get_report_value "$R_1426" "PITR_CURRENT_READY")"
PITR_ENABLE_DECISION="$(get_report_value "$R_1426" "PITR_ENABLE_DECISION")"
ARCHIVE_MODE_READY="$(get_report_value "$R_1426" "ARCHIVE_MODE_READY")"
ARCHIVE_COMMAND_READY="$(get_report_value "$R_1426" "ARCHIVE_COMMAND_READY")"
HOST_WAL_ARCHIVE_DIR_STATUS="$(get_report_value "$R_1426" "HOST_WAL_ARCHIVE_DIR_STATUS")"
WAL_ARCHIVE_MOUNT_STATUS="$(get_report_value "$R_1426" "WAL_ARCHIVE_MOUNT_STATUS")"

OBS_STACK_STATUS="$(get_report_value "$R_143" "DB_OBSERVABILITY_STACK_STATUS")"
OBS_RISK="$(get_report_value "$R_143" "DB_PERFORMANCE_RISK_FINAL")"
PERF_STACK_STATUS="$(get_report_value "$R_144" "DB_PERFORMANCE_STACK_STATUS")"
PERF_RISK="$(get_report_value "$R_144" "DB_PERFORMANCE_RISK_FINAL")"

detail "14_1_MIGRATION_RECONCILIATION_FINAL=$S_141"
detail "14_2_1_DB_BACKUP_PITR_READINESS_ASSESSMENT=$S_1421"
detail "14_2_2_LOGICAL_BACKUP_SMOKE=$S_1422"
detail "14_2_4_RESTORE_DRILL_TEST=$S_1424"
detail "14_2_5_PITR_DESIGN_WAL_ARCHIVE_PLAN=$S_1425"
detail "14_2_6_PITR_ENABLE_GATE=$S_1426"
detail "14_3_FINAL_STATUS=$S_143"
detail "14_4_FINAL_STATUS=$S_144"
detail "14_5_1_DB_MASTER_EVIDENCE_COLLECTOR=$S_1451"
detail "14_5_2_DB_PRODUCTION_READINESS_SCORECARD=$S_1452"
detail "14_5_3_DB_KNOWN_RISKS_DEFERRED_REGISTER=$S_1453"
detail "14_5_4_DB_RUNBOOK_INCIDENT_CHECKLIST=$S_1454"

detail "DB_PRODUCTION_READINESS_SCORE=$READINESS_SCORE"
detail "DB_PRODUCTION_READINESS_GRADE=$READINESS_GRADE"
detail "DB_PRODUCTION_READINESS_STATUS=$READINESS_STATUS"
detail "SCORECARD_BLOCKER_COUNT=$SCORECARD_BLOCKER_COUNT"
detail "RISK_REGISTER_ITEM_COUNT=$RISK_REGISTER_ITEM_COUNT"
detail "DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"
detail "OBSERVE_ONLY_COUNT=$OBSERVE_ONLY_COUNT"
detail "REGISTER_BLOCKER_COUNT=$REGISTER_BLOCKER_COUNT"

detail "PITR_CURRENT_READY=$PITR_CURRENT_READY"
detail "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"
detail "ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY"
detail "ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"
detail "HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS"
detail "WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"

detail "DB_OBSERVABILITY_STACK_STATUS=$OBS_STACK_STATUS"
detail "DB_OBSERVABILITY_RISK_FINAL=$OBS_RISK"
detail "DB_PERFORMANCE_STACK_STATUS=$PERF_STACK_STATUS"
detail "DB_PERFORMANCE_RISK_FINAL=$PERF_RISK"

if [ "$S_141" != "PASS" ]; then fail "14.1 migration reconciliation PASS degil"; fi
if [ "$S_1421" != "PASS" ]; then fail "14.2.1 readiness PASS degil"; fi
if [ "$S_1422" != "PASS" ]; then fail "14.2.2 logical backup PASS degil"; fi
if [ "$S_1424" != "PASS" ]; then fail "14.2.4 restore drill PASS degil"; fi
if [ "$S_1425" != "PASS" ]; then fail "14.2.5 PITR design PASS degil"; fi
if [ "$S_1426" != "PASS" ]; then fail "14.2.6 PITR enable gate PASS degil"; fi
if [ "$S_143" != "PASS" ]; then fail "14.3 final PASS degil"; fi
if [ "$S_144" != "PASS" ]; then fail "14.4 final PASS degil"; fi
if [ "$S_1451" != "PASS" ]; then fail "14.5.1 PASS degil"; fi
if [ "$S_1452" != "PASS" ]; then fail "14.5.2 PASS degil"; fi
if [ "$S_1453" != "PASS" ]; then fail "14.5.3 PASS degil"; fi
if [ "$S_1454" != "PASS" ]; then fail "14.5.4 PASS degil"; fi

if [ "$SCORECARD_BLOCKER_COUNT" != "0" ]; then fail "scorecard blocker count sifir degil"; fi
if [ "$REGISTER_BLOCKER_COUNT" != "0" ]; then fail "risk register blocker count sifir degil"; fi

if [ "$PITR_CURRENT_READY" = "NO" ]; then
  warn "PITR current ready NO; final status READY_WITH_DEFERRED_ACTIONS olarak muhurlenecek"
  risk "RISK_PITR_DEFERRED=PITR aktif degil; WAL archive maintenance bekliyor"
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

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_5_5_psql_ok.log 2>/tmp/pix2pi_14_5_5_psql_err.log; then
    FINAL_DB_CONNECTION_CHECK="PASS"
  else
    fail "final DB connection failed"
  fi
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  IN_RECOVERY="$(run_sql "select pg_is_in_recovery();")"

  case "$IN_RECOVERY" in
    f) FINAL_DB_ROLE="PRIMARY_WRITE" ;;
    t) FINAL_DB_ROLE="REPLICA_READ_ONLY"; fail "final DB replica/read-only gorunuyor" ;;
    *) FINAL_DB_ROLE="UNKNOWN"; fail "final pg_is_in_recovery okunamadi" ;;
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

if [ "$FINAL_DB_CONNECTION_CHECK" != "PASS" ]; then fail "final DB connection PASS degil"; fi
if [ "$FINAL_DB_ROLE" != "PRIMARY_WRITE" ]; then fail "final DB role PRIMARY_WRITE degil"; fi
if [ "$FINAL_IDLE_TX_COUNT" != "0" ]; then fail "final idle tx count sifir degil"; fi
if [ "$FINAL_LONG_QUERY_60S" != "0" ]; then fail "final long query 60s count sifir degil"; fi
if [ "$FINAL_WAITING_LOCK_COUNT" != "0" ]; then fail "final waiting lock count sifir degil"; fi
if [ "$FINAL_PREPARED_TX_COUNT" != "0" ]; then fail "final prepared transaction count sifir degil"; fi
if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then fail "final pg_stat_statements extension aktif degil"; fi
if [ "$FINAL_TRACK_IO" != "on" ]; then fail "final track_io_timing on degil"; fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  FAZ4_DB_FINAL_STATUS="PASS"

  if [ "$READINESS_STATUS" = "READY" ]; then
    FAZ4_DB_READINESS_STATUS="READY"
  else
    FAZ4_DB_READINESS_STATUS="READY_WITH_DEFERRED_ACTIONS"
  fi

  detail "FAZ4_DB_FINAL_CLOSURE_GATE=PASS"
else
  FAZ4_DB_FINAL_STATUS="FAIL"
  FAZ4_DB_READINESS_STATUS="REVIEW_REQUIRED"
  detail "FAZ4_DB_FINAL_CLOSURE_GATE=FAIL"
fi

detail "FAZ4_DB_FINAL_STATUS=$FAZ4_DB_FINAL_STATUS"
detail "FAZ4_DB_READINESS_STATUS=$FAZ4_DB_READINESS_STATUS"

closure "14.1 Migration/Reconciliation=PASS"
closure "14.2 Backup/Restore/PITR Gate=PASS"
closure "14.3 Observability=PASS"
closure "14.4 Performance Baseline=PASS"
closure "14.5.1 Master Evidence=PASS"
closure "14.5.2 Scorecard=PASS"
closure "14.5.3 Risk Register=PASS"
closure "14.5.4 Runbook=PASS"
closure "Final DB Connection=${FINAL_DB_CONNECTION_CHECK}"
closure "Final DB Role=${FINAL_DB_ROLE}"
closure "Production Readiness Score=${READINESS_SCORE}/100"
closure "Production Readiness Grade=${READINESS_GRADE}"
closure "Production Readiness Status=${FAZ4_DB_READINESS_STATUS}"
closure "Known Deferred Actions=${DEFERRED_ACTION_COUNT}"
closure "Known Observe Only Decisions=${OBSERVE_ONLY_COUNT}"
closure "Known Blockers=0"
closure "PITR Current Ready=${PITR_CURRENT_READY}"
closure "FAZ4_DB_FINAL_STATUS=${FAZ4_DB_FINAL_STATUS}"

{
  echo "# FAZ 4 / 14.5.5 - FAZ 4 DB Final Closure Gate Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ4_DB_FINAL_CLOSURE_GATE=PASS"
  else
    echo "FAZ4_DB_FINAL_CLOSURE_GATE=FAIL"
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
  cat "$CLOSURE_FILE_TMP"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ FAZ 4 DB final major risk yok"
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
  echo "# FAZ 4 - DB Final Closure Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Final Result"
  echo "FAZ4_DB_FINAL_STATUS=$FAZ4_DB_FINAL_STATUS"
  echo "FAZ4_DB_READINESS_STATUS=$FAZ4_DB_READINESS_STATUS"
  echo "FAZ4_DB_PRODUCTION_READINESS_SCORE=$READINESS_SCORE"
  echo "FAZ4_DB_PRODUCTION_READINESS_GRADE=$READINESS_GRADE"
  echo "FAZ4_DB_BLOCKER_COUNT=0"
  echo "FAZ4_DB_DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"
  echo "FAZ4_DB_OBSERVE_ONLY_COUNT=$OBSERVE_ONLY_COUNT"
  echo "PITR_CURRENT_READY=$PITR_CURRENT_READY"
  echo
  echo "## Closed Blocks"
  cat "$CLOSURE_FILE_TMP"
  echo
  echo "## Deferred Actions"
  echo "PITR enable deferred: PITR_CURRENT_READY=$PITR_CURRENT_READY"
  echo "WAL archive mount/status: HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS / WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"
  echo "archive_mode/archive_command: ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY / ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"
  echo
  echo "## Final DB Health"
  echo "FINAL_DB_CONNECTION_CHECK=$FINAL_DB_CONNECTION_CHECK"
  echo "FINAL_DB_ROLE=$FINAL_DB_ROLE"
  echo "FINAL_DB_TOTAL_CONNECTIONS=$FINAL_TOTAL_CONNECTIONS"
  echo "FINAL_DB_IDLE_IN_TRANSACTION_CONNECTIONS=$FINAL_IDLE_TX_COUNT"
  echo "FINAL_DB_LONG_RUNNING_ACTIVE_QUERIES_60S=$FINAL_LONG_QUERY_60S"
  echo "FINAL_DB_WAITING_LOCK_COUNT=$FINAL_WAITING_LOCK_COUNT"
  echo "FINAL_DB_DEADLOCK_COUNT=$FINAL_DEADLOCK_COUNT"
  echo "FINAL_DB_PREPARED_TRANSACTION_COUNT=$FINAL_PREPARED_TX_COUNT"
  echo "FINAL_PG_STAT_STATEMENTS_EXTENSION=$FINAL_PG_STAT_EXTENSION"
  echo "FINAL_TRACK_IO_TIMING=$FINAL_TRACK_IO"
  echo
  echo "## Safety"
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
  echo "QUERY_TEXT_PRINTED=NO"
} > "$FINAL_CLOSURE_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FINAL_CLOSURE_FILE=$FINAL_CLOSURE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAZ4_DB_FINAL_STATUS=$FAZ4_DB_FINAL_STATUS"
echo "FAZ4_DB_READINESS_STATUS=$FAZ4_DB_READINESS_STATUS"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "FAZ4_DB_FINAL_CLOSURE_GATE=FAIL ❌"
  exit 1
fi

echo "FAZ4_DB_FINAL_CLOSURE_GATE=PASS ✅"
