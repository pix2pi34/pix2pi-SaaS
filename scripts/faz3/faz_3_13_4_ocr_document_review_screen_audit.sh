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

echo "===== 175 — FAZ 3-13.4 OCR DOCUMENT REVIEW SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/document-integration/ocr-review/index.html"
CONFIG_FILE="configs/faz3/document-integration/ocr_document_review_screen.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN.md"

check_file "175 OCR document review HTML screen file" "$SCREEN_FILE"
check_file "175 OCR document review config file" "$CONFIG_FILE"
check_file "175 OCR document review documentation file" "$DOC_FILE"

check_grep "175 phase marker" "$SCREEN_FILE" "FAZ_3_13_4"
check_grep "175 screen marker" "$SCREEN_FILE" "OCR_DOCUMENT_REVIEW_SCREEN"
check_grep "175 title surface" "$SCREEN_FILE" "OCR / Belge Okuma Review Ekranı"
check_grep "175 review queue surface" "$SCREEN_FILE" "Belge Review Kuyruğu|reviewRows"
check_grep "175 lens-like document reading surface" "$SCREEN_FILE" "OCR/Lens|Lens benzeri|belge okuma"
check_grep "175 tax no extraction surface" "$SCREEN_FILE" "extractedTaxNo|Tax No|Vergi no"
check_grep "175 tax office extraction surface" "$SCREEN_FILE" "extractedTaxOffice|Tax Office|Vergi dairesi"
check_grep "175 address extraction surface" "$SCREEN_FILE" "extractedAddress|Address|adres"
check_grep "175 phone extraction surface" "$SCREEN_FILE" "extractedPhone|Phone|telefon"
check_grep "175 email extraction surface" "$SCREEN_FILE" "extractedEmail|Email|e-posta"
check_grep "175 confidence score surface" "$SCREEN_FILE" "confidenceScore|Confidence Score"
check_grep "175 confidence bucket surface" "$SCREEN_FILE" "confidenceBucket|Confidence Bucket|HIGH|MEDIUM|LOW"
check_grep "175 ready for review status" "$SCREEN_FILE" "READY_FOR_REVIEW"
check_grep "175 low confidence status" "$SCREEN_FILE" "LOW_CONFIDENCE"
check_grep "175 correction required status" "$SCREEN_FILE" "CORRECTION_REQUIRED"
check_grep "175 approved dry-run status" "$SCREEN_FILE" "APPROVED_DRY_RUN"
check_grep "175 missing fields surface" "$SCREEN_FILE" "missingFields|Missing Fields"
check_grep "175 manual correction surface" "$SCREEN_FILE" "Manual Correction|manual-correction|CORRECT"
check_grep "175 review decision surface" "$SCREEN_FILE" "reviewDecision|Review Decision"
check_grep "175 target entity surface" "$SCREEN_FILE" "targetEntity|Target Entity|CUSTOMER_CARD_DRY_RUN"
check_grep "175 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant ID|tenantId"
check_grep "175 review guard surface" "$SCREEN_FILE" "data-review-guard|Human Review"
check_grep "175 confidence policy surface" "$SCREEN_FILE" "data-confidence-policy|Confidence Gate"
check_grep "175 source image hash trace" "$SCREEN_FILE" "sourceImageHash|Source Image Hash"
check_grep "175 OCR payload hash trace" "$SCREEN_FILE" "ocrPayloadHash|OCR Payload Hash"
check_grep "175 extracted fields hash trace" "$SCREEN_FILE" "extractedFieldsHash|Extracted Fields Hash"
check_grep "175 correction hash trace" "$SCREEN_FILE" "correctionHash|Correction Hash"
check_grep "175 PII mask hash trace" "$SCREEN_FILE" "piiMaskHash|PII Mask Hash"
check_grep "175 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "175 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "175 preview extraction action" "$SCREEN_FILE" "Preview Extraction|data-action=\"preview-extraction\"|PREVIEW"
check_grep "175 validate fields action" "$SCREEN_FILE" "Validate Fields|data-action=\"validate-fields\"|VALIDATE"
check_grep "175 manual correction action" "$SCREEN_FILE" "Manual Correction|data-action=\"manual-correction\"|CORRECT"
check_grep "175 approve dry-run action" "$SCREEN_FILE" "APPROVE|Approve"
check_grep "175 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\"|AUDIT"
check_grep "175 auto commit closed surface" "$SCREEN_FILE" "autoCommitAllowed = false|Auto Commit: CLOSED"
check_grep "175 customer card write false surface" "$SCREEN_FILE" "customerCardWriteAllowed = false|Customer Card Write"
check_grep "175 raw image storage false surface" "$SCREEN_FILE" "rawImageStorageAllowed = false|Raw Image Storage"
check_grep "175 PII masking required surface" "$SCREEN_FILE" "piiMaskingRequired = true|PII"
check_grep "175 correction audit required surface" "$SCREEN_FILE" "correctionAuditRequired = true"
check_grep "175 review timeline surface" "$SCREEN_FILE" "Review Timeline|data-audit-trail"
check_grep "175 no auto commit notice" "$SCREEN_FILE" "otomatik cari kart yazımı yapmaz|insan onayı olmadan commit edilmez|raw image storage kapalı"

