#!/usr/bin/env bash
set -euo pipefail

echo "===== 14.4 BACKFILL / REBUILD CANDIDATE EXECUTION PLAN ====="

APPLY_BACKFILL="${APPLY_BACKFILL:-0}"
BACKFILL_JOB_KEY="${BACKFILL_JOB_KEY:-}"
TENANT_ID="${TENANT_ID:-}"
DRY_RUN="${DRY_RUN:-1}"

echo "BACKFILL_APPLY_EXECUTED=NO"
echo "REBUILD_APPLY_EXECUTED=NO"
echo "DB_MUTATION=NO"
echo "QUERY_TEXT_PRINTED=NO"

if [ "$APPLY_BACKFILL" != "1" ]; then
  echo "BACKFILL_PLAN_BLOCKED_BY_DEFAULT=YES"
  echo "BACKFILL_PLAN_DECISION=PLAN_READY_APPLY_NOT_EXECUTED"
  exit 0
fi

echo "BACKFILL_PLAN_BLOCKED_BY_DEFAULT=YES"
echo "BACKFILL_PLAN_DECISION=REFUSED_IN_14_4_STANDARD_STEP"
echo "ERROR: 14.4 standard adiminda gercek backfill/rebuild apply calistirilmaz."
echo "ERROR: Controlled apply icin sonraki apply gate adimi gerekir."
exit 2
