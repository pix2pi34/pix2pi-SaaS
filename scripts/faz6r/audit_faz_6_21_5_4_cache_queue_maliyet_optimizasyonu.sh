#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_5_4_CACHE_QUEUE_MALIYET_OPTIMIZASYONU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu.v1.json"
PLAN_FILE="configs/faz6r/cache_queue_cost_optimization.cost_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu_test.json"
RUNTIME_FILE="scripts/faz6r/run_cache_queue_cost_optimization_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_cache_queue_maliyet_optimizasyonu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_5_4_cache_queue_maliyet_optimizasyonu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_5_4_CACHE_QUEUE_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
PREV_STORAGE_LOG_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_3_STORAGE_LOG_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.5.4 CACHE QUEUE MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.5.4 previous storage log cost evidence file" "$PREV_STORAGE_LOG_EVIDENCE"
check_contains "6-21.5.4 previous storage log cost final PASS" "$PREV_STORAGE_LOG_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.5.4 documentation file" "$DOC_FILE"
check_file "6-21.5.4 config file" "$CONFIG_FILE"
check_file "6-21.5.4 plan file" "$PLAN_FILE"
check_file "6-21.5.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.5.4 runtime file" "$RUNTIME_FILE"
check_file "6-21.5.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.5.4 audit file" "$AUDIT_FILE"

check_contains "6-21.5.4 doc has Cache Queue Maliyet Optimizasyonu" "$DOC_FILE" "Cache / Queue Maliyet Optimizasyonu"
check_contains "6-21.5.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.5.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.5.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_5_3"
check_contains "6-21.5.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.5.4 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.5.4 config disables cache flush" "$CONFIG_FILE" '"cache_flush_allowed": false'
check_contains "6-21.5.4 config disables cache key delete" "$CONFIG_FILE" '"cache_key_delete_allowed": false'
check_contains "6-21.5.4 config disables ttl mutation" "$CONFIG_FILE" '"cache_ttl_mutation_allowed": false'
check_contains "6-21.5.4 config disables queue purge" "$CONFIG_FILE" '"queue_purge_allowed": false'
check_contains "6-21.5.4 config disables stream delete" "$CONFIG_FILE" '"stream_delete_allowed": false'
check_contains "6-21.5.4 config disables consumer delete" "$CONFIG_FILE" '"consumer_delete_allowed": false'
check_contains "6-21.5.4 config disables retention mutation" "$CONFIG_FILE" '"queue_retention_mutation_allowed": false'
check_contains "6-21.5.4 config has cache inventory" "$CONFIG_FILE" "cache_inventory_model"
check_contains "6-21.5.4 config has queue inventory" "$CONFIG_FILE" "queue_inventory_model"
check_contains "6-21.5.4 config has tenant namespace guard" "$CONFIG_FILE" "tenant_namespace_guard"
check_contains "6-21.5.4 config has idempotency guard" "$CONFIG_FILE" "idempotency_safety_guard"

check_contains "6-21.5.4 plan has ttl recommendation" "$PLAN_FILE" "cache-rec-ttl-review"
check_contains "6-21.5.4 plan has hot key recommendation" "$PLAN_FILE" "cache-rec-hot-key-review"
check_contains "6-21.5.4 plan has stream retention recommendation" "$PLAN_FILE" "queue-rec-stream-retention-review"
check_contains "6-21.5.4 plan has consumer lag recommendation" "$PLAN_FILE" "queue-rec-consumer-lag-review"
check_contains "6-21.5.4 plan has dlq recommendation" "$PLAN_FILE" "queue-rec-dlq-growth-review"
check_contains "6-21.5.4 plan has no mutation" "$PLAN_FILE" '"mutation_allowed": false'
check_contains "6-21.5.4 plan has dry-run status" "$PLAN_FILE" "dry_run_only_no_cache_queue_mutation"

check_contains "6-21.5.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_5_5"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json; then
  pass "6-21.5.4 dry-run cache queue cost runtime"
else
  fail "6-21.5.4 dry-run cache queue cost runtime"
fi

check_contains "6-21.5.4 runtime output is PASS" "/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.5.4 runtime output is dry run" "/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json" "cache_queue_cost_optimization_dry_run"
check_contains "6-21.5.4 runtime output disables provider mutation" "/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.5.4 runtime output disables cache flush" "/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json" '"cache_flush_allowed": false'
check_contains "6-21.5.4 runtime output disables queue purge" "/tmp/faz_6_21_5_4_cache_queue_cost_runtime.json" '"queue_purge_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.5.4 semantic validator runtime"
else
  fail "6-21.5.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.5.4 python3 dependency"
else
  fail "6-21.5.4 python3 dependency"
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
# FAZ 6-R / 296 — FAZ 6-21.5.4 Cache / Queue Maliyet Optimizasyonu Real Implementation Audit

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
FAZ_6_21_5_5_READY=${NEXT_READY}

Scope note: provider mutation, cache flush, key delete, TTL mutation, queue purge, stream delete, consumer delete and queue retention mutation remain closed in this step.
Dependency: FAZ_6_21_5_3 storage / log maliyet optimizasyonu evidence checked.
EOF2

echo "===== FAZ 6-21.5.4 CACHE QUEUE MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_5_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.5.4 CACHE QUEUE MALIYET OPTIMIZASYONU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_5_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
