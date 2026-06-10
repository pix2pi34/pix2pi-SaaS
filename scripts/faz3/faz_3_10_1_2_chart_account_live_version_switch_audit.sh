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

echo "===== 129 — FAZ 3-10.1.2 CHART ACCOUNT LIVE VERSION SWITCH REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/accountswitch/chart_account_live_version_switch.go"
TEST_FILE="internal/erp/turkiye/tdhp/accountswitch/chart_account_live_version_switch_test.go"
CONFIG_FILE="configs/faz3/tdhp/chart_account_live_version_switch.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH.md"

check_file "129 chart account live switch runtime file" "$RUNTIME_FILE"
check_file "129 chart account live switch test file" "$TEST_FILE"
check_file "129 chart account live switch config file" "$CONFIG_FILE"
check_file "129 chart account live switch documentation file" "$DOC_FILE"

check_grep "129 runtime constructor" "$RUNTIME_FILE" "NewChartAccountLiveSwitchRuntime"
check_grep "129 prepare switch runtime" "$RUNTIME_FILE" "PrepareSwitch"
check_grep "129 activate switch runtime" "$RUNTIME_FILE" "ActivateSwitch"
check_grep "129 rollback switch runtime" "$RUNTIME_FILE" "RollbackSwitch"
check_grep "129 resolve account runtime" "$RUNTIME_FILE" "ResolveAccount"

check_grep "129 chart version model" "$RUNTIME_FILE" "type ChartVersion"
check_grep "129 account rule model" "$RUNTIME_FILE" "type ChartAccountRule"
check_grep "129 switch request model" "$RUNTIME_FILE" "type SwitchRequest"
check_grep "129 rollback request model" "$RUNTIME_FILE" "type RollbackRequest"
check_grep "129 switch result model" "$RUNTIME_FILE" "type SwitchResult"
check_grep "129 rollback result model" "$RUNTIME_FILE" "type RollbackResult"
check_grep "129 resolve request model" "$RUNTIME_FILE" "type ResolveRequest"
check_grep "129 resolve result model" "$RUNTIME_FILE" "type ResolveResult"

check_grep "129 full switch strategy" "$RUNTIME_FILE" "FULL"
check_grep "129 canary switch strategy" "$RUNTIME_FILE" "CANARY"
check_grep "129 blue green switch strategy" "$RUNTIME_FILE" "BLUE_GREEN"
check_grep "129 rollback strategy" "$RUNTIME_FILE" "ROLLBACK"
check_grep "129 canary started decision" "$RUNTIME_FILE" "CANARY_STARTED"
check_grep "129 activated decision" "$RUNTIME_FILE" "ACTIVATED"
check_grep "129 rolled back decision" "$RUNTIME_FILE" "ROLLED_BACK"

check_grep "129 TDHP 120 purpose" "$RUNTIME_FILE" "RECEIVABLE"
check_grep "129 TDHP 600 purpose" "$RUNTIME_FILE" "SALES"
check_grep "129 TDHP 391 purpose" "$RUNTIME_FILE" "OUTPUT_KDV"
check_grep "129 TDHP 191 purpose" "$RUNTIME_FILE" "INPUT_KDV"
check_grep "129 TDHP 320 purpose" "$RUNTIME_FILE" "PAYABLE"
check_grep "129 TDHP 102 purpose" "$RUNTIME_FILE" "BANK"

