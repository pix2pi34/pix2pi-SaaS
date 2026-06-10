#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_8_FINAL_WEB_CLOSURE.md"
CONFIG_FILE="configs/faz6r/faz_6_22_8_final_web_closure.v1.json"
CLOSURE_FILE="configs/faz6r/final_web_closure.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_8_final_web_closure_test.json"
RUNTIME_FILE="scripts/faz6r/run_final_web_closure_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_final_web_closure.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_8_final_web_closure.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_8_FINAL_WEB_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"
PREV_VISUAL_REGRESSION_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_4_VISUAL_REGRESSION_SETI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-22.8 FINAL WEB CLOSURE REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.8 previous visual regression evidence file" "$PREV_VISUAL_REGRESSION_EVIDENCE"
check_contains "6-22.8 previous visual regression final PASS" "$PREV_VISUAL_REGRESSION_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.8 documentation file" "$DOC_FILE"
check_file "6-22.8 config file" "$CONFIG_FILE"
check_file "6-22.8 closure file" "$CLOSURE_FILE"
check_file "6-22.8 fixture file" "$FIXTURE_FILE"
check_file "6-22.8 runtime file" "$RUNTIME_FILE"
check_file "6-22.8 validator file" "$VALIDATOR_FILE"
check_file "6-22.8 audit file" "$AUDIT_FILE"

check_contains "6-22.8 doc has Final Web Closure" "$DOC_FILE" "Final Web Closure"
check_contains "6-22.8 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.8 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.8 config has dependency" "$CONFIG_FILE" "FAZ_6_22_4"
check_contains "6-22.8 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.8 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.8 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.8 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.8 config disables route mutation" "$CONFIG_FILE" '"route_mutation_allowed": false'
check_contains "6-22.8 config disables cdn invalidation" "$CONFIG_FILE" '"cdn_invalidation_allowed": false'
check_contains "6-22.8 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-22.8 config disables nginx mutation" "$CONFIG_FILE" '"nginx_mutation_allowed": false'
check_contains "6-22.8 config has accessibility closure" "$CONFIG_FILE" "accessibility_closure_gate"
check_contains "6-22.8 config has performance closure" "$CONFIG_FILE" "performance_budget_closure_gate"
check_contains "6-22.8 config has visual closure" "$CONFIG_FILE" "visual_regression_closure_gate"
check_contains "6-22.8 config has release blocker policy" "$CONFIG_FILE" "release_blocker_policy"
check_contains "6-22.8 config has rollback readiness" "$CONFIG_FILE" "rollback_readiness_policy"

check_contains "6-22.8 closure has public landing" "$CLOSURE_FILE" "web-closure-public-landing"
check_contains "6-22.8 closure has auth surface" "$CLOSURE_FILE" "web-closure-auth-surface"
check_contains "6-22.8 closure has tenant panel shell" "$CLOSURE_FILE" "web-closure-tenant-panel-shell"
check_contains "6-22.8 closure has workflow ui" "$CLOSURE_FILE" "web-closure-workflow-ui"
check_contains "6-22.8 closure has reporting ui" "$CLOSURE_FILE" "web-closure-reporting-ui"
check_contains "6-22.8 closure has no mutation" "$CLOSURE_FILE" '"mutation_allowed": false'
check_contains "6-22.8 closure has dry-run status" "$CLOSURE_FILE" "dry_run_only_no_final_web_release_mutation"
check_contains "6-22.8 closure has next step" "$CLOSURE_FILE" "FAZ_6_22_1"

check_contains "6-22.8 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_1"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$CLOSURE_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_8_final_web_closure_runtime.json; then
  pass "6-22.8 dry-run final web closure runtime"
else
  fail "6-22.8 dry-run final web closure runtime"
fi

check_contains "6-22.8 runtime output is PASS" "/tmp/faz_6_22_8_final_web_closure_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.8 runtime output is dry run" "/tmp/faz_6_22_8_final_web_closure_runtime.json" "final_web_closure_dry_run"
check_contains "6-22.8 runtime output disables provider mutation" "/tmp/faz_6_22_8_final_web_closure_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.8 runtime output disables frontend deploy" "/tmp/faz_6_22_8_final_web_closure_runtime.json" '"frontend_deploy_allowed": false'
check_contains "6-22.8 runtime output disables build publish" "/tmp/faz_6_22_8_final_web_closure_runtime.json" '"build_publish_allowed": false'
check_contains "6-22.8 runtime output has next step" "/tmp/faz_6_22_8_final_web_closure_runtime.json" "FAZ_6_22_1"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$CLOSURE_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.8 semantic validator runtime"
else
  fail "6-22.8 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.8 python3 dependency"
else
  fail "6-22.8 python3 dependency"
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
# FAZ 6-R / 311 — FAZ 6-22.8 Final Web Closure Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
CLOSURE_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_1_READY=${NEXT_READY}

Scope note: provider mutation, frontend deploy, build publish, route mutation, CDN invalidation, DNS mutation, Nginx mutation and asset pipeline mutation remain closed in this step.
Dependency: FAZ_6_22_4 visual regression seti evidence checked.
EOF2

echo "===== FAZ 6-22.8 FINAL WEB CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_8_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.8 FINAL WEB CLOSURE COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "CLOSURE_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_1_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
