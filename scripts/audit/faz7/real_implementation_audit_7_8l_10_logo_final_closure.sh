#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_10_LOGO_CONNECTOR_FINAL_CLOSURE_PROVIDER_LIVE_HANDOFF_GATE.md"
CONFIG_FILE="configs/faz7/logo_final_closure_provider_live_handoff.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/logo/logo_import_delivery.go"
VALIDATION_FILE="internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go"
ADMIN_OPS_FILE="internal/platform/integrations/providers/logo/logo_admin_ops.go"
E2E_FILE="internal/platform/integrations/providers/logo/logo_e2e_dry_run.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_final_closure.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_final_closure_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_final_closure.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_10_LOGO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_10_logo_final_closure_audit_counts.env"
TMP_BODY="$(mktemp)"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

pass() {
  local label="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "${label} IMPLEMENTED_OR_PRESENT / OK ✅"
  echo "- ${label}: IMPLEMENTED_OR_PRESENT / OK" >> "$TMP_BODY"
}

fail() {
  local label="$1"
  local detail="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "${label} REQUIRED_FAIL / ERROR ❌ :: ${detail}"
  echo "- ${label}: REQUIRED_FAIL :: ${detail}" >> "$TMP_BODY"
}

check_file() {
  local label="$1"
  local file="$2"
  if [ -s "$file" ]; then
    pass "$label"
  else
    fail "$label" "$file missing or empty"
  fi
}

check_dir() {
  local label="$1"
  local dir="$2"
  if [ -d "$dir" ]; then
    pass "$label"
  else
    fail "$label" "$dir missing"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -s "$file" ] && grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label" "pattern not found: ${pattern}"
  fi
}

check_json() {
  local label="$1"
  local file="$2"
  if python3 -m json.tool "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label" "invalid json: ${file}"
  fi
}

check_absent_file() {
  local label="$1"
  local file="$2"
  if [ ! -e "$file" ]; then
    pass "$label"
  else
    fail "$label" "wrong file exists: ${file}"
  fi
}

echo "===== 7-8L.10 LOGO FINAL CLOSURE REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.10.1 doc artifact" "$DOC_FILE"
check_file "7-8L.10.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.10.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.10.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.10.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.10.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.10.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.10.8 file generation runtime dependency" "$FILE_GENERATION_FILE"
check_file "7-8L.10.9 import delivery runtime dependency" "$IMPORT_DELIVERY_FILE"
check_file "7-8L.10.10 validation retry-DLQ runtime dependency" "$VALIDATION_FILE"
check_file "7-8L.10.11 admin ops runtime dependency" "$ADMIN_OPS_FILE"
check_file "7-8L.10.12 E2E dry-run runtime dependency" "$E2E_FILE"
check_file "7-8L.10.13 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.10.14 Go test artifact" "$TEST_FILE"
check_json "7-8L.10.15 config json validity" "$CONFIG_FILE"

check_grep "7-8L.10.16 module marker in doc" "$DOC_FILE" "FAZ 7-8L.10"
check_grep "7-8L.10.17 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.10.18 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_final_closure.go"
check_grep "7-8L.10.19 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_final_closure_test.go"
check_grep "7-8L.10.20 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.10.21 closure mode in doc" "$DOC_FILE" "Closure mode: FINAL_CLOSURE_PROVIDER_LIVE_HANDOFF_GATE"
check_grep "7-8L.10.22 final seal in doc" "$DOC_FILE" "LOGO_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED"
check_grep "7-8L.10.23 provider live handoff in doc" "$DOC_FILE" "LOGO_PROVIDER_LIVE_HANDOFF_GATE=READY_FOR_PROVIDER_LIVE_MODULE"
check_grep "7-8L.10.24 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.10.25 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.10.26 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.10.27 real secret forbidden in doc" "$DOC_FILE" "LOGO_REAL_SECRET_VALUE_STATUS=FORBIDDEN_IN_CODE_CONFIG_DOCS"
check_grep "7-8L.10.28 FAZ 7-9 hold in doc" "$DOC_FILE" "FAZ_7_9_HOLD_STATUS=HOLD_UNTIL_INTEGRATION_FAMILY_DONE"
check_grep "7-8L.10.29 provider live prerequisites in doc" "$DOC_FILE" "Provider Live Module Ön Şartları"
check_grep "7-8L.10.30 legal approval in doc" "$DOC_FILE" "Legal approval"
check_grep "7-8L.10.31 security approval in doc" "$DOC_FILE" "Security approval"
check_grep "7-8L.10.32 final operation in doc" "$DOC_FILE" "RETURN_TO_FAZ_7_8_INTEGRATION_FAMILY"
check_grep "7-8L.10.33 next module marker in doc" "$DOC_FILE" "sıradaki provider-specific modüle"

