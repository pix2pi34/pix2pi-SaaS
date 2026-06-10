#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_foundation.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_foundation_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_connector_foundation.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

ok() {
  local code="$1"
  local message="$2"
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '%s %s / OK ✅\n' "$code" "$message"
}

fail() {
  local code="$1"
  local message="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  printf '%s %s / FAIL ❌\n' "$code" "$message"
}

require_file() {
  local code="$1"
  local file="$2"
  local message="$3"
  if [[ -f "$file" ]]; then
    ok "$code" "$message"
  else
    fail "$code" "$message missing: $file"
  fi
}

require_contains() {
  local code="$1"
  local file="$2"
  local needle="$3"
  local message="$4"
  if [[ -f "$file" ]] && grep -qF "$needle" "$file"; then
    ok "$code" "$message"
  else
    fail "$code" "$message missing needle: $needle"
  fi
}

{
  echo "# FAZ 7-8Z Zirve Connector Foundation Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: code/config/doc/test/script real implementation presence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z ZIRVE CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.2.1" "$RUNTIME_FILE" "ProviderID  = \"zirve\"" "runtime declares Zirve provider id"
require_contains "7-8Z.2.2" "$RUNTIME_FILE" "ModuleCode  = \"FAZ_7_8Z\"" "runtime declares FAZ 7-8Z module code"
require_contains "7-8Z.2.3" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "runtime keeps real provider API closed"
require_contains "7-8Z.2.4" "$RUNTIME_FILE" "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "runtime keeps real file delivery closed"
require_contains "7-8Z.2.5" "$RUNTIME_FILE" "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "runtime keeps real ERP write closed"
require_contains "7-8Z.2.6" "$RUNTIME_FILE" "FORBIDDEN_IN_CODE_CONFIG_DOCS" "runtime forbids real secrets in code/config/docs"
require_contains "7-8Z.2.7" "$RUNTIME_FILE" "TENANT_CONTEXT_REQUIRED" "runtime requires tenant safety"
require_contains "7-8Z.2.8" "$RUNTIME_FILE" "AUDIT_DECISION_REQUIRED_FOR_EVERY_OPERATION" "runtime requires audit decision"
require_contains "7-8Z.2.9" "$RUNTIME_FILE" "func (z ZirveProviderIdentity) CanUseRealProviderAPI() bool" "runtime exposes real provider API guard"
require_contains "7-8Z.2.10" "$RUNTIME_FILE" "return false" "runtime has deny-by-default guards"
require_contains "7-8Z.2.11" "$RUNTIME_FILE" "DecideOperation" "runtime has operation decision contract"
require_contains "7-8Z.2.12" "$RUNTIME_FILE" "Readiness" "runtime has readiness projection"

require_contains "7-8Z.3.1" "$TEST_FILE" "TestZirveProviderIdentityValidates" "test validates provider identity"
require_contains "7-8Z.3.2" "$TEST_FILE" "TestZirveRealProviderBoundariesRemainClosed" "test validates real boundaries closed"
require_contains "7-8Z.3.3" "$TEST_FILE" "TestZirveCapabilitiesAndContracts" "test validates capability contracts"
require_contains "7-8Z.3.4" "$TEST_FILE" "TestZirveDryRunOperationDecisions" "test validates operation decisions"
require_contains "7-8Z.3.5" "$TEST_FILE" "TestZirveNoSecretTenantAndAuditPolicies" "test validates security policies"

require_contains "7-8Z.4.1" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.4.2" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z\"" "config declares module code"
require_contains "7-8Z.4.3" "$CONFIG_FILE" "\"real_zirve_api\": false" "config keeps real Zirve API closed"
require_contains "7-8Z.4.4" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.4.5" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.4.6" "$CONFIG_FILE" "\"real_operator_provider_action\": false" "config keeps operator provider action closed"

require_contains "7-8Z.5.1" "$DOC_FILE" "Gerçek Zirve API çağrısı" "doc states real Zirve API remains closed"
require_contains "7-8Z.5.2" "$DOC_FILE" "Gerçek Zirve dosya gönderimi" "doc states real file delivery remains closed"
require_contains "7-8Z.5.3" "$DOC_FILE" "Gerçek ERP write" "doc states real ERP write remains closed"
require_contains "7-8Z.5.4" "$DOC_FILE" "FAZ 7-8Z.2" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z ZIRVE CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
