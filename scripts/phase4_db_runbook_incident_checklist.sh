#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
REPORT_DIR="$ROOT_DIR/docs/phase4"

REPORT_FILE="$REPORT_DIR/14_5_4_db_runbook_incident_checklist_report.md"
RUNBOOK_FILE="$REPORT_DIR/14_5_4_db_operations_runbook.md"

R_1452="$REPORT_DIR/14_5_2_db_production_readiness_scorecard_report.md"
R_1453="$REPORT_DIR/14_5_3_db_known_risks_deferred_register_report.md"
RISK_REGISTER="$REPORT_DIR/14_5_3_db_known_risks_register.tsv"
R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
R_1422="$REPORT_DIR/14_2_2_logical_backup_smoke_report.md"
R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
R_1426="$REPORT_DIR/14_2_6_pitr_enable_gate_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
TOOL_FILE="$(mktemp)"
RISK_FILE="$(mktemp)"
CHECKLIST_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$TOOL_FILE" "$RISK_FILE" "$CHECKLIST_FILE"' EXIT

detail() { echo "$1" >> "$DETAILS_FILE"; }
warn() { echo "WARN ⚠️ $1" >> "$ISSUES_FILE"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { echo "FAIL ❌ $1" >> "$ISSUES_FILE"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
risk() { echo "RISK ⚠️ $1" >> "$RISK_FILE"; }
checkline() { echo "$1" >> "$CHECKLIST_FILE"; }

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
detail "RUNBOOK_FILE=docs/phase4/14_5_4_db_operations_runbook.md"

tool_status "grep" >/dev/null || true
tool_status "awk" >/dev/null || true
tool_status "sed" >/dev/null || true

require_file "14.5.2 scorecard report" "$R_1452" || true
require_file "14.5.3 risk register report" "$R_1453" || true
require_file "14.5.3 risk register tsv" "$RISK_REGISTER" || true
require_file "14.4.4 DB health baseline" "$R_1444" || true
require_file "14.2.2 logical backup smoke" "$R_1422" || true
require_file "14.2.4 restore drill test" "$R_1424" || true
require_file "14.2.6 PITR enable gate" "$R_1426" || true

SCORECARD_STATUS="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORECARD")"
READINESS_SCORE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_SCORE")"
READINESS_GRADE="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_GRADE")"
READINESS_STATUS="$(get_report_value "$R_1452" "DB_PRODUCTION_READINESS_STATUS")"

RISK_REGISTER_STATUS="$(get_report_value "$R_1453" "DB_KNOWN_RISKS_DEFERRED_REGISTER")"
RISK_REGISTER_ITEM_COUNT="$(get_report_value "$R_1453" "RISK_REGISTER_ITEM_COUNT")"
DEFERRED_ACTION_COUNT="$(get_report_value "$R_1453" "DEFERRED_ACTION_COUNT")"
OBSERVE_ONLY_COUNT="$(get_report_value "$R_1453" "OBSERVE_ONLY_COUNT")"
BLOCKER_COUNT="$(get_report_value "$R_1453" "BLOCKER_COUNT")"

DB_HEALTH_STATUS="$(get_report_value "$R_1444" "DB_HEALTH_BASELINE")"
DB_HEALTH_RISK_LEVEL="$(get_report_value "$R_1444" "DB_HEALTH_RISK_LEVEL")"
DB_WAITING_LOCK_COUNT="$(get_report_value "$R_1444" "DB_WAITING_LOCK_COUNT")"
DB_DEADLOCK_COUNT="$(get_report_value "$R_1444" "DB_DEADLOCK_COUNT")"
DB_IDLE_TX_COUNT="$(get_report_value "$R_1444" "DB_IDLE_IN_TRANSACTION_CONNECTIONS")"

LOGICAL_BACKUP_STATUS="$(get_report_value "$R_1422" "LOGICAL_BACKUP_SMOKE")"
RESTORE_DRILL_STATUS="$(get_report_value "$R_1424" "RESTORE_DRILL_TEST")"
PITR_CURRENT_READY="$(get_report_value "$R_1426" "PITR_CURRENT_READY")"
PITR_ENABLE_DECISION="$(get_report_value "$R_1426" "PITR_ENABLE_DECISION")"
HOST_WAL_ARCHIVE_DIR_STATUS="$(get_report_value "$R_1426" "HOST_WAL_ARCHIVE_DIR_STATUS")"
WAL_ARCHIVE_MOUNT_STATUS="$(get_report_value "$R_1426" "WAL_ARCHIVE_MOUNT_STATUS")"
ARCHIVE_MODE_READY="$(get_report_value "$R_1426" "ARCHIVE_MODE_READY")"
ARCHIVE_COMMAND_READY="$(get_report_value "$R_1426" "ARCHIVE_COMMAND_READY")"

