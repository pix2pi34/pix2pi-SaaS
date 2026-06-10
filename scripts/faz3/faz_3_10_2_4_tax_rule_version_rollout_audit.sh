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

echo "===== 125 — FAZ 3-10.2.4 TAX RULE VERSION ROLLOUT REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tax/rulerollout/tax_rule_version_rollout.go"
TEST_FILE="internal/erp/turkiye/tax/rulerollout/tax_rule_version_rollout_test.go"
CONFIG_FILE="configs/faz3/tax/tax_rule_version_rollout.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT.md"

check_file "125 tax rule rollout runtime file" "$RUNTIME_FILE"
check_file "125 tax rule rollout test file" "$TEST_FILE"
check_file "125 tax rule rollout config file" "$CONFIG_FILE"
check_file "125 tax rule rollout documentation file" "$DOC_FILE"

check_grep "125 runtime constructor" "$RUNTIME_FILE" "NewTaxRuleVersionRolloutRuntime"
check_grep "125 prepare rollout runtime" "$RUNTIME_FILE" "PrepareRollout"
check_grep "125 activate version runtime" "$RUNTIME_FILE" "ActivateVersion"
check_grep "125 rollback version runtime" "$RUNTIME_FILE" "RollbackVersion"
check_grep "125 tax rule version model" "$RUNTIME_FILE" "type TaxRuleVersion"
check_grep "125 rollout request model" "$RUNTIME_FILE" "type RolloutRequest"
check_grep "125 rollback request model" "$RUNTIME_FILE" "type RollbackRequest"
check_grep "125 rollout result model" "$RUNTIME_FILE" "type RolloutResult"
check_grep "125 rollback result model" "$RUNTIME_FILE" "type RollbackResult"

check_grep "125 full rollout strategy" "$RUNTIME_FILE" "FULL"
check_grep "125 canary rollout strategy" "$RUNTIME_FILE" "CANARY"
check_grep "125 blue green rollout strategy" "$RUNTIME_FILE" "BLUE_GREEN"
check_grep "125 rollback strategy" "$RUNTIME_FILE" "ROLLBACK"
check_grep "125 canary started decision" "$RUNTIME_FILE" "CANARY_STARTED"
check_grep "125 activated decision" "$RUNTIME_FILE" "ACTIVATED"
check_grep "125 rolled back decision" "$RUNTIME_FILE" "ROLLED_BACK"

check_grep "125 KDV family support" "$RUNTIME_FILE" "KDV"
check_grep "125 stopaj family support" "$RUNTIME_FILE" "STOPAJ"
check_grep "125 tax exemption family support" "$RUNTIME_FILE" "TAX_EXEMPTION"

check_grep "125 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "125 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "125 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "125 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "125 rollout id guard" "$RUNTIME_FILE" "rollout_id is required"
check_grep "125 rollback id guard" "$RUNTIME_FILE" "rollback_id is required"
check_grep "125 version id guard" "$RUNTIME_FILE" "version_id is required"
check_grep "125 version code guard" "$RUNTIME_FILE" "version_code is required"
check_grep "125 legal reference guard" "$RUNTIME_FILE" "legal_reference is required"
check_grep "125 rule artifact guard" "$RUNTIME_FILE" "rule_artifact_path is required"
check_grep "125 config artifact guard" "$RUNTIME_FILE" "config_artifact_path is required"
check_grep "125 evidence file guard" "$RUNTIME_FILE" "evidence_file_path is required"
check_grep "125 evidence suffix guard" "$RUNTIME_FILE" "evidence_file_path must end with"
check_grep "125 evidence hash guard" "$RUNTIME_FILE" "evidence_hash is required"
check_grep "125 approved by guard" "$RUNTIME_FILE" "approved_by is required"
check_grep "125 approved at guard" "$RUNTIME_FILE" "approved_at is required"
check_grep "125 canary allowlist guard" "$RUNTIME_FILE" "CANARY_TENANT_ALLOWLIST_REQUIRED"
check_grep "125 canary percent guard" "$RUNTIME_FILE" "CANARY_PERCENT_OUT_OF_RANGE"
check_grep "125 rollback reason guard" "$RUNTIME_FILE" "reason_code is required"
check_grep "125 family mismatch guard" "$RUNTIME_FILE" "ROLLBACK_TAX_FAMILY_MISMATCH"

check_grep "125 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "125 config country TR" "$CONFIG_FILE" "\"default_country_code\": \"TR\""
check_grep "125 config approval required" "$CONFIG_FILE" "\"approval_required\": true"
check_grep "125 config legal reference required" "$CONFIG_FILE" "\"legal_reference_required\": true"
check_grep "125 config canary allowed" "$CONFIG_FILE" "\"canary_allowed\": true"
check_grep "125 config rollback allowed" "$CONFIG_FILE" "\"rollback_allowed\": true"
check_grep "125 config KDV family" "$CONFIG_FILE" "KDV"
check_grep "125 config STOPAJ family" "$CONFIG_FILE" "STOPAJ"
check_grep "125 config TAX_EXEMPTION family" "$CONFIG_FILE" "TAX_EXEMPTION"
check_grep "125 config next gate" "$CONFIG_FILE" "FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE"

if go test ./internal/erp/turkiye/tax/rulerollout; then
  pass "125 tax rule rollout Go test status"
else
  fail "125 tax rule rollout Go test status"
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
# 125 — FAZ 3-10.2.4 — Tax Rule Version Rollout Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_2_5_READY=${NEXT_READY}

## Scope

- Tax rule version model
- Full rollout
- Canary rollout
- Blue/green rollout readiness
- Activate version
- Rollback version
- Legal reference guard
- Approval guard
- Evidence file/hash guard
- Artifact path guard
- Country TR guard
- Canary percent guard
- Canary tenant allowlist guard
- Rollback reason guard
- Version family consistency guard
- Runtime/config/audit switch readiness

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 125 — FAZ 3-10.2.4 TAX RULE VERSION ROLLOUT COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_2_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
