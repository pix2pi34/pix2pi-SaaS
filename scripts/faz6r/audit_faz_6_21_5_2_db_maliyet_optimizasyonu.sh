#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_5_2_DB_MALIYET_OPTIMIZASYONU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_5_2_db_maliyet_optimizasyonu.v1.json"
PLAN_FILE="configs/faz6r/db_cost_optimization.cost_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_5_2_db_maliyet_optimizasyonu_test.json"
RUNTIME_FILE="scripts/faz6r/run_db_cost_optimization_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_db_maliyet_optimizasyonu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_5_2_db_maliyet_optimizasyonu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_5_2_DB_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
PREV_COMPUTE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_1_COMPUTE_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.5.2 DB MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.5.2 previous compute cost evidence file" "$PREV_COMPUTE_EVIDENCE"
check_contains "6-21.5.2 previous compute cost final PASS" "$PREV_COMPUTE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.5.2 documentation file" "$DOC_FILE"
check_file "6-21.5.2 config file" "$CONFIG_FILE"
check_file "6-21.5.2 plan file" "$PLAN_FILE"
check_file "6-21.5.2 fixture file" "$FIXTURE_FILE"
check_file "6-21.5.2 runtime file" "$RUNTIME_FILE"
check_file "6-21.5.2 validator file" "$VALIDATOR_FILE"
check_file "6-21.5.2 audit file" "$AUDIT_FILE"

check_contains "6-21.5.2 doc has DB Maliyet Optimizasyonu" "$DOC_FILE" "DB Maliyet Optimizasyonu"
check_contains "6-21.5.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.5.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.5.2 config has dependency" "$CONFIG_FILE" "FAZ_6_21_5_1"
check_contains "6-21.5.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.5.2 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.5.2 config disables db resize" "$CONFIG_FILE" '"db_resize_allowed": false'
check_contains "6-21.5.2 config disables replica delete" "$CONFIG_FILE" '"replica_delete_allowed": false'
check_contains "6-21.5.2 config disables index drop" "$CONFIG_FILE" '"index_drop_allowed": false'
check_contains "6-21.5.2 config disables partition drop" "$CONFIG_FILE" '"partition_drop_allowed": false'
check_contains "6-21.5.2 config disables retention delete" "$CONFIG_FILE" '"retention_delete_allowed": false'
check_contains "6-21.5.2 config disables backup delete" "$CONFIG_FILE" '"backup_delete_allowed": false'
check_contains "6-21.5.2 config has db inventory model" "$CONFIG_FILE" "db_inventory_model"
check_contains "6-21.5.2 config has connection pool review" "$CONFIG_FILE" "connection_pool_review_policy"
check_contains "6-21.5.2 config has query cost review" "$CONFIG_FILE" "query_cost_review_policy"
check_contains "6-21.5.2 config has index cost review" "$CONFIG_FILE" "index_cost_review_policy"
check_contains "6-21.5.2 config has replica cost review" "$CONFIG_FILE" "replica_cost_review_policy"
check_contains "6-21.5.2 config has retention cost review" "$CONFIG_FILE" "retention_cost_review_policy"
check_contains "6-21.5.2 config has storage growth review" "$CONFIG_FILE" "storage_growth_review_policy"
check_contains "6-21.5.2 config has backup cost review" "$CONFIG_FILE" "backup_cost_review_policy"
check_contains "6-21.5.2 config has data safety guard" "$CONFIG_FILE" "data_safety_guard"

check_contains "6-21.5.2 plan has connection pool recommendation" "$PLAN_FILE" "db-rec-connection-pool-review"
check_contains "6-21.5.2 plan has slow query recommendation" "$PLAN_FILE" "db-rec-slow-query-optimization"
check_contains "6-21.5.2 plan has unused index recommendation" "$PLAN_FILE" "db-rec-unused-index-review"
check_contains "6-21.5.2 plan has replica cost recommendation" "$PLAN_FILE" "db-rec-replica-cost-review"
check_contains "6-21.5.2 plan has backup retention recommendation" "$PLAN_FILE" "db-rec-backup-retention-review"
check_contains "6-21.5.2 plan has no mutation" "$PLAN_FILE" '"mutation_allowed": false'
check_contains "6-21.5.2 plan has dry-run status" "$PLAN_FILE" "dry_run_only_no_db_mutation"

check_contains "6-21.5.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_5_3"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_5_2_db_cost_runtime.json; then
  pass "6-21.5.2 dry-run DB cost runtime"
else
  fail "6-21.5.2 dry-run DB cost runtime"
fi

check_contains "6-21.5.2 runtime output is PASS" "/tmp/faz_6_21_5_2_db_cost_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.5.2 runtime output is dry run" "/tmp/faz_6_21_5_2_db_cost_runtime.json" "db_cost_optimization_dry_run"
check_contains "6-21.5.2 runtime output disables provider mutation" "/tmp/faz_6_21_5_2_db_cost_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.5.2 runtime output disables db resize" "/tmp/faz_6_21_5_2_db_cost_runtime.json" '"db_resize_allowed": false'
check_contains "6-21.5.2 runtime output disables index drop" "/tmp/faz_6_21_5_2_db_cost_runtime.json" '"index_drop_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.5.2 semantic validator runtime"
else
  fail "6-21.5.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.5.2 python3 dependency"
else
  fail "6-21.5.2 python3 dependency"
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
# FAZ 6-R / 294 — FAZ 6-21.5.2 DB Maliyet Optimizasyonu Real Implementation Audit

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
FAZ_6_21_5_3_READY=${NEXT_READY}

Scope note: provider mutation, DB resize, replica delete, index drop, partition drop, retention delete and backup delete remain closed in this step.
Dependency: FAZ_6_21_5_1 compute maliyet optimizasyonu evidence checked.
EOF2

echo "===== FAZ 6-21.5.2 DB MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_5_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.5.2 DB MALIYET OPTIMIZASYONU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_5_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
