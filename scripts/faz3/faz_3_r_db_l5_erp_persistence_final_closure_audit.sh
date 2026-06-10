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

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
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

ERP_TABLES_SQL="'e_belge_documents',
'e_belge_status_history',
'e_belge_retry_queue',
'e_belge_cancel_requests',
'e_belge_provider_payloads',
'procurement_purchase_orders',
'procurement_purchase_order_lines',
'procurement_receipts',
'procurement_receipt_lines',
'procurement_purchase_invoices',
'procurement_purchase_invoice_lines',
'tax_rules',
'tax_rule_versions',
'tax_rule_conditions',
'tax_rule_audit_events',
'tdhp_charts',
'tdhp_chart_versions',
'tdhp_accounts',
'account_mapping_sets',
'account_mapping_versions',
'account_mapping_rules',
'journal_headers',
'journal_lines',
'journal_status_history',
'journal_posting_audit_events',
'ledger_posting_batches',
'ledger_account_movements',
'ledger_balances',
'ledger_period_closures',
'ledger_reconciliation_audit_events',
'inventory_movement_batches',
'inventory_stock_movements',
'inventory_warehouse_balances',
'inventory_reservations',
'inventory_balance_rebuild_audit_events',
'sales_quotations',
'sales_quotation_lines',
'sales_orders',
'sales_order_lines',
'sales_deliveries',
'sales_delivery_lines',
'sales_invoices',
'sales_invoice_lines',
'master_parties',
'master_customers',
'master_vendors',
'master_contacts',
'master_addresses',
'master_party_audit_events',
'product_categories',
'product_units',
'product_items',
'product_item_units',
'product_barcodes',
'product_item_audit_events',
'payment_methods',
'payment_transactions',
'collection_allocations',
'payment_allocations',
'refund_transactions',
'reconciliation_runs',
'reconciliation_items',
'payment_audit_events',
'export_runs',
'export_files',
'export_file_records',
'export_validations',
'export_audit_events',
'accountant_portal_accounts',
'accountant_portal_users',
'accountant_portal_subscriptions',
'accountant_portal_assigned_companies',
'accountant_portal_company_export_permissions',
'accountant_portal_audit_events'"

echo "===== 110 — FAZ 3-R DB-L5 ERP PERSISTENCE FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

check_file "110 evidence 97 e-Belge persistence" "docs/faz3/evidence/FAZ_3_9_10_E_BELGE_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 98 procurement persistence" "docs/faz3/evidence/FAZ_3_9_5_PROCUREMENT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 99 tax rule persistence" "docs/faz3/evidence/FAZ_3_9_9_TAX_RULE_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 100 TDHP account mapping persistence" "docs/faz3/evidence/FAZ_3_9_8_TDHP_ACCOUNT_MAPPING_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 101 journal persistence" "docs/faz3/evidence/FAZ_3_9_6_JOURNAL_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 102 ledger persistence" "docs/faz3/evidence/FAZ_3_9_7_LEDGER_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 103 inventory persistence" "docs/faz3/evidence/FAZ_3_9_3_INVENTORY_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 104 sales document persistence" "docs/faz3/evidence/FAZ_3_9_4_SALES_DOCUMENT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 105 master party persistence" "docs/faz3/evidence/FAZ_3_9_1_MASTER_PARTY_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 106 product item persistence" "docs/faz3/evidence/FAZ_3_9_2_PRODUCT_ITEM_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 107 payment collection reconciliation persistence" "docs/faz3/evidence/FAZ_3_9_11_PAYMENT_COLLECTION_RECONCILIATION_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 108 export persistence" "docs/faz3/evidence/FAZ_3_9_12_EXPORT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "110 evidence 109 accountant portal persistence" "docs/faz3/evidence/FAZ_3_9_13_ACCOUNTANT_PORTAL_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"

check_sql_count "110 DB-L5 ERP persistence total table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (${ERP_TABLES_SQL});
" "74"

check_sql_count "110 DB-L5 ERP persistence RLS enabled table count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (${ERP_TABLES_SQL})
AND c.relrowsecurity = true;
" "74"

check_sql_count "110 DB-L5 ERP persistence RLS forced table count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (${ERP_TABLES_SQL})
AND c.relforcerowsecurity = true;
" "74"

