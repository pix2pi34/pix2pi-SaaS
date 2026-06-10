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

echo "===== 107 — FAZ 3-9.11 PAYMENT COLLECTION RECONCILIATION REAL IMPLEMENTATION AUDIT START ====="

check_sql_count "107 payment collection reconciliation table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
);
" "8"

check_sql_count "107 payment collection reconciliation RLS enabled count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND c.relrowsecurity = true;
" "8"

check_sql_count "107 payment collection reconciliation RLS forced count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND c.relforcerowsecurity = true;
" "8"

check_sql_min_count "107 payment collection reconciliation tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND policyname LIKE '%tenant_policy';
" "8"

check_sql_min_count "107 payment collection reconciliation primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND constraint_type='PRIMARY KEY';
" "8"

check_sql_min_count "107 payment collection reconciliation foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND constraint_type='FOREIGN KEY';
" "22"

check_sql_min_count "107 payment collection reconciliation check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND constraint_type='CHECK';
" "18"

check_sql_min_count "107 payment collection reconciliation index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
);
" "24"

check_sql_count "107 payment collection reconciliation required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND column_name='tenant_id'
AND table_name IN (
  'payment_methods',
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions',
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
)
AND is_nullable='NO';
" "8"

check_sql_count "107 payment/collection/refund scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'payment_transactions',
  'collection_allocations',
  'payment_allocations',
  'refund_transactions'
);
" "4"

check_sql_count "107 reconciliation/audit scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'reconciliation_runs',
  'reconciliation_items',
  'payment_audit_events'
);
" "3"

check_sql_min_count "107 payment idempotency unique constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'payment_transactions',
  'refund_transactions'
)
AND constraint_type='UNIQUE'
AND constraint_name IN (
  'payment_transactions_idempotency_unique',
  'refund_transactions_idempotency_unique'
);
" "2"

check_sql_min_count "107 provider/bank reference columns count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND table_name='payment_transactions'
AND column_name IN (
  'provider_code',
  'provider_transaction_id',
  'bank_reference_no',
  'authorization_code'
);
" "4"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 107 — FAZ 3-9.11 — Payment Collection Reconciliation Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_9_11_PAYMENT_COLLECTION_RECONCILIATION_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_9_11_PAYMENT_COLLECTION_RECONCILIATION_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_9_12_READY=${NEXT_READY}

## Scope

- payment methods
- payment transactions
- collection allocations
- payment allocations
- refund transactions
- reconciliation runs
- reconciliation items
- payment audit events
- tenant-safe RLS policy
- FK / index / check constraint metadata
- idempotency unique constraints
- provider / bank reference columns

## Audit Notes

Final status is derived from real PostgreSQL metadata checks.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 107 — FAZ 3-9.11 PAYMENT COLLECTION RECONCILIATION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_9_11_PAYMENT_COLLECTION_RECONCILIATION_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_9_11_PAYMENT_COLLECTION_RECONCILIATION_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_9_12_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