check_grep "129 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "129 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "129 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "129 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "129 switch id guard" "$RUNTIME_FILE" "switch_id is required"
check_grep "129 rollback id guard" "$RUNTIME_FILE" "rollback_id is required"
check_grep "129 version id guard" "$RUNTIME_FILE" "version_id is required"
check_grep "129 version code guard" "$RUNTIME_FILE" "version_code is required"
check_grep "129 country guard" "$RUNTIME_FILE" "country_code mismatch"
check_grep "129 currency guard" "$RUNTIME_FILE" "currency_code mismatch"
check_grep "129 legal reference guard" "$RUNTIME_FILE" "legal_reference is required"
check_grep "129 chart artifact guard" "$RUNTIME_FILE" "chart_artifact_path is required"
check_grep "129 mapping artifact guard" "$RUNTIME_FILE" "mapping_artifact_path is required"
check_grep "129 config artifact guard" "$RUNTIME_FILE" "config_artifact_path is required"
check_grep "129 evidence file guard" "$RUNTIME_FILE" "evidence_file_path is required"
check_grep "129 evidence hash guard" "$RUNTIME_FILE" "evidence_hash is required"
check_grep "129 approved by guard" "$RUNTIME_FILE" "approved_by is required"
check_grep "129 approved at guard" "$RUNTIME_FILE" "approved_at is required"
check_grep "129 account code prefix validation" "$RUNTIME_FILE" "must start with required_prefix"
check_grep "129 required purpose coverage" "$RUNTIME_FILE" "required account purpose missing"
check_grep "129 canary allowlist guard" "$RUNTIME_FILE" "CANARY_TENANT_ALLOWLIST_REQUIRED"
check_grep "129 canary percent guard" "$RUNTIME_FILE" "CANARY_PERCENT_OUT_OF_RANGE"
check_grep "129 rollback reason guard" "$RUNTIME_FILE" "reason_code is required"

check_grep "129 prepare full test" "$TEST_FILE" "TestPrepareFullSwitchReady"
check_grep "129 prepare canary test" "$TEST_FILE" "TestPrepareCanarySwitchStarted"
check_grep "129 activate test" "$TEST_FILE" "TestActivateSwitch"
check_grep "129 rollback test" "$TEST_FILE" "TestRollbackSwitch"
check_grep "129 resolve account test" "$TEST_FILE" "TestResolveAccount"
check_grep "129 invalid account prefix test" "$TEST_FILE" "TestValidateRejectsInvalidAccountPrefix"
check_grep "129 missing evidence hash test" "$TEST_FILE" "TestValidateRejectsMissingEvidenceHash"

check_grep "129 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "129 config country TR" "$CONFIG_FILE" "\"default_country_code\": \"TR\""
check_grep "129 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "129 config canary allowed" "$CONFIG_FILE" "\"canary_allowed\": true"
check_grep "129 config rollback allowed" "$CONFIG_FILE" "\"rollback_allowed\": true"
check_grep "129 config 120 prefix" "$CONFIG_FILE" "\"RECEIVABLE\": \"120\""
check_grep "129 config 600 prefix" "$CONFIG_FILE" "\"SALES\": \"600\""
check_grep "129 config 391 prefix" "$CONFIG_FILE" "\"OUTPUT_KDV\": \"391\""
check_grep "129 config 191 prefix" "$CONFIG_FILE" "\"INPUT_KDV\": \"191\""
check_grep "129 config next gate" "$CONFIG_FILE" "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME"

if go test ./internal/erp/turkiye/tdhp/accountswitch; then
  pass "129 chart account live switch Go test status"
else
  fail "129 chart account live switch Go test status"
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
# 129 — FAZ 3-10.1.2 — Chart Account Live Version Switch Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_3_READY=${NEXT_READY}

## Scope

- Chart version model
- Account mapping rule model
- Full switch
- Canary switch
- Blue/green switch readiness
- Activate switch
- Rollback switch
- Resolve account by active version
- Legal reference guard
- Approval guard
- Evidence file/hash guard
- Artifact path guard
- Country TR guard
- Currency TRY guard
- Required account purpose coverage
- TDHP prefix validation
- Canary percent guard
- Canary tenant allowlist guard
- Rollback reason guard

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 129 — FAZ 3-10.1.2 CHART ACCOUNT LIVE VERSION SWITCH COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_2_CHART_ACCOUNT_LIVE_VERSION_SWITCH_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
