#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

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

echo "===== 176 — FAZ 3-13.6 DOCUMENT INTEGRATION UI TEST SUITE START ====="

declare -A SCREEN_FILES=(
  ["174"]="web/faz3/document-integration/ebelge-status-center/index.html"
  ["175"]="web/faz3/document-integration/ocr-review/index.html"
)

declare -A CONFIG_FILES=(
  ["174"]="configs/faz3/document-integration/ebelge_status_center.v1.json"
  ["175"]="configs/faz3/document-integration/ocr_document_review_screen.v1.json"
)

declare -A EVIDENCE_FILES=(
  ["174"]="docs/faz3/evidence/FAZ_3_13_1_EBELGE_STATUS_CENTER_REAL_IMPLEMENTATION_AUDIT.md"
  ["175"]="docs/faz3/evidence/FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
)

declare -A PHASE_MARKERS=(
  ["174"]="FAZ_3_13_1"
  ["175"]="FAZ_3_13_4"
)

declare -A SCREEN_MARKERS=(
  ["174"]="EBELGE_STATUS_CENTER"
  ["175"]="OCR_DOCUMENT_REVIEW_SCREEN"
)

for n in 174 175; do
  screen="${SCREEN_FILES[$n]}"
  config="${CONFIG_FILES[$n]}"
  evidence="${EVIDENCE_FILES[$n]}"

  check_file "176 screen ${n} HTML file" "$screen"
  check_file "176 screen ${n} config file" "$config"
  check_file "176 screen ${n} evidence file" "$evidence"

  check_grep "176 screen ${n} phase marker" "$screen" "${PHASE_MARKERS[$n]}"
  check_grep "176 screen ${n} screen marker" "$screen" "${SCREEN_MARKERS[$n]}"
  check_grep "176 screen ${n} tenant guard" "$screen" "Tenant|tenant|data-tenant-guard"
  check_grep "176 screen ${n} firm guard" "$screen" "Firm|Firma|firm|data-firm"
  check_grep "176 screen ${n} audit hash or evidence trace" "$screen" "auditHash|Audit Hash|evidenceFile|Evidence File|AUDIT|Audit"
  check_grep "176 screen ${n} closed or dry-run policy" "$screen" "CLOSED|closed|DRY-RUN|dry-run|FALSE|false|kapalı|yapmaz|read-only"
  check_grep "176 screen ${n} config screen enabled" "$config" "\"screen_enabled\"[[:space:]]*:[[:space:]]*true"
  check_grep "176 screen ${n} config route" "$config" "\"route\""
  check_grep "176 screen ${n} evidence final status" "$evidence" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
done

check_grep "176 screen 174 e-Belge type coverage" "${SCREEN_FILES[174]}" "E_FATURA|E_ARSIV|E_ADISYON"
check_grep "176 screen 174 provider closed policy" "${SCREEN_FILES[174]}" "realGibCallAllowed = false|realProviderCallAllowed = false|Real GİB: CLOSED"
check_grep "176 screen 174 callback/poll coverage" "${SCREEN_FILES[174]}" "callbackStatus|pollStatus|Callback Verify|Poll Plan"
check_grep "176 screen 174 retry/cancel/DLQ coverage" "${SCREEN_FILES[174]}" "retryStatus|cancelStatus|dlqStatus|manualReviewStatus"

check_grep "176 screen 175 OCR extraction coverage" "${SCREEN_FILES[175]}" "extractedTaxNo|extractedTaxOffice|extractedAddress|extractedPhone|extractedEmail"
check_grep "176 screen 175 confidence coverage" "${SCREEN_FILES[175]}" "confidenceScore|confidenceBucket|HIGH|MEDIUM|LOW"
check_grep "176 screen 175 human review policy" "${SCREEN_FILES[175]}" "humanReviewRequired = true|Human Review"
check_grep "176 screen 175 auto commit closed policy" "${SCREEN_FILES[175]}" "autoCommitAllowed = false|Auto Commit: CLOSED|customerCardWriteAllowed = false"

REPORT_FILE="web/faz3/document-integration/ui-tests/index.html"
CONFIG_FILE="configs/faz3/document-integration/document_integration_ui_tests.v1.json"

check_file "176 document integration UI tests report HTML file" "$REPORT_FILE"
check_file "176 document integration UI tests config file" "$CONFIG_FILE"

