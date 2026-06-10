#!/usr/bin/env bash
set -euo pipefail

DB_DSN="${DB_DSN:?DB_DSN is required}"
EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_sql_count() {
  local label="$1"
  local sql="$2"
  local expected="$3"
  local actual
  actual="$(psql "$DB_DSN" -X -A -t -v ON_ERROR_STOP=1 -c "$sql")"

  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label expected=${expected} actual=${actual}"
  fi
}

check_sql_min_count() {
  local label="$1"
  local sql="$2"
  local min_expected="$3"
  local actual
  actual="$(psql "$DB_DSN" -X -A -t -v ON_ERROR_STOP=1 -c "$sql")"

  if [ "$actual" -ge "$min_expected" ]; then
    pass "$label"
  else
    fail "$label min_expected=${min_expected} actual=${actual}"
  fi
}

echo "===== 103 — FAZ 3-9.3 INVENTORY REAL IMPLEMENTATION AUDIT START ====="

check_sql_count "103 inventory table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
);
" "5"

check_sql_count "103 inventory RLS enabled count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND c.relrowsecurity = true;
" "5"

check_sql_count "103 inventory RLS forced count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND c.relforcerowsecurity = true;
" "5"

check_sql_min_count "103 inventory tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND policyname LIKE '%tenant_policy';
" "5"

check_sql_min_count "103 inventory primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND constraint_type='PRIMARY KEY';
" "5"

check_sql_min_count "103 inventory foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'inventory_stock_movements',
  'inventory_warehouse_balances'
)
AND constraint_type='FOREIGN KEY';
" "3"

check_sql_min_count "103 inventory check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND constraint_type='CHECK';
" "12"

check_sql_min_count "103 inventory index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
);
" "16"

check_sql_count "103 inventory required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND column_name='tenant_id'
AND table_name IN (
  'inventory_movement_batches',
  'inventory_stock_movements',
  'inventory_warehouse_balances',
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
)
AND is_nullable='NO';
" "5"

check_sql_count "103 inventory movement/balance scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'inventory_stock_movements',
  'inventory_warehouse_balances'
);
" "2"

check_sql_count "103 inventory reservation/audit scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'inventory_reservations',
  'inventory_balance_rebuild_audit_events'
);
" "2"

check_sql_min_count "103 inventory idempotency unique constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'inventory_movement_batches',
  'inventory_stock_movements'
)
AND constraint_type='UNIQUE'
AND constraint_name IN (
  'inventory_movement_batches_idempotency_unique',
  'inventory_stock_movements_idempotency_unique'
);
" "2"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 103 — FAZ 3-9.3 — Inventory Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_9_3_INVENTORY_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_9_3_INVENTORY_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_9_4_READY=${NEXT_READY}

## Scope

- inventory movement batch
- inventory stock movement
- inventory warehouse balance
- inventory reservation
- inventory balance rebuild audit
- tenant-safe RLS policy
- FK / index / check constraint metadata
- idempotency unique constraints

## Audit Notes

Final status is derived from real PostgreSQL metadata checks.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 103 — FAZ 3-9.3 INVENTORY COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_9_3_INVENTORY_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_9_3_INVENTORY_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_9_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
