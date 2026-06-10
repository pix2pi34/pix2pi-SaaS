#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/runtime-config"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/runtime_config.js"
CSS_FILE="$WEB_DIR/runtime_config.css"
CONFIG_FILE="$CONFIG_DIR/runtime_config_environment_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"environment_indicator"' "3.1 environment_indicator capability contract"
check_contains "$CONFIG_FILE" '"runtime_config_surface"' "3.2 runtime_config_surface capability contract"
check_contains "$CONFIG_FILE" '"config_permission_guard"' "3.3 config_permission_guard capability contract"
check_contains "$CONFIG_FILE" '"read_only_config_view"' "3.4 read_only_config_view capability contract"
check_contains "$CONFIG_FILE" '"tests"' "3.5 tests capability contract"

check_contains "$HTML_FILE" 'pix2piEnvironmentIndicator' "4.1 environment indicator HTML"
check_contains "$HTML_FILE" 'pix2piRuntimeConfigSurface' "4.2 runtime config surface HTML"
check_contains "$HTML_FILE" 'pix2piConfigPermissionGuard' "4.3 config permission guard HTML"
check_contains "$HTML_FILE" 'READ_ONLY_CONFIG_VIEW' "4.4 read-only config view HTML"
check_contains "$HTML_FILE" 'runRuntimeConfigTestsButton' "4.5 tests button HTML"

check_contains "$JS_FILE" 'renderEnvironmentIndicator' "5.1 environment indicator JS"
check_contains "$JS_FILE" 'renderRuntimeConfigSurface' "5.2 runtime config surface JS"
check_contains "$JS_FILE" 'hasConfigReadPermission' "5.3 config permission guard JS"
check_contains "$JS_FILE" 'validateReadOnlyConfigView' "5.4 read-only config view JS"
check_contains "$JS_FILE" 'runRuntimeConfigTests' "5.5 tests JS"
check_contains "$JS_FILE" 'NEVER_RENDER' "5.6 secret never render policy JS"

check_contains "$CSS_FILE" 'pix2pi-badge.production' "6.1 production environment CSS"
check_contains "$CSS_FILE" 'pix2pi-config-surface' "6.2 runtime config surface CSS"
check_contains "$CSS_FILE" 'pix2pi-config-guard' "6.3 permission guard CSS"
check_contains "$CSS_FILE" 'pix2pi-readonly-banner' "6.4 read-only view CSS"
check_contains "$CSS_FILE" 'pix2pi-config-table' "6.5 config table CSS"

ENVIRONMENT_INDICATOR_STATUS="PASS"
RUNTIME_CONFIG_SURFACE_STATUS="PASS"
CONFIG_PERMISSION_GUARD_STATUS="PASS"
READ_ONLY_CONFIG_VIEW_STATUS="PASS"
TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  ENVIRONMENT_INDICATOR_STATUS="FAIL"
  RUNTIME_CONFIG_SURFACE_STATUS="FAIL"
  CONFIG_PERMISSION_GUARD_STATUS="FAIL"
  READ_ONLY_CONFIG_VIEW_STATUS="FAIL"
  TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.7 Runtime Config / Environment Surfaces Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- ENVIRONMENT_INDICATOR_STATUS=$ENVIRONMENT_INDICATOR_STATUS"
  echo "- RUNTIME_CONFIG_SURFACE_STATUS=$RUNTIME_CONFIG_SURFACE_STATUS"
  echo "- CONFIG_PERMISSION_GUARD_STATUS=$CONFIG_PERMISSION_GUARD_STATUS"
  echo "- READ_ONLY_CONFIG_VIEW_STATUS=$READ_ONLY_CONFIG_VIEW_STATUS"
  echo "- TESTS_STATUS=$TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENVIRONMENT_INDICATOR_STATUS=$ENVIRONMENT_INDICATOR_STATUS"
echo "RUNTIME_CONFIG_SURFACE_STATUS=$RUNTIME_CONFIG_SURFACE_STATUS"
echo "CONFIG_PERMISSION_GUARD_STATUS=$CONFIG_PERMISSION_GUARD_STATUS"
echo "READ_ONLY_CONFIG_VIEW_STATUS=$READ_ONLY_CONFIG_VIEW_STATUS"
echo "TESTS_STATUS=$TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE END ====="
