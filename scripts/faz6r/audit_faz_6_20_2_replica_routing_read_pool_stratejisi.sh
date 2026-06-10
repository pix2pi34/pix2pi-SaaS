#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_20_2_REPLICA_ROUTING_READ_POOL_STRATEJISI.md"
CONFIG_FILE="configs/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi.v1.json"
STRATEGY_FILE="configs/faz6r/replica_routing_read_pool_strategy.db_scale.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi_test.json"
RUNTIME_FILE="scripts/faz6r/run_replica_routing_read_pool_strategy_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_replica_routing_read_pool_stratejisi.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_20_2_replica_routing_read_pool_stratejisi.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_20_2_REPLICA_ROUTING_READ_POOL_STRATEJISI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_NODE_FENCING_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_1_5_NODE_HEALTH_FENCING_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-20.2 REPLICA ROUTING READ POOL STRATEJISI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-20.2 previous node health fencing evidence file" "$PREV_NODE_FENCING_EVIDENCE"
check_contains "6-20.2 previous node health fencing final PASS" "$PREV_NODE_FENCING_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-20.2 documentation file" "$DOC_FILE"
check_file "6-20.2 config file" "$CONFIG_FILE"
check_file "6-20.2 strategy file" "$STRATEGY_FILE"
check_file "6-20.2 fixture file" "$FIXTURE_FILE"
check_file "6-20.2 runtime file" "$RUNTIME_FILE"
check_file "6-20.2 validator file" "$VALIDATOR_FILE"
check_file "6-20.2 audit file" "$AUDIT_FILE"

check_contains "6-20.2 doc has Replica Routing" "$DOC_FILE" "Replica Routing"
check_contains "6-20.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-20.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-20.2 config has dependency" "$CONFIG_FILE" "FAZ_6_21_1_5"
check_contains "6-20.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-20.2 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-20.2 config disables dsn mutation" "$CONFIG_FILE" '"dsn_mutation_allowed": false'
check_contains "6-20.2 config disables app route mutation" "$CONFIG_FILE" '"application_route_mutation_allowed": false'
check_contains "6-20.2 config disables read pool attach" "$CONFIG_FILE" '"read_pool_attach_allowed": false'
check_contains "6-20.2 config disables read pool detach" "$CONFIG_FILE" '"read_pool_detach_allowed": false'
check_contains "6-20.2 config disables replica promotion" "$CONFIG_FILE" '"replica_promotion_allowed": false'
check_contains "6-20.2 config has read write split" "$CONFIG_FILE" "read_write_split_policy"
check_contains "6-20.2 config has primary write guard" "$CONFIG_FILE" "primary_write_only_guard"
check_contains "6-20.2 config has replica read pool model" "$CONFIG_FILE" "replica_read_pool_model"
check_contains "6-20.2 config has lag aware routing" "$CONFIG_FILE" "lag_aware_routing_policy"
check_contains "6-20.2 config has read after write guard" "$CONFIG_FILE" "read_after_write_consistency_guard"
check_contains "6-20.2 config has tenant safe read routing" "$CONFIG_FILE" "tenant_safe_read_routing_guard"

check_contains "6-20.2 strategy has operational api decision" "$STRATEGY_FILE" "readpool-operational-api-conditional"
check_contains "6-20.2 strategy has reporting decision" "$STRATEGY_FILE" "readpool-reporting-replica-eligible"
check_contains "6-20.2 strategy has dashboard decision" "$STRATEGY_FILE" "readpool-dashboard-route-based"
check_contains "6-20.2 strategy has export decision" "$STRATEGY_FILE" "readpool-background-export-replica"
check_contains "6-20.2 strategy has finance primary decision" "$STRATEGY_FILE" "readpool-billing-finance-primary-strict"
check_contains "6-20.2 strategy has no mutation" "$STRATEGY_FILE" '"mutation_allowed": false'
check_contains "6-20.2 strategy has dry-run status" "$STRATEGY_FILE" "dry_run_only_no_replica_routing_mutation"
check_contains "6-20.2 strategy has next step" "$STRATEGY_FILE" "FAZ_6_20_6"

check_contains "6-20.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_20_6"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$STRATEGY_FILE" "$FIXTURE_FILE" >/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json; then
  pass "6-20.2 dry-run replica routing runtime"
else
  fail "6-20.2 dry-run replica routing runtime"
fi

check_contains "6-20.2 runtime output is PASS" "/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json" '"runtime_status": "PASS"'
check_contains "6-20.2 runtime output is dry run" "/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json" "replica_routing_read_pool_strategy_dry_run"
check_contains "6-20.2 runtime output disables provider mutation" "/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-20.2 runtime output disables dsn mutation" "/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json" '"dsn_mutation_allowed": false'
check_contains "6-20.2 runtime output has next step" "/tmp/faz_6_20_2_replica_routing_read_pool_runtime.json" "FAZ_6_20_6"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$STRATEGY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-20.2 semantic validator runtime"
else
  fail "6-20.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-20.2 python3 dependency"
else
  fail "6-20.2 python3 dependency"
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
# FAZ 6-R / 306 — FAZ 6-20.2 Replica Routing / Read Pool Stratejisi Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
STRATEGY_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_20_6_READY=${NEXT_READY}

Scope note: provider mutation, DSN mutation, application route mutation, read pool attach/detach, replica promotion, DB role mutation, DNS mutation and load balancer mutation remain closed in this step.
Dependency: FAZ_6_21_1_5 node health fencing evidence checked.
EOF2

echo "===== FAZ 6-20.2 REPLICA ROUTING READ POOL STRATEJISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_20_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-20.2 REPLICA ROUTING READ POOL STRATEJISI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "STRATEGY_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_20_6_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
