#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_8_LOGO_ADMIN_OPS_MANUAL_REVIEW.md"
CONFIG_FILE="configs/faz7/logo_admin_ops_manual_review.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/logo/logo_import_delivery.go"
VALIDATION_FILE="internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_admin_ops.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_admin_ops_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_admin_ops.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_8_LOGO_ADMIN_OPS_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_8_logo_admin_ops_audit_counts.env"
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

echo "===== 7-8L.8 LOGO ADMIN OPS REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.8.1 doc artifact" "$DOC_FILE"
check_file "7-8L.8.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.8.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.8.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.8.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.8.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.8.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.8.8 file generation runtime dependency" "$FILE_GENERATION_FILE"
check_file "7-8L.8.9 import delivery runtime dependency" "$IMPORT_DELIVERY_FILE"
check_file "7-8L.8.10 validation retry-DLQ runtime dependency" "$VALIDATION_FILE"
check_file "7-8L.8.11 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.8.12 Go test artifact" "$TEST_FILE"
check_json "7-8L.8.13 config json validity" "$CONFIG_FILE"

check_grep "7-8L.8.14 module marker in doc" "$DOC_FILE" "FAZ 7-8L.8"
check_grep "7-8L.8.15 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.8.16 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_admin_ops.go"
check_grep "7-8L.8.17 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_admin_ops_test.go"
check_grep "7-8L.8.18 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.8.19 admin ops mode in doc" "$DOC_FILE" "Admin ops mode: ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY"
check_grep "7-8L.8.20 manual review queue in doc" "$DOC_FILE" "Manual review queue"
check_grep "7-8L.8.21 assign action in doc" "$DOC_FILE" "ASSIGN_LOGO_MANUAL_REVIEW"
check_grep "7-8L.8.22 resolve action in doc" "$DOC_FILE" "RESOLVE_LOGO_MANUAL_REVIEW"
check_grep "7-8L.8.23 reject action in doc" "$DOC_FILE" "REJECT_LOGO_MANUAL_REVIEW"
check_grep "7-8L.8.24 tenant safe boundary in doc" "$DOC_FILE" "Tenant-Safe Review Boundary"
check_grep "7-8L.8.25 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.8.26 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.8.27 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.8.28 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.9"

check_grep "7-8L.8.29 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.8.30 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.8\""
check_grep "7-8L.8.31 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.8.32 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.8.33 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_admin_ops.go\""
check_grep "7-8L.8.34 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_admin_ops_test.go\""
check_grep "7-8L.8.35 admin ops mode in config" "$CONFIG_FILE" "\"admin_ops_mode\": \"ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY\""
check_grep "7-8L.8.36 admin ops status in config" "$CONFIG_FILE" "\"admin_ops_status\": \"READY\""
check_grep "7-8L.8.37 queue status in config" "$CONFIG_FILE" "\"manual_review_queue_status\": \"READY\""
check_grep "7-8L.8.38 manual review contract in config" "$CONFIG_FILE" "\"manual_review_contract\""
check_grep "7-8L.8.39 operations in config" "$CONFIG_FILE" "\"operations\""
check_grep "7-8L.8.40 assign operation in config" "$CONFIG_FILE" "\"name\": \"ASSIGN_LOGO_MANUAL_REVIEW\""
check_grep "7-8L.8.41 resolve operation in config" "$CONFIG_FILE" "\"name\": \"RESOLVE_LOGO_MANUAL_REVIEW\""
check_grep "7-8L.8.42 reject operation in config" "$CONFIG_FILE" "\"name\": \"REJECT_LOGO_MANUAL_REVIEW\""
check_grep "7-8L.8.43 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.8.44 real file delivery disabled in config" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
check_grep "7-8L.8.45 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.8.46 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.8.47 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.8.48 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""

