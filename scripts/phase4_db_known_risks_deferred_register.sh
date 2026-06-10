#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_5_3_db_known_risks_deferred_register_report.md"
REGISTER_FILE="$REPORT_DIR/14_5_3_db_known_risks_register.tsv"

R_1452="$REPORT_DIR/14_5_2_db_production_readiness_scorecard_report.md"
R_1452_SCORECARD="$REPORT_DIR/14_5_2_db_production_readiness_scorecard.tsv"
R_1426="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"
R_1425="$REPORT_DIR/14_2_5_pitr_design_wal_archive_report.md"
R_1442="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"
R_1443="$REPORT_DIR/14_4_3_vacuum_bloat_readiness_report.md"
R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0
BLOCKER_COUNT=0
DEFERRED_ACTION_COUNT=0
OBSERVE_ONLY_COUNT=0
RISK_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
DEFERRED_FILE="$(mktemp)"
OBSERVE_FILE="$(mktemp)"
BLOCKER_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$DEFERRED_FILE" "$OBSERVE_FILE" "$BLOCKER_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "RISK ⚠️ $1" >> "$RISK_FILE"; RISK_COUNT=$((RISK_COUNT + 1)); }
defer() { echo "DEFERRED ⏭ $1" >> "$DEFERRED_FILE"; DEFERRED_ACTION_COUNT=$((DEFERRED_ACTION_COUNT + 1)); }
observe() { echo "OBSERVE 👀 $1" >> "$OBSERVE_FILE"; OBSERVE_ONLY_COUNT=$((OBSERVE_ONLY_COUNT + 1)); }
blocker() { echo "BLOCKER ❌ $1" >> "$BLOCKER_FILE"; BLOCKER_COUNT=$((BLOCKER_COUNT + 1)); FAIL_COUNT=$((FAIL_COUNT + 1)); }

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

add_register() {
  local risk_id="$1"
  local category="$2"
  local severity="$3"
  local status="$4"
  local source="$5"
  local evidence="$6"
  local action="$7"
  local closure_gate="$8"

  echo -e "${risk_id}\t${category}\t${severity}\t${status}\t${source}\t${evidence}\t${action}\t${closure_gate}" >> "$REGISTER_FILE"
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
detail "RISK_REGISTER_FILE=docs/phase4/14_5_3_db_known_risks_register.tsv"

tool_status "grep" >/dev/null || true
tool_status "awk" >/dev/null || true
tool_status "sed" >/dev/null || true

require_file "14.5.2 production readiness scorecard report" "$R_1452" || true
require_file "14.5.2 production readiness scorecard tsv" "$R_1452_SCORECARD" || true
require_file "14.2.6 PITR enable gate" "$R_1426" || true
require_file "14.2.5 PITR design" "$R_1425" || true
require_file "14.4.2 index usage baseline" "$R_1442" || true
require_file "14.4.3 vacuum bloat readiness" "$R_1443" || true
require_file "14.4.4 DB health baseline" "$R_1444" || true

{
  echo -e "risk_id\tcategory\tseverity\tstatus\tsource\tevidence\taction\tclosure_gate"
} > "$REGISTER_FILE"

SCORECARD_STATUS="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORECARD")"
READINESS_SCORE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORE")"
READINESS_GRADE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_GRADE")"
READINESS_STATUS="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_STATUS")"
SCORECARD_BLOCKER_COUNT="$(get_report_value "$R_1452" "BLOCKER_COUNT")"
SCORECARD_DEFERRED_COUNT="$(get_report_value "$R_1452" "DEFERRED_ACTION_COUNT")"

PITR_CURRENT_READY="$(get_report_value "$R_1426" "PITR_CURRENT_READY")"
PITR_ENABLE_DECISION="$(get_report_value "$R_1426" "PITR_ENABLE_DECISION")"
PITR_GATE="$(get_report_value "$R_1426" "PITR_ENABLE_GATE")"
PITR_DESIGN="$(get_report_value "$R_1425" "PITR_DESIGN_WAL_ARCHIVE_PLAN")"
HOST_WAL_ARCHIVE_DIR_STATUS="$(get_report_value "$R_1426" "HOST_WAL_ARCHIVE_DIR_STATUS")"
WAL_ARCHIVE_MOUNT_STATUS="$(get_report_value "$R_1426" "WAL_ARCHIVE_MOUNT_STATUS")"
ARCHIVE_MODE_READY="$(get_report_value "$R_1426" "ARCHIVE_MODE_READY")"
ARCHIVE_COMMAND_READY="$(get_report_value "$R_1426" "ARCHIVE_COMMAND_READY")"

