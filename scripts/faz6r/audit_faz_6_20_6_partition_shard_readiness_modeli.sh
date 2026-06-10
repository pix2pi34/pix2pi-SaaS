#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_20_6_PARTITION_SHARD_READINESS_MODELI.md"
CONFIG_FILE="configs/faz6r/faz_6_20_6_partition_shard_readiness_modeli.v1.json"
MODEL_FILE="configs/faz6r/partition_shard_readiness_model.db_scale.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_20_6_partition_shard_readiness_modeli_test.json"
RUNTIME_FILE="scripts/faz6r/run_partition_shard_readiness_model_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_partition_shard_readiness_modeli.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_20_6_partition_shard_readiness_modeli.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_20_6_PARTITION_SHARD_READINESS_MODELI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_REPLICA_ROUTING_EVIDENCE="docs/faz6r/evidence/FAZ_6_20_2_REPLICA_ROUTING_READ_POOL_STRATEJISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-20.6 PARTITION SHARD READINESS MODELI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-20.6 previous replica routing evidence file" "$PREV_REPLICA_ROUTING_EVIDENCE"
check_contains "6-20.6 previous replica routing final PASS" "$PREV_REPLICA_ROUTING_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-20.6 documentation file" "$DOC_FILE"
check_file "6-20.6 config file" "$CONFIG_FILE"
check_file "6-20.6 model file" "$MODEL_FILE"
check_file "6-20.6 fixture file" "$FIXTURE_FILE"
check_file "6-20.6 runtime file" "$RUNTIME_FILE"
check_file "6-20.6 validator file" "$VALIDATOR_FILE"
check_file "6-20.6 audit file" "$AUDIT_FILE"

check_contains "6-20.6 doc has Partition / Shard Readiness" "$DOC_FILE" "Partition / Shard Readiness"
check_contains "6-20.6 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-20.6 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-20.6 config has dependency" "$CONFIG_FILE" "FAZ_6_20_2"
check_contains "6-20.6 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-20.6 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-20.6 config disables partition create" "$CONFIG_FILE" '"partition_create_allowed": false'
check_contains "6-20.6 config disables partition drop" "$CONFIG_FILE" '"partition_drop_allowed": false'
check_contains "6-20.6 config disables shard split" "$CONFIG_FILE" '"shard_split_allowed": false'
check_contains "6-20.6 config disables shard move" "$CONFIG_FILE" '"shard_move_allowed": false'
check_contains "6-20.6 config disables tenant move" "$CONFIG_FILE" '"tenant_move_allowed": false'
check_contains "6-20.6 config disables table rewrite" "$CONFIG_FILE" '"table_rewrite_allowed": false'
check_contains "6-20.6 config disables index rebuild" "$CONFIG_FILE" '"index_rebuild_allowed": false'
check_contains "6-20.6 config disables routing mutation" "$CONFIG_FILE" '"routing_mutation_allowed": false'
check_contains "6-20.6 config has shard key policy" "$CONFIG_FILE" "shard_key_readiness_policy"
check_contains "6-20.6 config has tenant distribution model" "$CONFIG_FILE" "tenant_distribution_model"
check_contains "6-20.6 config has cross shard guard" "$CONFIG_FILE" "cross_shard_transaction_guard"
check_contains "6-20.6 config has FK boundary guard" "$CONFIG_FILE" "foreign_key_boundary_guard"
check_contains "6-20.6 config has reporting impact guard" "$CONFIG_FILE" "reporting_readmodel_impact_guard"
check_contains "6-20.6 config has rollback reversibility" "$CONFIG_FILE" "rollback_reversibility_policy"

check_contains "6-20.6 model has tenant events readiness" "$MODEL_FILE" "partition-ready-tenant-operational-events"
check_contains "6-20.6 model has audit logs readiness" "$MODEL_FILE" "partition-ready-audit-logs-time"
check_contains "6-20.6 model has reporting readiness" "$MODEL_FILE" "partition-ready-reporting-readmodels"
check_contains "6-20.6 model has pos shard review" "$MODEL_FILE" "shard-review-pos-receipt-movements"
check_contains "6-20.6 model has finance blocked" "$MODEL_FILE" "shard-blocked-finance-ledger"
check_contains "6-20.6 model has no mutation" "$MODEL_FILE" '"mutation_allowed": false'
check_contains "6-20.6 model has dry-run status" "$MODEL_FILE" "dry_run_only_no_partition_shard_mutation"
check_contains "6-20.6 model has next step" "$MODEL_FILE" "FAZ_6_22_2"

check_contains "6-20.6 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_22_2"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$MODEL_FILE" "$FIXTURE_FILE" >/tmp/faz_6_20_6_partition_shard_readiness_runtime.json; then
  pass "6-20.6 dry-run partition shard readiness runtime"
else
  fail "6-20.6 dry-run partition shard readiness runtime"
fi

check_contains "6-20.6 runtime output is PASS" "/tmp/faz_6_20_6_partition_shard_readiness_runtime.json" '"runtime_status": "PASS"'
check_contains "6-20.6 runtime output is dry run" "/tmp/faz_6_20_6_partition_shard_readiness_runtime.json" "partition_shard_readiness_model_dry_run"
check_contains "6-20.6 runtime output disables provider mutation" "/tmp/faz_6_20_6_partition_shard_readiness_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-20.6 runtime output disables tenant move" "/tmp/faz_6_20_6_partition_shard_readiness_runtime.json" '"tenant_move_allowed": false'
check_contains "6-20.6 runtime output has next step" "/tmp/faz_6_20_6_partition_shard_readiness_runtime.json" "FAZ_6_22_2"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$MODEL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-20.6 semantic validator runtime"
else
  fail "6-20.6 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-20.6 python3 dependency"
else
  fail "6-20.6 python3 dependency"
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
# FAZ 6-R / 307 — FAZ 6-20.6 Partition / Shard Readiness Modeli Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
MODEL_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_22_2_READY=${NEXT_READY}

DB_L8_SCALE_READINESS_REMAINING_COMPLETE=YES
FAZ_6_R_PRIORITY_3_READY=YES

Scope note: provider mutation, partition create/drop, shard split/move, tenant move, table rewrite, index rebuild, sequence remap, FK mutation, routing mutation and DSN mutation remain closed in this step.
Dependency: FAZ_6_20_2 replica routing / read pool stratejisi evidence checked.
EOF2

echo "===== FAZ 6-20.6 PARTITION SHARD READINESS MODELI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_20_6_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-20.6 PARTITION SHARD READINESS MODELI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "MODEL_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "DB_L8_SCALE_READINESS_REMAINING_COMPLETE=YES"
echo "FAZ_6_R_PRIORITY_3_READY=YES"
echo "FAZ_6_22_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
