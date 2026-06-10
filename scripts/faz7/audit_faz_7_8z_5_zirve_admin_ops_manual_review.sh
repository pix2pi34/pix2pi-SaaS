#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_admin_ops.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_admin_ops_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_admin_ops_manual_review.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"

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
  echo "# FAZ 7-8Z.5 Zirve Admin Ops Manual Review Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: admin/ops manual review queue code/config/doc/test/script evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.5 ZIRVE ADMIN OPS MANUAL REVIEW REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.5.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.5.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.5.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.5.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.5.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.5.2.1" "$RUNTIME_FILE" "ZirveAdminOpsModuleCode   = \"FAZ_7_8Z_5\"" "runtime declares FAZ 7-8Z.5 module code"
require_contains "7-8Z.5.2.2" "$RUNTIME_FILE" "ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY" "runtime declares admin ops dry-run mode"
require_contains "7-8Z.5.2.3" "$RUNTIME_FILE" "QUEUE_VALIDATION_DLQ_AND_MANUAL_REVIEW_DECISIONS" "runtime declares queue policy"
require_contains "7-8Z.5.2.4" "$RUNTIME_FILE" "ASSIGN_RESOLVE_REJECT_DRY_RUN_ONLY" "runtime declares action policy"
require_contains "7-8Z.5.2.5" "$RUNTIME_FILE" "EVERY_REVIEW_ACTION_REQUIRES_AUDIT_DECISION" "runtime declares audit policy"
require_contains "7-8Z.5.2.6" "$RUNTIME_FILE" "OpenManualReview" "runtime implements open manual review"
require_contains "7-8Z.5.2.7" "$RUNTIME_FILE" "ListTenantManualReviews" "runtime implements tenant-safe review list"
require_contains "7-8Z.5.2.8" "$RUNTIME_FILE" "GetTenantManualReview" "runtime implements tenant-safe review read"
require_contains "7-8Z.5.2.9" "$RUNTIME_FILE" "ApplyManualReviewAction" "runtime implements manual review actions"
require_contains "7-8Z.5.2.10" "$RUNTIME_FILE" "ZirveManualReviewActionAssign" "runtime supports assign action"
require_contains "7-8Z.5.2.11" "$RUNTIME_FILE" "ZirveManualReviewActionResolve" "runtime supports resolve action"
require_contains "7-8Z.5.2.12" "$RUNTIME_FILE" "ZirveManualReviewActionReject" "runtime supports reject action"
require_contains "7-8Z.5.2.13" "$RUNTIME_FILE" "manual review tenant boundary violation" "runtime has tenant boundary guard"
require_contains "7-8Z.5.2.14" "$RUNTIME_FILE" "pass/retry decisions are not eligible" "runtime rejects pass/retry decisions"
require_contains "7-8Z.5.2.15" "$RUNTIME_FILE" "manual review is already closed" "runtime rejects closed review mutation"
require_contains "7-8Z.5.2.16" "$RUNTIME_FILE" "RealProviderAPIAllowed:            false" "runtime keeps real provider API closed"
require_contains "7-8Z.5.2.17" "$RUNTIME_FILE" "RealFileDeliveryAllowed:           false" "runtime keeps real file delivery closed"
require_contains "7-8Z.5.2.18" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:        false" "runtime keeps real delivery channel closed"
require_contains "7-8Z.5.2.19" "$RUNTIME_FILE" "RealERPWriteAllowed:               false" "runtime keeps real ERP write closed"
require_contains "7-8Z.5.2.20" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed: false" "runtime keeps real operator provider action closed"

require_contains "7-8Z.5.3.1" "$TEST_FILE" "TestZirveAdminOpsOpensManualReview" "test validates opening manual review"
require_contains "7-8Z.5.3.2" "$TEST_FILE" "TestZirveAdminOpsQueuesDLQAndDenyDecisions" "test validates DLQ and DENY queueing"
require_contains "7-8Z.5.3.3" "$TEST_FILE" "TestZirveAdminOpsKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.5.3.4" "$TEST_FILE" "TestZirveAdminOpsTenantSafeListAndRead" "test validates tenant-safe read/list"
require_contains "7-8Z.5.3.5" "$TEST_FILE" "TestZirveAdminOpsAssignAndResolveReview" "test validates assign and resolve"
require_contains "7-8Z.5.3.6" "$TEST_FILE" "TestZirveAdminOpsRejectReview" "test validates reject action"
require_contains "7-8Z.5.3.7" "$TEST_FILE" "TestZirveAdminOpsRejectsPassDecision" "test rejects PASS decision"
require_contains "7-8Z.5.3.8" "$TEST_FILE" "TestZirveAdminOpsRejectsNonDryRunAction" "test rejects non-dry-run action"
require_contains "7-8Z.5.3.9" "$TEST_FILE" "TestZirveAdminOpsRejectsClosedReviewMutation" "test rejects closed review mutation"

require_contains "7-8Z.5.4.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_5\"" "config declares module code"
require_contains "7-8Z.5.4.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.5.4.3" "$CONFIG_FILE" "\"mode\": \"ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY\"" "config declares dry-run mode"
require_contains "7-8Z.5.4.4" "$CONFIG_FILE" "\"queue_policy\": \"QUEUE_VALIDATION_DLQ_AND_MANUAL_REVIEW_DECISIONS\"" "config declares queue policy"
require_contains "7-8Z.5.4.5" "$CONFIG_FILE" "\"action_policy\": \"ASSIGN_RESOLVE_REJECT_DRY_RUN_ONLY\"" "config declares action policy"
require_contains "7-8Z.5.4.6" "$CONFIG_FILE" "\"TENANT_CONTEXT_REQUIRED\"" "config declares tenant safety"
require_contains "7-8Z.5.4.7" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.5.4.8" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.5.4.9" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.5.4.10" "$CONFIG_FILE" "\"real_operator_provider_action\": false" "config keeps real operator provider action closed"

require_contains "7-8Z.5.5.1" "$DOC_FILE" "Manual review queue runtime" "doc includes manual review queue scope"
require_contains "7-8Z.5.5.2" "$DOC_FILE" "Tenant-safe review list/read" "doc includes tenant-safe read/list scope"
require_contains "7-8Z.5.5.3" "$DOC_FILE" "Assign action" "doc includes assign action scope"
require_contains "7-8Z.5.5.4" "$DOC_FILE" "Resolve action" "doc includes resolve action scope"
require_contains "7-8Z.5.5.5" "$DOC_FILE" "Reject action" "doc includes reject action scope"
require_contains "7-8Z.5.5.6" "$DOC_FILE" "Gerçek operator provider action" "doc states real operator provider action remains closed"
require_contains "7-8Z.5.5.7" "$DOC_FILE" "FAZ 7-8Z.6" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.5 ZIRVE ADMIN OPS MANUAL REVIEW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
