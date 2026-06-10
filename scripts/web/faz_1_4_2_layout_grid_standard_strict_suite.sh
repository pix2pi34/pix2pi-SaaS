#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/layout-grid"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/layout_grid.js"
CSS_FILE="$WEB_DIR/layout_grid.css"
CONFIG_FILE="$CONFIG_DIR/layout_grid_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"page_grid"' "3.1 page_grid capability contract"
check_contains "$CONFIG_FILE" '"card_layout"' "3.2 card_layout capability contract"
check_contains "$CONFIG_FILE" '"form_layout"' "3.3 form_layout capability contract"
check_contains "$CONFIG_FILE" '"table_layout"' "3.4 table_layout capability contract"
check_contains "$CONFIG_FILE" '"responsive_layout"' "3.5 responsive_layout capability contract"

check_contains "$HTML_FILE" 'pix2pi-page-grid' "4.1 page grid HTML"
check_contains "$HTML_FILE" 'pix2pi-card-grid' "4.2 card layout HTML"
check_contains "$HTML_FILE" 'pix2pi-form-grid' "4.3 form layout HTML"
check_contains "$HTML_FILE" 'pix2pi-table-region' "4.4 table layout HTML"
check_contains "$HTML_FILE" 'data-responsive-layout="true"' "4.5 responsive layout HTML"

check_contains "$JS_FILE" 'validatePageGrid' "5.1 page grid validation JS"
check_contains "$JS_FILE" 'validateCardLayout' "5.2 card layout validation JS"
check_contains "$JS_FILE" 'validateFormLayout' "5.3 form layout validation JS"
check_contains "$JS_FILE" 'validateTableLayout' "5.4 table layout validation JS"
check_contains "$JS_FILE" 'validateResponsiveLayout' "5.5 responsive layout validation JS"
check_contains "$JS_FILE" 'runLayoutGridChecks' "5.6 layout checks JS"

check_contains "$CSS_FILE" 'pix2pi-page-grid' "6.1 page grid CSS"
check_contains "$CSS_FILE" 'pix2pi-card-grid' "6.2 card layout CSS"
check_contains "$CSS_FILE" 'pix2pi-form-grid' "6.3 form layout CSS"
check_contains "$CSS_FILE" 'pix2pi-table-region' "6.4 table layout CSS"
check_contains "$CSS_FILE" '@media' "6.5 responsive media CSS"

PAGE_GRID_STATUS="PASS"
CARD_LAYOUT_STATUS="PASS"
FORM_LAYOUT_STATUS="PASS"
TABLE_LAYOUT_STATUS="PASS"
RESPONSIVE_LAYOUT_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  PAGE_GRID_STATUS="FAIL"
  CARD_LAYOUT_STATUS="FAIL"
  FORM_LAYOUT_STATUS="FAIL"
  TABLE_LAYOUT_STATUS="FAIL"
  RESPONSIVE_LAYOUT_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.2 Layout / Grid Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- PAGE_GRID_STATUS=$PAGE_GRID_STATUS"
  echo "- CARD_LAYOUT_STATUS=$CARD_LAYOUT_STATUS"
  echo "- FORM_LAYOUT_STATUS=$FORM_LAYOUT_STATUS"
  echo "- TABLE_LAYOUT_STATUS=$TABLE_LAYOUT_STATUS"
  echo "- RESPONSIVE_LAYOUT_STATUS=$RESPONSIVE_LAYOUT_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "PAGE_GRID_STATUS=$PAGE_GRID_STATUS"
echo "CARD_LAYOUT_STATUS=$CARD_LAYOUT_STATUS"
echo "FORM_LAYOUT_STATUS=$FORM_LAYOUT_STATUS"
echo "TABLE_LAYOUT_STATUS=$TABLE_LAYOUT_STATUS"
echo "RESPONSIVE_LAYOUT_STATUS=$RESPONSIVE_LAYOUT_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE END ====="
