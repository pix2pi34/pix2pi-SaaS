#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }

check_file() {
  local label="$1"; local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label file_missing=${file}"; fi
}

check_grep() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then pass "$label"; else fail "$label pattern_missing=${pattern}"; fi
}

echo "===== 179 — FAZ 3-13.5 MANUAL CORRECTION QUEUE REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/document-integration/manual-correction-queue/index.html"
CONFIG_FILE="configs/faz3/document-integration/manual_correction_queue.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_5_MANUAL_CORRECTION_QUEUE.md"

check_file "179 manual correction queue HTML screen file" "$SCREEN_FILE"
check_file "179 manual correction queue config file" "$CONFIG_FILE"
check_file "179 manual correction queue documentation file" "$DOC_FILE"

check_grep "179 phase marker" "$SCREEN_FILE" "FAZ_3_13_5"
check_grep "179 screen marker" "$SCREEN_FILE" "MANUAL_CORRECTION_QUEUE"
check_grep "179 title surface" "$SCREEN_FILE" "Manuel Düzeltme Kuyruğu"
check_grep "179 correction queue surface" "$SCREEN_FILE" "Düzeltme Kuyruğu|queueRows"
check_grep "179 OCR review source surface" "$SCREEN_FILE" "OCR_REVIEW|ocr-003"
check_grep "179 e-Belge status source surface" "$SCREEN_FILE" "EBELGE_STATUS|doc-004"
check_grep "179 provider error source surface" "$SCREEN_FILE" "PROVIDER_ERROR|perr-001"
check_grep "179 retry cancel resend source surface" "$SCREEN_FILE" "RETRY_CANCEL_RESEND|act-005"
check_grep "179 open status coverage" "$SCREEN_FILE" "OPEN"
check_grep "179 assigned status coverage" "$SCREEN_FILE" "ASSIGNED"
check_grep "179 waiting approval status coverage" "$SCREEN_FILE" "WAITING_APPROVAL"
check_grep "179 approved dry-run status coverage" "$SCREEN_FILE" "APPROVED_DRY_RUN"
check_grep "179 rejected status coverage" "$SCREEN_FILE" "REJECTED"
check_grep "179 low priority coverage" "$SCREEN_FILE" "LOW"
check_grep "179 medium priority coverage" "$SCREEN_FILE" "MEDIUM"
check_grep "179 high priority coverage" "$SCREEN_FILE" "HIGH"
check_grep "179 critical priority coverage" "$SCREEN_FILE" "CRITICAL"
check_grep "179 correction field surface" "$SCREEN_FILE" "correctionField|Correction Field|ADDRESS|TAX_NO"
check_grep "179 current value surface" "$SCREEN_FILE" "currentValue|Current Value"
check_grep "179 proposed value surface" "$SCREEN_FILE" "proposedValue|Proposed Value"
check_grep "179 operator surface" "$SCREEN_FILE" "operatorId|Operator ID|data-operator-guard"
check_grep "179 reviewer surface" "$SCREEN_FILE" "reviewerId|Reviewer ID"
check_grep "179 decision surface" "$SCREEN_FILE" "decision|Decision"
check_grep "179 decision reason surface" "$SCREEN_FILE" "decisionReason|Decision Reason"
check_grep "179 approval status surface" "$SCREEN_FILE" "approvalStatus|Approval Status"
check_grep "179 rejection reason surface" "$SCREEN_FILE" "rejectionReason|Rejection Reason"
check_grep "179 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant ID|tenantId"
check_grep "179 approval policy surface" "$SCREEN_FILE" "data-approval-policy|Human Approval"
check_grep "179 correction source hash trace" "$SCREEN_FILE" "correctionSourceHash|Correction Source Hash"
check_grep "179 before value hash trace" "$SCREEN_FILE" "beforeValueHash|Before Value Hash"
check_grep "179 after value hash trace" "$SCREEN_FILE" "afterValueHash|After Value Hash"
check_grep "179 decision hash trace" "$SCREEN_FILE" "decisionHash|Decision Hash"
check_grep "179 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "179 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "179 assign operator action" "$SCREEN_FILE" "Assign Operator|data-action=\"assign-operator\"|ASSIGN"
check_grep "179 preview correction action" "$SCREEN_FILE" "Preview Correction|data-action=\"preview-correction\"|CORRECT"
check_grep "179 approve dry-run action" "$SCREEN_FILE" "Approve Dry-run|data-action=\"approve-dry-run\"|APPROVE"
check_grep "179 reject correction action" "$SCREEN_FILE" "Reject Correction|data-action=\"reject-correction\"|REJECT"
check_grep "179 live apply disabled surface" "$SCREEN_FILE" "LIVE_APPLY|Apply|autoApplyAllowed===false|liveWriteAllowed===false"
check_grep "179 auto apply closed surface" "$SCREEN_FILE" "autoApplyAllowed = false|Auto Apply: CLOSED"
check_grep "179 human approval required surface" "$SCREEN_FILE" "humanApprovalRequired = true|Human Approval"
check_grep "179 dual control required surface" "$SCREEN_FILE" "dualControlRequired = true|Dual Control"
check_grep "179 live write false surface" "$SCREEN_FILE" "liveWriteAllowed = false|Live Write"
check_grep "179 raw pii false surface" "$SCREEN_FILE" "rawPiiVisible = false"
check_grep "179 correction timeline surface" "$SCREEN_FILE" "Correction Timeline|data-audit-trail"
check_grep "179 no auto apply notice" "$SCREEN_FILE" "otomatik düzeltme uygulamaz|insan onayı|dual-control|audit evidence"

