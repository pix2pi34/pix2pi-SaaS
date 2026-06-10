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

echo "===== 126 — FAZ 3-10.2.5 TAX AUDIT PERSISTENCE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tax/auditpersistence/tax_audit_persistence.go"
TEST_FILE="internal/erp/turkiye/tax/auditpersistence/tax_audit_persistence_test.go"
CONFIG_FILE="configs/faz3/tax/tax_audit_persistence.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE.md"

check_file "126 tax audit persistence runtime file" "$RUNTIME_FILE"
check_file "126 tax audit persistence test file" "$TEST_FILE"
check_file "126 tax audit persistence config file" "$CONFIG_FILE"
check_file "126 tax audit persistence documentation file" "$DOC_FILE"

check_grep "126 runtime constructor" "$RUNTIME_FILE" "NewTaxAuditPersistenceRuntime"
check_grep "126 repository interface" "$RUNTIME_FILE" "type TaxAuditRepository interface"
check_grep "126 in-memory repository" "$RUNTIME_FILE" "type InMemoryTaxAuditRepository"
check_grep "126 audit record model" "$RUNTIME_FILE" "type TaxAuditRecord"
check_grep "126 audit export model" "$RUNTIME_FILE" "type TaxAuditExport"
check_grep "126 append operation" "$RUNTIME_FILE" "Append(record TaxAuditRecord)"
check_grep "126 find by audit id operation" "$RUNTIME_FILE" "FindByAuditID"
check_grep "126 find by idempotency operation" "$RUNTIME_FILE" "FindByIdempotencyKey"
check_grep "126 list by tenant operation" "$RUNTIME_FILE" "ListByTenant"
check_grep "126 list by tax family operation" "$RUNTIME_FILE" "ListByTaxFamily"
check_grep "126 list by date range operation" "$RUNTIME_FILE" "ListByDateRange"
check_grep "126 export tenant audit trail operation" "$RUNTIME_FILE" "ExportTenantAuditTrail"

check_grep "126 append-only guard" "$RUNTIME_FILE" "tax audit persistence must be append-only"
check_grep "126 duplicate audit id guard" "$RUNTIME_FILE" "audit_id already exists"
check_grep "126 duplicate idempotency guard" "$RUNTIME_FILE" "idempotency_key already exists"
check_grep "126 tenant scoped audit key" "$RUNTIME_FILE" "tenantAuditKey"
check_grep "126 tenant scoped idempotency key" "$RUNTIME_FILE" "tenantIdempotencyKey"
check_grep "126 export hash builder" "$RUNTIME_FILE" "buildExportHash"

check_grep "126 KDV family support" "$RUNTIME_FILE" "KDV"
check_grep "126 stopaj family support" "$RUNTIME_FILE" "STOPAJ"
check_grep "126 tax exemption family support" "$RUNTIME_FILE" "TAX_EXEMPTION"
check_grep "126 KDV action support" "$RUNTIME_FILE" "KDV_CALCULATED"
check_grep "126 stopaj action support" "$RUNTIME_FILE" "STOPAJ_CALCULATED"
check_grep "126 exemption action support" "$RUNTIME_FILE" "EXEMPTION_APPLIED"
check_grep "126 rollout action support" "$RUNTIME_FILE" "RULE_VERSION_ACTIVATED"

check_grep "126 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "126 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "126 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "126 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "126 audit id guard" "$RUNTIME_FILE" "audit_id is required"
check_grep "126 rule version guard" "$RUNTIME_FILE" "rule_version is required"
check_grep "126 document or target version guard" "$RUNTIME_FILE" "document_id or target_rule_version is required"
check_grep "126 tax base non-negative guard" "$RUNTIME_FILE" "tax_base_amount_kurus cannot be negative"
check_grep "126 tax amount non-negative guard" "$RUNTIME_FILE" "tax_amount_kurus cannot be negative"
check_grep "126 evidence file path guard" "$RUNTIME_FILE" "evidence_file_path is required"
check_grep "126 evidence hash guard" "$RUNTIME_FILE" "evidence_hash is required"
check_grep "126 request hash guard" "$RUNTIME_FILE" "request_hash is required"
check_grep "126 result hash guard" "$RUNTIME_FILE" "result_hash is required"
check_grep "126 actor id guard" "$RUNTIME_FILE" "actor_id is required"
check_grep "126 actor role guard" "$RUNTIME_FILE" "actor_role is required"
check_grep "126 created at guard" "$RUNTIME_FILE" "created_at is required"

check_grep "126 config persistence enabled" "$CONFIG_FILE" "\"persistence_enabled\": true"
check_grep "126 config append only" "$CONFIG_FILE" "\"append_only\": true"
check_grep "126 config idempotency required" "$CONFIG_FILE" "\"idempotency_required\": true"
check_grep "126 config evidence hash required" "$CONFIG_FILE" "\"evidence_hash_required\": true"
check_grep "126 config actor required" "$CONFIG_FILE" "\"actor_required\": true"
check_grep "126 config KDV family" "$CONFIG_FILE" "KDV"
check_grep "126 config STOPAJ family" "$CONFIG_FILE" "STOPAJ"
check_grep "126 config TAX_EXEMPTION family" "$CONFIG_FILE" "TAX_EXEMPTION"
check_grep "126 config next gate" "$CONFIG_FILE" "FAZ_3_10_2_6_TAX_RUNTIME_TESTS"

if go test ./internal/erp/turkiye/tax/auditpersistence; then
  pass "126 tax audit persistence Go test status"
else
  fail "126 tax audit persistence Go test status"
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
# 126 — FAZ 3-10.2.5 — Tax Audit Persistence Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_2_6_READY=${NEXT_READY}

## Scope

- Tax audit record model
- Tax audit export model
- Tax audit repository contract
- In-memory repository implementation
- Append-only persistence
- Tenant-scoped lookup
- Tenant-scoped export
- Idempotency uniqueness guard
- Audit ID uniqueness guard
- Evidence file / hash guard
- Request hash / result hash guard
- Rule version guard
- Actor guard
- Amount non-negative guard
- Export aggregation totals
- Export hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 126 — FAZ 3-10.2.5 TAX AUDIT PERSISTENCE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_2_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
