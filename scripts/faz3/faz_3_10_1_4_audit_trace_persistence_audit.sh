#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

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

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 131 — FAZ 3-10.1.4 AUDIT TRACE PERSISTENCE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/audittrace/audit_trace_persistence.go"
TEST_FILE="internal/erp/turkiye/tdhp/audittrace/audit_trace_persistence_test.go"
CONFIG_FILE="configs/faz3/tdhp/audit_trace_persistence.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE.md"

check_file "131 audit trace persistence runtime file" "$RUNTIME_FILE"
check_file "131 audit trace persistence test file" "$TEST_FILE"
check_file "131 audit trace persistence config file" "$CONFIG_FILE"
check_file "131 audit trace persistence documentation file" "$DOC_FILE"

check_grep "131 runtime constructor" "$RUNTIME_FILE" "NewAuditTracePersistenceRuntime"
check_grep "131 repository interface" "$RUNTIME_FILE" "type AuditTraceRepository interface"
check_grep "131 in-memory repository" "$RUNTIME_FILE" "type InMemoryAuditTraceRepository"
check_grep "131 audit trace record model" "$RUNTIME_FILE" "type AuditTraceRecord"
check_grep "131 audit trace export model" "$RUNTIME_FILE" "type AuditTraceExport"
check_grep "131 record trace runtime" "$RUNTIME_FILE" "RecordTrace"
check_grep "131 record from posting runtime" "$RUNTIME_FILE" "RecordFromPosting"
check_grep "131 find trace runtime" "$RUNTIME_FILE" "FindTrace"
check_grep "131 list document traces runtime" "$RUNTIME_FILE" "ListDocumentTraces"
check_grep "131 list posting traces runtime" "$RUNTIME_FILE" "ListPostingTraces"
check_grep "131 export tenant trace runtime" "$RUNTIME_FILE" "ExportTenantTrace"

check_grep "131 append operation" "$RUNTIME_FILE" "Append(record AuditTraceRecord)"
check_grep "131 find by trace id operation" "$RUNTIME_FILE" "FindByTraceID"
check_grep "131 find by idempotency operation" "$RUNTIME_FILE" "FindByIdempotencyKey"
check_grep "131 list by tenant operation" "$RUNTIME_FILE" "ListByTenant"
check_grep "131 list by document operation" "$RUNTIME_FILE" "ListByDocument"
check_grep "131 list by posting operation" "$RUNTIME_FILE" "ListByPosting"
check_grep "131 list by date range operation" "$RUNTIME_FILE" "ListByDateRange"

check_grep "131 posting runtime import" "$RUNTIME_FILE" "postingruntime"
check_grep "131 append-only guard" "$RUNTIME_FILE" "audit trace persistence must be append-only"
check_grep "131 duplicate trace id guard" "$RUNTIME_FILE" "trace_id already exists"
check_grep "131 duplicate idempotency guard" "$RUNTIME_FILE" "idempotency_key already exists"
check_grep "131 tenant trace key" "$RUNTIME_FILE" "tenantTraceKey"
check_grep "131 tenant idempotency key" "$RUNTIME_FILE" "tenantIdempotencyKey"
check_grep "131 export hash builder" "$RUNTIME_FILE" "buildExportHash"

check_grep "131 voucher built action" "$RUNTIME_FILE" "VOUCHER_BUILT"
check_grep "131 posting prepared action" "$RUNTIME_FILE" "POSTING_PREPARED"
check_grep "131 posting posted action" "$RUNTIME_FILE" "POSTING_POSTED"
check_grep "131 posting reversed action" "$RUNTIME_FILE" "POSTING_REVERSED"
check_grep "131 reconciliation action" "$RUNTIME_FILE" "RECONCILIATION_MATCHED"
check_grep "131 manual review action" "$RUNTIME_FILE" "MANUAL_REVIEW_QUEUED"