INDEX_LOW_DATA_CONTEXT="$(get_report_value "$R_1442" "LOW_DATA_CONTEXT")"
INDEX_UNUSED_COUNT="$(get_report_value "$R_1442" "DB_UNUSED_INDEX_COUNT")"
INDEX_UNUSED_NON_UNIQUE_COUNT="$(get_report_value "$R_1442" "DB_UNUSED_NON_UNIQUE_INDEX_COUNT")"
INDEX_RISK_LEVEL="$(get_report_value "$R_1442" "INDEX_USAGE_RISK_LEVEL")"

VACUUM_LOW_DATA_CONTEXT="$(get_report_value "$R_1443" "LOW_DATA_CONTEXT")"
VACUUM_TOTAL_LIVE_TUPLES="$(get_report_value "$R_1443" "DB_TOTAL_LIVE_TUPLES")"
VACUUM_TOTAL_DEAD_TUPLES="$(get_report_value "$R_1443" "DB_TOTAL_DEAD_TUPLES")"
VACUUM_HIGH_DEAD_RATIO_COUNT="$(get_report_value "$R_1443" "DB_HIGH_DEAD_RATIO_TABLE_COUNT")"
VACUUM_RISK_LEVEL="$(get_report_value "$R_1443" "VACUUM_RISK_LEVEL")"

DB_HEALTH_RISK_LEVEL="$(get_report_value "$R_1444" "DB_HEALTH_RISK_LEVEL")"
DB_WAITING_LOCK_COUNT="$(get_report_value "$R_1444" "DB_WAITING_LOCK_COUNT")"
DB_DEADLOCK_COUNT="$(get_report_value "$R_1444" "DB_DEADLOCK_COUNT")"
DB_IDLE_TX_COUNT="$(get_report_value "$R_1444" "DB_IDLE_IN_TRANSACTION_CONNECTIONS")"

detail "DB_PRODUCTION_READINESS_SCORECARD=$SCORECARD_STATUS"
detail "DB_PRODUCTION_READINESS_SCORE=$READINESS_SCORE"
detail "DB_PRODUCTION_READINESS_GRADE=$READINESS_GRADE"
detail "DB_PRODUCTION_READINESS_STATUS=$READINESS_STATUS"
detail "SCORECARD_BLOCKER_COUNT=$SCORECARD_BLOCKER_COUNT"
detail "SCORECARD_DEFERRED_ACTION_COUNT=$SCORECARD_DEFERRED_COUNT"

detail "PITR_CURRENT_READY=$PITR_CURRENT_READY"
detail "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"
detail "PITR_ENABLE_GATE=$PITR_GATE"
detail "PITR_DESIGN_WAL_ARCHIVE_PLAN=$PITR_DESIGN"
detail "HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS"
detail "WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"
detail "ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY"
detail "ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"

detail "INDEX_LOW_DATA_CONTEXT=$INDEX_LOW_DATA_CONTEXT"
detail "DB_UNUSED_INDEX_COUNT=$INDEX_UNUSED_COUNT"
detail "DB_UNUSED_NON_UNIQUE_INDEX_COUNT=$INDEX_UNUSED_NON_UNIQUE_COUNT"
detail "INDEX_USAGE_RISK_LEVEL=$INDEX_RISK_LEVEL"

detail "VACUUM_LOW_DATA_CONTEXT=$VACUUM_LOW_DATA_CONTEXT"
detail "DB_TOTAL_LIVE_TUPLES=$VACUUM_TOTAL_LIVE_TUPLES"
detail "DB_TOTAL_DEAD_TUPLES=$VACUUM_TOTAL_DEAD_TUPLES"
detail "DB_HIGH_DEAD_RATIO_TABLE_COUNT=$VACUUM_HIGH_DEAD_RATIO_COUNT"
detail "VACUUM_RISK_LEVEL=$VACUUM_RISK_LEVEL"

detail "DB_HEALTH_RISK_LEVEL=$DB_HEALTH_RISK_LEVEL"
detail "DB_WAITING_LOCK_COUNT=$DB_WAITING_LOCK_COUNT"
detail "DB_DEADLOCK_COUNT=$DB_DEADLOCK_COUNT"
detail "DB_IDLE_IN_TRANSACTION_CONNECTIONS=$DB_IDLE_TX_COUNT"

if [ "$SCORECARD_STATUS" != "PASS" ]; then
  blocker "14.5.2 scorecard PASS degil"