check_grep "175 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "175 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/ocr-review/\""
check_grep "175 config review queue visibility" "$CONFIG_FILE" "\"ocr_review_queue_visibility\": true"
check_grep "175 config lens visibility" "$CONFIG_FILE" "\"lens_like_document_reading_visibility\": true"
check_grep "175 config tax no visibility" "$CONFIG_FILE" "\"tax_no_extraction_visibility\": true"
check_grep "175 config tax office visibility" "$CONFIG_FILE" "\"tax_office_extraction_visibility\": true"
check_grep "175 config address visibility" "$CONFIG_FILE" "\"address_extraction_visibility\": true"
check_grep "175 config phone visibility" "$CONFIG_FILE" "\"phone_extraction_visibility\": true"
check_grep "175 config email visibility" "$CONFIG_FILE" "\"email_extraction_visibility\": true"
check_grep "175 config confidence score visibility" "$CONFIG_FILE" "\"confidence_score_visibility\": true"
check_grep "175 config confidence bucket visibility" "$CONFIG_FILE" "\"confidence_bucket_visibility\": true"
check_grep "175 config missing field visibility" "$CONFIG_FILE" "\"missing_field_visibility\": true"
check_grep "175 config manual correction visibility" "$CONFIG_FILE" "\"manual_correction_visibility\": true"
check_grep "175 config review decision visibility" "$CONFIG_FILE" "\"review_decision_visibility\": true"
check_grep "175 config target entity visibility" "$CONFIG_FILE" "\"target_entity_visibility\": true"
check_grep "175 config source image hash visibility" "$CONFIG_FILE" "\"source_image_hash_visibility\": true"
check_grep "175 config OCR payload hash visibility" "$CONFIG_FILE" "\"ocr_payload_hash_visibility\": true"
check_grep "175 config extracted fields hash visibility" "$CONFIG_FILE" "\"extracted_fields_hash_visibility\": true"
check_grep "175 config correction hash visibility" "$CONFIG_FILE" "\"correction_hash_visibility\": true"
check_grep "175 config PII mask hash visibility" "$CONFIG_FILE" "\"pii_mask_hash_visibility\": true"
check_grep "175 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "175 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "175 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "175 config review id required" "$CONFIG_FILE" "\"review_id_required\": true"
check_grep "175 config document no required" "$CONFIG_FILE" "\"document_no_required\": true"
check_grep "175 config document type required" "$CONFIG_FILE" "\"document_type_required\": true"
check_grep "175 config tax no required" "$CONFIG_FILE" "\"tax_no_required\": true"
check_grep "175 config tax office required" "$CONFIG_FILE" "\"tax_office_required\": true"
check_grep "175 config address required" "$CONFIG_FILE" "\"address_required\": true"
check_grep "175 config phone required" "$CONFIG_FILE" "\"phone_required\": true"
check_grep "175 config email required" "$CONFIG_FILE" "\"email_required\": true"
check_grep "175 config confidence score required" "$CONFIG_FILE" "\"confidence_score_required\": true"
check_grep "175 config confidence bucket required" "$CONFIG_FILE" "\"confidence_bucket_required\": true"
check_grep "175 config review decision required" "$CONFIG_FILE" "\"review_decision_required\": true"
check_grep "175 config source image hash required" "$CONFIG_FILE" "\"source_image_hash_required\": true"
check_grep "175 config OCR payload hash required" "$CONFIG_FILE" "\"ocr_payload_hash_required\": true"
check_grep "175 config extracted fields hash required" "$CONFIG_FILE" "\"extracted_fields_hash_required\": true"
check_grep "175 config correction hash required" "$CONFIG_FILE" "\"correction_hash_required\": true"
check_grep "175 config PII mask hash required" "$CONFIG_FILE" "\"pii_mask_hash_required\": true"
check_grep "175 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "175 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "175 config tax certificate coverage" "$CONFIG_FILE" "\"tax_certificate\": true"
check_grep "175 config business card coverage" "$CONFIG_FILE" "\"business_card\": true"
check_grep "175 config invoice image coverage" "$CONFIG_FILE" "\"invoice_image\": true"
check_grep "175 config contact form coverage" "$CONFIG_FILE" "\"contact_form\": true"
check_grep "175 config tax no coverage" "$CONFIG_FILE" "\"tax_no\": true"
check_grep "175 config tax office coverage" "$CONFIG_FILE" "\"tax_office\": true"
check_grep "175 config address coverage" "$CONFIG_FILE" "\"address\": true"
check_grep "175 config phone coverage" "$CONFIG_FILE" "\"phone\": true"
check_grep "175 config email coverage" "$CONFIG_FILE" "\"email\": true"
check_grep "175 config ready for review coverage" "$CONFIG_FILE" "\"ready_for_review\": true"
check_grep "175 config low confidence coverage" "$CONFIG_FILE" "\"low_confidence\": true"
check_grep "175 config correction required coverage" "$CONFIG_FILE" "\"correction_required\": true"
check_grep "175 config approved dry-run coverage" "$CONFIG_FILE" "\"approved_dry_run\": true"
check_grep "175 config high confidence coverage" "$CONFIG_FILE" "\"high\": true"
check_grep "175 config medium confidence coverage" "$CONFIG_FILE" "\"medium\": true"
check_grep "175 config low confidence bucket coverage" "$CONFIG_FILE" "\"low\": true"

