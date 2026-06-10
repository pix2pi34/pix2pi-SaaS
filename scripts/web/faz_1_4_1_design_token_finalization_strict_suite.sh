#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/design-tokens"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/design_tokens.js"
CSS_FILE="$WEB_DIR/design_tokens.css"
CONFIG_FILE="$CONFIG_DIR/design_tokens_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

  if grep -q -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"color_tokens"' "3.1 color_tokens capability contract"
check_contains "$CONFIG_FILE" '"typography_scale"' "3.2 typography_scale capability contract"
check_contains "$CONFIG_FILE" '"spacing_tokens"' "3.3 spacing_tokens capability contract"
check_contains "$CONFIG_FILE" '"radius_shadow_tokens"' "3.4 radius_shadow_tokens capability contract"
check_contains "$CONFIG_FILE" '"component_usage_doc"' "3.5 component_usage_doc capability contract"

check_contains "$CSS_FILE" '--pix2pi-color-bg' "4.1 color bg token CSS"
check_contains "$CSS_FILE" '--pix2pi-color-accent' "4.2 color accent token CSS"
check_contains "$CSS_FILE" '--pix2pi-font-size-base' "4.3 typography base token CSS"
check_contains "$CSS_FILE" '--pix2pi-font-size-2xl' "4.4 typography 2xl token CSS"
check_contains "$CSS_FILE" '--pix2pi-space-4' "4.5 spacing token CSS"
check_contains "$CSS_FILE" '--pix2pi-space-8' "4.6 spacing large token CSS"
check_contains "$CSS_FILE" '--pix2pi-radius-md' "4.7 radius token CSS"
check_contains "$CSS_FILE" '--pix2pi-shadow-lg' "4.8 shadow token CSS"

check_contains "$HTML_FILE" 'pix2piColorTokenGrid' "5.1 color token HTML"
check_contains "$HTML_FILE" 'pix2piTypographyTokenGrid' "5.2 typography token HTML"
check_contains "$HTML_FILE" 'pix2piSpacingTokenGrid' "5.3 spacing token HTML"
check_contains "$HTML_FILE" 'pix2piRadiusShadowTokenGrid' "5.4 radius/shadow token HTML"
check_contains "$HTML_FILE" 'Component usage doc' "5.5 component usage doc HTML"

check_contains "$JS_FILE" 'validateColorTokens' "6.1 color token validation JS"
check_contains "$JS_FILE" 'validateTypographyScale' "6.2 typography validation JS"
check_contains "$JS_FILE" 'validateSpacingTokens' "6.3 spacing validation JS"
check_contains "$JS_FILE" 'validateRadiusShadowTokens' "6.4 radius/shadow validation JS"
check_contains "$JS_FILE" 'validateComponentUsageDoc' "6.5 component usage validation JS"
check_contains "$JS_FILE" 'runDesignTokenTests' "6.6 design token tests JS"

COLOR_TOKENS_STATUS="PASS"
TYPOGRAPHY_SCALE_STATUS="PASS"
SPACING_TOKENS_STATUS="PASS"
RADIUS_SHADOW_TOKENS_STATUS="PASS"
COMPONENT_USAGE_DOC_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  COLOR_TOKENS_STATUS="FAIL"
  TYPOGRAPHY_SCALE_STATUS="FAIL"
  SPACING_TOKENS_STATUS="FAIL"
  RADIUS_SHADOW_TOKENS_STATUS="FAIL"
  COMPONENT_USAGE_DOC_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.1 Design Token Finalization Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- COLOR_TOKENS_STATUS=$COLOR_TOKENS_STATUS"
  echo "- TYPOGRAPHY_SCALE_STATUS=$TYPOGRAPHY_SCALE_STATUS"
  echo "- SPACING_TOKENS_STATUS=$SPACING_TOKENS_STATUS"
  echo "- RADIUS_SHADOW_TOKENS_STATUS=$RADIUS_SHADOW_TOKENS_STATUS"
  echo "- COMPONENT_USAGE_DOC_STATUS=$COMPONENT_USAGE_DOC_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "COLOR_TOKENS_STATUS=$COLOR_TOKENS_STATUS"
echo "TYPOGRAPHY_SCALE_STATUS=$TYPOGRAPHY_SCALE_STATUS"
echo "SPACING_TOKENS_STATUS=$SPACING_TOKENS_STATUS"
echo "RADIUS_SHADOW_TOKENS_STATUS=$RADIUS_SHADOW_TOKENS_STATUS"
echo "COMPONENT_USAGE_DOC_STATUS=$COMPONENT_USAGE_DOC_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE END ====="
