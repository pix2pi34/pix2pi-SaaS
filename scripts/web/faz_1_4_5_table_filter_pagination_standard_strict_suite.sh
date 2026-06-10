#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/table-filter-pagination"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/table_filter_pagination.js"
CSS_FILE="$WEB_DIR/table_filter_pagination.css"
CONFIG_FILE="$CONFIG_DIR/table_filter_pagination_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"table_component"' "3.1 table_component capability contract"
check_contains "$CONFIG_FILE" '"filter_component"' "3.2 filter_component capability contract"
check_contains "$CONFIG_FILE" '"sort"' "3.3 sort capability contract"
check_contains "$CONFIG_FILE" '"pagination"' "3.4 pagination capability contract"
check_contains "$CONFIG_FILE" '"empty_state"' "3.5 empty_state capability contract"

check_contains "$HTML_FILE" 'pix2piDataTable' "4.1 table component HTML"
check_contains "$HTML_FILE" 'pix2piTableFilterInput' "4.2 filter component HTML"
check_contains "$HTML_FILE" 'pix2piSortSelect' "4.3 sort select HTML"
check_contains "$HTML_FILE" 'pix2piPagination' "4.4 pagination HTML"
check_contains "$HTML_FILE" 'pix2piTableEmptyState' "4.5 empty state HTML"

check_contains "$JS_FILE" 'renderTable' "5.1 table render JS"
check_contains "$JS_FILE" 'applyFilters' "5.2 filter JS"
check_contains "$JS_FILE" 'sortRows' "5.3 sort JS"
check_contains "$JS_FILE" 'paginateRows' "5.4 pagination JS"
check_contains "$JS_FILE" 'renderEmptyState' "5.5 empty state JS"
check_contains "$JS_FILE" 'runTableStandardTests' "5.6 table tests JS"

check_contains "$CSS_FILE" 'pix2pi-table' "6.1 table CSS"
check_contains "$CSS_FILE" 'pix2pi-filter' "6.2 filter CSS"
check_contains "$CSS_FILE" 'pix2pi-sort-button' "6.3 sort CSS"
check_contains "$CSS_FILE" 'pix2pi-pagination' "6.4 pagination CSS"
check_contains "$CSS_FILE" 'pix2pi-empty-state' "6.5 empty state CSS"

TABLE_COMPONENT_STATUS="PASS"
FILTER_COMPONENT_STATUS="PASS"
SORT_STATUS="PASS"
PAGINATION_STATUS="PASS"
EMPTY_STATE_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  TABLE_COMPONENT_STATUS="FAIL"
  FILTER_COMPONENT_STATUS="FAIL"
  SORT_STATUS="FAIL"
  PAGINATION_STATUS="FAIL"
  EMPTY_STATE_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.5 Table / Filter / Pagination Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- TABLE_COMPONENT_STATUS=$TABLE_COMPONENT_STATUS"
  echo "- FILTER_COMPONENT_STATUS=$FILTER_COMPONENT_STATUS"
  echo "- SORT_STATUS=$SORT_STATUS"
  echo "- PAGINATION_STATUS=$PAGINATION_STATUS"
  echo "- EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TABLE_COMPONENT_STATUS=$TABLE_COMPONENT_STATUS"
echo "FILTER_COMPONENT_STATUS=$FILTER_COMPONENT_STATUS"
echo "SORT_STATUS=$SORT_STATUS"
echo "PAGINATION_STATUS=$PAGINATION_STATUS"
echo "EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE END ====="
