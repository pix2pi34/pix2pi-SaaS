#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ENV_FILE="$ROOT_DIR/.env"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_5_1_db_master_evidence_collector_report.md"
INVENTORY_FILE="$REPORT_DIR/14_5_1_db_master_evidence_inventory.tsv"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
MASTER_FILE="$(mktemp)"

trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$MASTER_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "$1" >> "$RISK_FILE"; }
master() { echo "$1" >> "$MASTER_FILE"; }

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

file_size_or_zero() {
  local file="$1"
  if [ -f "$file" ]; then
    wc -c < "$file" | tr -d ' '
  else
    echo "0"
  fi
}

run_sql() {
  local sql="$1"
  PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "$sql" 2>/tmp/pix2pi_14_5_1_sql_err.log || echo "error"
}

add_inventory() {
  local block="$1"
  local item="$2"
  local status="$3"
  local key="$4"
  local value="$5"
  local file="$6"
  local size="0"

  size="$(file_size_or_zero "$file")"

  echo -e "${block}\t${item}\t${status}\t${key}\t${value}\t${file#$ROOT_DIR/}\t${size}" >> "$INVENTORY_FILE"
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

require_value() {
  local block="$1"
  local label="$2"
  local file="$3"
  local key="$4"
  local expected="$5"
  local value=""

  value="$(get_report_value "$file" "$key")"

  if [ "$value" = "$expected" ]; then
    add_inventory "$block" "$label" "PASS" "$key" "$value" "$file"
    master "${block}_${label}=PASS"
    return 0
  fi

  add_inventory "$block" "$label" "FAIL" "$key" "$value" "$file"
  fail "$block / $label beklenen deger degil: $key expected=$expected actual=$value"
  return 1
}

collect_optional_value() {
  local block="$1"
  local label="$2"
  local file="$3"
  local key="$4"
  local value=""

  value="$(get_report_value "$file" "$key")"
  [ -n "$value" ] || value="MISSING"

  add_inventory "$block" "$label" "INFO" "$key" "$value" "$file"
  master "${block}_${label}=$value"
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
detail "MASTER_INVENTORY_FILE=docs/phase4/14_5_1_db_master_evidence_inventory.tsv"

PSQL_FOUND=0
if tool_status "psql"; then PSQL_FOUND=1; fi

if [ "$PSQL_FOUND" -ne 1 ]; then
  fail "psql bulunamadi"
fi

R_1418="$REPORT_DIR/14_1_8_migration_reconciliation_final_report.md"
R_1421="$REPORT_DIR/14_2_1_db_backup_pitr_readiness_report.md"
R_1422="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"
R_1423="$REPORT_DIR/14_2_3_restore_drill_sandbox_plan_report.md"
R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
R_1425="$REPORT_DIR/14_2_5_pitr_design_wal_archive_report.md"
R_1426="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"
R_143_FINAL="$REPORT_DIR/14_3_final_db_observability_closure_report.md"
R_144_FINAL="$REPORT_DIR/14_4_final_db_performance_closure_report.md"
R_1445="$REPORT_DIR/14_4_5_db_performance_final_closure_report.md"

{
  echo -e "block\titem\tstatus\tkey\tvalue\tfile\tsize_bytes"
} > "$INVENTORY_FILE"

require_file "14.1 migration final reconciliation" "$R_1418" || true
require_file "14.2.1 backup/PITR readiness" "$R_1421" || true
require_file "14.2.2 logical backup smoke" "$R_1422" || true
require_file "14.2.3 restore drill plan" "$R_1423" || true
require_file "14.2.4 restore drill test" "$R_1424" || true
require_file "14.2.5 PITR design" "$R_1425" || true
require_file "14.2.6 PITR enable gate" "$R_1426" || true
require_file "14.3 final observability closure" "$R_143_FINAL" || true
require_file "14.4 final DB performance closure" "$R_144_FINAL" || true
require_file "14.4.5 DB performance final closure gate" "$R_1445" || true

if [ "$FAIL_COUNT" -eq 0 ]; then
  require_value "14.1" "MIGRATION_RECONCILIATION_FINAL" "$R_1418" "MIGRATION_RECONCILIATION_FINAL" "PASS" || true
  collect_optional_value "14.1" "FINAL_DECISION" "$R_1418" "FINAL_DECISION"
  collect_optional_value "14.1" "APPLY_ACTION" "$R_1418" "APPLY_ACTION"
  collect_optional_value "14.1" "INDEX_APPLY_ACTION" "$R_1418" "INDEX_APPLY_ACTION"

  require_value "14.2" "READINESS" "$R_1421" "DB_BACKUP_PITR_READINESS_ASSESSMENT" "PASS" || true
  require_value "14.2" "LOGICAL_BACKUP_SMOKE" "$R_1422" "LOGICAL_BACKUP_SMOKE" "PASS" || true
  require_value "14.2" "RESTORE_DRILL_PLAN" "$R_1423" "RESTORE_DRILL_SANDBOX_PLAN" "PASS" || true
  require_value "14.2" "RESTORE_DRILL_TEST" "$R_1424" "RESTORE_DRILL_TEST" "PASS" || true
  require_value "14.2" "PITR_DESIGN" "$R_1425" "PITR_DESIGN_WAL_ARCHIVE_PLAN" "PASS" || true
  require_value "14.2" "PITR_ENABLE_GATE" "$R_1426" "PITR_ENABLE_GATE" "PASS" || true
  collect_optional_value "14.2" "PITR_CURRENT_READY" "$R_1426" "PITR_CURRENT_READY"
  collect_optional_value "14.2" "PITR_ENABLE_DECISION" "$R_1426" "PITR_ENABLE_DECISION"

  require_value "14.3" "FINAL_STATUS" "$R_143_FINAL" "FAZ4_14_3_FINAL_STATUS" "PASS" || true
  require_value "14.3" "OBSERVABILITY_STACK" "$R_143_FINAL" "DB_OBSERVABILITY_STACK_STATUS" "ACTIVE" || true
  require_value "14.3" "PERFORMANCE_RISK" "$R_143_FINAL" "DB_PERFORMANCE_RISK_FINAL" "LOW" || true

  require_value "14.4" "FINAL_STATUS" "$R_144_FINAL" "FAZ4_14_4_FINAL_STATUS" "PASS" || true
  require_value "14.4" "PERFORMANCE_STACK" "$R_144_FINAL" "DB_PERFORMANCE_STACK_STATUS" "BASELINED" || true
  require_value "14.4" "PERFORMANCE_RISK" "$R_144_FINAL" "DB_PERFORMANCE_RISK_FINAL" "LOW" || true
  require_value "14.4" "FINAL_CLOSURE" "$R_1445" "DB_PERFORMANCE_FINAL_CLOSURE" "PASS" || true
fi

FAZ4_14_1_STATUS="PASS"
FAZ4_14_2_STATUS="PASS"
FAZ4_14_3_STATUS="PASS"
FAZ4_14_4_STATUS="PASS"

if [ "$(get_report_value "$R_1418" "MIGRATION_RECONCILIATION_FINAL")" != "PASS" ]; then FAZ4_14_1_STATUS="FAIL"; fi

for pair in \
  "$R_1421|DB_BACKUP_PITR_READINESS_ASSESSMENT" \
  "$R_1422|LOGICAL_BACKUP_SMOKE" \
  "$R_1423|RESTORE_DRILL_SANDBOX_PLAN" \
  "$R_1424|RESTORE_DRILL_TEST" \
  "$R_1425|PITR_DESIGN_WAL_ARCHIVE_PLAN" \
  "$R_1426|PITR_ENABLE_GATE"
do
  file="${pair%%|*}"
  key="${pair##*|}"
  if [ "$(get_report_value "$file" "$key")" != "PASS" ]; then
    FAZ4_14_2_STATUS="FAIL"
  fi
done

if [ "$(get_report_value "$R_143_FINAL" "FAZ4_14_3_FINAL_STATUS")" != "PASS" ]; then FAZ4_14_3_STATUS="FAIL"; fi
if [ "$(get_report_value "$R_144_FINAL" "FAZ4_14_4_FINAL_STATUS")" != "PASS" ]; then FAZ4_14_4_STATUS="FAIL"; fi

detail "FAZ4_14_1_STATUS=$FAZ4_14_1_STATUS"
detail "FAZ4_14_2_STATUS=$FAZ4_14_2_STATUS"
detail "FAZ4_14_3_STATUS=$FAZ4_14_3_STATUS"
detail "FAZ4_14_4_STATUS=$FAZ4_14_4_STATUS"

if [ "$FAZ4_14_1_STATUS" != "PASS" ]; then fail "14.1 master status PASS degil"; fi
if [ "$FAZ4_14_2_STATUS" != "PASS" ]; then fail "14.2 master status PASS degil"; fi
if [ "$FAZ4_14_3_STATUS" != "PASS" ]; then fail "14.3 master status PASS degil"; fi
if [ "$FAZ4_14_4_STATUS" != "PASS" ]; then fail "14.4 master status PASS degil"; fi

INVENTORY_LINE_COUNT="$(wc -l < "$INVENTORY_FILE" | tr -d ' ')"
detail "MASTER_EVIDENCE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

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

FINAL_DB_ROLE="unknown"
FINAL_DB_CONNECTION_CHECK="FAIL"
FINAL_TOTAL_CONNECTIONS="error"
FINAL_WAITING_LOCK_COUNT="error"
FINAL_LONG_QUERY_60S="error"
FINAL_IDLE_TX_COUNT="error"
FINAL_DEADLOCK_COUNT="error"
FINAL_PG_STAT_EXTENSION="error"
FINAL_TRACK_IO="error"
FINAL_DATABASE_SIZE_BYTES="error"

if [ "$FAIL_COUNT" -eq 0 ]; then
  if PGCONNECT_TIMEOUT=5 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;" >/tmp/pix2pi_14_5_1_psql_ok.log 2>/tmp/pix2pi_14_5_1_psql_err.log; then
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
detail "FINAL_PG_STAT_STATEMENTS_EXTENSION=$FINAL_PG_STAT_EXTENSION"
detail "FINAL_TRACK_IO_TIMING=$FINAL_TRACK_IO"
detail "FINAL_DATABASE_SIZE_BYTES=$FINAL_DATABASE_SIZE_BYTES"

if [ "$FINAL_DB_CONNECTION_CHECK" != "PASS" ]; then fail "final DB connection PASS degil"; fi
if [ "$FINAL_DB_ROLE" != "PRIMARY_WRITE" ]; then fail "final DB role PRIMARY_WRITE degil"; fi
if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then fail "final pg_stat_statements extension aktif degil"; fi
if [ "$FINAL_TRACK_IO" != "on" ]; then fail "final track_io_timing on degil"; fi

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

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_MASTER_EVIDENCE_COLLECTOR=PASS"
else
  detail "DB_MASTER_EVIDENCE_COLLECTOR=FAIL"
fi

{
  echo "# FAZ 4 / 14.5.1 - DB Master Evidence Collector Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_MASTER_EVIDENCE_COLLECTOR=PASS"
  else
    echo "DB_MASTER_EVIDENCE_COLLECTOR=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Master Evidence"
  if [ -s "$MASTER_FILE" ]; then
    cat "$MASTER_FILE"
  else
    echo "master evidence yok"
  fi

  echo
  echo "## Evidence Inventory"
  echo "MASTER_INVENTORY_FILE=docs/phase4/14_5_1_db_master_evidence_inventory.tsv"
  echo "MASTER_EVIDENCE_INVENTORY_LINE_COUNT=$INVENTORY_LINE_COUNT"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ DB master evidence major risk yok"
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
echo "INVENTORY_FILE=$INVENTORY_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_MASTER_EVIDENCE_COLLECTOR=FAIL ❌"
  exit 1
fi

echo "DB_MASTER_EVIDENCE_COLLECTOR=PASS ✅"