check_grep "176 report phase marker" "$REPORT_FILE" "FAZ_3_13_6"
check_grep "176 report screen marker" "$REPORT_FILE" "DOCUMENT_INTEGRATION_UI_TESTS_REPORT"
check_grep "176 report title surface" "$REPORT_FILE" "Belge / Entegrasyon UI Testleri"
check_grep "176 report tenant guard" "$REPORT_FILE" "data-tenant-guard|Tenant Guard"
check_grep "176 report firm guard" "$REPORT_FILE" "data-firm-guard|Firm Guard"
check_grep "176 report correlation review guard" "$REPORT_FILE" "data-correlation-guard|Correlation / Review Guard"
check_grep "176 report production false" "$REPORT_FILE" "data-production-approved|Production: FALSE"
check_grep "176 report 174 coverage" "$REPORT_FILE" "174.*e-Belge Durum Merkezi|/faz3/document-integration/ebelge-status-center/"
check_grep "176 report 175 coverage" "$REPORT_FILE" "175.*OCR / Belge Okuma Review|/faz3/document-integration/ocr-review/"
check_grep "176 report 177 next coverage" "$REPORT_FILE" "177.*Retry / Cancel / Resend|FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "176 report 178 planned coverage" "$REPORT_FILE" "178.*Provider Hata|FAZ_3_13_3_PROVIDER_ERROR_VIEW"
check_grep "176 report 179 planned coverage" "$REPORT_FILE" "179.*Manuel Düzeltme|FAZ_3_13_5_MANUAL_CORRECTION_QUEUE"
check_grep "176 report live policy closed" "$REPORT_FILE" "Real GİB: CLOSED|Real provider: CLOSED|Auto commit: CLOSED|Audit delete/mutation: CLOSED"

check_grep "176 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "176 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/ui-tests/\""
check_grep "176 config screen 174 coverage" "$CONFIG_FILE" "\"screen_174_ebelge_status_center\""
check_grep "176 config screen 175 coverage" "$CONFIG_FILE" "\"screen_175_ocr_document_review\""
check_grep "176 config planned 177 next" "$CONFIG_FILE" "\"screen_177_retry_cancel_resend_action_surface\""
check_grep "176 config planned 178" "$CONFIG_FILE" "\"screen_178_provider_error_view\""
check_grep "176 config planned 179" "$CONFIG_FILE" "\"screen_179_manual_correction_queue\""
check_grep "176 config html required" "$CONFIG_FILE" "\"html_file_required\": true"
check_grep "176 config config required" "$CONFIG_FILE" "\"config_file_required\": true"
check_grep "176 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "176 config phase marker required" "$CONFIG_FILE" "\"phase_marker_required\": true"
check_grep "176 config screen marker required" "$CONFIG_FILE" "\"screen_marker_required\": true"
check_grep "176 config tenant guard required" "$CONFIG_FILE" "\"tenant_guard_required\": true"
check_grep "176 config firm guard required" "$CONFIG_FILE" "\"firm_guard_required\": true"
check_grep "176 config correlation review guard required" "$CONFIG_FILE" "\"correlation_or_review_guard_required\": true"
check_grep "176 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "176 config evidence trace required" "$CONFIG_FILE" "\"evidence_trace_required\": true"
check_grep "176 config live provider closed required" "$CONFIG_FILE" "\"live_provider_closed_required\": true"
check_grep "176 config real GIB closed required" "$CONFIG_FILE" "\"real_gib_closed_required\": true"
check_grep "176 config auto commit closed required" "$CONFIG_FILE" "\"auto_commit_closed_required\": true"
check_grep "176 config human review required" "$CONFIG_FILE" "\"human_review_required\": true"
check_grep "176 config dry-run required" "$CONFIG_FILE" "\"dry_run_or_readonly_policy_required\": true"
check_grep "176 config no external action required" "$CONFIG_FILE" "\"no_real_external_action_required\": true"

check_grep "176 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "176 config static readonly true" "$CONFIG_FILE" "\"document_integration_ui_tests_are_static_and_readonly\": true"
check_grep "176 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "176 config real provider false" "$CONFIG_FILE" "\"real_provider_call_allowed\": false"
check_grep "176 config external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "176 config auto commit false" "$CONFIG_FILE" "\"auto_commit_allowed\": false"
check_grep "176 config customer card write false" "$CONFIG_FILE" "\"customer_card_write_allowed\": false"
check_grep "176 config raw image storage false" "$CONFIG_FILE" "\"raw_image_storage_allowed\": false"
check_grep "176 config audit delete false" "$CONFIG_FILE" "\"audit_delete_allowed\": false"
check_grep "176 config audit mutation false" "$CONFIG_FILE" "\"audit_mutation_allowed\": false"
check_grep "176 config ui actions evidence only" "$CONFIG_FILE" "\"ui_actions_are_navigation_evidence_only\": true"
check_grep "176 config ebelge backend gate" "$CONFIG_FILE" "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS"
check_grep "176 config document AI backend gate" "$CONFIG_FILE" "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS"
check_grep "176 config previous gate" "$CONFIG_FILE" "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN"
check_grep "176 config next gate" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"auto_commit_allowed\"[[:space:]]*:[[:space:]]*true|\"customer_card_write_allowed\"[[:space:]]*:[[:space:]]*true|\"raw_image_storage_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "176 live policy document integration UI tests guard"
else
  pass "176 live policy document integration UI tests guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

echo "===== 176 — FAZ 3-13.6 DOCUMENT INTEGRATION UI TEST SUITE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TEST_SUITE_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_2_READY=${NEXT_READY}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
