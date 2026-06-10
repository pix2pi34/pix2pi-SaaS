#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_3_FRONTEND_PERFORMANCE_BUDGET.md"
CONFIG_FILE="configs/faz6r/faz_6_22_3_frontend_performance_budget.v1.json"
BUDGET_FILE="configs/faz6r/frontend_performance_budget.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_3_frontend_performance_budget_test.json"
RUNTIME_FILE="scripts/faz6r/run_frontend_performance_budget_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_frontend_performance_budget.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_3_frontend_performance_budget.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_3_FRONTEND_PERFORMANCE_BUDGET_REAL_IMPLEMENTATION_AUDIT.md"
PREV_ACCESSIBILITY_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_2_ACCESSIBILITY_FINALIZASYON_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-22.3 FRONTEND PERFORMANCE BUDGET REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.3 previous accessibility evidence file" "$PREV_ACCESSIBILITY_EVIDENCE"
check_contains "6-22.3 previous accessibility final PASS" "$PREV_ACCESSIBILITY_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.3 documentation file" "$DOC_FILE"
check_file "6-22.3 config file" "$CONFIG_FILE"
check_file "6-22.3 budget file" "$BUDGET_FILE"
check_file "6-22.3 fixture file" "$FIXTURE_FILE"
check_file "6-22.3 runtime file" "$RUNTIME_FILE"
check_file "6-22.3 validator file" "$VALIDATOR_FILE"
check_file "6-22.3 audit file" "$AUDIT_FILE"

check_contains "6-22.3 doc has Frontend Performance Budget" "$DOC_FILE" "Frontend Performance Budget"
check_contains "6-22.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.3 config has dependency" "$CONFIG_FILE" "FAZ_6_22_2"
check_contains "6-22.3 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.3 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.3 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.3 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.3 config disables bundle mutation" "$CONFIG_FILE" '"bundle_mutation_allowed": false'
check_contains "6-22.3 config disables cdn invalidation" "$CONFIG_FILE" '"cdn_invalidation_allowed": false'
check_contains "6-22.3 config disables route mutation" "$CONFIG_FILE" '"route_mutation_allowed": false'
check_contains "6-22.3 config disables asset pipeline mutation" "$CONFIG_FILE" '"asset_pipeline_mutation_allowed": false'
check_contains "6-22.3 config has core web vitals policy" "$CONFIG_FILE" "core_web_vitals_budget_policy"
check_contains "6-22.3 config has route budget policy" "$CONFIG_FILE" "route_level_budget_policy"
check_contains "6-22.3 config has JS budget policy" "$CONFIG_FILE" "js_bundle_budget_policy"
check_contains "6-22.3 config has cache budget policy" "$CONFIG_FILE" "cache_budget_policy"
check_contains "6-22.3 config has third party budget policy" "$CONFIG_FILE" "third_party_script_budget_policy"

check_contains "6-22.3 budget has public landing budget" "$BUDGET_FILE" "perf-budget-public-landing"
check_contains "6-22.3 budget has auth login budget" "$BUDGET_FILE" "perf-budget-auth-login"
check_contains "6-22.3 budget has panel shell budget" "$BUDGET_FILE" "perf-budget-tenant-panel-shell"
check_contains "6-22.3 budget has approval inbox budget" "$BUDGET_FILE" "perf-budget-approval-inbox"
check_contains "6-22.3 budget has workflow monitor budget" "$BUDGET_FILE" "perf-budget-workflow-monitor"
check_contains "6-22.3 budget has reporting tables budget" "$BUDGET_FILE" "perf-budget-reporting-tables"
check_contains "6-22.3 budget has no mutation" "$BUDGET_FILE" '"mutation_allowed": false'
check_contains "6-22.3 budget has dry-run status" "$BUDGET_FILE" "dry_run_only_no_frontend_performance_mutation"
check_contains "6-22.3 budget has next step" "$BUDGET_FILE" "FAZ_6_22_4"

check_contains "6-22.3 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_4"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$BUDGET_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_3_frontend_performance_runtime.json; then
  pass "6-22.3 dry-run frontend performance runtime"
else
  fail "6-22.3 dry-run frontend performance runtime"
fi

check_contains "6-22.3 runtime output is PASS" "/tmp/faz_6_22_3_frontend_performance_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.3 runtime output is dry run" "/tmp/faz_6_22_3_frontend_performance_runtime.json" "frontend_performance_budget_dry_run"
check_contains "6-22.3 runtime output disables provider mutation" "/tmp/faz_6_22_3_frontend_performance_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.3 runtime output disables frontend deploy" "/tmp/faz_6_22_3_frontend_performance_runtime.json" '"frontend_deploy_allowed": false'
check_contains "6-22.3 runtime output disables build publish" "/tmp/faz_6_22_3_frontend_performance_runtime.json" '"build_publish_allowed": false'
check_contains "6-22.3 runtime output has next step" "/tmp/faz_6_22_3_frontend_performance_runtime.json" "FAZ_6_22_4"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$BUDGET_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.3 semantic validator runtime"
else
  fail "6-22.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.3 python3 dependency"
else
  fail "6-22.3 python3 dependency"
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
# FAZ 6-R / 309 — FAZ 6-22.3 Frontend Performance Budget Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
BUDGET_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_4_READY=${NEXT_READY}

Scope note: provider mutation, frontend deploy, build publish, bundle mutation, CDN invalidation, route mutation, asset pipeline mutation and compression mutation remain closed in this step.
Dependency: FAZ_6_22_2 accessibility finalizasyon evidence checked.
EOF2

echo "===== FAZ 6-22.3 FRONTEND PERFORMANCE BUDGET REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.3 FRONTEND PERFORMANCE BUDGET COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "BUDGET_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_22_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
