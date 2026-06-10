#!/usr/bin/env bash
set -euo pipefail

echo "===== 14.6 BACKUP / RESTORE CANDIDATE EXECUTION PLAN ====="

APPLY_BACKUP_RESTORE="${APPLY_BACKUP_RESTORE:-0}"
BACKUP_GATE_KEY="${BACKUP_GATE_KEY:-}"
TENANT_ID="${TENANT_ID:-}"
DRY_RUN="${DRY_RUN:-1}"

echo "BACKUP_EXECUTED=NO"
echo "RESTORE_EXECUTED=NO"
echo "PITR_APPLY_EXECUTED=NO"
echo "DB_MUTATION=NO"
echo "QUERY_TEXT_PRINTED=NO"

if [ "$APPLY_BACKUP_RESTORE" != "1" ]; then
  echo "BACKUP_RESTORE_PLAN_BLOCKED_BY_DEFAULT=YES"
  echo "BACKUP_RESTORE_PLAN_DECISION=PLAN_READY_APPLY_NOT_EXECUTED"
  exit 0
fi

echo "BACKUP_RESTORE_PLAN_BLOCKED_BY_DEFAULT=YES"
echo "BACKUP_RESTORE_PLAN_DECISION=REFUSED_IN_14_6_STANDARD_STEP"
echo "ERROR: 14.6 standard adiminda gercek backup/restore/PITR apply calistirilmaz."
echo "ERROR: Controlled apply veya bakim penceresi gate olmadan islem yapilmaz."
exit 2