check_grep "7-8L.10.34 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.10.35 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.10\""
check_grep "7-8L.10.36 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.10.37 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.10.38 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_final_closure.go\""
check_grep "7-8L.10.39 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_final_closure_test.go\""
check_grep "7-8L.10.40 closure mode in config" "$CONFIG_FILE" "\"closure_mode\": \"FINAL_CLOSURE_PROVIDER_LIVE_HANDOFF_GATE\""
check_grep "7-8L.10.41 final closure status in config" "$CONFIG_FILE" "\"final_closure_status\": \"PASS\""
check_grep "7-8L.10.42 module final seal in config" "$CONFIG_FILE" "\"module_final_seal_status\": \"SEALED\""
check_grep "7-8L.10.43 dry-run module sealed in config" "$CONFIG_FILE" "\"dry_run_module_status\": \"SEALED\""
check_grep "7-8L.10.44 provider live handoff gate in config" "$CONFIG_FILE" "\"provider_live_handoff_gate\": \"READY_FOR_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.10.45 required step seals in config" "$CONFIG_FILE" "\"required_step_seals\""
check_grep "7-8L.10.46 7-8L.1 seal in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.1\""
check_grep "7-8L.10.47 7-8L.9 seal in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.9\""
check_grep "7-8L.10.48 live handoff requirements in config" "$CONFIG_FILE" "\"provider_live_handoff_requirements\""
check_grep "7-8L.10.49 legal pending in config" "$CONFIG_FILE" "\"legal_approval_status\": \"PENDING_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.10.50 finance pending in config" "$CONFIG_FILE" "\"finance_approval_status\": \"PENDING_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.10.51 security pending in config" "$CONFIG_FILE" "\"security_approval_status\": \"PENDING_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.10.52 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.10.53 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.10.54 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
check_grep "7-8L.10.55 real secret forbidden in config" "$CONFIG_FILE" "\"real_secret_value_status\": \"FORBIDDEN_IN_CODE_CONFIG_DOCS\""
check_grep "7-8L.10.56 FAZ 7-9 hold in config" "$CONFIG_FILE" "\"faz_7_9_hold_status\": \"HOLD_UNTIL_INTEGRATION_FAMILY_DONE\""
check_grep "7-8L.10.57 next provider ready in config" "$CONFIG_FILE" "\"faz_7_8_next_provider_module_ready\": \"YES\""
check_grep "7-8L.10.58 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.10.59 real provider live disabled in config" "$CONFIG_FILE" "\"real_provider_live_allowed\": false"
check_grep "7-8L.10.60 return operation in config" "$CONFIG_FILE" "\"name\": \"RETURN_TO_FAZ_7_8_INTEGRATION_FAMILY\""