check_grep "179 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "179 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/manual-correction-queue/\""
check_grep "179 config manual correction queue visibility" "$CONFIG_FILE" "\"manual_correction_queue_visibility\": true"
check_grep "179 config OCR review source visibility" "$CONFIG_FILE" "\"ocr_review_source_visibility\": true"
check_grep "179 config ebelge status source visibility" "$CONFIG_FILE" "\"ebelge_status_source_visibility\": true"
check_grep "179 config provider error source visibility" "$CONFIG_FILE" "\"provider_error_source_visibility\": true"
check_grep "179 config retry cancel resend source visibility" "$CONFIG_FILE" "\"retry_cancel_resend_source_visibility\": true"
check_grep "179 config correction field visibility" "$CONFIG_FILE" "\"correction_field_visibility\": true"
check_grep "179 config current value visibility" "$CONFIG_FILE" "\"current_value_visibility\": true"
check_grep "179 config proposed value visibility" "$CONFIG_FILE" "\"proposed_value_visibility\": true"
check_grep "179 config operator assignment visibility" "$CONFIG_FILE" "\"operator_assignment_visibility\": true"
check_grep "179 config reviewer visibility" "$CONFIG_FILE" "\"reviewer_visibility\": true"
check_grep "179 config decision visibility" "$CONFIG_FILE" "\"decision_visibility\": true"
check_grep "179 config approval status visibility" "$CONFIG_FILE" "\"approval_status_visibility\": true"
check_grep "179 config rejection reason visibility" "$CONFIG_FILE" "\"rejection_reason_visibility\": true"
check_grep "179 config correction source hash visibility" "$CONFIG_FILE" "\"correction_source_hash_visibility\": true"
check_grep "179 config before hash visibility" "$CONFIG_FILE" "\"before_value_hash_visibility\": true"
check_grep "179 config after hash visibility" "$CONFIG_FILE" "\"after_value_hash_visibility\": true"
check_grep "179 config decision hash visibility" "$CONFIG_FILE" "\"decision_hash_visibility\": true"
check_grep "179 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "179 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "179 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "179 config operator required" "$CONFIG_FILE" "\"operator_indicator_required\": true"
check_grep "179 config reviewer required" "$CONFIG_FILE" "\"reviewer_indicator_required\": true"
check_grep "179 config queue id required" "$CONFIG_FILE" "\"queue_id_required\": true"
check_grep "179 config source type required" "$CONFIG_FILE" "\"source_type_required\": true"
check_grep "179 config source ref required" "$CONFIG_FILE" "\"source_ref_required\": true"
check_grep "179 config document no required" "$CONFIG_FILE" "\"document_no_required\": true"
check_grep "179 config correction field required" "$CONFIG_FILE" "\"correction_field_required\": true"
check_grep "179 config current value required" "$CONFIG_FILE" "\"current_value_required\": true"
check_grep "179 config proposed value required" "$CONFIG_FILE" "\"proposed_value_required\": true"
check_grep "179 config status required" "$CONFIG_FILE" "\"status_required\": true"
check_grep "179 config priority required" "$CONFIG_FILE" "\"priority_required\": true"
check_grep "179 config decision required" "$CONFIG_FILE" "\"decision_required\": true"
check_grep "179 config decision reason required" "$CONFIG_FILE" "\"decision_reason_required\": true"
check_grep "179 config approval status required" "$CONFIG_FILE" "\"approval_status_required\": true"
check_grep "179 config correction source hash required" "$CONFIG_FILE" "\"correction_source_hash_required\": true"
check_grep "179 config before hash required" "$CONFIG_FILE" "\"before_value_hash_required\": true"
check_grep "179 config after hash required" "$CONFIG_FILE" "\"after_value_hash_required\": true"
check_grep "179 config decision hash required" "$CONFIG_FILE" "\"decision_hash_required\": true"
check_grep "179 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "179 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "179 config OCR source coverage" "$CONFIG_FILE" "\"ocr_review\": true"
check_grep "179 config ebelge source coverage" "$CONFIG_FILE" "\"ebelge_status\": true"
check_grep "179 config provider error source coverage" "$CONFIG_FILE" "\"provider_error\": true"
check_grep "179 config retry cancel resend source coverage" "$CONFIG_FILE" "\"retry_cancel_resend\": true"
check_grep "179 config open coverage" "$CONFIG_FILE" "\"open\": true"
check_grep "179 config assigned coverage" "$CONFIG_FILE" "\"assigned\": true"
check_grep "179 config waiting approval coverage" "$CONFIG_FILE" "\"waiting_approval\": true"
check_grep "179 config approved dry-run coverage" "$CONFIG_FILE" "\"approved_dry_run\": true"
check_grep "179 config rejected coverage" "$CONFIG_FILE" "\"rejected\": true"
check_grep "179 config low priority coverage" "$CONFIG_FILE" "\"low\": true"
check_grep "179 config medium priority coverage" "$CONFIG_FILE" "\"medium\": true"
check_grep "179 config high priority coverage" "$CONFIG_FILE" "\"high\": true"
check_grep "179 config critical priority coverage" "$CONFIG_FILE" "\"critical\": true"
check_grep "179 config assign operation" "$CONFIG_FILE" "\"assign_operator\": true"
check_grep "179 config preview correction operation" "$CONFIG_FILE" "\"preview_correction\": true"
check_grep "179 config approve dry-run operation" "$CONFIG_FILE" "\"approve_dry_run\": true"
check_grep "179 config reject correction operation" "$CONFIG_FILE" "\"reject_correction\": true"
check_grep "179 config audit evidence operation" "$CONFIG_FILE" "\"audit_evidence\": true"
check_grep "179 config live apply disabled operation" "$CONFIG_FILE" "\"live_apply_disabled\": true"

