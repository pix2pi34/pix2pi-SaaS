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

echo "===== 115 — FAZ 3-10.3.6 EBELGE LIVE INTEGRATION TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/ebelge/liveintegrationtests/ebelge_live_integration_suite.go"
TEST_FILE="internal/erp/turkiye/ebelge/liveintegrationtests/ebelge_live_integration_suite_test.go"
CONFIG_FILE="configs/faz3/ebelge/e_belge_live_integration_tests.v1.json"
DOC_FILE="docs/faz3/ebelge/FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS.md"

check_file "115 e-Belge live integration suite file" "$SUITE_FILE"
check_file "115 e-Belge live integration test file" "$TEST_FILE"
check_file "115 e-Belge live integration config file" "$CONFIG_FILE"
check_file "115 e-Belge live integration documentation file" "$DOC_FILE"

check_grep "115 suite constructor" "$SUITE_FILE" "NewLiveIntegrationSuite"
check_grep "115 live gate validation" "$SUITE_FILE" "ValidateLiveGate"
check_grep "115 send document validation" "$SUITE_FILE" "ValidateSendDocument"
check_grep "115 status check validation" "$SUITE_FILE" "ValidateStatusCheck"
check_grep "115 cancel document validation" "$SUITE_FILE" "ValidateCancelDocument"
check_grep "115 download artifact validation" "$SUITE_FILE" "ValidateDownloadArtifact"
check_grep "115 callback validation" "$SUITE_FILE" "ValidateCallback"
check_grep "115 poll plan validation" "$SUITE_FILE" "ValidatePollPlan"
check_grep "115 retry DLQ validation" "$SUITE_FILE" "ValidateRetryAndDLQ"
check_grep "115 readiness matrix runtime" "$SUITE_FILE" "RunReadinessMatrix"

check_grep "115 e-Fatura document support" "$SUITE_FILE" "E_FATURA"
check_grep "115 e-Arşiv document support" "$SUITE_FILE" "E_ARSIV"
check_grep "115 e-Adisyon document support" "$SUITE_FILE" "E_ADISYON"

check_grep "115 live provider gate closed guard" "$SUITE_FILE" "production e-belge live provider access is closed"
check_grep "115 credential ref guard" "$SUITE_FILE" "credential_ref is required"
check_grep "115 raw secret policy guard" "$SUITE_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "115 raw secret material guard" "$SUITE_FILE" "raw secret material"
check_grep "115 tenant guard" "$SUITE_FILE" "tenant_id is required"
check_grep "115 correlation guard" "$SUITE_FILE" "correlation_id is required"
check_grep "115 request guard" "$SUITE_FILE" "request_id is required"
check_grep "115 idempotency guard" "$SUITE_FILE" "idempotency_key is required"
check_grep "115 document id guard" "$SUITE_FILE" "document_id is required"
check_grep "115 document no guard" "$SUITE_FILE" "document_no is required"
check_grep "115 provider payload hash guard" "$SUITE_FILE" "provider_payload_hash is required"
check_grep "115 UBL hash guard" "$SUITE_FILE" "ubl_hash is required"
check_grep "115 artifact hash guard" "$SUITE_FILE" "ARTIFACT_HASH_REQUIRED"
check_grep "115 callback signature guard" "$SUITE_FILE" "CALLBACK_SIGNATURE_REQUIRED"
check_grep "115 callback payload hash guard" "$SUITE_FILE" "CALLBACK_PAYLOAD_HASH_REQUIRED"
check_grep "115 cancel reason guard" "$SUITE_FILE" "CANCEL_REASON_REQUIRED"
check_grep "115 retry error code guard" "$SUITE_FILE" "ERROR_CODE_REQUIRED"
check_grep "115 DLQ route status" "$SUITE_FILE" "DLQ"
check_grep "115 manual review readiness" "$SUITE_FILE" "ManualReviewReady"

check_grep "115 e-Fatura live readiness test" "$TEST_FILE" "TestEFaturaLiveReadinessMatrix"
check_grep "115 e-Arşiv live readiness test" "$TEST_FILE" "TestEArsivLiveReadinessMatrix"
check_grep "115 e-Adisyon live readiness test" "$TEST_FILE" "TestEAdisyonLiveReadinessMatrix"
check_grep "115 callback poll retry DLQ test" "$TEST_FILE" "TestCallbackPollRetryAndDLQReadiness"
check_grep "115 readiness matrix coverage test" "$TEST_FILE" "TestReadinessMatrixCoversAllDocuments"
check_grep "115 live gate denied test" "$TEST_FILE" "TestLiveGateDeniesProductionWithoutApprovals"
check_grep "115 raw secret policy violation test" "$TEST_FILE" "TestRejectsRawSecretPolicyViolation"

check_grep "115 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "115 config real provider gate closed" "$CONFIG_FILE" "\"real_provider_gate_open\": false"
check_grep "115 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "115 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "115 config e-Fatura support" "$CONFIG_FILE" "E_FATURA"
check_grep "115 config e-Arşiv support" "$CONFIG_FILE" "E_ARSIV"
check_grep "115 config e-Adisyon support" "$CONFIG_FILE" "E_ADISYON"
check_grep "115 config actual provider request not allowed" "$CONFIG_FILE" "NOT_ALLOWED_IN_THIS_PHASE"
check_grep "115 config next gate" "$CONFIG_FILE" "FAZ_3_R_NEXT_PRIORITY_READY"

if go test ./internal/erp/turkiye/ebelge/liveintegrationtests; then
  pass "115 e-Belge live integration Go test status"
else
  fail "115 e-Belge live integration Go test status"
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
# 115 — FAZ 3-10.3.6 — e-Belge Live Integration Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}

## Scope

- e-Fatura live readiness
- e-Arşiv live readiness
- e-Adisyon live readiness
- Send / status / cancel / download readiness
- Callback signature readiness
- Poll readiness
- Retry readiness
- DLQ readiness
- Manual review readiness
- Live provider gate guard
- Credential ref only guard
- Raw secret policy guard

## Live Policy

- Real provider API remains closed
- Production approved remains false
- Actual GIB / private integrator request is not allowed in this phase

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 115 — FAZ 3-10.3.6 EBELGE LIVE INTEGRATION TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