check_grep "131 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "131 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "131 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "131 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "131 trace id guard" "$RUNTIME_FILE" "trace_id is required"
check_grep "131 source guard" "$RUNTIME_FILE" "source is not allowed"
check_grep "131 action guard" "$RUNTIME_FILE" "action is not allowed"
check_grep "131 document or posting or reconciliation guard" "$RUNTIME_FILE" "document_id or posting_id or reconciliation_id is required"
check_grep "131 currency guard" "$RUNTIME_FILE" "currency_code is required"
check_grep "131 debit amount guard" "$RUNTIME_FILE" "total_debit_kurus cannot be negative"
check_grep "131 credit amount guard" "$RUNTIME_FILE" "total_credit_kurus cannot be negative"
check_grep "131 evidence file guard" "$RUNTIME_FILE" "evidence_file_path is required"
check_grep "131 evidence hash guard" "$RUNTIME_FILE" "evidence_hash is required"
check_grep "131 request hash guard" "$RUNTIME_FILE" "request_hash is required"
check_grep "131 result hash guard" "$RUNTIME_FILE" "result_hash is required"
check_grep "131 before snapshot guard" "$RUNTIME_FILE" "before_snapshot_hash is required"
check_grep "131 after snapshot guard" "$RUNTIME_FILE" "after_snapshot_hash is required"
check_grep "131 actor id guard" "$RUNTIME_FILE" "actor_id is required"
check_grep "131 actor role guard" "$RUNTIME_FILE" "actor_role is required"

check_grep "131 record from posting test" "$TEST_FILE" "TestRecordFromPostingPersistsTrace"
check_grep "131 tenant scoped find test" "$TEST_FILE" "TestFindTraceIsTenantScoped"
check_grep "131 duplicate idempotency test" "$TEST_FILE" "TestDuplicateIdempotencyRejected"
check_grep "131 duplicate trace id test" "$TEST_FILE" "TestDuplicateTraceIDRejected"
check_grep "131 list traces test" "$TEST_FILE" "TestListDocumentAndPostingTraces"
check_grep "131 export test" "$TEST_FILE" "TestExportTenantTraceAggregatesDocumentPostingSource"
check_grep "131 evidence hash validation test" "$TEST_FILE" "TestValidationRejectsMissingEvidenceHash"
check_grep "131 snapshot hash validation test" "$TEST_FILE" "TestValidationRejectsMissingSnapshotHash"
check_grep "131 actor validation test" "$TEST_FILE" "TestValidationRejectsMissingActor"

check_grep "131 config persistence enabled" "$CONFIG_FILE" "\"persistence_enabled\": true"
check_grep "131 config append only" "$CONFIG_FILE" "\"append_only\": true"
check_grep "131 config idempotency required" "$CONFIG_FILE" "\"idempotency_required\": true"
check_grep "131 config evidence hash required" "$CONFIG_FILE" "\"evidence_hash_required\": true"
check_grep "131 config snapshot hash required" "$CONFIG_FILE" "\"snapshot_hash_required\": true"
check_grep "131 config actor required" "$CONFIG_FILE" "\"actor_required\": true"
check_grep "131 config document posting source" "$CONFIG_FILE" "DOCUMENT_BASED_POSTING_RUNTIME"
check_grep "131 config posting posted action" "$CONFIG_FILE" "POSTING_POSTED"
check_grep "131 config next gate" "$CONFIG_FILE" "FAZ_3_10_1_5_RECONCILIATION_RUNTIME"

if go test ./internal/erp/turkiye/tdhp/audittrace; then
  pass "131 audit trace persistence Go test status"
else
  fail "131 audit trace persistence Go test status"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 131 — FAZ 3-10.1.4 — Audit Trace Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_5_READY=${NEXT_READY}

## Scope

- Audit trace record model
- Audit trace export model
- Audit trace repository contract
- In-memory repository implementation
- Record trace
- Record from posting
- Find trace
- Document trace listing
- Posting trace listing
- Tenant trace export
- Idempotency uniqueness guard
- Trace ID uniqueness guard
- Evidence file/hash guard
- Request/result hash guard
- Before/after snapshot hash guard
- Actor guard
- Tenant-scoped lookup/export
- Append-only persistence

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 131 — FAZ 3-10.1.4 AUDIT TRACE PERSISTENCE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
