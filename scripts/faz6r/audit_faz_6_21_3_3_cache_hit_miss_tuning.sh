#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_3_3_CACHE_HIT_MISS_TUNING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_3_3_cache_hit_miss_tuning.v1.json"
TUNING_FILE="configs/faz6r/cache_hit_miss_tuning.performance_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_3_3_cache_hit_miss_tuning_test.json"
RUNTIME_FILE="scripts/faz6r/run_cache_hit_miss_tuning_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_cache_hit_miss_tuning.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_3_3_cache_hit_miss_tuning.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_3_3_CACHE_HIT_MISS_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_COST_PERF_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_5_COST_PERFORMANCE_RAPORU_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail(){
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label missing"
  fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label missing pattern $pattern"
  fi
}

echo "===== FAZ 6-21.3.3 CACHE HIT/MISS TUNING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.3.3 previous cost-performance evidence file" "$PREV_COST_PERF_EVIDENCE"
check_contains "6-21.3.3 previous cost-performance final PASS" "$PREV_COST_PERF_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.3.3 documentation file" "$DOC_FILE"
check_file "6-21.3.3 config file" "$CONFIG_FILE"
check_file "6-21.3.3 tuning file" "$TUNING_FILE"
check_file "6-21.3.3 fixture file" "$FIXTURE_FILE"
check_file "6-21.3.3 runtime file" "$RUNTIME_FILE"
check_file "6-21.3.3 validator file" "$VALIDATOR_FILE"
check_file "6-21.3.3 audit file" "$AUDIT_FILE"

check_contains "6-21.3.3 doc has Cache Hit/Miss Tuning" "$DOC_FILE" "Cache Hit/Miss Tuning"
check_contains "6-21.3.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.3.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.3.3 config has dependency" "$CONFIG_FILE" "FAZ_6_21_5_5"
check_contains "6-21.3.3 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.3.3 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.3.3 config disables redis mutation" "$CONFIG_FILE" '"redis_mutation_allowed": false'
check_contains "6-21.3.3 config disables cache flush" "$CONFIG_FILE" '"cache_flush_allowed": false'
check_contains "6-21.3.3 config disables key delete" "$CONFIG_FILE" '"cache_key_delete_allowed": false'
check_contains "6-21.3.3 config disables ttl mutation" "$CONFIG_FILE" '"cache_ttl_mutation_allowed": false'
check_contains "6-21.3.3 config disables namespace mutation" "$CONFIG_FILE" '"namespace_mutation_allowed": false'
check_contains "6-21.3.3 config has tenant namespace guard" "$CONFIG_FILE" "tenant_namespace_guard"
check_contains "6-21.3.3 config has ttl tuning policy" "$CONFIG_FILE" "ttl_tuning_policy"
check_contains "6-21.3.3 config has hot key review policy" "$CONFIG_FILE" "hot_key_review_policy"
check_contains "6-21.3.3 config has fallback safety" "$CONFIG_FILE" "fallback_safety_policy"
check_contains "6-21.3.3 config has stale data guard" "$CONFIG_FILE" "stale_data_guard"
check_contains "6-21.3.3 config has rate limit cache guard" "$CONFIG_FILE" "rate_limit_cache_guard"

check_contains "6-21.3.3 tuning has tenant ttl recommendation" "$TUNING_FILE" "cache-tune-tenant-data-ttl-review"
check_contains "6-21.3.3 tuning has readmodel recommendation" "$TUNING_FILE" "cache-tune-readmodel-cache-hit-ratio"
check_contains "6-21.3.3 tuning has hot key recommendation" "$TUNING_FILE" "cache-tune-hot-key-distribution"
check_contains "6-21.3.3 tuning has rate limit recommendation" "$TUNING_FILE" "cache-tune-rate-limit-cache-safety"
check_contains "6-21.3.3 tuning has public asset recommendation" "$TUNING_FILE" "cache-tune-public-asset-cache"
check_contains "6-21.3.3 tuning has no mutation" "$TUNING_FILE" '"mutation_allowed": false'
check_contains "6-21.3.3 tuning has dry-run status" "$TUNING_FILE" "dry_run_only_no_cache_mutation"

check_contains "6-21.3.3 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_3_4"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json; then
  pass "6-21.3.3 dry-run cache tuning runtime"
else
  fail "6-21.3.3 dry-run cache tuning runtime"
fi

check_contains "6-21.3.3 runtime output is PASS" "/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.3.3 runtime output is dry run" "/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json" "cache_hit_miss_tuning_dry_run"
check_contains "6-21.3.3 runtime output disables provider mutation" "/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.3.3 runtime output disables redis mutation" "/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json" '"redis_mutation_allowed": false'
check_contains "6-21.3.3 runtime output disables cache flush" "/tmp/faz_6_21_3_3_cache_hit_miss_runtime.json" '"cache_flush_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.3.3 semantic validator runtime"
else
  fail "6-21.3.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.3.3 python3 dependency"
else
  fail "6-21.3.3 python3 dependency"
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
# FAZ 6-R / 298 — FAZ 6-21.3.3 Cache Hit/Miss Tuning Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
TUNING_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_3_4_READY=${NEXT_READY}

Scope note: provider mutation, Redis mutation, cache flush, key delete, TTL mutation and namespace mutation remain closed in this step.
Dependency: FAZ_6_21_5_5 cost-performance raporu evidence checked.
FIX_V2_STATUS=AUDIT_SCRIPT_SYNTAX_FIXED
EOF2

echo "===== FAZ 6-21.3.3 CACHE HIT/MISS TUNING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_3_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.3.3 CACHE HIT/MISS TUNING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "TUNING_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_3_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
