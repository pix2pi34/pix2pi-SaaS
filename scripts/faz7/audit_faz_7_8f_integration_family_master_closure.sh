#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/family/integration_family_master_closure.go"
TEST_FILE="internal/platform/integrations/family/integration_family_master_closure_test.go"
CONFIG_FILE="configs/faz7/integrations/integration_family_master_closure.json"
DOC_FILE="docs/faz7/integrations/FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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

warn() {
  local code="$1"
  local message="$2"
  OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
  printf '%s %s / WARN ⚠️\n' "$code" "$message"
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

require_dir() {
  local code="$1"
  local dir="$2"
  local message="$3"
  if [[ -d "$dir" ]]; then
    ok "$code" "$message"
  else
    fail "$code" "$message missing: $dir"
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

require_any_file() {
  local code="$1"
  local message="$2"
  shift 2

  local candidate
  for candidate in "$@"; do
    if [[ -f "$candidate" ]]; then
      ok "$code" "$message found: $candidate"
      return 0
    fi
  done

  fail "$code" "$message no candidate file found"
  return 1
}

mkdir -p "$(dirname "$EVIDENCE_FILE")"

{
  echo "# FAZ 7-8F Integration Family Master Closure Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: family master closure code/config/doc/test/script and provider family final closure evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8F INTEGRATION FAMILY MASTER CLOSURE REAL IMPLEMENTATION AUDIT ====="

require_file "7-8F.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8F.1.2" "$TEST_FILE" "test file exists"
require_file "7-8F.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8F.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8F.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_dir "7-8F.2.1" "internal/platform/integrations/providers/parasut" "Paraşüt provider directory exists"
require_dir "7-8F.2.2" "internal/platform/integrations/providers/logo" "Logo provider directory exists"
require_dir "7-8F.2.3" "internal/platform/integrations/providers/mikro" "Mikro provider directory exists"
require_dir "7-8F.2.4" "internal/platform/integrations/providers/zirve" "Zirve provider directory exists"

require_any_file "7-8F.3.1" "Paraşüt final closure evidence" \
  "docs/faz7/evidence/FAZ_7_8P_12_PARASUT_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

require_any_file "7-8F.3.2" "Logo final closure evidence" \
  "docs/faz7/evidence/FAZ_7_8L_10_LOGO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

require_any_file "7-8F.3.3" "Mikro final closure evidence" \
  "docs/faz7/evidence/FAZ_7_8M_7_MIKRO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

require_any_file "7-8F.3.4" "Zirve final closure evidence" \
  "docs/faz7/evidence/FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

require_contains "7-8F.4.1" "$RUNTIME_FILE" "IntegrationFamilyMasterModuleCode = \"FAZ_7_8F\"" "runtime declares FAZ 7-8F module code"
require_contains "7-8F.4.2" "$RUNTIME_FILE" "INTEGRATION_FAMILY_MASTER_CLOSURE" "runtime declares master closure mode"
require_contains "7-8F.4.3" "$RUNTIME_FILE" "PARASUT_LOGO_MIKRO_ZIRVE" "runtime declares required provider set"
require_contains "7-8F.4.4" "$RUNTIME_FILE" "READY_FOR_PROVIDER_SPECIFIC_LIVE_MODULES" "runtime declares provider-specific live module gate"
require_contains "7-8F.4.5" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULES" "runtime keeps real operations closed until provider live modules"
require_contains "7-8F.4.6" "$RUNTIME_FILE" "DefaultProviderFamilySeals" "runtime declares provider family seals"
require_contains "7-8F.4.7" "$RUNTIME_FILE" "ProviderParasut" "runtime includes Paraşüt provider"
require_contains "7-8F.4.8" "$RUNTIME_FILE" "ProviderLogo" "runtime includes Logo provider"
require_contains "7-8F.4.9" "$RUNTIME_FILE" "ProviderMikro" "runtime includes Mikro provider"
require_contains "7-8F.4.10" "$RUNTIME_FILE" "ProviderZirve" "runtime includes Zirve provider"
require_contains "7-8F.4.11" "$RUNTIME_FILE" "CanReleaseFaz79Hold" "runtime exposes FAZ 7-9 hold release decision"
require_contains "7-8F.4.12" "$RUNTIME_FILE" "DecideIntegrationFamilyOperation" "runtime exposes decision model"

require_contains "7-8F.5.1" "$TEST_FILE" "TestIntegrationFamilyMasterClosureReportValidates" "test validates master closure report"
require_contains "7-8F.5.2" "$TEST_FILE" "TestIntegrationFamilyMasterClosureRequiresAllProviders" "test validates all providers"
require_contains "7-8F.5.3" "$TEST_FILE" "TestIntegrationFamilyMasterClosureKeepsAllRealOperationsClosed" "test validates real operations closed"
require_contains "7-8F.5.4" "$TEST_FILE" "TestIntegrationFamilyMasterClosureCanReleaseFaz79Hold" "test validates FAZ 7-9 hold release"
require_contains "7-8F.5.5" "$TEST_FILE" "TestIntegrationFamilyMasterClosureRejectsMissingProvider" "test rejects missing provider"
require_contains "7-8F.5.6" "$TEST_FILE" "TestIntegrationFamilyMasterClosureRejectsUnsealedProvider" "test rejects unsealed provider"
require_contains "7-8F.5.7" "$TEST_FILE" "TestIntegrationFamilyMasterClosureRejectsRealOperationsOpen" "test rejects open real operations"
require_contains "7-8F.5.8" "$TEST_FILE" "TestIntegrationFamilyMasterClosureDecisionModel" "test validates decision model"

require_contains "7-8F.6.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8F\"" "config declares module code"
require_contains "7-8F.6.2" "$CONFIG_FILE" "\"provider_dry_run_set\": \"PARASUT_LOGO_MIKRO_ZIRVE\"" "config declares provider dry-run set"
require_contains "7-8F.6.3" "$CONFIG_FILE" "\"required_provider_count\": 4" "config declares required provider count"
require_contains "7-8F.6.4" "$CONFIG_FILE" "\"provider_id\": \"parasut\"" "config includes Paraşüt"
require_contains "7-8F.6.5" "$CONFIG_FILE" "\"provider_id\": \"logo\"" "config includes Logo"
require_contains "7-8F.6.6" "$CONFIG_FILE" "\"provider_id\": \"mikro\"" "config includes Mikro"
require_contains "7-8F.6.7" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config includes Zirve"
require_contains "7-8F.6.8" "$CONFIG_FILE" "\"all_real_provider_apis_closed\": true" "config keeps all real provider APIs closed"
require_contains "7-8F.6.9" "$CONFIG_FILE" "\"all_real_file_deliveries_closed\": true" "config keeps all real file deliveries closed"
require_contains "7-8F.6.10" "$CONFIG_FILE" "\"all_real_erp_writes_closed\": true" "config keeps all real ERP writes closed"
require_contains "7-8F.6.11" "$CONFIG_FILE" "\"faz_7_9_hold_status\": \"READY_TO_RELEASE\"" "config prepares FAZ 7-9 hold release"
require_contains "7-8F.6.12" "$CONFIG_FILE" "\"faz_7_9_ready\": \"YES\"" "config marks FAZ 7-9 ready"

require_contains "7-8F.7.1" "$DOC_FILE" "Paraşüt Connector Dry-Run Family" "doc includes Paraşüt family"
require_contains "7-8F.7.2" "$DOC_FILE" "Logo Connector Dry-Run Family" "doc includes Logo family"
require_contains "7-8F.7.3" "$DOC_FILE" "Mikro Connector Dry-Run Family" "doc includes Mikro family"
require_contains "7-8F.7.4" "$DOC_FILE" "Zirve Connector Dry-Run Family" "doc includes Zirve family"
require_contains "7-8F.7.5" "$DOC_FILE" "FAZ_7_9_HOLD_STATUS=READY_TO_RELEASE" "doc declares FAZ 7-9 hold release"
require_contains "7-8F.7.6" "$DOC_FILE" "FAZ 7-9 — Accountant Portal Commercial Surface" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8F INTEGRATION FAMILY MASTER CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8F_INTEGRATION_FAMILY_MASTER_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
