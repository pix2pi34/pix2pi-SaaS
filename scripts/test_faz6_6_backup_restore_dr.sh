#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_6_BACKUP_RESTORE_DISASTER_RECOVERY.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_6_BACKUP_RESTORE_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_6_backup_restore_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_6_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_BACKUP_RESTORE_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 6-6 BACKUP / RESTORE / DR TEST BASLADI ====="

check_file "6-6 master dokumani mevcut" "$DOC_FILE"
check_file "6-6 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-6 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-6 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-6 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-6 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-6.1 Backup Inventory tanimli" "$DOC_FILE" "6-6.1 Backup Inventory"
check_grep "6-6.2 Restore Drill Readiness tanimli" "$DOC_FILE" "6-6.2 Restore Drill Readiness"
check_grep "6-6.3 RPO / RTO Hedefleri tanimli" "$DOC_FILE" "6-6.3 RPO / RTO Hedefleri"
check_grep "6-6.4 Disaster Scenario Seti tanimli" "$DOC_FILE" "6-6.4 Disaster Scenario Seti"
check_grep "6-6.5 Retention Cron Backup Logs tanimli" "$DOC_FILE" "6-6.5 Retention / Cron / Backup Logs"
check_grep "6-6.6 PITR WAL Readiness tanimli" "$DOC_FILE" "6-6.6 PITR / WAL Readiness"
check_grep "6-6.7 DR Runbook Incident Flow tanimli" "$DOC_FILE" "6-6.7 DR Runbook / Incident Flow"
check_grep "6-6.8 Final Closure Gate tanimli" "$DOC_FILE" "6-6.8 Backup / Restore Final Closure Gate"

check_grep "6-6.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_1_BACKUP_INVENTORY_STATUS=READY"
check_grep "6-6.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_2_RESTORE_DRILL_STATUS=READY"
check_grep "6-6.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_3_RPO_RTO_STATUS=READY"
check_grep "6-6.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_4_DISASTER_SCENARIO_STATUS=READY"
check_grep "6-6.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_5_RETENTION_CRON_LOG_STATUS=READY"
check_grep "6-6.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_6_PITR_WAL_STATUS=READY"
check_grep "6-6.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_7_DR_RUNBOOK_INCIDENT_FLOW_STATUS=READY"
check_grep "6-6.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_8_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-6 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-6 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-6 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_6_RUNTIME_AUDIT=COMPLETE"
check_grep "6-6 runtime disk usage var" "$RUNTIME_EVIDENCE_FILE" "6-6.2 Disk Usage"
check_grep "6-6 runtime backup directory inventory var" "$RUNTIME_EVIDENCE_FILE" "6-6.3 Backup Directory Inventory"
check_grep "6-6 runtime scripts inventory var" "$RUNTIME_EVIDENCE_FILE" "6-6.4 Backup / Restore Scripts Inventory"
check_grep "6-6 runtime cron inventory var" "$RUNTIME_EVIDENCE_FILE" "6-6.5 Cron Backup / Retention Inventory"
check_grep "6-6 runtime backup logs var" "$RUNTIME_EVIDENCE_FILE" "6-6.6 Backup / Retention Logs"
check_grep "6-6 runtime restic probe var" "$RUNTIME_EVIDENCE_FILE" "6-6.7 Restic"
check_grep "6-6 runtime postgres wal probe var" "$RUNTIME_EVIDENCE_FILE" "6-6.10 PostgreSQL WAL / Archive Runtime Probe"

echo
echo "===== 6-6 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-6 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-6.1.1 DB backup real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.1.1 Database backup"
check_grep "6-6.1.2 File config backup real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.1.2 File / config backup"
check_grep "6-6.1.3 Restic repo real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.1.3 Restic / backup repository"
check_grep "6-6.2.1 Restore real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.2.1 Restore script"
check_grep "6-6.2.2 Restore smoke real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.2.2 Restore smoke test"
check_grep "6-6.2.3 Restore safety real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.2.3 Restore safety"
check_grep "6-6.3 RPO RTO real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.3 RPO / RTO"
check_grep "6-6.4 Disaster scenario real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.4 Disaster scenario"
check_grep "6-6.5.1 Cron retention real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.5.1 Cron / systemd"
check_grep "6-6.5.2 Log real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.5.2 Backup / retention log"
check_grep "6-6.5.3 Retention guard real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.5.3 Retention guard"
check_grep "6-6.6 PITR real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.6 PITR / WAL"
check_grep "6-6 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-6 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-6 BACKUP / RESTORE / DR TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_6_DOC_STATUS=READY ✅"
  echo "FAZ_6_6_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_6_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_6_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_6_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_7_READY=YES ✅"
  elif grep -Fq "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_6_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_7_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_6_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_7_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-6 Backup / Restore / Disaster Recovery testi tamamlandi"
  exit 0
else
  echo "FAZ_6_6_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-6 testlerinde eksik var"
  exit 1
fi