check_sql_min_count "110 DB-L5 ERP persistence tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (${ERP_TABLES_SQL})
AND policyname LIKE '%tenant_policy';
" "74"

check_sql_count "110 DB-L5 ERP persistence required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND table_name IN (${ERP_TABLES_SQL})
AND column_name='tenant_id'
AND is_nullable='NO';
" "74"

check_sql_min_count "110 DB-L5 ERP persistence primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (${ERP_TABLES_SQL})
AND constraint_type='PRIMARY KEY';
" "74"

check_sql_min_count "110 DB-L5 ERP persistence foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (${ERP_TABLES_SQL})
AND constraint_type='FOREIGN KEY';
" "99"

check_sql_min_count "110 DB-L5 ERP persistence check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (${ERP_TABLES_SQL})
AND constraint_type='CHECK';
" "154"

check_sql_min_count "110 DB-L5 ERP persistence index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (${ERP_TABLES_SQL});
" "220"

check_sql_count "110 e-Belge scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
);
" "5"

check_sql_count "110 procurement scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'procurement_purchase_orders',
  'procurement_purchase_order_lines',
  'procurement_receipts',
  'procurement_receipt_lines',
  'procurement_purchase_invoices',
  'procurement_purchase_invoice_lines'
);
" "6"

check_sql_count "110 tax rule scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'tax_rules',
  'tax_rule_versions',
  'tax_rule_conditions',
  'tax_rule_audit_events'
);
" "4"

check_sql_count "110 TDHP mapping scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'tdhp_charts',
  'tdhp_chart_versions',
  'tdhp_accounts',
  'account_mapping_sets',
  'account_mapping_versions',
  'account_mapping_rules'
);
" "6"

check_sql_count "110 journal scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'journal_headers',
  'journal_lines',
  'journal_status_history',
  'journal_posting_audit_events'
);
" "4"

check_sql_count "110 ledger scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'ledger_posting_batches',
  'ledger_account_movements',
  'ledger_balances',
  'ledger_period_closures',
  'ledger_reconciliation_audit_events'
);
" "5"

check_sql_count "110 inventory scope table count" "
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

check_sql_count "110 sales document scope table count" "
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

check_sql_count "110 master party scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'master_parties',
  'master_customers',
  'master_vendors',
  'master_contacts',
  'master_addresses',
  'master_party_audit_events'
);
" "6"

check_sql_count "110 product item scope table count" "
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

check_sql_count "110 payment collection reconciliation scope table count" "
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

check_sql_count "110 export scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'export_runs',
  'export_files',
  'export_file_records',
  'export_validations',
  'export_audit_events'
);
" "5"

check_sql_count "110 accountant portal scope table count" "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='erp'
AND table_name IN (
  'accountant_portal_accounts',
  'accountant_portal_users',
  'accountant_portal_subscriptions',
  'accountant_portal_assigned_companies',
  'accountant_portal_company_export_permissions',
  'accountant_portal_audit_events'
);
" "6"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 110 — FAZ 3-R — DB-L5 ERP Persistence Final Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_R_DB_L5_ERP_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_R_DB_L5_ERP_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}

## Closed Scope

- 97 — e-Belge persistence
- 98 — Procurement persistence
- 99 — Tax rule persistence
- 100 — TDHP chart / account mapping persistence
- 101 — Journal persistence
- 102 — Ledger persistence
- 103 — Inventory persistence
- 104 — Sales document persistence
- 105 — Master party persistence
- 106 — Product item persistence
- 107 — Payment / collection / reconciliation persistence
- 108 — Export persistence
- 109 — Accountant portal persistence

## Real DB Metadata Scope

- ERP table count: 74
- RLS enabled table count: 74
- RLS forced table count: 74
- Required tenant_id column count: 74
- Tenant policy count: >=74
- Primary key count: >=74
- Foreign key count: >=99
- Check constraint count: >=154
- Index count: >=220

## Audit Notes

Final status is derived from real PostgreSQL metadata checks and existing evidence files.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 110 — FAZ 3-R DB-L5 ERP PERSISTENCE FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_R_DB_L5_ERP_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_R_DB_L5_ERP_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
