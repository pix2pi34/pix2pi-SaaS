#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_import_delivery.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_import_delivery_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_import_delivery_contract.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md"

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

mkdir -p "$(dirname "$EVIDENCE_FILE")"

{
  echo "# FAZ 7-8Z.3 Zirve Import Delivery Contract Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: import delivery contract code/config/doc/test/script evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.3 ZIRVE IMPORT DELIVERY CONTRACT REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.3.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.3.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.3.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.3.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.3.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.3.2.1" "$RUNTIME_FILE" "ZirveImportDeliveryModuleCode     = \"FAZ_7_8Z_3\"" "runtime declares FAZ 7-8Z.3 module code"
require_contains "7-8Z.3.2.2" "$RUNTIME_FILE" "IMPORT_PACKAGE_DELIVERY_CONTRACT_DRY_RUN_ONLY" "runtime declares import delivery contract dry-run mode"
require_contains "7-8Z.3.2.3" "$RUNTIME_FILE" "READY_DRY_RUN_ONLY" "runtime declares dry-run-only contract status"
require_contains "7-8Z.3.2.4" "$RUNTIME_FILE" "PLACEHOLDER_ONLY" "runtime declares placeholder-only delivery channel status"
require_contains "7-8Z.3.2.5" "$RUNTIME_FILE" "BuildDryRunImportDeliveryContract" "runtime implements dry-run import delivery contract builder"
require_contains "7-8Z.3.2.6" "$RUNTIME_FILE" "validateZirveDryRunExportPackageForDelivery" "runtime validates upstream 7-8Z.2 export package"
require_contains "7-8Z.3.2.7" "$RUNTIME_FILE" "ZirveDeliveryChannelLocalPackage" "runtime requires local package placeholder channel"
require_contains "7-8Z.3.2.8" "$RUNTIME_FILE" "RealProviderAPIAllowed:" "runtime exposes real provider API guard"
require_contains "7-8Z.3.2.9" "$RUNTIME_FILE" "RealFileDeliveryAllowed:" "runtime exposes real file delivery guard"
require_contains "7-8Z.3.2.10" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:" "runtime exposes real delivery channel guard"
require_contains "7-8Z.3.2.11" "$RUNTIME_FILE" "RealERPWriteAllowed:" "runtime exposes real ERP write guard"
require_contains "7-8Z.3.2.12" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed:" "runtime exposes real operator provider action guard"
require_contains "7-8Z.3.2.13" "$RUNTIME_FILE" "delivery_manifest.json" "runtime builds delivery manifest artifact"
require_contains "7-8Z.3.2.14" "$RUNTIME_FILE" "delivery_handoff.json" "runtime builds delivery handoff artifact"
require_contains "7-8Z.3.2.15" "$RUNTIME_FILE" "delivery_audit_decision.json" "runtime builds delivery audit decision artifact"
require_contains "7-8Z.3.2.16" "$RUNTIME_FILE" "fingerprintZirvePackageArtifacts" "runtime fingerprints upstream package artifacts"
require_contains "7-8Z.3.2.17" "$RUNTIME_FILE" "external_delivery_attempted" "runtime records external delivery not attempted"

require_contains "7-8Z.3.3.1" "$TEST_FILE" "TestZirveImportDeliveryBuildsDryRunContract" "test validates dry-run import delivery contract build"
require_contains "7-8Z.3.3.2" "$TEST_FILE" "TestZirveImportDeliveryKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.3.3.3" "$TEST_FILE" "TestZirveImportDeliveryRejectsProviderLiveChannel" "test rejects provider live delivery channel"
require_contains "7-8Z.3.3.4" "$TEST_FILE" "TestZirveImportDeliveryRejectsNonDryRun" "test rejects non-dry-run request"
require_contains "7-8Z.3.3.5" "$TEST_FILE" "TestZirveImportDeliveryRejectsTenantMismatch" "test rejects tenant mismatch"
require_contains "7-8Z.3.3.6" "$TEST_FILE" "TestZirveImportDeliveryRejectsInvalidPackage" "test rejects invalid upstream package"
require_contains "7-8Z.3.3.7" "$TEST_FILE" "TestZirveImportDeliveryArtifactsAreAuditable" "test validates auditable delivery artifacts"

require_contains "7-8Z.3.4.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_3\"" "config declares module code"
require_contains "7-8Z.3.4.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.3.4.3" "$CONFIG_FILE" "\"contract_mode\": \"IMPORT_PACKAGE_DELIVERY_CONTRACT_DRY_RUN_ONLY\"" "config declares contract mode"
require_contains "7-8Z.3.4.4" "$CONFIG_FILE" "\"delivery_channel\": \"LOCAL_PACKAGE_PLACEHOLDER\"" "config declares local package placeholder channel"
require_contains "7-8Z.3.4.5" "$CONFIG_FILE" "\"delivery_channel_status\": \"PLACEHOLDER_ONLY\"" "config declares placeholder-only channel status"
require_contains "7-8Z.3.4.6" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.3.4.7" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.3.4.8" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.3.4.9" "$CONFIG_FILE" "\"external_delivery_attempted\": false" "config states external delivery not attempted"

require_contains "7-8Z.3.5.1" "$DOC_FILE" "Gerçek Zirve dosya gönderimi" "doc states real Zirve file delivery remains closed"
require_contains "7-8Z.3.5.2" "$DOC_FILE" "Gerçek delivery channel" "doc states real delivery channel remains closed"
require_contains "7-8Z.3.5.3" "$DOC_FILE" "Gerçek ERP write" "doc states real ERP write remains closed"
require_contains "7-8Z.3.5.4" "$DOC_FILE" "FAZ 7-8Z.4" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.3 ZIRVE IMPORT DELIVERY CONTRACT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