detail "DB_PRODUCTION_READINESS_SCORECARD=$SCORECARD_STATUS"
detail "DB_PRODUCTION_READINESS_SCORE=$READINESS_SCORE"
detail "DB_PRODUCTION_READINESS_GRADE=$READINESS_GRADE"
detail "DB_PRODUCTION_READINESS_STATUS=$READINESS_STATUS"
detail "DB_KNOWN_RISKS_DEFERRED_REGISTER=$RISK_REGISTER_STATUS"
detail "RISK_REGISTER_ITEM_COUNT=$RISK_REGISTER_ITEM_COUNT"
detail "DEFERRED_ACTION_COUNT=$DEFERRED_ACTION_COUNT"
detail "OBSERVE_ONLY_COUNT=$OBSERVE_ONLY_COUNT"
detail "BLOCKER_COUNT=$BLOCKER_COUNT"
detail "DB_HEALTH_BASELINE=$DB_HEALTH_STATUS"
detail "DB_HEALTH_RISK_LEVEL=$DB_HEALTH_RISK_LEVEL"
detail "DB_WAITING_LOCK_COUNT=$DB_WAITING_LOCK_COUNT"
detail "DB_DEADLOCK_COUNT=$DB_DEADLOCK_COUNT"
detail "DB_IDLE_IN_TRANSACTION_CONNECTIONS=$DB_IDLE_TX_COUNT"
detail "LOGICAL_BACKUP_SMOKE=$LOGICAL_BACKUP_STATUS"
detail "RESTORE_DRILL_TEST=$RESTORE_DRILL_STATUS"
detail "PITR_CURRENT_READY=$PITR_CURRENT_READY"
detail "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"
detail "HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS"
detail "WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"
detail "ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY"
detail "ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"

if [ "$SCORECARD_STATUS" != "PASS" ]; then
  fail "14.5.2 scorecard PASS degil"
fi

if [ "$RISK_REGISTER_STATUS" != "PASS" ]; then
  fail "14.5.3 risk register PASS degil"
fi

if [ "$BLOCKER_COUNT" != "0" ]; then
  fail "risk register blocker count sifir degil"
fi

if [ "$LOGICAL_BACKUP_STATUS" != "PASS" ]; then
  fail "logical backup smoke PASS degil"
fi

if [ "$RESTORE_DRILL_STATUS" != "PASS" ]; then
  fail "restore drill test PASS degil"
fi

if [ "$DB_HEALTH_STATUS" != "PASS" ]; then
  fail "DB health baseline PASS degil"
fi

if [ "$DB_HEALTH_RISK_LEVEL" != "LOW" ]; then
  warn "DB health risk LOW degil: $DB_HEALTH_RISK_LEVEL"
fi

if [ "$PITR_CURRENT_READY" = "NO" ]; then
  risk "PITR aktif degil; runbook icinde deferred maintenance olarak yazildi"
fi

checkline "DB health kontrol checklist"
checkline "Backup restore kontrol checklist"
checkline "PITR deferred action checklist"
checkline "WAL archive enable checklist"
checkline "Lock deadlock incident checklist"
checkline "Slow query incident checklist"
checkline "Connection saturation checklist"
checkline "Vacuum bloat observe checklist"
checkline "Index usage observe checklist"
checkline "Rollback decision tree"
checkline "Production baseline schedule"

cat <<RUNBOOK > "$RUNBOOK_FILE"
# FAZ 4 / 14.5.4 - DB Operations Runbook / Incident Checklist

Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')

## 1. Current DB Readiness Snapshot

| Alan | Deger |
|---|---|
| Production readiness score | ${READINESS_SCORE}/100 |
| Production readiness grade | ${READINESS_GRADE} |
| Production readiness status | ${READINESS_STATUS} |
| Blocker count | ${BLOCKER_COUNT} |
| Deferred action count | ${DEFERRED_ACTION_COUNT} |
| Observe-only count | ${OBSERVE_ONLY_COUNT} |
| DB health risk | ${DB_HEALTH_RISK_LEVEL} |
| PITR current ready | ${PITR_CURRENT_READY} |

## 2. Golden Safety Rules

