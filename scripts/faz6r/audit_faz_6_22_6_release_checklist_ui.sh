#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_6_RELEASE_CHECKLIST_UI.md"
CONFIG_FILE="configs/faz6r/faz_6_22_6_release_checklist_ui.v1.json"
UI_FILE="configs/faz6r/release_checklist_ui.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_6_release_checklist_ui_test.json"
RUNTIME_FILE="scripts/faz6r/run_release_checklist_ui_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_release_checklist_ui.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_6_release_checklist_ui.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_6_RELEASE_CHECKLIST_UI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_PERMISSION_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_5_PERMISSION_REGRESSION_SETI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-22.6 RELEASE CHECKLIST UI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.6 previous permission regression evidence file" "$PREV_PERMISSION_EVIDENCE"
check_contains "6-22.6 previous permission regression final PASS" "$PREV_PERMISSION_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.6 documentation file" "$DOC_FILE"
check_file "6-22.6 config file" "$CONFIG_FILE"
check_file "6-22.6 UI file" "$UI_FILE"
check_file "6-22.6 fixture file" "$FIXTURE_FILE"
check_file "6-22.6 runtime file" "$RUNTIME_FILE"
check_file "6-22.6 validator file" "$VALIDATOR_FILE"
check_file "6-22.6 audit file" "$AUDIT_FILE"

check_contains "6-22.6 doc has Release Checklist UI" "$DOC_FILE" "Release Checklist UI"
check_contains "6-22.6 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.6 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.6 config has dependency" "$CONFIG_FILE" "FAZ_6_22_5"
check_contains "6-22.6 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.6 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.6 config disables ui deploy" "$CONFIG_FILE" '"ui_deploy_allowed": false'
check_contains "6-22.6 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.6 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.6 config disables route mutation" "$CONFIG_FILE" '"route_mutation_allowed": false'
check_contains "6-22.6 config disables checklist mutation" "$CONFIG_FILE" '"checklist_state_mutation_allowed": false'
check_contains "6-22.6 config disables approval mutation" "$CONFIG_FILE" '"approval_state_mutation_allowed": false'
check_contains "6-22.6 config has release gate visibility" "$CONFIG_FILE" "release_gate_visibility_policy"
check_contains "6-22.6 config has blocker status" "$CONFIG_FILE" "blocker_status_policy"
check_contains "6-22.6 config has dependency evidence display" "$CONFIG_FILE" "dependency_evidence_display_policy"
check_contains "6-22.6 config has tenant safe visibility" "$CONFIG_FILE" "tenant_safe_release_visibility_policy"
check_contains "6-22.6 config has audit evidence link" "$CONFIG_FILE" "audit_evidence_link_policy"

check_contains "6-22.6 UI has security edge section" "$UI_FILE" "release-ui-security-edge-sre-ops"
check_contains "6-22.6 UI has DR cost section" "$UI_FILE" "release-ui-dr-cost-tuning"
check_contains "6-22.6 UI has DB scale section" "$UI_FILE" "release-ui-db-scale-readiness"
check_contains "6-22.6 UI has web polish section" "$UI_FILE" "release-ui-web-polish"
check_contains "6-22.6 UI has permission section" "$UI_FILE" "release-ui-permission-release-ui"
check_contains "6-22.6 UI has build readiness section" "$UI_FILE" "release-ui-build-readiness"
check_contains "6-22.6 UI has no mutation" "$UI_FILE" '"mutation_allowed": false'
check_contains "6-22.6 UI has dry-run status" "$UI_FILE" "dry_run_only_no_release_checklist_ui_mutation"
check_contains "6-22.6 UI has next step" "$UI_FILE" "FAZ_6_22_7"

check_contains "6-22.6 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_7"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$UI_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_6_release_checklist_ui_runtime.json; then
  pass "6-22.6 dry-run release checklist UI runtime"
else
  fail "6-22.6 dry-run release checklist UI runtime"
fi

check_contains "6-22.6 runtime output is PASS" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.6 runtime output is dry run" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" "release_checklist_ui_dry_run"
check_contains "6-22.6 runtime output disables provider mutation" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.6 runtime output disables ui deploy" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" '"ui_deploy_allowed": false'
check_contains "6-22.6 runtime output disables checklist mutation" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" '"checklist_state_mutation_allowed": false'
check_contains "6-22.6 runtime output has next step" "/tmp/faz_6_22_6_release_checklist_ui_runtime.json" "FAZ_6_22_7"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$UI_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.6 semantic validator runtime"
else
  fail "6-22.6 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.6 python3 dependency"
else
  fail "6-22.6 python3 dependency"
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
# FAZ 6-R / 314 — FAZ 6-22.6 Release Checklist UI Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
UI_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_7_READY=${NEXT_READY}

Scope note: provider mutation, UI/frontend deploy, build publish, route mutation, checklist state mutation, approval state mutation and CDN invalidation remain closed in this step.
Dependency: FAZ_6_22_5 permission regression seti evidence checked.
EOF2

echo "===== FAZ 6-22.6 RELEASE CHECKLIST UI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_6_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.6 RELEASE CHECKLIST UI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "UI_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_7_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
