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

echo "===== 104 — FAZ 3-9.4 SALES DOCUMENT REAL IMPLEMENTATION AUDIT START ====="

check_sql_count "104 sales document table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
);
" "8"

check_sql_count "104 sales document RLS enabled count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND c.relrowsecurity = true;
" "8"

check_sql_count "104 sales document RLS forced count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND c.relforcerowsecurity = true;
" "8"

check_sql_min_count "104 sales document tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND policyname LIKE '%tenant_policy';
" "8"

check_sql_min_count "104 sales document primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND constraint_type='PRIMARY KEY';
" "8"

check_sql_min_count "104 sales document foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND constraint_type='FOREIGN KEY';
" "12"

check_sql_min_count "104 sales document check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND constraint_type='CHECK';
" "18"

check_sql_min_count "104 sales document index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
);
" "24"

check_sql_count "104 sales document required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND column_name='tenant_id'
AND table_name IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines',
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
)
AND is_nullable='NO';
" "8"

check_sql_count "104 quotation/order scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotations',
  'sales_quotation_lines',
  'sales_orders',
  'sales_order_lines'
);
" "4"

check_sql_count "104 delivery/invoice scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'sales_deliveries',
  'sales_delivery_lines',
  'sales_invoices',
  'sales_invoice_lines'
);
" "4"

check_sql_min_count "104 sales document idempotency unique constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'sales_quotations',
  'sales_orders',
  'sales_deliveries',
  'sales_invoices'
)
AND constraint_type='UNIQUE'
AND constraint_name IN (
  'sales_quotations_idempotency_unique',
  'sales_orders_idempotency_unique',
  'sales_deliveries_idempotency_unique',
  'sales_invoices_idempotency_unique'
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
# 104 — FAZ 3-9.4 — Sales Document Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_9_4_SALES_DOCUMENT_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_9_4_SALES_DOCUMENT_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_9_1_READY=${NEXT_READY}

## Scope

- quotation header / line
- order header / line
- delivery header / line
- invoice header / line
- tenant-safe RLS policy
- FK / index / check constraint metadata
- idempotency unique constraints

## Audit Notes

Final status is derived from real PostgreSQL metadata checks.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 104 — FAZ 3-9.4 SALES DOCUMENT COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_9_4_SALES_DOCUMENT_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_9_4_SALES_DOCUMENT_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_9_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