check_grep "7-8L.10.61 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.10.62 final closure contract struct" "$CODE_FILE" "type LogoFinalClosureContract struct"
check_grep "7-8L.10.63 required step seal type" "$CODE_FILE" "type LogoRequiredStepSeal struct"
check_grep "7-8L.10.64 provider live requirements type" "$CODE_FILE" "type LogoProviderLiveHandoffRequirements struct"
check_grep "7-8L.10.65 final closure rules type" "$CODE_FILE" "type LogoFinalClosureRules struct"
check_grep "7-8L.10.66 final closure operation type" "$CODE_FILE" "type LogoFinalClosureOperationContract struct"
check_grep "7-8L.10.67 final summary type" "$CODE_FILE" "type LogoFinalClosureSummary struct"
check_grep "7-8L.10.68 constructor" "$CODE_FILE" "func NewLogoFinalClosureContract() LogoFinalClosureContract"
check_grep "7-8L.10.69 validator" "$CODE_FILE" "func (c LogoFinalClosureContract) Validate() error"
check_grep "7-8L.10.70 real integrations closed guard" "$CODE_FILE" "func (c LogoFinalClosureContract) RealIntegrationsClosed() bool"
check_grep "7-8L.10.71 required step seals validator" "$CODE_FILE" "func (c LogoFinalClosureContract) ValidateRequiredStepSeals() error"
check_grep "7-8L.10.72 operations validator" "$CODE_FILE" "func (c LogoFinalClosureContract) ValidateOperations() error"
check_grep "7-8L.10.73 summary builder" "$CODE_FILE" "func (c LogoFinalClosureContract) BuildSummary()"
check_grep "7-8L.10.74 E2E dependency" "$CODE_FILE" "NewLogoE2EDryRunContract"
check_grep "7-8L.10.75 final seal const" "$CODE_FILE" "LogoConnectorModuleFinalSealStatus"
check_grep "7-8L.10.76 provider handoff const" "$CODE_FILE" "LogoProviderLiveHandoffGate"
check_grep "7-8L.10.77 pending provider live const" "$CODE_FILE" "PENDING_PROVIDER_LIVE_MODULE"
check_grep "7-8L.10.78 FAZ 7-9 hold const" "$CODE_FILE" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE"
check_grep "7-8L.10.79 real provider live denied model" "$CODE_FILE" "RealProviderLiveAllowed"
check_grep "7-8L.10.80 return operation const" "$CODE_FILE" "RETURN_TO_FAZ_7_8_INTEGRATION_FAMILY"
check_grep "7-8L.10.81 real secret closed guard" "$CODE_FILE" "LogoRealSecretValueStatus"
check_grep "7-8L.10.82 real delivery channel closed guard" "$CODE_FILE" "LogoRealDeliveryChannelStatus"

check_grep "7-8L.10.83 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.10.84 readiness test" "$TEST_FILE" "TestLogoFinalClosureContractReadiness"
check_grep "7-8L.10.85 integrations closed test" "$TEST_FILE" "TestLogoFinalClosureKeepsRealIntegrationsClosed"
check_grep "7-8L.10.86 step seals test" "$TEST_FILE" "TestLogoFinalClosureValidatesAllRequiredStepSeals"
check_grep "7-8L.10.87 handoff gate test" "$TEST_FILE" "TestLogoFinalClosureProviderLiveHandoffGate"
check_grep "7-8L.10.88 summary test" "$TEST_FILE" "TestLogoFinalClosureBuildsSummary"
check_grep "7-8L.10.89 real provider live rejection test" "$TEST_FILE" "TestLogoFinalClosureRejectsRealProviderLiveAllowed"
check_grep "7-8L.10.90 missing step seal rejection test" "$TEST_FILE" "TestLogoFinalClosureRejectsMissingStepSeal"

check_absent_file "7-8L.10.91 runtime flat Logo final closure file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.10 Logo Final Closure Real Implementation Audit"
  echo
  echo "## Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  echo
  echo "## Evidence"
  echo
  cat "$TMP_BODY"
} > "$EVIDENCE_FILE"

cat <<COUNT_EOF > "$COUNT_FILE"
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}
COUNT_EOF

echo "===== 7-8L.10 LOGO FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_10_LOGO_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_10_LOGO_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
