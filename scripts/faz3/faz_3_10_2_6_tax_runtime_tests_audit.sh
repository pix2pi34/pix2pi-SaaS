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

echo "===== 127 — FAZ 3-10.2.6 TAX RUNTIME TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/tax/runtimetests/tax_runtime_test_suite.go"
TEST_FILE="internal/erp/turkiye/tax/runtimetests/tax_runtime_test_suite_test.go"
CONFIG_FILE="configs/faz3/tax/tax_runtime_tests.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_6_TAX_RUNTIME_TESTS.md"

check_file "127 tax runtime test suite file" "$SUITE_FILE"
check_file "127 tax runtime test file" "$TEST_FILE"
check_file "127 tax runtime config file" "$CONFIG_FILE"
check_file "127 tax runtime documentation file" "$DOC_FILE"

check_grep "127 suite constructor" "$SUITE_FILE" "NewTaxRuntimeTestSuite"
check_grep "127 KDV runtime wired" "$SUITE_FILE" "KDVRuntime"
check_grep "127 Stopaj runtime wired" "$SUITE_FILE" "StopajRuntime"
check_grep "127 Exemption runtime wired" "$SUITE_FILE" "ExemptionRuntime"
check_grep "127 Rollout runtime wired" "$SUITE_FILE" "RolloutRuntime"
check_grep "127 Audit runtime wired" "$SUITE_FILE" "AuditRuntime"

check_grep "127 KDV request helper" "$SUITE_FILE" "KDVOutputRequest"
check_grep "127 Stopaj request helper" "$SUITE_FILE" "StopajRentRequest"
check_grep "127 Exemption request helper" "$SUITE_FILE" "KDVFullExemptionRequest"
check_grep "127 Tax rollout request helper" "$SUITE_FILE" "TaxRolloutRequest"
check_grep "127 KDV audit record helper" "$SUITE_FILE" "AuditRecordFromKDV"
check_grep "127 Stopaj audit record helper" "$SUITE_FILE" "AuditRecordFromStopaj"
check_grep "127 Exemption audit record helper" "$SUITE_FILE" "AuditRecordFromExemption"
check_grep "127 Rollout audit record helper" "$SUITE_FILE" "AuditRecordFromRollout"

check_grep "127 KDV config coverage" "$SUITE_FILE" "TR_KDV_2026_V1"
check_grep "127 Stopaj config coverage" "$SUITE_FILE" "TR_STOPAJ_2026_V1"
check_grep "127 Exemption config coverage" "$SUITE_FILE" "TR_TAX_EXEMPTION_2026_V1"
check_grep "127 KDV account output coverage" "$SUITE_FILE" "391.01.20"
check_grep "127 KDV account input coverage" "$SUITE_FILE" "191.01.20"
check_grep "127 Stopaj account coverage" "$SUITE_FILE" "360.01"

check_grep "127 happy path E2E test" "$TEST_FILE" "TestTaxRuntimeSuiteKDVStopajExemptionRolloutAndAuditPersistence"
check_grep "127 failure path test" "$TEST_FILE" "TestTaxRuntimeSuiteFailurePathsProtectTaxRuntime"
check_grep "127 KDV execute test" "$TEST_FILE" "KDVRuntime.Execute"
check_grep "127 Stopaj execute test" "$TEST_FILE" "StopajRuntime.Execute"
check_grep "127 Exemption execute test" "$TEST_FILE" "ExemptionRuntime.Execute"
check_grep "127 Rollout prepare test" "$TEST_FILE" "RolloutRuntime.PrepareRollout"
check_grep "127 Audit record test" "$TEST_FILE" "AuditRuntime.Record"
check_grep "127 Audit export test" "$TEST_FILE" "ExportTenantAuditTrail"
check_grep "127 KDV currency failure path" "$TEST_FILE" "currency mismatch"
check_grep "127 Stopaj tenant failure path" "$TEST_FILE" "tenant validation"
check_grep "127 Exemption reason failure path" "$TEST_FILE" "EXEMPTION_REASON_REQUIRED"
check_grep "127 Canary allowlist failure path" "$TEST_FILE" "CANARY_TENANT_ALLOWLIST_REQUIRED"
check_grep "127 duplicate idempotency failure path" "$TEST_FILE" "duplicate idempotency"

check_grep "127 config KDV module" "$CONFIG_FILE" "KDV_RUNTIME_EXECUTION"
check_grep "127 config Stopaj module" "$CONFIG_FILE" "STOPAJ_RUNTIME_EXECUTION"
check_grep "127 config Exemption module" "$CONFIG_FILE" "TAX_EXEMPTION_RUNTIME_EXECUTION"
check_grep "127 config Rule Rollout module" "$CONFIG_FILE" "TAX_RULE_VERSION_ROLLOUT"
check_grep "127 config Audit Persistence module" "$CONFIG_FILE" "TAX_AUDIT_PERSISTENCE"
check_grep "127 config next gate" "$CONFIG_FILE" "FAZ_3_R_NEXT_PRIORITY_READY"

if go test ./internal/erp/turkiye/tax/runtimetests; then
  pass "127 tax runtime tests Go test status"
else
  fail "127 tax runtime tests Go test status"
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
# 127 — FAZ 3-10.2.6 — Tax Runtime Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_6_TAX_RUNTIME_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_6_TAX_RUNTIME_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}

## Scope

- KDV runtime execution
- Stopaj runtime execution
- Tax exemption runtime execution
- Tax rule version rollout
- Tax audit persistence
- Audit trail export
- Failure path protection

## Test Scenarios

- KDV / Stopaj / Exemption / Rollout / Audit Persistence E2E
- KDV currency mismatch
- Stopaj tenant missing
- Exemption reason missing
- Canary allowlist missing
- Audit duplicate idempotency

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 127 — FAZ 3-10.2.6 TAX RUNTIME TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_6_TAX_RUNTIME_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_6_TAX_RUNTIME_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