check_grep "175 config preview extraction operation" "$CONFIG_FILE" "\"preview_extraction\": true"
check_grep "175 config validate fields operation" "$CONFIG_FILE" "\"validate_fields\": true"
check_grep "175 config manual correction operation" "$CONFIG_FILE" "\"manual_correction\": true"
check_grep "175 config approve dry-run operation" "$CONFIG_FILE" "\"approve_dry_run\": true"
check_grep "175 config audit evidence operation" "$CONFIG_FILE" "\"audit_evidence\": true"

check_grep "175 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "175 config auto commit false" "$CONFIG_FILE" "\"auto_commit_allowed\": false"
check_grep "175 config human review required" "$CONFIG_FILE" "\"human_review_required\": true"
check_grep "175 config raw image storage false" "$CONFIG_FILE" "\"raw_image_storage_allowed\": false"
check_grep "175 config PII masking required" "$CONFIG_FILE" "\"pii_masking_required\": true"
check_grep "175 config confidence gate required" "$CONFIG_FILE" "\"confidence_gate_required\": true"
check_grep "175 config correction audit required" "$CONFIG_FILE" "\"correction_audit_required\": true"
check_grep "175 config customer card write false" "$CONFIG_FILE" "\"customer_card_write_allowed\": false"
check_grep "175 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_preview_validate_correct_audit_only\": true"
check_grep "175 config OCR runtime backend gate" "$CONFIG_FILE" "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME"
check_grep "175 config tax extraction backend gate" "$CONFIG_FILE" "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME"
check_grep "175 config contact extraction backend gate" "$CONFIG_FILE" "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME"
check_grep "175 config confidence queue backend gate" "$CONFIG_FILE" "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME"
check_grep "175 config AI runtime tests backend gate" "$CONFIG_FILE" "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS"
check_grep "175 config ebelge status center gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"
check_grep "175 config previous gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"
check_grep "175 config next gate" "$CONFIG_FILE" "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"auto_commit_allowed\"[[:space:]]*:[[:space:]]*true|\"human_review_required\"[[:space:]]*:[[:space:]]*false|\"raw_image_storage_allowed\"[[:space:]]*:[[:space:]]*true|\"pii_masking_required\"[[:space:]]*:[[:space:]]*false|\"confidence_gate_required\"[[:space:]]*:[[:space:]]*false|\"correction_audit_required\"[[:space:]]*:[[:space:]]*false|\"customer_card_write_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "175 live policy OCR human review guard"
else
  pass "175 live policy OCR human review guard"
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
# 175 — FAZ 3-13.4 — OCR Document Review Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_6_READY=${NEXT_READY}

## Scope

- OCR review queue visibility
- Lens-like document reading visibility
- Tax no / tax office / address / phone / email extraction visibility
- Confidence score / bucket visibility
- HIGH / MEDIUM / LOW confidence coverage
- READY_FOR_REVIEW / LOW_CONFIDENCE / CORRECTION_REQUIRED / APPROVED_DRY_RUN status coverage
- Manual correction visibility
- Review decision visibility
- Target entity dry-run visibility
- Source image / OCR payload / extracted fields / correction / PII mask / audit hash traces
- Evidence file trace
- Review timeline

## Live Policy

- Auto commit: CLOSED
- Human review required: TRUE
- Raw image storage: CLOSED
- PII masking required: TRUE
- Confidence gate required: TRUE
- Correction audit required: TRUE
- Customer card write: CLOSED
- Production approved: FALSE
- UI actions are preview/validate/correct/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 175 — FAZ 3-13.4 OCR DOCUMENT REVIEW SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
