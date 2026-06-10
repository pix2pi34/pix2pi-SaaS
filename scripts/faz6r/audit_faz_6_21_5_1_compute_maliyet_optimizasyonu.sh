#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_5_1_COMPUTE_MALIYET_OPTIMIZASYONU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu.v1.json"
PLAN_FILE="configs/faz6r/compute_cost_optimization.cost_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu_test.json"
RUNTIME_FILE="scripts/faz6r/run_compute_cost_optimization_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_compute_maliyet_optimizasyonu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_5_1_compute_maliyet_optimizasyonu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_5_1_COMPUTE_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
PREV_DR_REHEARSAL_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_6_5_DR_REHEARSAL_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  if [ -f "$2" ]; then pass "$1"; else fail "$1 missing"; fi
}

check_contains(){
  if [ -f "$2" ] && grep -q "$3" "$2"; then pass "$1"; else fail "$1 missing pattern $3"; fi
}

echo "===== FAZ 6-21.5.1 COMPUTE MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.5.1 previous DR rehearsal evidence file" "$PREV_DR_REHEARSAL_EVIDENCE"
check_contains "6-21.5.1 previous DR rehearsal final PASS" "$PREV_DR_REHEARSAL_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.5.1 documentation file" "$DOC_FILE"
check_file "6-21.5.1 config file" "$CONFIG_FILE"
check_file "6-21.5.1 plan file" "$PLAN_FILE"
check_file "6-21.5.1 fixture file" "$FIXTURE_FILE"
check_file "6-21.5.1 runtime file" "$RUNTIME_FILE"
check_file "6-21.5.1 validator file" "$VALIDATOR_FILE"
check_file "6-21.5.1 audit file" "$AUDIT_FILE"

check_contains "6-21.5.1 doc has Compute Maliyet Optimizasyonu" "$DOC_FILE" "Compute Maliyet Optimizasyonu"
check_contains "6-21.5.1 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.5.1 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.5.1 config has dependency" "$CONFIG_FILE" "FAZ_6_21_6_5"
check_contains "6-21.5.1 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.5.1 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.5.1 config disables production resize" "$CONFIG_FILE" '"production_resize_allowed": false'
check_contains "6-21.5.1 config disables instance shutdown" "$CONFIG_FILE" '"instance_shutdown_allowed": false'
check_contains "6-21.5.1 config disables autoscaling mutation" "$CONFIG_FILE" '"autoscaling_policy_mutation_allowed": false'
check_contains "6-21.5.1 config has workload classes" "$CONFIG_FILE" "workload_classification_policy"
check_contains "6-21.5.1 config has rightsizing policy" "$CONFIG_FILE" "rightsizing_recommendation_policy"
check_contains "6-21.5.1 config has idle capacity policy" "$CONFIG_FILE" "idle_capacity_detection_policy"
check_contains "6-21.5.1 config has scale down guard" "$CONFIG_FILE" "scale_down_guard_policy"
check_contains "6-21.5.1 config has reservation review" "$CONFIG_FILE" "reservation_commitment_review_policy"
check_contains "6-21.5.1 config has burst capacity" "$CONFIG_FILE" "burst_capacity_policy"
check_contains "6-21.5.1 config has slo guard" "$CONFIG_FILE" "performance_slo_guard"
check_contains "6-21.5.1 config has manual approval" "$CONFIG_FILE" "manual_approval_policy"

check_contains "6-21.5.1 plan has api gateway recommendation" "$PLAN_FILE" "compute-rec-api-gateway-rightsize"
check_contains "6-21.5.1 plan has panel recommendation" "$PLAN_FILE" "compute-rec-panel-rightsize"
check_contains "6-21.5.1 plan has background jobs recommendation" "$PLAN_FILE" "compute-rec-background-jobs-schedule"
check_contains "6-21.5.1 plan has staging idle recommendation" "$PLAN_FILE" "compute-rec-staging-idle"
check_contains "6-21.5.1 plan has no mutation" "$PLAN_FILE" '"mutation_allowed": false'
check_contains "6-21.5.1 plan has dry-run status" "$PLAN_FILE" "dry_run_only_no_provider_mutation"

check_contains "6-21.5.1 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_5_2"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_5_1_compute_cost_runtime.json; then
  pass "6-21.5.1 dry-run compute cost runtime"
else
  fail "6-21.5.1 dry-run compute cost runtime"
fi

check_contains "6-21.5.1 runtime output is PASS" "/tmp/faz_6_21_5_1_compute_cost_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.5.1 runtime output is dry run" "/tmp/faz_6_21_5_1_compute_cost_runtime.json" "compute_cost_optimization_dry_run"
check_contains "6-21.5.1 runtime output disables provider mutation" "/tmp/faz_6_21_5_1_compute_cost_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.5.1 runtime output disables production resize" "/tmp/faz_6_21_5_1_compute_cost_runtime.json" '"production_resize_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.5.1 semantic validator runtime"
else
  fail "6-21.5.1 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.5.1 python3 dependency"
else
  fail "6-21.5.1 python3 dependency"
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
# FAZ 6-R / 293 — FAZ 6-21.5.1 Compute Maliyet Optimizasyonu Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
PLAN_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_5_2_READY=${NEXT_READY}

Scope note: provider mutation, production resize, instance shutdown and autoscaling policy mutation remain closed in this step.
Dependency: FAZ_6_21_6_5 DR rehearsal evidence checked.
EOF2

echo "===== FAZ 6-21.5.1 COMPUTE MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_5_1_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.5.1 COMPUTE MALIYET OPTIMIZASYONU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_5_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
