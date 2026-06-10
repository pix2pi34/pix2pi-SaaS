#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_file_generation.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_file_generation_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_file_generation_dry_run.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"

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
  echo "# FAZ 7-8Z.2 Zirve File Generation Dry-Run Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: dry-run export package builder code/config/doc/test/script evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.2 ZIRVE FILE GENERATION DRY-RUN REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.2.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.2.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.2.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.2.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.2.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.2.2.1" "$RUNTIME_FILE" "ZirveFileGenerationModuleCode = \"FAZ_7_8Z_2\"" "runtime declares FAZ 7-8Z.2 module code"
require_contains "7-8Z.2.2.2" "$RUNTIME_FILE" "EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY" "runtime declares dry-run package builder mode"
require_contains "7-8Z.2.2.3" "$RUNTIME_FILE" "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" "runtime declares no external delivery policy"
require_contains "7-8Z.2.2.4" "$RUNTIME_FILE" "BuildDryRunExportPackage" "runtime implements dry-run package builder"
require_contains "7-8Z.2.2.5" "$RUNTIME_FILE" "DeliveryModeFilePackageDryRun" "runtime requires file package dry-run delivery mode"
require_contains "7-8Z.2.2.6" "$RUNTIME_FILE" "RealFileDeliveryAllowed:           false" "runtime keeps real file delivery closed"
require_contains "7-8Z.2.2.7" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:        false" "runtime keeps real delivery channel closed"
require_contains "7-8Z.2.2.8" "$RUNTIME_FILE" "RealERPWriteAllowed:               false" "runtime keeps real ERP write closed"
require_contains "7-8Z.2.2.9" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed: false" "runtime keeps real operator provider action closed"
require_contains "7-8Z.2.2.10" "$RUNTIME_FILE" "manifest.json" "runtime builds manifest artifact"
require_contains "7-8Z.2.2.11" "$RUNTIME_FILE" "objects.ndjson" "runtime builds objects ndjson artifact"
require_contains "7-8Z.2.2.12" "$RUNTIME_FILE" "validation_report.json" "runtime builds validation report artifact"
require_contains "7-8Z.2.2.13" "$RUNTIME_FILE" "audit_decision.json" "runtime builds audit decision artifact"
require_contains "7-8Z.2.2.14" "$RUNTIME_FILE" "sha256.Sum256" "runtime generates artifact SHA256 integrity hash"

require_contains "7-8Z.2.3.1" "$TEST_FILE" "TestZirveFileGenerationBuildsDryRunPackage" "test validates dry-run package build"
require_contains "7-8Z.2.3.2" "$TEST_FILE" "TestZirveFileGenerationKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.2.3.3" "$TEST_FILE" "TestZirveFileGenerationRejectsRealDeliveryMode" "test rejects real delivery mode"
require_contains "7-8Z.2.3.4" "$TEST_FILE" "TestZirveFileGenerationRejectsNonDryRun" "test rejects non-dry-run request"
require_contains "7-8Z.2.3.5" "$TEST_FILE" "TestZirveFileGenerationRequiresTenantCorrelationAndObjects" "test validates tenant/correlation/object requirements"
require_contains "7-8Z.2.3.6" "$TEST_FILE" "TestZirveFileGenerationArtifactsAreAuditable" "test validates auditable artifacts"

require_contains "7-8Z.2.4.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_2\"" "config declares module code"
require_contains "7-8Z.2.4.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.2.4.3" "$CONFIG_FILE" "\"delivery_mode\": \"FILE_PACKAGE_DRY_RUN\"" "config declares dry-run file package delivery mode"
require_contains "7-8Z.2.4.4" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.2.4.5" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.2.4.6" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"

require_contains "7-8Z.2.5.1" "$DOC_FILE" "Gerçek Zirve dosya gönderimi" "doc states real Zirve file delivery remains closed"
require_contains "7-8Z.2.5.2" "$DOC_FILE" "Gerçek delivery channel" "doc states real delivery channel remains closed"
require_contains "7-8Z.2.5.3" "$DOC_FILE" "Gerçek ERP write" "doc states real ERP write remains closed"
require_contains "7-8Z.2.5.4" "$DOC_FILE" "FAZ 7-8Z.3" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.2 ZIRVE FILE GENERATION DRY-RUN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
