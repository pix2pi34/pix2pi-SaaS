#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_5_5_COST_PERFORMANCE_RAPORU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_5_5_cost_performance_raporu.v1.json"
REPORT_FILE="configs/faz6r/cost_performance_report.cost_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_5_5_cost_performance_raporu_test.json"
RUNTIME_FILE="scripts/faz6r/run_cost_performance_report_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_cost_performance_raporu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_5_5_cost_performance_raporu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_5_5_COST_PERFORMANCE_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

COMPUTE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_1_COMPUTE_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
DB_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_2_DB_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
STORAGE_LOG_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_3_STORAGE_LOG_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
CACHE_QUEUE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_4_CACHE_QUEUE_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.5.5 COST-PERFORMANCE RAPORU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.5.5 compute cost evidence file" "$COMPUTE_EVIDENCE"
check_contains "6-21.5.5 compute cost final PASS" "$COMPUTE_EVIDENCE" "FINAL_STATUS=PASS"
check_file "6-21.5.5 DB cost evidence file" "$DB_EVIDENCE"
check_contains "6-21.5.5 DB cost final PASS" "$DB_EVIDENCE" "FINAL_STATUS=PASS"
check_file "6-21.5.5 storage log cost evidence file" "$STORAGE_LOG_EVIDENCE"
check_contains "6-21.5.5 storage log cost final PASS" "$STORAGE_LOG_EVIDENCE" "FINAL_STATUS=PASS"
check_file "6-21.5.5 cache queue cost evidence file" "$CACHE_QUEUE_EVIDENCE"
check_contains "6-21.5.5 cache queue cost final PASS" "$CACHE_QUEUE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.5.5 documentation file" "$DOC_FILE"
check_file "6-21.5.5 config file" "$CONFIG_FILE"
check_file "6-21.5.5 report file" "$REPORT_FILE"
check_file "6-21.5.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.5.5 runtime file" "$RUNTIME_FILE"
check_file "6-21.5.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.5.5 audit file" "$AUDIT_FILE"

check_contains "6-21.5.5 doc has Cost-Performance Raporu" "$DOC_FILE" "Cost-Performance Raporu"
check_contains "6-21.5.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.5.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.5.5 config has compute dependency" "$CONFIG_FILE" "FAZ_6_21_5_1"
check_contains "6-21.5.5 config has DB dependency" "$CONFIG_FILE" "FAZ_6_21_5_2"
check_contains "6-21.5.5 config has storage log dependency" "$CONFIG_FILE" "FAZ_6_21_5_3"
check_contains "6-21.5.5 config has cache queue dependency" "$CONFIG_FILE" "FAZ_6_21_5_4"
check_contains "6-21.5.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.5.5 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.5.5 config disables production change" "$CONFIG_FILE" '"production_change_allowed": false'
check_contains "6-21.5.5 config disables cost action execute" "$CONFIG_FILE" '"cost_action_execute_allowed": false'
check_contains "6-21.5.5 config has risk impact matrix" "$CONFIG_FILE" "risk_impact_matrix"
check_contains "6-21.5.5 config has savings priority model" "$CONFIG_FILE" "savings_priority_model"
check_contains "6-21.5.5 config has slo dr data safety guard" "$CONFIG_FILE" "slo_dr_data_safety_guard"
check_contains "6-21.5.5 config has tenant isolation guard" "$CONFIG_FILE" "tenant_isolation_guard"

check_contains "6-21.5.5 report has compute category" "$REPORT_FILE" '"category": "compute"'
check_contains "6-21.5.5 report has database category" "$REPORT_FILE" '"category": "database"'
check_contains "6-21.5.5 report has storage log category" "$REPORT_FILE" '"category": "storage_log"'
check_contains "6-21.5.5 report has cache queue category" "$REPORT_FILE" '"category": "cache_queue"'
check_contains "6-21.5.5 report has performance regression risk" "$REPORT_FILE" "performance_regression"
check_contains "6-21.5.5 report has data loss risk" "$REPORT_FILE" "data_loss"
check_contains "6-21.5.5 report has tenant isolation risk" "$REPORT_FILE" "tenant_isolation_break"
check_contains "6-21.5.5 report has next tuning step" "$REPORT_FILE" "FAZ_6_21_3_3"
check_contains "6-21.5.5 report has no mutation" "$REPORT_FILE" '"mutation_allowed": false'

check_contains "6-21.5.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_3_3"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$REPORT_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_5_5_cost_performance_runtime.json; then
  pass "6-21.5.5 dry-run cost-performance runtime"
else
  fail "6-21.5.5 dry-run cost-performance runtime"
fi

check_contains "6-21.5.5 runtime output is PASS" "/tmp/faz_6_21_5_5_cost_performance_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.5.5 runtime output is dry run" "/tmp/faz_6_21_5_5_cost_performance_runtime.json" "cost_performance_report_dry_run"
check_contains "6-21.5.5 runtime output disables provider mutation" "/tmp/faz_6_21_5_5_cost_performance_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.5.5 runtime output has next step" "/tmp/faz_6_21_5_5_cost_performance_runtime.json" "FAZ_6_21_3_3"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$REPORT_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.5.5 semantic validator runtime"
else
  fail "6-21.5.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.5.5 python3 dependency"
else
  fail "6-21.5.5 python3 dependency"
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
# FAZ 6-R / 297 — FAZ 6-21.5.5 Cost-Performance Raporu Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
REPORT_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_3_3_READY=${NEXT_READY}

Scope note: provider mutation, production change, resize, delete, purge, retention, TTL, queue and DB mutations remain closed in this step.
Dependencies checked:
- FAZ_6_21_5_1 compute cost
- FAZ_6_21_5_2 DB cost
- FAZ_6_21_5_3 storage/log cost
- FAZ_6_21_5_4 cache/queue cost
EOF2

echo "===== FAZ 6-21.5.5 COST-PERFORMANCE RAPORU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_5_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.5.5 COST-PERFORMANCE RAPORU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "REPORT_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_3_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
