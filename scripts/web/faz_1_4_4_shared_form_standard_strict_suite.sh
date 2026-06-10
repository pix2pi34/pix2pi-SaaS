#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/shared-form"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/shared_form.js"
CSS_FILE="$WEB_DIR/shared_form.css"
CONFIG_FILE="$CONFIG_DIR/shared_form_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"input_standard"' "3.1 input_standard capability contract"
check_contains "$CONFIG_FILE" '"validation_standard"' "3.2 validation_standard capability contract"
check_contains "$CONFIG_FILE" '"error_display"' "3.3 error_display capability contract"
check_contains "$CONFIG_FILE" '"save_cancel_pattern"' "3.4 save_cancel_pattern capability contract"
check_contains "$CONFIG_FILE" '"form_tests"' "3.5 form_tests capability contract"

check_contains "$HTML_FILE" 'pix2pi-input' "4.1 input standard HTML"
check_contains "$HTML_FILE" 'pix2pi-select' "4.2 select standard HTML"
check_contains "$HTML_FILE" 'pix2pi-textarea' "4.3 textarea standard HTML"
check_contains "$HTML_FILE" 'pix2pi-field-error' "4.4 field error HTML"
check_contains "$HTML_FILE" 'sharedFormError' "4.5 form error HTML"
check_contains "$HTML_FILE" 'saveSharedFormButton' "4.6 save button HTML"
check_contains "$HTML_FILE" 'cancelSharedFormButton' "4.7 cancel button HTML"

check_contains "$JS_FILE" 'validateRequired' "5.1 required validation JS"
check_contains "$JS_FILE" 'validateEmail' "5.2 email validation JS"
check_contains "$JS_FILE" 'validateMinLength' "5.3 min length validation JS"
check_contains "$JS_FILE" 'validateTenantCode' "5.4 tenant code validation JS"
check_contains "$JS_FILE" 'validateTaxNumber' "5.5 tax number validation JS"
check_contains "$JS_FILE" 'renderFieldError' "5.6 field error display JS"
check_contains "$JS_FILE" 'renderValidationResult' "5.7 validation result render JS"
check_contains "$JS_FILE" 'handleSave' "5.8 save pattern JS"
check_contains "$JS_FILE" 'handleCancel' "5.9 cancel pattern JS"
check_contains "$JS_FILE" 'runSharedFormTests' "5.10 form tests JS"

check_contains "$CSS_FILE" 'pix2pi-input' "6.1 input CSS"
check_contains "$CSS_FILE" 'pix2pi-select' "6.2 select CSS"
check_contains "$CSS_FILE" 'pix2pi-textarea' "6.3 textarea CSS"
check_contains "$CSS_FILE" 'pix2pi-field-error' "6.4 field error CSS"
check_contains "$CSS_FILE" 'pix2pi-form-error' "6.5 form error CSS"
check_contains "$CSS_FILE" 'pix2pi-form-actions' "6.6 form actions CSS"

INPUT_STANDARD_STATUS="PASS"
VALIDATION_STANDARD_STATUS="PASS"
ERROR_DISPLAY_STATUS="PASS"
SAVE_CANCEL_PATTERN_STATUS="PASS"
FORM_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  INPUT_STANDARD_STATUS="FAIL"
  VALIDATION_STANDARD_STATUS="FAIL"
  ERROR_DISPLAY_STATUS="FAIL"
  SAVE_CANCEL_PATTERN_STATUS="FAIL"
  FORM_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.4 Shared Form Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- INPUT_STANDARD_STATUS=$INPUT_STANDARD_STATUS"
  echo "- VALIDATION_STANDARD_STATUS=$VALIDATION_STANDARD_STATUS"
  echo "- ERROR_DISPLAY_STATUS=$ERROR_DISPLAY_STATUS"
  echo "- SAVE_CANCEL_PATTERN_STATUS=$SAVE_CANCEL_PATTERN_STATUS"
  echo "- FORM_TESTS_STATUS=$FORM_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "INPUT_STANDARD_STATUS=$INPUT_STANDARD_STATUS"
echo "VALIDATION_STANDARD_STATUS=$VALIDATION_STANDARD_STATUS"
echo "ERROR_DISPLAY_STATUS=$ERROR_DISPLAY_STATUS"
echo "SAVE_CANCEL_PATTERN_STATUS=$SAVE_CANCEL_PATTERN_STATUS"
echo "FORM_TESTS_STATUS=$FORM_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE END ====="