- Canli DB uzerinde once kanit, sonra karar.
- Raw DSN, password ve query text rapora basma.
- Backup almadan config apply yapma.
- Restore drill kaniti olmadan backup'a guvenme.
- Query kill / lock termination yalniz incident owner onayi ile.
- Index drop karari production veri hacmi ve tekrar baseline olmadan verilmez.
- Vacuum/analyze canli ortamda sadece kontrollu planla uygulanir.
- PITR apply islemi maintenance window olmadan yapilmaz.

## 3. DB Health Quick Check

Amac: DB calisiyor mu, primary mi, lock/deadlock/idle transaction var mi?

\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_db_health_baseline.sh .

grep -E 'DB_CONNECTION_CHECK=|DB_ROLE=|DB_TOTAL_CONNECTIONS=|DB_IDLE_IN_TRANSACTION_CONNECTIONS=|DB_LONG_RUNNING_ACTIVE_QUERIES_60S=|DB_WAITING_LOCK_COUNT=|DB_DEADLOCK_COUNT=|DB_PREPARED_TRANSACTION_COUNT=|DB_HEALTH_RISK_LEVEL=' \\
  docs/phase4/14_4_4_db_health_baseline_report.md
\`\`\`

Beklenen:
\`\`\`text
DB_CONNECTION_CHECK=PASS
DB_ROLE=PRIMARY_WRITE
DB_WAITING_LOCK_COUNT=0
DB_DEADLOCK_COUNT=0
DB_IDLE_IN_TRANSACTION_CONNECTIONS=0
DB_HEALTH_RISK_LEVEL=LOW
\`\`\`

## 4. Backup / Restore Quick Check

\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_logical_backup_smoke.sh .
bash scripts/phase4_restore_drill_test.sh .

grep -E 'LOGICAL_BACKUP_SMOKE=|DUMP_SIZE_BYTES=|PG_RESTORE_LIST_CHECK=' \\
  docs/phase4/14_2_2_logical_backup_smoke_report.md

grep -E 'RESTORE_DRILL_TEST=|SANDBOX_RESTORE_STATUS=|RESTORED_TABLE_COUNT=|SANDBOX_CLEANUP_STATUS=' \\
  docs/phase4/14_2_4_restore_drill_test_report.md
\`\`\`

Beklenen:
\`\`\`text
LOGICAL_BACKUP_SMOKE=PASS
RESTORE_DRILL_TEST=PASS
SANDBOX_RESTORE_STATUS=PASS
SANDBOX_CLEANUP_STATUS=PASS
\`\`\`

## 5. PITR Deferred Action Runbook

Mevcut durum:
\`\`\`text
PITR_CURRENT_READY=${PITR_CURRENT_READY}
PITR_ENABLE_DECISION=${PITR_ENABLE_DECISION}
HOST_WAL_ARCHIVE_DIR_STATUS=${HOST_WAL_ARCHIVE_DIR_STATUS}
WAL_ARCHIVE_MOUNT_STATUS=${WAL_ARCHIVE_MOUNT_STATUS}
ARCHIVE_MODE_READY=${ARCHIVE_MODE_READY}
ARCHIVE_COMMAND_READY=${ARCHIVE_COMMAND_READY}
\`\`\`

PITR maintenance window oncesi zorunlu kapilar:

- Fresh logical backup al.
- Restore drill PASS al.
- Docker compose/config backup al.
- WAL archive host dizini olustur.
- WAL archive mount ekle.
- archive_mode=on yap.
- archive_command tanimla.
- PostgreSQL controlled restart yap.
- DB health PASS al.
- pg_switch_wal ile WAL dosyasi arsive dustu mu dogrula.
- Restic backup kapsamina WAL archive dizinini al.
- PITR readiness raporunu tekrar calistir.

Kontrol komutlari:
\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_db_backup_pitr_readiness.sh .
bash scripts/phase4_pitr_enable_gate.sh .

grep -E 'PITR_CURRENT_READY=|ARCHIVE_MODE_READY=|ARCHIVE_COMMAND_READY=|HOST_WAL_ARCHIVE_DIR_STATUS=|WAL_ARCHIVE_MOUNT_STATUS=' \\
  docs/phase4/14_2_6_pitr_enable_gate_report.md
\`\`\`

## 6. WAL Archive Enable Checklist

- [ ] Bakim penceresi onaylandi.
- [ ] Fresh backup PASS.
- [ ] Restore drill PASS.
- [ ] Config backup alindi.
- [ ] Host WAL archive dizini olusturuldu.
- [ ] Container mount eklendi.
- [ ] archive_mode=on yapildi.
- [ ] archive_command tanimlandi.
- [ ] PostgreSQL restart edildi.
- [ ] DB_CONNECTION_CHECK=PASS.
- [ ] DB_ROLE=PRIMARY_WRITE.
- [ ] WAL switch test edildi.
- [ ] WAL archive dosyasi goruldu.
- [ ] Risk register DB-RISK-001/002/003 kapatildi.

## 7. Lock / Deadlock Incident Checklist

Ilk kontrol:
\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_db_health_baseline.sh .

grep -E 'DB_WAITING_LOCK_COUNT=|DB_BLOCKED_PID_COUNT=|DB_DEADLOCK_COUNT=|DB_HEALTH_RISK_LEVEL=' \\
  docs/phase4/14_4_4_db_health_baseline_report.md
\`\`\`

Karar agaci:
- Waiting lock 0 ise incident yok.
- Waiting lock > 0 ise once etkilenen servis/tenant/log kontrol edilir.
- Query text rapora basilmaz.
- Kill islemi otomatik yapilmaz.
- Query kill gerekiyorsa incident owner onayi gerekir.
- Kill sonrasi DB health baseline tekrar alinir.

## 8. Slow Query Incident Checklist

Ilk kontrol:
\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_query_performance_baseline.sh .

grep -E 'PG_STAT_MEAN_OVER_WARN_COUNT=|PG_STAT_TOTAL_OVER_WARN_COUNT=|PG_STAT_TEMP_BLOCK_QUERY_COUNT=|QUERY_PERF_RISK_LEVEL=' \\
  docs/phase4/14_4_1_query_performance_baseline_report.md
\`\`\`

Karar agaci:
- Risk LOW ise observe.
- Mean/total threshold asildiysa queryid bazli analiz yap.
- Query text rapora basma.
- Index ekleme karari icin 14.4.2 index usage baseline ile birlikte degerlendir.
- Production verisi artinca tekrar baseline al.

## 9. Connection Saturation Checklist

Kontrol:
\`\`\`bash
grep -E 'POSTGRES_MAX_CONNECTIONS=|DB_TOTAL_CONNECTIONS=|DB_CONNECTION_USAGE_PERCENT=|DB_IDLE_IN_TRANSACTION_CONNECTIONS=' \\
  docs/phase4/14_4_4_db_health_baseline_report.md
\`\`\`

Karar agaci:
- Connection usage < %70 ise normal.
- Usage >= %70 ise connection pool ayarlari incelenir.
- idle in transaction > 0 ise uygulama transaction lifecycle incelenir.
- Max connection artirmadan once pool / leak analizi yapilir.

## 10. Vacuum / Bloat Observe Checklist

Kontrol:
\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_vacuum_bloat_readiness.sh .

grep -E 'AUTOVACUUM=|TRACK_COUNTS=|DB_TOTAL_LIVE_TUPLES=|DB_TOTAL_DEAD_TUPLES=|DB_HIGH_DEAD_RATIO_TABLE_COUNT=|LOW_DATA_CONTEXT=|VACUUM_RISK_LEVEL=' \\
  docs/phase4/14_4_3_vacuum_bloat_readiness_report.md
\`\`\`

Karar:
- LOW_DATA_CONTEXT=YES ise vacuum/analyze calistirma, observe-only.
- Production veri hacmi artinca tekrar baseline al.
- Gercek bloat icin pgstattuple ayri gate ile degerlendirilecek.

## 11. Index Usage Observe Checklist

Kontrol:
\`\`\`bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_index_usage_baseline.sh .

grep -E 'DB_UNUSED_INDEX_COUNT=|DB_UNUSED_NON_UNIQUE_INDEX_COUNT=|LOW_DATA_CONTEXT=|INDEX_USAGE_RISK_LEVEL=' \\
  docs/phase4/14_4_2_index_usage_baseline_report.md
\`\`\`

Karar:
- LOW_DATA_CONTEXT=YES ise index drop yok.
- Primary/unique indexler observe-only.
- Production veri hacmi artinca index usage tekrar degerlendirilir.
- Drop karari icin en az iki farkli production baseline gerekir.

## 12. Rollback Decision Tree

Config apply sonrasi DB acilmiyorsa:
1. Son config backup bulunur.
2. Son compose/config backup restore edilir.
3. PostgreSQL container controlled restart edilir.
4. DB_CONNECTION_CHECK=PASS dogrulanir.
5. DB_ROLE=PRIMARY_WRITE dogrulanir.
6. Incident kaydi acilir.
7. Basarisiz config apply risk register'a eklenir.

Backup/restore problemi varsa:
1. Son logical backup raporu kontrol edilir.
2. Son restore drill raporu kontrol edilir.
3. Dump checksum dogrulanir.
4. Sandbox restore tekrar denenir.
5. Canli restore yapilmaz; once sandbox kaniti alinir.

## 13. Production Sonrasi Tekrar Baseline Takvimi

- Ilk 1 hafta: Her gun DB health baseline.
- Ilk 1 hafta: Her gun query performance baseline.
- Ilk 1 ay: Haftalik index usage baseline.
- Ilk 1 ay: Haftalik vacuum/bloat readiness baseline.
- Her major release sonrasi: 14.4.1 - 14.4.5 tekrar.
- PITR enable sonrasi: 14.2.1 - 14.2.6 tekrar.

## 14. Final Operational Status

\`\`\`text
DB_RUNBOOK_STATUS=ACTIVE
DB_PRODUCTION_READINESS_SCORE=${READINESS_SCORE}
DB_PRODUCTION_READINESS_GRADE=${READINESS_GRADE}
DB_PRODUCTION_READINESS_STATUS=${READINESS_STATUS}
KNOWN_BLOCKERS=${BLOCKER_COUNT}
KNOWN_DEFERRED_ACTIONS=${DEFERRED_ACTION_COUNT}
KNOWN_OBSERVE_ONLY_DECISIONS=${OBSERVE_ONLY_COUNT}
\`\`\`
RUNBOOK

RUNBOOK_SECTION_COUNT="$(grep -c '^## ' "$RUNBOOK_FILE" || true)"
RUNBOOK_SIZE_BYTES="$(wc -c < "$RUNBOOK_FILE" | tr -d ' ')"
CHECKLIST_COUNT="$(wc -l < "$CHECKLIST_FILE" | tr -d ' ')"

detail "RUNBOOK_CREATED=YES"
detail "RUNBOOK_SECTION_COUNT=$RUNBOOK_SECTION_COUNT"
detail "RUNBOOK_SIZE_BYTES=$RUNBOOK_SIZE_BYTES"
detail "CHECKLIST_TOPIC_COUNT=$CHECKLIST_COUNT"

if [ "$RUNBOOK_SECTION_COUNT" -lt 10 ]; then
  fail "runbook section count yetersiz"
fi

if ! grep -q "PITR Deferred Action Runbook" "$RUNBOOK_FILE"; then
  fail "PITR deferred action runbook bolumu yok"
fi

if ! grep -q "Lock / Deadlock Incident Checklist" "$RUNBOOK_FILE"; then
  fail "lock/deadlock checklist bolumu yok"
fi

if ! grep -q "Slow Query Incident Checklist" "$RUNBOOK_FILE"; then
  fail "slow query checklist bolumu yok"
fi

if ! grep -q "Rollback Decision Tree" "$RUNBOOK_FILE"; then
  fail "rollback decision tree bolumu yok"
fi

if ! grep -q "Production Sonrasi Tekrar Baseline Takvimi" "$RUNBOOK_FILE"; then
  fail "production baseline takvimi bolumu yok"
fi

if grep -Eiq 'password=|POSTGRES_PASSWORD=|PGPASSWORD=' "$RUNBOOK_FILE"; then
  fail "runbook icinde secret benzeri ifade var"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  detail "DB_RUNBOOK_INCIDENT_CHECKLIST=PASS"
else
  detail "DB_RUNBOOK_INCIDENT_CHECKLIST=FAIL"
fi

{
  echo "# FAZ 4 / 14.5.4 - DB Runbook / Incident Checklist Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DB_RUNBOOK_INCIDENT_CHECKLIST=PASS"
  else
    echo "DB_RUNBOOK_INCIDENT_CHECKLIST=FAIL"
  fi

  echo
  echo "## Tool Status"
  if [ -s "$TOOL_FILE" ]; then
    cat "$TOOL_FILE"
  else
    echo "tool status yok"
  fi

  echo
  echo "## Checklist Topics"
  cat "$CHECKLIST_FILE"

  echo
  echo "## Risks"
  if [ -s "$RISK_FILE" ]; then
    cat "$RISK_FILE"
  else
    echo "OK ✅ runbook major risk yok"
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
echo "RUNBOOK_FILE=$RUNBOOK_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RUNBOOK_SECTION_COUNT=$RUNBOOK_SECTION_COUNT"
echo "RUNBOOK_SIZE_BYTES=$RUNBOOK_SIZE_BYTES"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DB_RUNBOOK_INCIDENT_CHECKLIST=FAIL ❌"
  exit 1
fi

echo "DB_RUNBOOK_INCIDENT_CHECKLIST=PASS ✅"
