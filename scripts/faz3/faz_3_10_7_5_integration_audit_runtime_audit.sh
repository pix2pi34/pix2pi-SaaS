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

echo "===== 120 — FAZ 3-10.7.5 INTEGRATION AUDIT RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/integrationaudit/integration_audit_runtime.go"
TEST_FILE="internal/erp/turkiye/payment/integrationaudit/integration_audit_runtime_test.go"
CONFIG_FILE="configs/faz3/payment/integration_audit_runtime.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME.md"

check_file "120 integration audit runtime file" "$RUNTIME_FILE"
check_file "120 integration audit test file" "$TEST_FILE"
check_file "120 integration audit config file" "$CONFIG_FILE"
check_file "120 integration audit documentation file" "$DOC_FILE"

check_grep "120 runtime constructor" "$RUNTIME_FILE" "NewIntegrationAuditRuntime"
check_grep "120 register audit event runtime" "$RUNTIME_FILE" "RegisterAuditEvent"
check_grep "120 evaluate evidence bundle runtime" "$RUNTIME_FILE" "EvaluateEvidenceBundle"
check_grep "120 audit event model" "$RUNTIME_FILE" "type IntegrationAuditEvent"
check_grep "120 audit result model" "$RUNTIME_FILE" "type IntegrationAuditResult"
check_grep "120 evidence bundle model" "$RUNTIME_FILE" "type EvidenceBundle"
check_grep "120 evidence bundle result model" "$RUNTIME_FILE" "type EvidenceBundleResult"
check_grep "120 production provider gate guard" "$RUNTIME_FILE" "production real provider audit access is closed"
check_grep "120 fail blocks closure policy" "$RUNTIME_FILE" "FailBlocksClosure"
check_grep "120 warn requires review policy" "$RUNTIME_FILE" "WarnRequiresReview"
check_grep "120 minimum pass count policy" "$RUNTIME_FILE" "MinimumPassCountForReadiness"
check_grep "120 required scope missing guard" "$RUNTIME_FILE" "REQUIRED_AUDIT_SCOPE_MISSING"
check_grep "120 minimum pass count guard" "$RUNTIME_FILE" "MINIMUM_PASS_COUNT_NOT_MET"
check_grep "120 fail count blocks closure guard" "$RUNTIME_FILE" "FAIL_COUNT_BLOCKS_CLOSURE"

check_grep "120 POS provider scope" "$RUNTIME_FILE" "POS_PROVIDER_RUNTIME"
check_grep "120 bank collection scope" "$RUNTIME_FILE" "BANK_COLLECTION_RUNTIME"
check_grep "120 reconciliation scope" "$RUNTIME_FILE" "RECONCILIATION_RUNTIME"
check_grep "120 refund cancel scope" "$RUNTIME_FILE" "REFUND_CANCEL_RUNTIME"
check_grep "120 payment status sync scope" "$RUNTIME_FILE" "PAYMENT_STATUS_SYNC"
check_grep "120 payment error retry scope" "$RUNTIME_FILE" "PAYMENT_ERROR_RETRY_RUNTIME"
check_grep "120 payment integration E2E scope" "$RUNTIME_FILE" "PAYMENT_INTEGRATION_E2E"

check_grep "120 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "120 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "120 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "120 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "120 audit event id guard" "$RUNTIME_FILE" "audit_event_id is required"
check_grep "120 audit source guard" "$RUNTIME_FILE" "audit source is required"
check_grep "120 check name guard" "$RUNTIME_FILE" "check_name is required"
check_grep "120 artifact path guard" "$RUNTIME_FILE" "artifact_path is required"
check_grep "120 evidence file path guard" "$RUNTIME_FILE" "evidence_file_path is required"
check_grep "120 evidence hash guard" "$RUNTIME_FILE" "evidence_hash is required"
check_grep "120 pass fail mismatch guard" "$RUNTIME_FILE" "PASS audit event cannot have fail_count greater than zero"
check_grep "120 fail count required guard" "$RUNTIME_FILE" "FAIL audit event must have fail_count greater than zero"

check_grep "120 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "120 config real provider gate closed" "$CONFIG_FILE" "\"real_provider_gate_open\": false"
check_grep "120 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "120 config fail blocks closure" "$CONFIG_FILE" "\"fail_blocks_closure\": true"
check_grep "120 config warn requires review" "$CONFIG_FILE" "\"warn_requires_review\": true"
check_grep "120 config evidence hash required" "$CONFIG_FILE" "\"evidence_hash_required\": true"
check_grep "120 config required POS scope" "$CONFIG_FILE" "POS_PROVIDER_RUNTIME"
check_grep "120 config required reconciliation scope" "$CONFIG_FILE" "RECONCILIATION_RUNTIME"
check_grep "120 config required E2E scope" "$CONFIG_FILE" "PAYMENT_INTEGRATION_E2E"
check_grep "120 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "120 config next gate" "$CONFIG_FILE" "FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS"

if go test ./internal/erp/turkiye/payment/integrationaudit; then
  pass "120 integration audit Go test status"
else
  fail "120 integration audit Go test status"
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
# 120 — FAZ 3-10.7.5 — Integration Audit Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_6_READY=${NEXT_READY}

## Scope

- Audit event registration
- Evidence bundle evaluation
- Required scope coverage
- Pass / fail / warn counter validation
- Evidence hash guard
- Artifact path guard
- Evidence file path guard
- Fail blocks closure policy
- Warn requires review policy
- Minimum pass count readiness policy
- Production real provider gate closed
- Tenant / correlation / request / idempotency guards

## Required Scopes

- POS provider runtime
- Bank collection runtime
- Reconciliation runtime
- Refund / cancel runtime
- Payment status sync
- Payment error / retry runtime
- Payment integration E2E

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 120 — FAZ 3-10.7.5 INTEGRATION AUDIT RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
