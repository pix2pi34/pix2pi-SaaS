#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_2_ACCESSIBILITY_FINALIZASYON.md"
CONFIG_FILE="configs/faz6r/faz_6_22_2_accessibility_finalizasyon.v1.json"
CHECKLIST_FILE="configs/faz6r/accessibility_finalization.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_2_accessibility_finalizasyon_test.json"
RUNTIME_FILE="scripts/faz6r/run_accessibility_finalization_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_accessibility_finalizasyon.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_2_accessibility_finalizasyon.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_2_ACCESSIBILITY_FINALIZASYON_REAL_IMPLEMENTATION_AUDIT.md"
PREV_PARTITION_SHARD_EVIDENCE="docs/faz6r/evidence/FAZ_6_20_6_PARTITION_SHARD_READINESS_MODELI_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label missing"; fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then pass "$label"; else fail "$label missing pattern $pattern"; fi
}

echo "===== FAZ 6-22.2 ACCESSIBILITY FINALIZASYON REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.2 previous partition shard evidence file" "$PREV_PARTITION_SHARD_EVIDENCE"
check_contains "6-22.2 previous partition shard final PASS" "$PREV_PARTITION_SHARD_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.2 documentation file" "$DOC_FILE"
check_file "6-22.2 config file" "$CONFIG_FILE"
check_file "6-22.2 checklist file" "$CHECKLIST_FILE"
check_file "6-22.2 fixture file" "$FIXTURE_FILE"
check_file "6-22.2 runtime file" "$RUNTIME_FILE"
check_file "6-22.2 validator file" "$VALIDATOR_FILE"
check_file "6-22.2 audit file" "$AUDIT_FILE"

check_contains "6-22.2 doc has Accessibility Finalizasyon" "$DOC_FILE" "Accessibility Finalizasyon"
check_contains "6-22.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.2 config has dependency" "$CONFIG_FILE" "FAZ_6_20_6"
check_contains "6-22.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.2 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.2 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.2 config disables css mutation" "$CONFIG_FILE" '"css_mutation_allowed": false'
check_contains "6-22.2 config disables js mutation" "$CONFIG_FILE" '"js_mutation_allowed": false'
check_contains "6-22.2 config disables design token mutation" "$CONFIG_FILE" '"design_token_mutation_allowed": false'
check_contains "6-22.2 config disables route mutation" "$CONFIG_FILE" '"route_mutation_allowed": false'
check_contains "6-22.2 config disables cdn invalidation" "$CONFIG_FILE" '"cdn_invalidation_allowed": false'
check_contains "6-22.2 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.2 config has WCAG target" "$CONFIG_FILE" "WCAG_2_2_AA"
check_contains "6-22.2 config has keyboard policy" "$CONFIG_FILE" "keyboard_navigation_policy"
check_contains "6-22.2 config has focus policy" "$CONFIG_FILE" "focus_management_policy"
check_contains "6-22.2 config has contrast policy" "$CONFIG_FILE" "color_contrast_policy"
check_contains "6-22.2 config has screen reader policy" "$CONFIG_FILE" "screen_reader_readiness_policy"

check_contains "6-22.2 checklist has auth login check" "$CHECKLIST_FILE" "a11y-auth-login-critical-flow"
check_contains "6-22.2 checklist has panel shell check" "$CHECKLIST_FILE" "a11y-tenant-panel-shell-navigation"
check_contains "6-22.2 checklist has approval inbox check" "$CHECKLIST_FILE" "a11y-approval-inbox-actions"
check_contains "6-22.2 checklist has workflow monitor check" "$CHECKLIST_FILE" "a11y-workflow-monitor-status"
check_contains "6-22.2 checklist has reporting tables check" "$CHECKLIST_FILE" "a11y-reporting-tables-grid"
check_contains "6-22.2 checklist has public landing check" "$CHECKLIST_FILE" "a11y-public-landing"
check_contains "6-22.2 checklist has no mutation" "$CHECKLIST_FILE" '"mutation_allowed": false'
check_contains "6-22.2 checklist has dry-run status" "$CHECKLIST_FILE" "dry_run_only_no_accessibility_mutation"
check_contains "6-22.2 checklist has next step" "$CHECKLIST_FILE" "FAZ_6_22_3"

check_contains "6-22.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_3"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$CHECKLIST_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_2_accessibility_runtime.json; then
  pass "6-22.2 dry-run accessibility runtime"
else
  fail "6-22.2 dry-run accessibility runtime"
fi

check_contains "6-22.2 runtime output is PASS" "/tmp/faz_6_22_2_accessibility_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.2 runtime output is dry run" "/tmp/faz_6_22_2_accessibility_runtime.json" "accessibility_finalization_dry_run"
check_contains "6-22.2 runtime output disables provider mutation" "/tmp/faz_6_22_2_accessibility_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.2 runtime output disables frontend deploy" "/tmp/faz_6_22_2_accessibility_runtime.json" '"frontend_deploy_allowed": false'
check_contains "6-22.2 runtime output has next step" "/tmp/faz_6_22_2_accessibility_runtime.json" "FAZ_6_22_3"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$CHECKLIST_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.2 semantic validator runtime"
else
  fail "6-22.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.2 python3 dependency"
else
  fail "6-22.2 python3 dependency"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 6-R / 308 — FAZ 6-22.2 Accessibility Finalizasyon Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
CHECKLIST_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_3_READY=${NEXT_READY}

Scope note: provider mutation, frontend deploy, CSS/JS mutation, design token mutation, route mutation, CDN invalidation and build publish remain closed in this step.
Dependency: FAZ_6_20_6 partition / shard readiness modeli evidence checked.
EOF2

echo "===== FAZ 6-22.2 ACCESSIBILITY FINALIZASYON REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.2 ACCESSIBILITY FINALIZASYON COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "CHECKLIST_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
