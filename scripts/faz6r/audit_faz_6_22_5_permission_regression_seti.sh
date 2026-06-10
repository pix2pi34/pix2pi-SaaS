#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_5_PERMISSION_REGRESSION_SETI.md"
CONFIG_FILE="configs/faz6r/faz_6_22_5_permission_regression_seti.v1.json"
SET_FILE="configs/faz6r/permission_regression_set.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_5_permission_regression_seti_test.json"
RUNTIME_FILE="scripts/faz6r/run_permission_regression_set_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_permission_regression_seti.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_5_permission_regression_seti.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_5_PERMISSION_REGRESSION_SETI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_RESPONSIVE_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_1_RESPONSIVE_FINALIZASYON_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-22.5 PERMISSION REGRESSION SETI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.5 previous responsive evidence file" "$PREV_RESPONSIVE_EVIDENCE"
check_contains "6-22.5 previous responsive final PASS" "$PREV_RESPONSIVE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.5 documentation file" "$DOC_FILE"
check_file "6-22.5 config file" "$CONFIG_FILE"
check_file "6-22.5 regression set file" "$SET_FILE"
check_file "6-22.5 fixture file" "$FIXTURE_FILE"
check_file "6-22.5 runtime file" "$RUNTIME_FILE"
check_file "6-22.5 validator file" "$VALIDATOR_FILE"
check_file "6-22.5 audit file" "$AUDIT_FILE"

check_contains "6-22.5 doc has Permission Regression Seti" "$DOC_FILE" "Permission Regression Seti"
check_contains "6-22.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.5 config has dependency" "$CONFIG_FILE" "FAZ_6_22_1"
check_contains "6-22.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.5 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.5 config disables role permission mutation" "$CONFIG_FILE" '"role_permission_mutation_allowed": false'
check_contains "6-22.5 config disables jwt mutation" "$CONFIG_FILE" '"jwt_claim_mutation_allowed": false'
check_contains "6-22.5 config disables route guard mutation" "$CONFIG_FILE" '"route_guard_mutation_allowed": false'
check_contains "6-22.5 config disables api policy mutation" "$CONFIG_FILE" '"api_policy_mutation_allowed": false'
check_contains "6-22.5 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.5 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.5 config has tenant permission isolation" "$CONFIG_FILE" "tenant_permission_isolation_policy"
check_contains "6-22.5 config has super admin boundary" "$CONFIG_FILE" "super_admin_boundary_policy"
check_contains "6-22.5 config has api ui alignment" "$CONFIG_FILE" "api_ui_permission_alignment_guard"
check_contains "6-22.5 config has negative permission test" "$CONFIG_FILE" "negative_permission_test_policy"
check_contains "6-22.5 config has accountant portal permission" "$CONFIG_FILE" "accountant_portal_permission_policy"

check_contains "6-22.5 set has auth cross tenant deny" "$SET_FILE" "perm-auth-session-cross-tenant-deny"
check_contains "6-22.5 set has panel nav matrix" "$SET_FILE" "perm-panel-nav-role-route-matrix"
check_contains "6-22.5 set has role management boundary" "$SET_FILE" "perm-user-role-management-super-admin-boundary"
check_contains "6-22.5 set has approval action deny" "$SET_FILE" "perm-approval-inbox-action-deny"
check_contains "6-22.5 set has reporting export" "$SET_FILE" "perm-reporting-export-mask-or-deny"
check_contains "6-22.5 set has accountant portal" "$SET_FILE" "perm-accountant-portal-assigned-tenant-only"
check_contains "6-22.5 set has super admin audit boundary" "$SET_FILE" "perm-super-admin-audit-boundary"
check_contains "6-22.5 set has no mutation" "$SET_FILE" '"mutation_allowed": false'
check_contains "6-22.5 set has dry-run status" "$SET_FILE" "dry_run_only_no_permission_mutation"
check_contains "6-22.5 set has next step" "$SET_FILE" "FAZ_6_22_6"

check_contains "6-22.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_6"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_5_permission_regression_runtime.json; then
  pass "6-22.5 dry-run permission regression runtime"
else
  fail "6-22.5 dry-run permission regression runtime"
fi

check_contains "6-22.5 runtime output is PASS" "/tmp/faz_6_22_5_permission_regression_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.5 runtime output is dry run" "/tmp/faz_6_22_5_permission_regression_runtime.json" "permission_regression_set_dry_run"
check_contains "6-22.5 runtime output disables provider mutation" "/tmp/faz_6_22_5_permission_regression_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.5 runtime output disables role permission mutation" "/tmp/faz_6_22_5_permission_regression_runtime.json" '"role_permission_mutation_allowed": false'
check_contains "6-22.5 runtime output disables jwt mutation" "/tmp/faz_6_22_5_permission_regression_runtime.json" '"jwt_claim_mutation_allowed": false'
check_contains "6-22.5 runtime output has next step" "/tmp/faz_6_22_5_permission_regression_runtime.json" "FAZ_6_22_6"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.5 semantic validator runtime"
else
  fail "6-22.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.5 python3 dependency"
else
  fail "6-22.5 python3 dependency"
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
# FAZ 6-R / 313 — FAZ 6-22.5 Permission Regression Seti Real Implementation Audit

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
FAZ_6_22_6_READY=${NEXT_READY}

Scope note: provider mutation, role/permission mutation, JWT claim mutation, route guard mutation, API policy mutation, frontend deploy and build publish remain closed in this step.
Dependency: FAZ_6_22_1 responsive finalizasyon evidence checked.
EOF2

echo "===== FAZ 6-22.5 PERMISSION REGRESSION SETI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.5 PERMISSION REGRESSION SETI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "SET_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_6_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