check_grep "7-8L.8.49 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.8.50 admin ops contract struct" "$CODE_FILE" "type LogoAdminOpsContract struct"
check_grep "7-8L.8.51 manual review item type" "$CODE_FILE" "type LogoManualReviewItem struct"
check_grep "7-8L.8.52 admin ops runtime type" "$CODE_FILE" "type LogoAdminOpsRuntime struct"
check_grep "7-8L.8.53 operation contract type" "$CODE_FILE" "type LogoAdminOpsOperationContract struct"
check_grep "7-8L.8.54 admin ops constructor" "$CODE_FILE" "func NewLogoAdminOpsContract() LogoAdminOpsContract"
check_grep "7-8L.8.55 admin ops validator" "$CODE_FILE" "func (c LogoAdminOpsContract) Validate() error"
check_grep "7-8L.8.56 runtime constructor" "$CODE_FILE" "func NewLogoAdminOpsRuntime() LogoAdminOpsRuntime"
check_grep "7-8L.8.57 create review method" "$CODE_FILE" "func (r *LogoAdminOpsRuntime) CreateManualReviewItem"
check_grep "7-8L.8.58 list review method" "$CODE_FILE" "func (r LogoAdminOpsRuntime) ListManualReviews"
check_grep "7-8L.8.59 read review method" "$CODE_FILE" "func (r LogoAdminOpsRuntime) ReadManualReview"
check_grep "7-8L.8.60 assign review method" "$CODE_FILE" "func (r *LogoAdminOpsRuntime) AssignManualReview"
check_grep "7-8L.8.61 resolve review method" "$CODE_FILE" "func (r *LogoAdminOpsRuntime) ResolveManualReview"
check_grep "7-8L.8.62 reject review method" "$CODE_FILE" "func (r *LogoAdminOpsRuntime) RejectManualReview"
check_grep "7-8L.8.63 tenant boundary error" "$CODE_FILE" "cross-tenant manual review access denied"
check_grep "7-8L.8.64 OPEN status" "$CODE_FILE" "OPEN"
check_grep "7-8L.8.65 ASSIGNED status" "$CODE_FILE" "ASSIGNED"
check_grep "7-8L.8.66 RESOLVED status" "$CODE_FILE" "RESOLVED"
check_grep "7-8L.8.67 REJECTED status" "$CODE_FILE" "REJECTED"
check_grep "7-8L.8.68 unknown provider reason" "$CODE_FILE" "UNKNOWN_PROVIDER_ERROR"
check_grep "7-8L.8.69 external call denied model" "$CODE_FILE" "ExternalCallAllowed"
check_grep "7-8L.8.70 real file delivery denied model" "$CODE_FILE" "RealFileDeliveryAllowed"
check_grep "7-8L.8.71 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.8.72 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.8.73 readiness test" "$TEST_FILE" "TestLogoAdminOpsContractReadiness"
check_grep "7-8L.8.74 integrations closed test" "$TEST_FILE" "TestLogoAdminOpsKeepsRealIntegrationsClosed"
check_grep "7-8L.8.75 create review test" "$TEST_FILE" "TestLogoManualReviewItemCreation"
check_grep "7-8L.8.76 tenant list/read test" "$TEST_FILE" "TestLogoManualReviewTenantSafeListAndRead"
check_grep "7-8L.8.77 assign resolve test" "$TEST_FILE" "TestLogoManualReviewAssignAndResolve"
check_grep "7-8L.8.78 reject test" "$TEST_FILE" "TestLogoManualReviewReject"
check_grep "7-8L.8.79 cross-tenant rejected test" "$TEST_FILE" "TestLogoManualReviewCrossTenantReadRejected"
check_grep "7-8L.8.80 invalid transition test" "$TEST_FILE" "TestLogoManualReviewInvalidTransitionRejected"
check_grep "7-8L.8.81 external op rejection test" "$TEST_FILE" "TestLogoAdminOpsRejectsExternalOperation"
check_grep "7-8L.8.82 file delivery rejection test" "$TEST_FILE" "TestLogoAdminOpsRejectsRealFileDeliveryOperation"
check_grep "7-8L.8.83 ERP write rejection test" "$TEST_FILE" "TestLogoAdminOpsRejectsERPWriteOperation"

check_absent_file "7-8L.8.84 runtime flat Logo admin ops file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.8 Logo Admin Ops Real Implementation Audit"
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

echo "===== 7-8L.8 LOGO ADMIN OPS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_8_LOGO_ADMIN_OPS_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_8_LOGO_ADMIN_OPS_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