check_grep "179 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "179 config auto apply false" "$CONFIG_FILE" "\"auto_apply_allowed\": false"
check_grep "179 config human approval required" "$CONFIG_FILE" "\"human_approval_required\": true"
check_grep "179 config dual control required" "$CONFIG_FILE" "\"dual_control_required\": true"
check_grep "179 config before after hash required" "$CONFIG_FILE" "\"before_after_hash_required\": true"
check_grep "179 config audit hash required live" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "179 config live write false" "$CONFIG_FILE" "\"live_write_allowed\": false"
check_grep "179 config raw pii false" "$CONFIG_FILE" "\"raw_pii_visible\": false"
check_grep "179 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_assign_correct_approve_reject_audit_only\": true"
check_grep "179 config OCR review gate" "$CONFIG_FILE" "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN"
check_grep "179 config ebelge status gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"
check_grep "179 config retry cancel resend gate" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "179 config provider error gate" "$CONFIG_FILE" "FAZ_3_13_3_PROVIDER_ERROR_VIEW"
check_grep "179 config document UI tests gate" "$CONFIG_FILE" "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS"
check_grep "179 config previous gate" "$CONFIG_FILE" "FAZ_3_13_3_PROVIDER_ERROR_VIEW"
check_grep "179 config next gate" "$CONFIG_FILE" "FAZ_3_R_PRIORITY_3_FINAL_RECHECK"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"auto_apply_allowed\"[[:space:]]*:[[:space:]]*true|\"human_approval_required\"[[:space:]]*:[[:space:]]*false|\"dual_control_required\"[[:space:]]*:[[:space:]]*false|\"before_after_hash_required\"[[:space:]]*:[[:space:]]*false|\"audit_hash_required\"[[:space:]]*:[[:space:]]*false|\"live_write_allowed\"[[:space:]]*:[[:space:]]*true|\"raw_pii_visible\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "179 live policy manual correction guard"
else
  pass "179 live policy manual correction guard"
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
# 179 — FAZ 3-13.5 — Manual Correction Queue Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_PRIORITY_3_FINAL_RECHECK_READY=${NEXT_READY}

## Scope

- Manual correction queue
- OCR_REVIEW / EBELGE_STATUS / PROVIDER_ERROR / RETRY_CANCEL_RESEND source coverage
- OPEN / ASSIGNED / WAITING_APPROVAL / APPROVED_DRY_RUN / REJECTED status coverage
- LOW / MEDIUM / HIGH / CRITICAL priority coverage
- Correction field / current value / proposed value visibility
- Operator / reviewer / decision / approval / rejection visibility
- Correction source hash / before value hash / after value hash / decision hash / audit hash traces
- Evidence file trace
- Correction timeline

## Live Policy

- Auto apply: CLOSED
- Human approval required: TRUE
- Dual control required: TRUE
- Before/after hash required: TRUE
- Audit hash required: TRUE
- Live write: CLOSED
- Raw PII visible: FALSE
- Production approved: FALSE
- UI actions are assign/correct/approve/reject/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 179 — FAZ 3-13.5 MANUAL CORRECTION QUEUE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_PRIORITY_3_FINAL_RECHECK_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