fi

if [ "$SCORECARD_BLOCKER_COUNT" != "0" ]; then
  blocker "14.5.2 blocker count sifir degil: $SCORECARD_BLOCKER_COUNT"
fi

if [ "$PITR_CURRENT_READY" = "NO" ]; then
  add_register \
    "DB-RISK-001" \
    "pitr" \
    "HIGH" \
    "DEFERRED" \
    "14.2.6/14.5.2" \
    "PITR_CURRENT_READY=NO; PITR_ENABLE_DECISION=${PITR_ENABLE_DECISION}" \
    "Bakim penceresinde WAL archive mount/config apply yap ve PITR verification al" \
    "PITR_CURRENT_READY=YES"

  defer "DB-RISK-001 PITR aktif degil; bakim penceresinde enable edilecek"
  risk "RISK_PITR_NOT_ACTIVE=PITR current ready NO"
fi

if [ "$HOST_WAL_ARCHIVE_DIR_STATUS" = "NOT_FOUND" ] || [ "$WAL_ARCHIVE_MOUNT_STATUS" = "NOT_FOUND" ]; then
  add_register \
    "DB-RISK-002" \
    "wal_archive" \
    "HIGH" \
    "DEFERRED" \
    "14.2.6" \
    "HOST_WAL_ARCHIVE_DIR_STATUS=${HOST_WAL_ARCHIVE_DIR_STATUS}; WAL_ARCHIVE_MOUNT_STATUS=${WAL_ARCHIVE_MOUNT_STATUS}" \
    "Host WAL archive dizini ve container mount kontrollu apply adiminda olusturulacak" \
    "WAL_ARCHIVE_MOUNT_STATUS=FOUND"

  defer "DB-RISK-002 WAL archive dizini/mount henuz aktif degil"
fi

if [ "$ARCHIVE_MODE_READY" = "NO" ] || [ "$ARCHIVE_COMMAND_READY" = "NO" ]; then
  add_register \
    "DB-RISK-003" \
    "pitr_config" \
    "HIGH" \
    "DEFERRED" \
    "14.2.6" \
    "ARCHIVE_MODE_READY=${ARCHIVE_MODE_READY}; ARCHIVE_COMMAND_READY=${ARCHIVE_COMMAND_READY}" \
    "archive_mode=on ve archive_command kontrollu maintenance adiminda aktif edilecek" \
    "ARCHIVE_MODE_READY=YES; ARCHIVE_COMMAND_READY=YES"

  defer "DB-RISK-003 archive_mode/archive_command aktif degil"
fi

if [ "$INDEX_LOW_DATA_CONTEXT" = "YES" ]; then
  add_register \
    "DB-RISK-004" \
    "index_usage" \
    "MEDIUM" \
    "OBSERVE_ONLY" \
    "14.4.2" \
    "LOW_DATA_CONTEXT=YES; DB_UNUSED_INDEX_COUNT=${INDEX_UNUSED_COUNT}; DB_UNUSED_NON_UNIQUE_INDEX_COUNT=${INDEX_UNUSED_NON_UNIQUE_COUNT}" \
    "Production veri hacmi artinca index usage baseline tekrar alinacak; simdi index drop yok" \
    "Production baseline tekrar PASS"

  observe "DB-RISK-004 low-data nedeniyle unused indexler drop adayi degil, observe-only"
fi

if [ "$VACUUM_LOW_DATA_CONTEXT" = "YES" ]; then
  add_register \
    "DB-RISK-005" \
    "vacuum_bloat" \
    "MEDIUM" \
    "OBSERVE_ONLY" \
    "14.4.3" \
    "LOW_DATA_CONTEXT=YES; LIVE=${VACUUM_TOTAL_LIVE_TUPLES}; DEAD=${VACUUM_TOTAL_DEAD_TUPLES}; HIGH_DEAD_RATIO_TABLES=${VACUUM_HIGH_DEAD_RATIO_COUNT}" \
    "Production veri hacmi artinca vacuum/dead tuple baseline tekrar alinacak; simdi vacuum/analyze yok" \
    "Production vacuum baseline tekrar PASS"

  observe "DB-RISK-005 low-data nedeniyle dead tuple/bloat sinyali observe-only"
fi

