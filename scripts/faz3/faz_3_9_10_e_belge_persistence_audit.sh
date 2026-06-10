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

echo "===== 97 — FAZ 3-9.10 E-BELGE REAL IMPLEMENTATION AUDIT START ====="

check_sql_count "97 e-Belge table count" "
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

check_sql_count "97 e-Belge RLS enabled count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND c.relrowsecurity = true;
" "5"

check_sql_count "97 e-Belge RLS forced count" "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='erp'
AND c.relname IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND c.relforcerowsecurity = true;
" "5"

check_sql_min_count "97 e-Belge tenant policy count" "
SELECT count(*)
FROM pg_policies
WHERE schemaname='erp'
AND tablename IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND policyname LIKE '%tenant_policy';
" "5"

check_sql_min_count "97 e-Belge primary key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND constraint_type='PRIMARY KEY';
" "5"

check_sql_min_count "97 e-Belge foreign key count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND constraint_type='FOREIGN KEY';
" "4"

check_sql_min_count "97 e-Belge check constraint count" "
SELECT count(*)
FROM information_schema.table_constraints
WHERE table_schema='erp'
AND table_name IN (
  'e_belge_documents',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND constraint_type='CHECK';
" "8"

check_sql_min_count "97 e-Belge index count" "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='erp'
AND tablename IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
);
" "10"

check_sql_count "97 e-Belge required tenant_id column count" "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='erp'
AND column_name='tenant_id'
AND table_name IN (
  'e_belge_documents',
  'e_belge_status_history',
  'e_belge_retry_queue',
  'e_belge_cancel_requests',
  'e_belge_provider_payloads'
)
AND is_nullable='NO';
" "5"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 97 — FAZ 3-9.10 — e-Belge Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_9_10_E_BELGE_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_9_10_E_BELGE_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_9_5_READY=${NEXT_READY}

## Scope

- e_belge_documents
- e_belge_status_history
- e_belge_retry_queue
- e_belge_cancel_requests
- e_belge_provider_payloads

## Audit Notes

Final status is derived from real PostgreSQL metadata checks.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 97 — FAZ 3-9.10 E-BELGE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_9_10_E_BELGE_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_9_10_E_BELGE_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_9_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
