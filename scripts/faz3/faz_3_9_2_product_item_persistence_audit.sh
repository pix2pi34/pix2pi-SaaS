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

echo "===== 106 — FAZ 3-9.2 PRODUCT ITEM REAL IMPLEMENTATION AUDIT START ====="

check_sql_count "106 product item table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
);
" "6"

check_sql_count "106 product item RLS enabled count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND c.relrowsecurity = true;
" "6"

check_sql_count "106 product item RLS forced count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND c.relforcerowsecurity = true;
" "6"

check_sql_min_count "106 product item tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND policyname LIKE '%tenant_policy';
" "6"

check_sql_min_count "106 product item primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND constraint_type='PRIMARY KEY';
" "6"

check_sql_min_count "106 product item foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'product_categories',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND constraint_type='FOREIGN KEY';
" "7"

check_sql_min_count "106 product item check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND constraint_type='CHECK';
" "14"

check_sql_min_count "106 product item index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
);
" "20"

check_sql_count "106 product item required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND column_name='tenant_id'
AND table_name IN (
  'product_categories',
  'product_units',
  'product_items',
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
)
AND is_nullable='NO';
" "6"

check_sql_count "106 category/unit/item scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'product_categories',
  'product_units',
  'product_items'
);
" "3"

check_sql_count "106 item unit/barcode/audit scope count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'product_item_units',
  'product_barcodes',
  'product_item_audit_events'
);
" "3"

check_sql_min_count "106 product item oem/equivalent/barcode columns count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND table_name='product_items'
AND column_name IN (
  'oem_code',
  'equivalent_code',
  'barcode',
  'sku'
);
" "4"

check_sql_min_count "106 product item idempotency unique constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name='product_items'
AND constraint_type='UNIQUE'
AND constraint_name='product_items_idempotency_unique';
" "1"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 106 — FAZ 3-9.2 — Product Item Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_9_2_PRODUCT_ITEM_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_9_2_PRODUCT_ITEM_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_9_11_READY=${NEXT_READY}

## Scope

- product category
- product unit
- product item
- product item unit
- product barcode
- product item audit event
- tenant-safe RLS policy
- FK / index / check constraint metadata
- OEM / equivalent / barcode columns
- idempotency unique constraint

## Audit Notes

Final status is derived from real PostgreSQL metadata checks.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 106 — FAZ 3-9.2 PRODUCT ITEM COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_9_2_PRODUCT_ITEM_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_9_2_PRODUCT_ITEM_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_9_11_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