if [ "$READINESS_STATUS" = "READY_WITH_DEFERRED_ACTIONS" ]; then
  add_register \
    "DB-RISK-006" \
    "production_readiness" \
    "MEDIUM" \
    "DEFERRED" \
    "14.5.2" \
    "READINESS_STATUS=READY_WITH_DEFERRED_ACTIONS; SCORE=${READINESS_SCORE}; GRADE=${READINESS_GRADE}" \
    "Deferred PITR apply tamamlanana kadar DB readiness A ama PITR tam aktif degil olarak etiketlenecek" \
    "READINESS_STATUS=READY"

  defer "DB-RISK-006 production readiness deferred action ile hazir"
fi

if [ "$DB_HEALTH_RISK_LEVEL" = "LOW" ] && [ "$DB_WAITING_LOCK_COUNT" = "0" ] && [ "$DB_DEADLOCK_COUNT" = "0" ] && [ "$DB_IDLE_TX_COUNT" = "0" ]; then
  add_register \
    "DB-RISK-007" \
    "db_health" \
    "LOW" \
    "ACCEPTED_BASELINE" \
    "14.4.4" \
    "HEALTH_RISK=LOW; LOCK=${DB_WAITING_LOCK_COUNT}; DEADLOCK=${DB_DEADLOCK_COUNT}; IDLE_TX=${DB_IDLE_TX_COUNT}" \
    "Normal operasyon baseline olarak kabul edildi; production sonrasi periyodik tekrar alinacak" \
    "Periodic DB health baseline PASS"
else
  add_register \
    "DB-RISK-007" \
    "db_health" \
    "HIGH" \
    "REVIEW" \
    "14.4.4" \
    "HEALTH_RISK=${DB_HEALTH_RISK_LEVEL}; LOCK=${DB_WAITING_LOCK_COUNT}; DEADLOCK=${DB_DEADLOCK_COUNT}; IDLE_TX=${DB_IDLE_TX_COUNT}" \
    "DB health risk review edilmeli" \
    "DB_HEALTH_RISK_LEVEL=LOW"

  warn "DB health baseline LOW degil veya sifir metrikler bozuk"
fi

REGISTER_LINE_COUNT="$(wc -l < "$REGISTER_FILE" | tr -d ' ')"
REGISTER_ITEM_COUNT=$((REGISTER_LINE_COUNT - 1))

detail "RISK_REGISTER_CREATED=YES"
detail "RISK_REGISTER_LINE_COUNT=$REGISTER_LINE_COUNT"
detail "RISK_REGISTER_ITEM_COUNT=$REGISTER_ITEM_COUNT"
detail "BLOCKER_COUNT=$BLOCKER_COUNT"
detail "DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"
detail "OBSERVE_ONLY_COUNT=$OBSERVE_ONLY_COUNT"
detail "RISK_COUNT=$RISK_COUNT"

if [ "$REGISTER_ITEM_COUNT" -lt 1 ]; then
  fail "risk register bos olamaz"
fi

if [ "$BLOCKER_COUNT" -gt 0 ]; then
  fail "blocker count sifir degil"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_KNOWN_RISKS_DEFERRED_REGISTER=PASS"
else
  detail "DB_KNOWN_RISKS_DEFERRED_REGISTER=FAIL"
fi

{
  echo "# FAZ 4 / 14.5.3 - DB Known Risks / Deferred Actions Register Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_KNOWN_RISKS_DEFERRED_REGISTER=PASS"
  else
    echo "DB_KNOWN_RISKS_DEFERRED_REGISTER=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Deferred Actions"
  if [ -s "$DEFERRED_FILE" ]; then
    cat "$DEFERRED_FILE"
  else
    echo "OK ✅ deferred action yok"
  fi

  echo
  echo "## Observe Only Decisions"
  if [ -s "$OBSERVE_FILE" ]; then
    cat "$OBSERVE_FILE"
  else
    echo "OK ✅ observe-only decision yok"
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
    echo "OK ✅ major risk yok"
  fi

  echo
  echo "## Risk Register File"
  echo "RISK_REGISTER_FILE=docs/phase4/14_5_3_db_known_risks_register.tsv"
  echo "RISK_REGISTER_ITEM_COUNT=$REGISTER_ITEM_COUNT"

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
echo "REGISTER_FILE=$REGISTER_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RISK_REGISTER_ITEM_COUNT=$REGISTER_ITEM_COUNT"
echo "DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"
echo "OBSERVE_ONLY_COUNT=$OBSERVE_ONLY_COUNT"
echo "BLOCKER_COUNT=$BLOCKER_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_KNOWN_RISKS_DEFERRED_REGISTER=FAIL ❌"
  exit 1
fi

echo "DB_KNOWN_RISKS_DEFERRED_REGISTER=PASS ✅"
