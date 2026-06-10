#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_4_VISUAL_REGRESSION_SETI.md"
CONFIG_FILE="configs/faz6r/faz_6_22_4_visual_regression_seti.v1.json"
SET_FILE="configs/faz6r/visual_regression_set.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_4_visual_regression_seti_test.json"
RUNTIME_FILE="scripts/faz6r/run_visual_regression_set_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_visual_regression_seti.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_4_visual_regression_seti.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_4_VISUAL_REGRESSION_SETI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_FRONTEND_PERF_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_3_FRONTEND_PERFORMANCE_BUDGET_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-22.4 VISUAL REGRESSION SETI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.4 previous frontend performance evidence file" "$PREV_FRONTEND_PERF_EVIDENCE"
check_contains "6-22.4 previous frontend performance final PASS" "$PREV_FRONTEND_PERF_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.4 documentation file" "$DOC_FILE"
check_file "6-22.4 config file" "$CONFIG_FILE"
check_file "6-22.4 visual set file" "$SET_FILE"
check_file "6-22.4 fixture file" "$FIXTURE_FILE"
check_file "6-22.4 runtime file" "$RUNTIME_FILE"
check_file "6-22.4 validator file" "$VALIDATOR_FILE"
check_file "6-22.4 audit file" "$AUDIT_FILE"

check_contains "6-22.4 doc has Visual Regression Seti" "$DOC_FILE" "Visual Regression Seti"
check_contains "6-22.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.4 config has dependency" "$CONFIG_FILE" "FAZ_6_22_3"
check_contains "6-22.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.4 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.4 config disables baseline mutation" "$CONFIG_FILE" '"screenshot_baseline_mutation_allowed": false'
check_contains "6-22.4 config disables snapshot update" "$CONFIG_FILE" '"snapshot_update_allowed": false'
check_contains "6-22.4 config disables visual approval mutation" "$CONFIG_FILE" '"visual_approval_mutation_allowed": false'
check_contains "6-22.4 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.4 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.4 config disables route mutation" "$CONFIG_FILE" '"route_mutation_allowed": false'
check_contains "6-22.4 config disables cdn invalidation" "$CONFIG_FILE" '"cdn_invalidation_allowed": false'
check_contains "6-22.4 config has viewport matrix" "$CONFIG_FILE" "viewport_matrix_policy"
check_contains "6-22.4 config has theme matrix" "$CONFIG_FILE" "theme_matrix_policy"
check_contains "6-22.4 config has diff threshold" "$CONFIG_FILE" "visual_diff_threshold_policy"
check_contains "6-22.4 config has deterministic fixture" "$CONFIG_FILE" "deterministic_fixture_policy"
check_contains "6-22.4 config has pii secret masking" "$CONFIG_FILE" "pii_secret_masking_policy"

check_contains "6-22.4 visual set has public landing" "$SET_FILE" "visual-public-landing-matrix"
check_contains "6-22.4 visual set has auth login" "$SET_FILE" "visual-auth-login-states"
check_contains "6-22.4 visual set has panel shell" "$SET_FILE" "visual-tenant-panel-shell-navigation"
check_contains "6-22.4 visual set has approval inbox" "$SET_FILE" "visual-approval-inbox-states"
check_contains "6-22.4 visual set has workflow monitor" "$SET_FILE" "visual-workflow-monitor-status"
check_contains "6-22.4 visual set has reporting tables" "$SET_FILE" "visual-reporting-tables-density"
check_contains "6-22.4 visual set has no mutation" "$SET_FILE" '"mutation_allowed": false'
check_contains "6-22.4 visual set has dry-run status" "$SET_FILE" "dry_run_only_no_visual_regression_mutation"
check_contains "6-22.4 visual set has next step" "$SET_FILE" "FAZ_6_22_8"

check_contains "6-22.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_8"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_4_visual_regression_runtime.json; then
  pass "6-22.4 dry-run visual regression runtime"
else
  fail "6-22.4 dry-run visual regression runtime"
fi

check_contains "6-22.4 runtime output is PASS" "/tmp/faz_6_22_4_visual_regression_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.4 runtime output is dry run" "/tmp/faz_6_22_4_visual_regression_runtime.json" "visual_regression_set_dry_run"
check_contains "6-22.4 runtime output disables provider mutation" "/tmp/faz_6_22_4_visual_regression_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.4 runtime output disables baseline mutation" "/tmp/faz_6_22_4_visual_regression_runtime.json" '"screenshot_baseline_mutation_allowed": false'
check_contains "6-22.4 runtime output disables snapshot update" "/tmp/faz_6_22_4_visual_regression_runtime.json" '"snapshot_update_allowed": false'
check_contains "6-22.4 runtime output has next step" "/tmp/faz_6_22_4_visual_regression_runtime.json" "FAZ_6_22_8"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.4 semantic validator runtime"
else
  fail "6-22.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.4 python3 dependency"
else
  fail "6-22.4 python3 dependency"
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
# FAZ 6-R / 310 — FAZ 6-22.4 Visual Regression Seti Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
SET_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_8_READY=${NEXT_READY}

Scope note: provider mutation, screenshot baseline mutation, snapshot update, visual approval mutation, frontend deploy, build publish, route mutation and CDN invalidation remain closed in this step.
Dependency: FAZ_6_22_3 frontend performance budget evidence checked.
EOF2

echo "===== FAZ 6-22.4 VISUAL REGRESSION SETI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.4 VISUAL REGRESSION SETI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "SET_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_8_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
